import 'dart:async';

import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/session_manager.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_booking_for_whom.dart';
import 'tutor_policy_widgets.dart';
import 'tutor_pricing_widgets.dart';

String? _modeLabel(String mode) => switch (mode) {
      'online' => L10n.current.commonOnline,
      'student_home' => L10n.current.tutoringModeStudentHomeMine,
      'tutor_home' => L10n.current.tutoringModeTutorHome,
      'neutral_place' => L10n.current.tutoringModeNeutralPlace,
      _ => null,
    };
const _modeIcons = {
  'online': Icons.videocam_outlined,
  'student_home': Icons.home_outlined,
  'tutor_home': Icons.school_outlined,
  'neutral_place': Icons.place_outlined,
};

/// Flow de réservation en 3 écrans (professeur_complete.md  "Flow de
/// réservation mobile", 3 écrans maximum) implémenté comme un seul écran
/// avec état interne d'étape, à l'image du stepper de TutorProfileScreen.
class TutorBookingFlowScreen extends StatefulWidget {
  final TutorProfile profile;
  final List<TutorAvailabilityOccurrence> occurrences;
  final TutorAvailabilityOccurrence? initialOccurrence;

  /// Sujets déjà saisis dans la recherche de tuteurs (lot 9.1).
  final List<String> initialTopics;

  /// Lot 9.3 : réservation en un clic depuis une attribution active.
  final TutorAssignment? assignment;

  const TutorBookingFlowScreen({
    super.key,
    required this.profile,
    this.occurrences = const [],
    this.initialOccurrence,
    this.initialTopics = const [],
    this.assignment,
  });

  @override
  State<TutorBookingFlowScreen> createState() => _TutorBookingFlowScreenState();
}

class _TutorBookingFlowScreenState extends State<TutorBookingFlowScreen> {
  int _step = 0; // 0 = créneau, 1 = récap, 2 = paiement

  List<TutorAvailabilityOccurrence> _occurrences = [];
  bool _loadingCalendar = false;
  late DateTime _selectedDay;
  TutorAvailabilityOccurrence? _selectedOccurrence;
  String? _mode;

  // Lot 9.1 : durée libre par tranches de 30 min, matière (tarif de base),
  // sujets à travailler et devis serveur.
  int? _durationMinutes;
  String? _subject;
  List<String> _topics = [];
  TutorPriceQuote? _quote;
  bool _quoteLoading = false;
  String? _quoteError;
  int _quoteRequest = 0;

  // Lot 9.2 (17.6) : Mobile Money ou solde du portefeuille (lu sur le serveur).
  String _payMethod = 'mobile_money';
  num? _walletAvailable;
  bool _walletLoading = false;

  // Lot 9.3 (17.4) : pour qui (enfants, élèves de l'institution, groupe d'étude).
  TutorBookingContext? _ctx;
  ForWhomValue _forWhom = const ForWhomValue();
  int? _currentUserId;

  int get _maxGroupSize => widget.profile.effectiveMaxGroupSize;
  int get _participantCount => _forWhom.count < 1 ? 1 : _forWhom.count;

  Future<void> _loadContext() async {
    _currentUserId = await SessionManager.getUserId();
    try {
      final ctx = await TutorBookingService.instance.getBookingContext();
      if (!mounted) return;
      final preset = widget.assignment?.beneficiaries.map((b) => b.userId).take(_maxGroupSize < 1 ? 1 : _maxGroupSize).toList();
      setState(() {
        _ctx = ctx;
        _forWhom = ForWhomValue.initial(ctx, preset: preset);
      });
    } catch (_) {
      // Sans contexte : réservation pour soi, comme avant le 9.3.
    }
  }

  String get _participantNames {
    if (_forWhom.payerType == 'student') return L10n.current.tutoringMe;
    final pool = [
      ...?_ctx?.children,
      ...?_ctx?.institutionStudents,
      ...?_ctx?.studyGroups.expand((g) => g.members),
    ];
    return _forWhom.participantIds
        .map((id) => id == _currentUserId
            ? L10n.current.tutoringMe
            : (pool.where((p) => p.userId == id).firstOrNull?.label ?? '#$id'))
        .join(', ');
  }

  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  TutorBookingRecord? _booking;
  Timer? _pollTimer;
  DateTime? _pollStarted;
  bool _pollTimedOut = false;

  List<String> get _availableModes {
    final p = widget.profile;
    return [
      if (p.offersOnline) 'online',
      if (p.offersAtStudentHome) 'student_home',
      if (p.offersAtTutorHome) 'tutor_home',
      if (p.offersNeutralPlace) 'neutral_place',
    ];
  }

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDay = DateTime(today.year, today.month, today.day);
    _mode = _availableModes.isNotEmpty ? _availableModes.first : null;
    _subject =
        widget.profile.subjects.isNotEmpty ? widget.profile.subjects.first : null;
    _topics = widget.initialTopics.take(kMaxTopics).toList();
    final assignedSubject = widget.assignment?.subject;
    if (assignedSubject != null && widget.profile.subjects.contains(assignedSubject)) {
      _subject = assignedSubject;
    }
    _loadContext();

    if (widget.occurrences.isNotEmpty) {
      _occurrences = widget.occurrences;
    } else {
      _loadCalendar();
    }

    if (widget.initialOccurrence != null) {
      // Le créneau tapé sur la fiche est présélectionné ; l'élève choisit
      // encore sa durée, sa matière et ses sujets avant le récapitulatif.
      final d = widget.initialOccurrence!.date;
      _selectedDay = DateTime(d.year, d.month, d.day);
      _pickOccurrence(widget.initialOccurrence!);
    }
  }

  void _pickOccurrence(TutorAvailabilityOccurrence occ) {
    final durations = occ.availableDurationsMinutes;
    _selectedOccurrence = occ;
    _durationMinutes = durations.isEmpty
        ? null
        : durations.length == 1
            ? durations.first
            : (durations.contains(60) ? 60 : durations.first);
  }

  /// Devis serveur (jamais de prix calculé localement) ; seule la réponse
  /// à la dernière demande est gardée.
  Future<void> _refreshQuote() async {
    final occ = _selectedOccurrence;
    final duration = _durationMinutes;
    final mode = _mode;
    if (occ == null || duration == null || mode == null) return;
    final req = ++_quoteRequest;
    setState(() {
      _quoteLoading = true;
      _quoteError = null;
    });
    try {
      final q = await TutorBookingService.instance.quote(
        tutorUserId: widget.profile.userId,
        sessionDate: occ.date,
        startTime: occ.startTime,
        durationMinutes: duration,
        mode: mode,
        subject: _subject,
        participantCount: _participantCount,
      );
      if (!mounted || req != _quoteRequest) return;
      setState(() {
        _quote = q;
        _quoteLoading = false;
      });
    } catch (e) {
      if (!mounted || req != _quoteRequest) return;
      setState(() {
        _quote = null;
        _quoteLoading = false;
        _quoteError = _apiMessage(e) ?? L10n.current.tutoringQuoteError;
      });
    }
  }

  static String? _apiMessage(Object e) {
    try {
      final data = (e as dynamic).response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
    } catch (_) {}
    return null;
  }

  bool get _quoteReady =>
      _quote != null && _quote!.isAvailable != false && !_quoteLoading;

  bool get _walletCovers =>
      _walletAvailable != null &&
      _quote != null &&
      _walletAvailable! >= _quote!.totalXaf;

  // Suivi 17.14 : libellés du solde adaptés au payeur (élève, parent,
  // institution, membre qui paie pour son groupe d'étude).
  String get _walletTitle => switch (_forWhom.payerType) {
        'parent' => L10n.current.tutoringWalletParent,
        'institution' => L10n.current.tutoringWalletInstitution,
        'study_group' => L10n.current.tutoringWalletMineGroup,
        _ => L10n.current.tutoringWalletMine,
      };

  String get _walletPayLabel => switch (_forWhom.payerType) {
        'parent' => L10n.current.tutoringPayWithParentWallet,
        'institution' => L10n.current.tutoringPayWithInstitutionWallet,
        _ => L10n.current.tutoringPayWithBalance,
      };

  String get _walletShortfallHint => switch (_forWhom.payerType) {
        'parent' => L10n.current.tutoringShortfallParent,
        'institution' =>
          L10n.current.tutoringShortfallInstitution,
        _ => L10n.current.tutoringShortfallMine,
      };

  Future<void> _loadWallet() async {
    setState(() => _walletLoading = true);
    final available = await TutorBookingService.instance.getWalletAvailableXaf();
    if (!mounted) return;
    setState(() {
      _walletAvailable = available;
      _walletLoading = false;
    });
  }

  void _goToPayment() {
    setState(() => _step = 2);
    _loadWallet();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCalendar() async {
    setState(() => _loadingCalendar = true);
    try {
      final occ = await TutorBookingService.instance
          .getTwoWeekCalendar(widget.profile.userId);
      if (mounted)
        setState(() {
          _occurrences = occ;
          _loadingCalendar = false;
        });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCalendar = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.tutoringCalendarError)));
      }
    }
  }

  List<DateTime> get _days {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(14, (i) => start.add(Duration(days: i)));
  }

  bool _dayHasBookable(DateTime day) => _occurrences.any((o) =>
      o.date.year == day.year &&
      o.date.month == day.month &&
      o.date.day == day.day &&
      o.isBookable);

  /// Formatte un numéro camerounais en local sans indicatif pays, comme
  /// attendu par le backend (NotchPay) : on retire les préfixes +237 / 237
  /// et tout ce qui n'est pas un chiffre.
  String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('237') && digits.length > 9) {
      digits = digits.substring(digits.length - 9);
    }
    return digits;
  }

  Future<void> _submitBooking() async {
    final occ = _selectedOccurrence;
    final mode = _mode;
    final duration = _durationMinutes;
    if (occ == null || mode == null || duration == null || !_quoteReady) {
      return;
    }
    final byWallet = _payMethod == 'wallet';
    final phone = _normalizePhone(_phoneCtrl.text);
    if (!byWallet && phone.length < 9) {
      setState(() => _submitError = L10n.current.tutoringPhoneInvalid);
      return;
    }
    if (byWallet && !_walletCovers) {
      setState(() => _submitError =
          L10n.current.tutoringBalanceNotCover(_walletShortfallHint));
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final result = await TutorBookingService.instance.createBooking(
        tutorUserId: widget.profile.userId,
        sessionDate: occ.date,
        startTime: occ.startTime,
        durationMinutes: duration,
        mode: mode,
        phone: byWallet ? null : phone,
        paymentMethod: _payMethod,
        subject: _subject,
        topics: _topics,
        payerType: _forWhom.payerType,
        participantUserIds: _forWhom.payerType == 'student' ? null : _forWhom.participantIds,
        studyGroupId: _forWhom.studyGroupId,
        tutorAssignmentId: widget.assignment?.isActive == true ? widget.assignment!.id : null,
      );
      if (!mounted) return;
      setState(() {
        _booking = result.booking;
        _submitting = false;
      });
      // Payé par solde : débité avec la création, la demande part tout de
      // suite au tuteur ; aucune confirmation Mobile Money à attendre.
      if (!byWallet) _startPolling(result.booking.id);
    } catch (e) {
      if (mounted) {
        setState(() {
          _submitting = false;
          _submitError = _apiMessage(e) ??
              L10n.current.tutoringBookingCreateError;
        });
      }
    }
  }

  void _startPolling(int bookingId) {
    _pollStarted = DateTime.now();
    setState(() => _pollTimedOut = false);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      if (!mounted) {
        t.cancel();
        return;
      }
      final elapsed = DateTime.now().difference(_pollStarted!);
      if (elapsed > const Duration(minutes: 5)) {
        t.cancel();
        setState(() => _pollTimedOut = true);
        return;
      }
      try {
        final b = await TutorBookingService.instance.getBooking(bookingId);
        if (!mounted) return;
        setState(() => _booking = b);
        if (b.isConfirmed || b.isPendingTutorApproval || b.isCancelled) {
          t.cancel();
        }
      } catch (_) {
        // on retente au prochain tick
      }
    });
  }

  void _goToStep1() {
    if (_selectedOccurrence == null || _durationMinutes == null) return;
    setState(() => _step = 1);
    _refreshQuote();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final titles = [
      context.l10n.tutoringStepChooseSlot,
      context.l10n.tutoringStepRecap,
      context.l10n.tutoringStepPayment
    ];
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () {
            if (_step > 0 && _booking == null) {
              setState(() => _step -= 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(titles[_step], style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: Column(children: [
          if (_booking == null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: _BookingStepper(step: _step),
            ),
          ],
          Expanded(
            child: switch (_step) {
              0 => _buildStepSlot(s),
              1 => _buildStepRecap(s),
              _ => _buildStepPayment(s),
            },
          ),
        ]),
      ),
    );
  }

  // ---------------- Étape 1 : choix du créneau ----------------

  Widget _buildStepSlot(WinScheme s) {
    if (_loadingCalendar)
      return const Center(child: CircularProgressIndicator());
    final daySlots = _occurrences
        .where((o) =>
            o.date.year == _selectedDay.year &&
            o.date.month == _selectedDay.month &&
            o.date.day == _selectedDay.day)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(context.l10n.tutoringTutor, style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 4),
        Text(widget.profile.fullName ?? widget.profile.title ?? context.l10n.tutoringTutor,
            style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 20),
        Text(context.l10n.tutoringChooseDay, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = _days[i];
              final active = day.year == _selectedDay.year &&
                  day.month == _selectedDay.month &&
                  day.day == _selectedDay.day;
              final bookable = _dayHasBookable(day);
              return GestureDetector(
                onTap: () => setState(() {
                  _selectedDay = day;
                  _selectedOccurrence = null;
                }),
                child: Container(
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active
                        ? s.primary
                        : (bookable ? WinColors.successBg : s.chipBg),
                    borderRadius: BorderRadius.circular(WinRadii.sm),
                    border: Border.all(color: active ? s.primary : s.outline),
                  ),
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(WinFormat.weekdayShortCap(day.weekday),
                            style: WinType.labelS(
                                active ? Colors.white : s.onMuted)),
                        const SizedBox(height: 2),
                        Text('${day.day}',
                            style: WinType.titleM(active
                                ? Colors.white
                                : (bookable ? WinColors.success : s.onStrong))),
                      ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.tutoringAvailableSlots, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        if (daySlots.isEmpty)
          Text(context.l10n.tutoringNoSlotThatDay, style: WinType.bodyS(s.onFaint))
        else
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: daySlots.map((occ) {
                final selected = _selectedOccurrence == occ;
                return GestureDetector(
                  onTap: occ.isBookable
                      ? () => setState(() => _pickOccurrence(occ))
                      : null,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: selected
                          ? s.primary
                          : (occ.isBookable ? WinColors.successBg : s.chipBg),
                      borderRadius: BorderRadius.circular(WinRadii.full),
                      border: Border.all(
                          color: selected
                              ? s.primary
                              : (occ.isBookable
                                  ? WinColors.success
                                  : s.outline)),
                    ),
                    child: Text(occ.startTime,
                        style: WinType.labelM(selected
                            ? Colors.white
                            : (occ.isBookable
                                ? WinColors.success
                                : s.onFaint))),
                  ),
                );
              }).toList()),
        if (_selectedOccurrence != null) ...[
          const SizedBox(height: 20),
          Row(children: [
            Text(context.l10n.commonDuration, style: WinType.labelM(s.onStrong)),
            if (_durationMinutes != null) ...[
              const SizedBox(width: 8),
              Text(
                  context.l10n.tutoringEndsAt(addMinutesToHhmm(_selectedOccurrence!.startTime, _durationMinutes!)),
                  style: WinType.labelS(s.onMuted)),
            ],
          ]),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedOccurrence!.availableDurationsMinutes
                .map((d) => WinChip(formatDurationMinutes(d),
                    active: _durationMinutes == d,
                    onTap: () => setState(() => _durationMinutes = d)))
                .toList(),
          ),
          const SizedBox(height: 4),
          Text(context.l10n.tutoringDurationHint,
              style: WinType.labelS(s.onFaint)),
        ],
        if (widget.profile.subjects.length > 1) ...[
          const SizedBox(height: 20),
          Text(context.l10n.commonSubject, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.profile.subjects
                .map((sub) => WinChip(sub,
                    active: _subject == sub,
                    onTap: () => setState(() => _subject = sub)))
                .toList(),
          ),
        ],
        const SizedBox(height: 20),
        Text(context.l10n.tutoringTopicsOptional,
            style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 4),
        Text(context.l10n.tutoringTopicsHelp,
            style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 6),
        TopicsField(
            topics: _topics, onChanged: (t) => setState(() => _topics = t)),
        if (_ctx != null && TutorBookingForWhom.hasChoice(_ctx!)) ...[
          const SizedBox(height: 20),
          TutorBookingForWhom(
            context: _ctx!,
            value: _forWhom,
            onChanged: (v) => setState(() => _forWhom = v),
            currentUserId: _currentUserId,
            maxGroupSize: _maxGroupSize,
          ),
        ],
        const SizedBox(height: 28),
        WinButton(context.l10n.commonContinue,
            block: true,
            onTap: _selectedOccurrence != null && _durationMinutes != null && _forWhom.isValid(_maxGroupSize)
                ? _goToStep1
                : null),
      ],
    );
  }

  // ---------------- Étape 2 : récapitulatif ----------------

  Widget _buildStepRecap(WinScheme s) {
    final occ = _selectedOccurrence!;
    final duration = _durationMinutes ?? 0;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _RecapRow(
                icon: Icons.person_outline,
                label: context.l10n.tutoringTutor,
                value: widget.profile.fullName ?? widget.profile.title ?? ''),
            const SizedBox(height: 10),
            _RecapRow(
                icon: Icons.event_outlined,
                label: context.l10n.tutoringDate,
                value: WinFormat.dateNumeric(occ.date)),
            const SizedBox(height: 10),
            _RecapRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.tutoringTime,
                value:
                    '${occ.startTime} – ${addMinutesToHhmm(occ.startTime, duration)} (${formatDurationMinutes(duration)})'),
            if (_forWhom.payerType != 'student') ...[
              const SizedBox(height: 10),
              _RecapRow(
                  icon: Icons.groups_outlined,
                  label: _participantCount > 1 ? context.l10n.tutoringStudentsN(_participantCount) : context.l10n.roleStudent,
                  value: _participantNames),
            ],
            if (_subject != null) ...[
              const SizedBox(height: 10),
              _RecapRow(
                  icon: Icons.menu_book_outlined,
                  label: context.l10n.commonSubject,
                  value: _subject!),
            ],
            if (_topics.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(context.l10n.tutoringTopics, style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 6),
              TopicChipsRow(_topics),
            ],
          ]),
        ),
        const SizedBox(height: 16),
        Text(context.l10n.tutoringPrice, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        WinCard(
          child: _quoteLoading
              ? const Center(
                  child: Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator()))
              : _quote != null
                  ? TutorPriceBreakdownView(quote: _quote!)
                  : Text(_quoteError ?? context.l10n.tutoringPriceUnavailable,
                      style: WinType.bodyS(s.onMuted)),
        ),
        if (_quote != null && _quote!.isAvailable == false) ...[
          const SizedBox(height: 10),
          WinAlert(
              _quote!.unavailableReason ?? context.l10n.tutoringSlotGone,
              type: BadgeColor.error),
        ],
        const SizedBox(height: 20),
        Text(context.l10n.tutoringSessionMode, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        if (_availableModes.isEmpty)
          WinAlert(
              context.l10n.tutoringNoModeConfigured,
              type: BadgeColor.warn)
        else
          Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableModes
                  .map((m) => GestureDetector(
                        onTap: () {
                          if (_mode == m) return;
                          setState(() => _mode = m);
                          _refreshQuote(); // le mode change le tarif de base
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: _mode == m ? s.primary : s.chipBg,
                            borderRadius: BorderRadius.circular(WinRadii.full),
                            border: Border.all(
                                color: _mode == m ? s.primary : s.outline),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(_modeIcons[m],
                                size: 16,
                                color: _mode == m ? Colors.white : s.onMuted),
                            const SizedBox(width: 6),
                            Text(_modeLabel(m) ?? m,
                                style: WinType.labelM(
                                    _mode == m ? Colors.white : s.onSurface)),
                          ]),
                        ),
                      ))
                  .toList()),
        const SizedBox(height: 20),
        TutorCancellationPolicyCard(
          compact: true,
          fullRefundHours: widget.profile.fullRefundHours,
          partialRefundPercent: widget.profile.partialRefundPercent,
          noRefundHours: widget.profile.noRefundHours,
        ),
        const SizedBox(height: 28),
        WinButton(
            _quote != null && _quoteReady
                ? context.l10n.tutoringPayAmount(fmtXaf(_quote!.totalXaf))
                : context.l10n.tutoringPayNow,
            block: true,
            onTap: (_mode != null && _quoteReady) ? _goToPayment : null),
      ],
    );
  }

  // ---------------- Étape 3 : paiement (Mobile Money ou solde) ----------------

  Widget _buildStepPayment(WinScheme s) {
    final booking = _booking;

    if (booking == null) {
      // Choix du moyen de paiement, puis saisie du numéro (Mobile Money).
      final byWallet = _payMethod == 'wallet';
      final walletHint = _walletLoading
          ? context.l10n.tutoringWalletLoading
          : _walletAvailable == null
              ? context.l10n.tutoringWalletUnavailable
              : context.l10n.tutoringWalletAvailable(fmtXaf(_walletAvailable!));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(context.l10n.tutoringPayMethod, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          _PayOption(
            icon: Icons.phone_android_outlined,
            title: 'Mobile Money',
            hint: context.l10n.tutoringMomoHint,
            selected: !byWallet,
            onTap: () => setState(() {
              _payMethod = 'mobile_money';
              _submitError = null;
            }),
          ),
          const SizedBox(height: 8),
          _PayOption(
            icon: Icons.account_balance_wallet_outlined,
            title: _walletTitle,
            hint: walletHint,
            selected: byWallet,
            onTap: _walletLoading || _walletAvailable == null
                ? null
                : () => setState(() {
                      _payMethod = 'wallet';
                      _submitError = null;
                    }),
          ),
          if (byWallet && _walletAvailable != null && _quote != null) ...[
            const SizedBox(height: 8),
            Text(
                _walletCovers
                    ? context.l10n.tutoringWalletOk
                    : context.l10n.tutoringWalletMissing(fmtXaf(_quote!.totalXaf - _walletAvailable!), _walletShortfallHint),
                style: WinType.labelS(
                    _walletCovers ? s.onMuted : WinColors.error)),
          ],
          if (!byWallet) ...[
            const SizedBox(height: 20),
            Text(context.l10n.tutoringMomoNumber, style: WinType.labelM(s.onStrong)),
            const SizedBox(height: 8),
            WinTextField(
              hint: '6XX XXX XXX',
              icon: Icons.phone_android_outlined,
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Text(context.l10n.tutoringPhoneHint,
                style: WinType.labelS(s.onFaint)),
          ],
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            WinAlert(_submitError!, type: BadgeColor.error),
          ],
          const SizedBox(height: 24),
          WinButton(
              _submitting
                  ? context.l10n.tutoringSending
                  : (_quote != null
                      ? '${byWallet ? _walletPayLabel : context.l10n.tutoringPay} ${fmtXaf(_quote!.totalXaf)} XAF'
                      : context.l10n.tutoringPay),
              block: true,
              loading: _submitting,
              onTap: _submitting || (byWallet && !_walletCovers)
                  ? null
                  : _submitBooking),
        ],
      );
    }

    if (booking.isConfirmed || booking.isPendingTutorApproval) {
      return _buildSuccess(s, booking);
    }
    if (booking.isCancelled) {
      return _buildCancelled(s, booking);
    }
    if (_pollTimedOut) {
      return _buildTimedOut(s, booking);
    }
    return _buildWaiting(s, booking);
  }

  Widget _buildWaiting(WinScheme s, TutorBookingRecord booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 20),
          Text(context.l10n.tutoringWaitingConfirmation,
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              context.l10n.tutoringWaitingUssd,
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center),
          if (booking.notchpayReference != null) ...[
            const SizedBox(height: 12),
            Text(context.l10n.tutoringReference('${booking.notchpayReference}'),
                style: WinType.labelS(s.onFaint)),
          ],
        ]),
      ),
    );
  }

  Widget _buildTimedOut(WinScheme s, TutorBookingRecord booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.hourglass_bottom_outlined, size: 48, color: s.onFaint),
          const SizedBox(height: 16),
          Text(context.l10n.tutoringStillWaiting,
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              context.l10n.tutoringPaymentSlow,
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          WinButton(context.l10n.tutoringCheckNow,
              variant: WinButtonVariant.outline,
              onTap: () => _startPolling(booking.id)),
          const SizedBox(height: 10),
          WinButton(context.l10n.commonClose,
              variant: WinButtonVariant.ghost,
              onTap: () => Navigator.of(context).pop()),
        ]),
      ),
    );
  }

  Widget _buildCancelled(WinScheme s, TutorBookingRecord booking) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cancel_outlined, size: 48, color: WinColors.error),
          const SizedBox(height: 16),
          Text(context.l10n.tutoringBookingCancelled,
              style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(
              booking.cancellationReason ??
                  context.l10n.tutoringPaymentNotConfirmed,
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          WinButton(context.l10n.commonRetry,
              onTap: () => setState(() {
                    _booking = null;
                    _phoneCtrl.clear();
                  })),
        ]),
      ),
    );
  }

  Widget _buildSuccess(WinScheme s, TutorBookingRecord booking) {
    final alreadyConfirmed = booking.isConfirmed;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 12),
        const Icon(Icons.check_circle_outline,
            size: 56, color: WinColors.success),
        const SizedBox(height: 12),
        Center(
          child: Text(
            alreadyConfirmed
                ? context.l10n.tutoringSessionConfirmed
                : context.l10n.tutoringPaymentReceivedAwaiting,
            style: WinType.archivo(size: 20, color: s.onStrong),
            textAlign: TextAlign.center,
          ),
        ),
        if (!alreadyConfirmed) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              context.l10n.tutoringMustAccept,
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 20),
        WinCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _RecapRow(
                icon: Icons.person_outline,
                label: context.l10n.tutoringTutor,
                value: booking.tutorName ?? ''),
            const SizedBox(height: 10),
            _RecapRow(
                icon: Icons.event_outlined,
                label: context.l10n.tutoringDate,
                value: WinFormat.dateNumeric(booking.sessionDate)),
            const SizedBox(height: 10),
            _RecapRow(
                icon: Icons.schedule_outlined,
                label: context.l10n.tutoringTime,
                value: '${booking.startTime} – ${booking.endTime}'),
            const SizedBox(height: 10),
            _RecapRow(
                icon: Icons.payments_outlined,
                label: context.l10n.tutoringPrice,
                value: '${fmtXaf(booking.priceXaf)} XAF'),
            const SizedBox(height: 10),
            _RecapRow(
                icon: _modeIcons[booking.mode] ?? Icons.info_outline,
                label: context.l10n.tutoringMode,
                value: _modeLabel(booking.mode) ?? booking.mode),
          ]),
        ),
        const SizedBox(height: 24),
        WinButton(context.l10n.tutoringViewMySession,
            block: true,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ],
    );
  }
}

/// Stepper numéroté 3 étapes (mêmes rond+trait que l'onboarding répétiteur
/// côté professeur)  remplace le simple changement de titre dans l'AppBar,
/// qui ne montrait ni la progression ni les étapes restantes.
class _BookingStepper extends StatelessWidget {
  final int step;
  const _BookingStepper({required this.step});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final labels = [context.l10n.tutoringStepSlot, context.l10n.tutoringStepRecap, context.l10n.tutoringStepPayment];
    return Row(
        children: List.generate(labels.length * 2 - 1, (i) {
      if (i.isOdd) {
        final done = (i ~/ 2) < step;
        return Expanded(
            child: Container(
                height: 2, color: done ? WinColors.teal400 : s.outline));
      }
      final idx = i ~/ 2;
      final active = idx == step;
      final done = idx < step;
      return Column(children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active
                ? WinColors.teal400
                : (done ? WinColors.teal50 : s.chipBg),
            border: Border.all(
                color: active || done ? WinColors.teal400 : s.outline),
          ),
          child: done
              ? const Icon(Icons.check, size: 14, color: WinColors.teal700)
              : Text('${idx + 1}',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : s.onMuted)),
        ),
      ]);
    }));
  }
}

/// Option de moyen de paiement (lot 9.2).
class _PayOption extends StatelessWidget {
  final IconData icon;
  final String title, hint;
  final bool selected;
  final VoidCallback? onTap;
  const _PayOption({
    required this.icon,
    required this.title,
    required this.hint,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Opacity(
      opacity: onTap == null && !selected ? 0.55 : 1,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? WinColors.teal50 : s.chipBg,
            borderRadius: BorderRadius.circular(WinRadii.sm),
            border: Border.all(
                color: selected ? WinColors.teal400 : s.outline,
                width: selected ? 2 : 1),
          ),
          child: Row(children: [
            Icon(icon, size: 20, color: selected ? WinColors.teal700 : s.onMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title, style: WinType.titleM(s.onStrong)),
                const SizedBox(height: 2),
                Text(hint, style: WinType.labelS(s.onMuted)),
              ]),
            ),
            if (selected)
              const Icon(Icons.check_circle, size: 20, color: WinColors.teal700),
          ]),
        ),
      ),
    );
  }
}

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _RecapRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(children: [
      Icon(icon, size: 18, color: s.onFaint),
      const SizedBox(width: 10),
      Text(label, style: WinType.bodyS(s.onMuted)),
      const Spacer(),
      Text(value, style: WinType.titleM(s.onStrong)),
    ]);
  }
}
