import 'dart:async';

import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/session_manager.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_engagement_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../shared/tutor_engagement_screen.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_booking_for_whom.dart';
import 'tutor_policy_widgets.dart';
import 'tutor_pricing_widgets.dart';

/// Lot 9.4 (suivi 17.7) : création d'un engagement mensuel, parité web.
/// Étapes : créneaux hebdomadaires et pour qui, devis serveur du mois
/// (séances, remise, total, conflits), paiement d'avance par solde ou
/// Mobile Money (renouvellement automatique proposé si paiement par solde).
class TutorEngagementFlowScreen extends StatefulWidget {
  final TutorProfile profile;
  final List<String> initialTopics;

  /// Attribution active servant de point de départ (bénéficiaires pré-remplis).
  final TutorAssignment? assignment;

  const TutorEngagementFlowScreen({super.key, required this.profile, this.initialTopics = const [], this.assignment});

  @override
  State<TutorEngagementFlowScreen> createState() => _TutorEngagementFlowScreenState();
}

String? _modeLabel(String mode) => switch (mode) {
      'online' => L10n.current.commonOnline,
      'student_home' => L10n.current.tutoringModeStudentHome,
      'tutor_home' => L10n.current.tutoringModeTutorHome,
      'neutral_place' => L10n.current.tutoringModeNeutralPlace,
      _ => null,
    };
const _weekOrder = [1, 2, 3, 4, 5, 6, 0];
const _durations = [30, 60, 90, 120, 150, 180, 240];

int _toMin(String hhmm) {
  final p = hhmm.split(':');
  return int.parse(p[0]) * 60 + (p.length > 1 ? int.parse(p[1]) : 0);
}

String _toHhmm(int m) => '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';

String _shortDate(DateTime d) {
  return '${WinFormat.weekdayShort(d.weekday)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

class _TutorEngagementFlowScreenState extends State<TutorEngagementFlowScreen> {
  int _step = 0; // 0 = créneaux, 1 = devis, 2 = paiement
  late DateTime _startDate;
  List<EngagementSlot> _slots = [];
  String _mode = 'online';
  String? _subject;
  List<String> _topics = [];

  TutorBookingContext? _ctx;
  ForWhomValue _forWhom = const ForWhomValue();
  int? _currentUserId;

  EngagementQuote? _quote;
  bool _quoteLoading = false;
  String? _quoteError;

  String _payMethod = 'wallet';
  num? _walletAvailable;
  bool _walletLoading = false;
  bool _autoRenew = false;
  final _phoneCtrl = TextEditingController();
  bool _submitting = false;
  String? _submitError;

  TutorEngagementRecord? _created;
  Timer? _poll;
  bool _waiting = false;

  int get _maxGroupSize => widget.profile.effectiveMaxGroupSize;
  int get _participantCount => _forWhom.count < 1 ? 1 : _forWhom.count;

  List<String> get _modes {
    final p = widget.profile;
    final m = [
      if (p.offersOnline) 'online',
      if (p.offersAtStudentHome) 'student_home',
      if (p.offersAtTutorHome) 'tutor_home',
      if (p.offersNeutralPlace) 'neutral_place',
    ];
    return m.isEmpty ? ['online'] : m;
  }

  /// Heures de début dans les plages déclarées du tuteur pour ce jour (tranches de 30 min).
  List<String> _startOptions(int day) {
    final set = <String>{};
    for (final r in widget.profile.availabilitySlots.where((s) => s.dayOfWeek == day && s.isActive)) {
      for (var m = (_toMin(r.startTime) / 30).ceil() * 30; m + 30 <= _toMin(r.endTime); m += 30) {
        set.add(_toHhmm(m));
      }
    }
    return set.toList()..sort();
  }

  EngagementSlot _defaultSlot() {
    for (final d in _weekOrder) {
      final opts = _startOptions(d);
      if (opts.isNotEmpty) return EngagementSlot(dayOfWeek: d, startTime: opts.first, durationMinutes: 60);
    }
    return const EngagementSlot(dayOfWeek: 1, startTime: '17:00', durationMinutes: 60);
  }

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final lead = (widget.profile.noticeHours / 24).ceil() + 1;
    _startDate = DateTime(now.year, now.month, now.day).add(Duration(days: lead < 2 ? 2 : lead));
    _slots = [_defaultSlot()];
    _mode = _modes.first;
    _subject = widget.profile.subjects.isNotEmpty ? widget.profile.subjects.first : null;
    final assigned = widget.assignment?.subject;
    if (assigned != null && widget.profile.subjects.contains(assigned)) _subject = assigned;
    _topics = widget.initialTopics.take(kMaxTopics).toList();
    _loadContext();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _phoneCtrl.dispose();
    super.dispose();
  }

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
    } catch (_) {}
  }

  Future<void> _loadQuote() async {
    setState(() {
      _step = 1;
      _quoteLoading = true;
      _quoteError = null;
    });
    try {
      final q = await TutorEngagementService.instance.quote(
          tutorUserId: widget.profile.userId,
          startDate: _startDate,
          slots: _slots,
          mode: _mode,
          subject: _subject,
          participantCount: _participantCount);
      if (!mounted) return;
      setState(() {
        _quote = q;
        _quoteLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quote = null;
        _quoteLoading = false;
        _quoteError = TutorEngagementService.errorMessage(e) ?? L10n.current.tutoringEngQuoteError;
      });
    }
  }

  Future<void> _goToPayment() async {
    setState(() {
      _step = 2;
      _walletLoading = true;
    });
    final available = await TutorBookingService.instance.getWalletAvailableXaf();
    if (!mounted) return;
    setState(() {
      _walletAvailable = available;
      _walletLoading = false;
      if (available == null) _payMethod = 'mobile_money';
    });
  }

  bool get _walletCovers => _walletAvailable != null && _quote != null && _walletAvailable! >= _quote!.totalXaf;

  String _normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('237') && digits.length > 9) digits = digits.substring(digits.length - 9);
    return digits;
  }

  Future<void> _submit() async {
    final byWallet = _payMethod == 'wallet';
    final phone = _normalizePhone(_phoneCtrl.text);
    if (!byWallet && phone.length != 9) {
      setState(() => _submitError = context.l10n.tutoringEngPhoneFormat);
      return;
    }
    if (byWallet && !_walletCovers) {
      setState(() => _submitError = context.l10n.tutoringEngWalletShort);
      return;
    }
    setState(() {
      _submitting = true;
      _submitError = null;
    });
    try {
      final created = await TutorEngagementService.instance.create(
        tutorUserId: widget.profile.userId,
        startDate: _startDate,
        slots: _slots,
        mode: _mode,
        subject: _subject,
        participantCount: _participantCount,
        topics: _topics,
        paymentMethod: _payMethod,
        phone: byWallet ? null : phone,
        payerType: _forWhom.payerType,
        participantUserIds: _forWhom.payerType == 'student' ? null : _forWhom.participantIds,
        studyGroupId: _forWhom.studyGroupId,
        tutorAssignmentId: widget.assignment?.isActive == true ? widget.assignment!.id : null,
        autoRenew: byWallet && _autoRenew,
      );
      if (!mounted) return;
      setState(() {
        _created = created;
        _submitting = false;
        _waiting = !byWallet;
      });
      if (!byWallet) _startPolling(created.id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitError = TutorEngagementService.errorMessage(e) ?? L10n.current.tutoringEngCreateError;
      });
    }
  }

  void _startPolling(int id) {
    final started = DateTime.now();
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 4), (t) async {
      if (!mounted || DateTime.now().difference(started) > const Duration(minutes: 5)) {
        t.cancel();
        if (mounted) setState(() => _waiting = false);
        return;
      }
      try {
        final e = await TutorEngagementService.instance.get(id);
        if (!mounted) return;
        if (e.status != 'pending_payment') {
          t.cancel();
          setState(() {
            _created = e;
            _waiting = false;
          });
        }
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final titles = [context.l10n.tutoringEngStagePlan, context.l10n.tutoringEngStageQuote, context.l10n.tutoringEngStagePayment];
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () {
            if (_step > 0 && _created == null) {
              setState(() => _step -= 1);
            } else {
              Navigator.pop(context);
            }
          },
        ),
        title: Text(_created != null ? context.l10n.tutoringEngStageSuccess : titles[_step], style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _created != null
            ? _buildDone(s)
            : switch (_step) {
                0 => _buildPlan(s),
                1 => _buildQuote(s),
                _ => _buildPayment(s),
              },
      ),
    );
  }

  Widget _buildPlan(WinScheme s) {
    final valid = _slots.isNotEmpty && _forWhom.isValid(_maxGroupSize);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(
          '${context.l10n.tutoringEngIntro}'
          '${widget.profile.monthlyDiscountPercent > 0 ? context.l10n.tutoringEngIntroDiscount(widget.profile.monthlyDiscountPercent) : ''}'
          '${context.l10n.tutoringEngIntroEnd}',
          style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 16),
      Text(context.l10n.tutoringEngFirstDay, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 6),
      WinButton(
        '${_shortDate(_startDate)} ${_startDate.year}',
        variant: WinButtonVariant.outline,
        icon: Icons.event_outlined,
        onTap: () async {
          final now = DateTime.now();
          final picked = await showDatePicker(
              context: context,
              initialDate: _startDate,
              firstDate: DateTime(now.year, now.month, now.day),
              lastDate: now.add(const Duration(days: 120)));
          if (picked != null) setState(() => _startDate = picked);
        },
      ),
      const SizedBox(height: 16),
      Text(context.l10n.tutoringEngWeeklySlots, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 6),
      for (var i = 0; i < _slots.length; i++) _slotRow(s, i),
      if (_slots.length < 7)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => setState(() => _slots = [..._slots, _defaultSlot()]),
            icon: const Icon(Icons.add, size: 18),
            label: Text(context.l10n.tutoringEngAddSlot),
          ),
        ),
      Text(context.l10n.tutoringEngPerMonth(_slots.length * 4), style: WinType.labelS(s.onFaint)),
      if (widget.profile.subjects.length > 1) ...[
        const SizedBox(height: 16),
        Text(context.l10n.commonSubject, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.profile.subjects
                .map((sub) => WinChip(sub, active: _subject == sub, onTap: () => setState(() => _subject = sub)))
                .toList()),
      ],
      const SizedBox(height: 16),
      Text(context.l10n.tutoringMode, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 8),
      Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _modes.map((m) => WinChip(_modeLabel(m) ?? m, active: _mode == m, onTap: () => setState(() => _mode = m))).toList()),
      if (_ctx != null && TutorBookingForWhom.hasChoice(_ctx!)) ...[
        const SizedBox(height: 16),
        TutorBookingForWhom(
          context: _ctx!,
          value: _forWhom,
          onChanged: (v) => setState(() => _forWhom = v),
          currentUserId: _currentUserId,
          maxGroupSize: _maxGroupSize,
        ),
      ],
      const SizedBox(height: 16),
      Text(context.l10n.tutoringTopicsOptional, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 6),
      TopicsField(topics: _topics, onChanged: (t) => setState(() => _topics = t)),
      const SizedBox(height: 24),
      WinButton(context.l10n.tutoringEngSeeQuote, block: true, onTap: valid ? _loadQuote : null),
    ]);
  }

  Widget _slotRow(WinScheme s, int i) {
    final slot = _slots[i];
    final opts = _startOptions(slot.dayOfWeek);
    final starts = opts.isEmpty ? [slot.startTime] : opts;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(children: [
        Expanded(
          flex: 4,
          child: DropdownButtonFormField<int>(
            key: ValueKey('day-$i-${slot.dayOfWeek}'),
            initialValue: slot.dayOfWeek,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: context.l10n.tutoringEngDay),
            items: _weekOrder
                .map((d) => DropdownMenuItem(value: d, child: Text(WinFormat.weekdayCap(d == 0 ? DateTime.sunday : d) + (_startOptions(d).isEmpty ? ' ${context.l10n.tutoringUnavailableShort}' : ''))))
                .toList(),
            onChanged: (d) {
              if (d == null) return;
              final o = _startOptions(d);
              setState(() => _slots[i] = slot.copyWith(dayOfWeek: d, startTime: o.isNotEmpty && !o.contains(slot.startTime) ? o.first : slot.startTime));
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<String>(
            key: ValueKey('start-$i-${slot.dayOfWeek}-${slot.startTime}'),
            initialValue: starts.contains(slot.startTime) ? slot.startTime : starts.first,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: context.l10n.tutoringEngStart),
            items: starts.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
            onChanged: (t) => t == null ? null : setState(() => _slots[i] = slot.copyWith(startTime: t)),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 3,
          child: DropdownButtonFormField<int>(
            key: ValueKey('dur-$i-${slot.durationMinutes}'),
            initialValue: slot.durationMinutes,
            isExpanded: true,
            decoration: InputDecoration(isDense: true, labelText: context.l10n.commonDuration),
            items: _durations.map((d) => DropdownMenuItem(value: d, child: Text(formatDurationMinutes(d)))).toList(),
            onChanged: (d) => d == null ? null : setState(() => _slots[i] = slot.copyWith(durationMinutes: d)),
          ),
        ),
        IconButton(
          tooltip: context.l10n.tutoringEngRemoveSlot,
          icon: Icon(Icons.delete_outline, color: s.onMuted),
          onPressed: _slots.length == 1 ? null : () => setState(() => _slots = [..._slots]..removeAt(i)),
        ),
      ]),
    );
  }

  Widget _buildQuote(WinScheme s) {
    if (_quoteLoading) return const Center(child: CircularProgressIndicator());
    final q = _quote;
    if (q == null) {
      return ListView(padding: const EdgeInsets.all(16), children: [
        WinAlert(_quoteError ?? context.l10n.tutoringEngQuoteUnavailable, type: BadgeColor.error),
        const SizedBox(height: 16),
        WinButton(context.l10n.tutoringEngEditSlots, variant: WinButtonVariant.outline, block: true, onTap: () => setState(() => _step = 0)),
      ]);
    }
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(context.l10n.tutoringEngQuoteRange(_shortDate(q.startDate), _shortDate(q.endDate), q.sessions.length) +
          (q.participantCount > 1 ? context.l10n.tutoringEngQuoteStudents(q.participantCount) : ''),
          style: WinType.bodyS(s.onMuted)),
      const SizedBox(height: 10),
      WinCard(
        child: Column(children: [
          for (final x in q.sessions)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${_shortDate(x.sessionDate)} · ${x.startTime}-${x.endTime}', style: WinType.labelM(s.onStrong)),
                    if (!x.isAvailable) Text(x.unavailableReason ?? context.l10n.tutoringUnavailable, style: WinType.labelS(WinColors.error)),
                  ]),
                ),
                if (x.discountXaf > 0)
                  Text('${fmtXaf(x.baseTotalXaf)} ',
                      style: WinType.labelS(s.onFaint).copyWith(decoration: TextDecoration.lineThrough)),
                Text('${fmtXaf(x.priceXaf)} XAF', style: WinType.labelM(s.onStrong)),
              ]),
            ),
        ]),
      ),
      const SizedBox(height: 12),
      _totalRow(s, context.l10n.tutoringEngSubtotal, '${fmtXaf(q.subtotalXaf)} XAF'),
      if (q.discountXaf > 0) _totalRow(s, context.l10n.tutoringEngMonthlyDiscount(q.discountPercent), '-${fmtXaf(q.discountXaf)} XAF', color: WinColors.success),
      _totalRow(s, context.l10n.tutoringEngTotalAdvance, '${fmtXaf(q.totalXaf)} XAF', strong: true),
      if (!q.isAvailable) ...[
        const SizedBox(height: 10),
        WinAlert(
            q.monthlyEnabled
                ? context.l10n.tutoringEngSomeUnavailable
                : (q.conflicts.isNotEmpty ? q.conflicts.first : context.l10n.tutoringEngNotOffered),
            type: BadgeColor.error),
      ],
      const SizedBox(height: 14),
      TutorCancellationPolicyCard(
        compact: true,
        fullRefundHours: widget.profile.fullRefundHours,
        partialRefundPercent: widget.profile.partialRefundPercent,
        noRefundHours: widget.profile.noRefundHours,
      ),
      const SizedBox(height: 8),
      Text(
          context.l10n.tutoringEngQuoteHelp,
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 20),
      WinButton(context.l10n.tutoringEngPayMonth, block: true, onTap: q.isAvailable ? _goToPayment : null),
    ]);
  }

  Widget _totalRow(WinScheme s, String label, String value, {bool strong = false, Color? color}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(children: [
          Expanded(child: Text(label, style: strong ? WinType.titleM(s.onStrong) : WinType.bodyS(color ?? s.onMuted))),
          Text(value, style: strong ? WinType.titleM(s.onStrong) : WinType.labelM(color ?? s.onStrong)),
        ]),
      );

  Widget _buildPayment(WinScheme s) {
    if (_waiting) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.tutoringEngValidateOnPhone, style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          ]),
        ),
      );
    }
    final total = _quote?.totalXaf ?? 0;
    final byWallet = _payMethod == 'wallet';
    final walletTitle = switch (_forWhom.payerType) {
      'parent' => context.l10n.tutoringWalletParent,
      'institution' => context.l10n.tutoringWalletInstitution,
      _ => context.l10n.tutoringWalletMine,
    };
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(context.l10n.tutoringPayMethod, style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 8),
      WinChip('$walletTitle${_walletLoading ? '' : _walletAvailable == null ? ' ${context.l10n.tutoringUnavailableParen}' : ' · ${fmtXaf(_walletAvailable!)} XAF'}',
          icon: Icons.account_balance_wallet_outlined,
          active: byWallet,
          onTap: _walletAvailable == null ? null : () => setState(() => _payMethod = 'wallet')),
      const SizedBox(height: 8),
      WinChip(context.l10n.tutoringEngMomoChip,
          icon: Icons.phone_android_outlined,
          active: !byWallet,
          onTap: () => setState(() {
                _payMethod = 'mobile_money';
                _autoRenew = false;
              })),
      if (byWallet && _walletAvailable != null && !_walletCovers) ...[
        const SizedBox(height: 8),
        Text(context.l10n.tutoringEngWalletMissing(fmtXaf(total - _walletAvailable!)), style: WinType.labelS(WinColors.error)),
      ],
      const SizedBox(height: 14),
      if (byWallet)
        CheckboxListTile(
          contentPadding: EdgeInsets.zero,
          value: _autoRenew,
          onChanged: (v) => setState(() => _autoRenew = v ?? false),
          title: Text(context.l10n.tutoringEngAutoRenew, style: WinType.labelM(s.onStrong)),
          subtitle: Text(
              context.l10n.tutoringEngAutoRenewHelp,
              style: WinType.labelS(s.onFaint)),
        )
      else ...[
        Text(context.l10n.tutoringMomoNumber, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        WinTextField(hint: '6XX XXX XXX', icon: Icons.phone_android_outlined, controller: _phoneCtrl, keyboardType: TextInputType.phone),
        const SizedBox(height: 6),
        Text(context.l10n.tutoringEngAutoRenewWalletOnly, style: WinType.labelS(s.onFaint)),
      ],
      if (_submitError != null) ...[
        const SizedBox(height: 12),
        WinAlert(_submitError!, type: BadgeColor.error),
      ],
      const SizedBox(height: 20),
      WinButton(_submitting ? context.l10n.tutoringSending : context.l10n.tutoringPayAmount(fmtXaf(total)),
          block: true, loading: _submitting, onTap: _submitting || (byWallet && !_walletCovers) ? null : _submit),
    ]);
  }

  Widget _buildDone(WinScheme s) {
    final e = _created!;
    final failed = e.status == 'cancelled';
    return ListView(padding: const EdgeInsets.all(16), children: [
      const SizedBox(height: 12),
      Icon(failed ? Icons.cancel_outlined : Icons.check_circle_outline, size: 56, color: failed ? WinColors.error : WinColors.success),
      const SizedBox(height: 12),
      Center(
        child: Text(
            failed
                ? context.l10n.tutoringEngPaymentNotConfirmed
                : e.status == 'pending_payment'
                    ? context.l10n.tutoringEngPaymentPending
                    : context.l10n.tutoringEngPaymentReceived,
            style: WinType.titleM(s.onStrong),
            textAlign: TextAlign.center),
      ),
      const SizedBox(height: 8),
      Text(
          failed
              ? (e.cancellationReason ?? context.l10n.tutoringPaymentNotConfirmed)
              : context.l10n.tutoringEngSuccessText(e.sessionsCount, _shortDate(e.startDate), _shortDate(e.endDate)),
          style: WinType.bodyS(s.onMuted),
          textAlign: TextAlign.center),
      const SizedBox(height: 20),
      WinButton(context.l10n.tutoringEngSeeEngagement,
          block: true,
          onTap: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: e.id)))),
    ]);
  }
}
