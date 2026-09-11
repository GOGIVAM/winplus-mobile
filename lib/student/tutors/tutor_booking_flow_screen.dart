import 'dart:async';

import 'package:flutter/material.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_profile_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

const _weekdayShort = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

const _modeLabels = {
  'online': 'En ligne',
  'student_home': 'À domicile (chez moi)',
  'tutor_home': 'Chez le tuteur',
  'neutral_place': 'Lieu neutre',
};
const _modeIcons = {
  'online': Icons.videocam_outlined,
  'student_home': Icons.home_outlined,
  'tutor_home': Icons.school_outlined,
  'neutral_place': Icons.place_outlined,
};

/// Flow de réservation en 3 écrans (professeur_complete.md — "Flow de
/// réservation mobile", 3 écrans maximum) implémenté comme un seul écran
/// avec état interne d'étape, à l'image du stepper de TutorProfileScreen.
class TutorBookingFlowScreen extends StatefulWidget {
  final TutorProfile profile;
  final List<TutorAvailabilityOccurrence> occurrences;
  final TutorAvailabilityOccurrence? initialOccurrence;

  const TutorBookingFlowScreen({
    super.key,
    required this.profile,
    this.occurrences = const [],
    this.initialOccurrence,
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

    if (widget.occurrences.isNotEmpty) {
      _occurrences = widget.occurrences;
    } else {
      _loadCalendar();
    }

    if (widget.initialOccurrence != null) {
      _selectedOccurrence = widget.initialOccurrence;
      final d = widget.initialOccurrence!.date;
      _selectedDay = DateTime(d.year, d.month, d.day);
      _step = 1; // saute directement au récap
    }
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
      final occ = await TutorBookingService.instance.getTwoWeekCalendar(widget.profile.userId);
      if (mounted) setState(() { _occurrences = occ; _loadingCalendar = false; });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingCalendar = false);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Impossible de charger les disponibilités.')));
      }
    }
  }

  List<DateTime> get _days {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    return List.generate(14, (i) => start.add(Duration(days: i)));
  }

  bool _dayHasBookable(DateTime day) => _occurrences.any((o) =>
      o.date.year == day.year && o.date.month == day.month && o.date.day == day.day && o.isBookable);

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
    if (occ == null || mode == null) return;
    final phone = _normalizePhone(_phoneCtrl.text);
    if (phone.length < 9) {
      setState(() => _submitError = 'Numéro de téléphone invalide.');
      return;
    }
    setState(() { _submitting = true; _submitError = null; });
    try {
      final result = await TutorBookingService.instance.createBooking(
        tutorUserId: widget.profile.userId,
        sessionDate: occ.date,
        startTime: occ.startTime,
        endTime: occ.endTime,
        mode: mode,
        phone: phone,
      );
      if (!mounted) return;
      setState(() { _booking = result.booking; _submitting = false; });
      _startPolling(result.booking.id);
    } catch (_) {
      if (mounted) {
        setState(() { _submitting = false; _submitError = 'Erreur lors de la création de la réservation.'; });
      }
    }
  }

  void _startPolling(int bookingId) {
    _pollStarted = DateTime.now();
    setState(() => _pollTimedOut = false);
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 4), (t) async {
      if (!mounted) { t.cancel(); return; }
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
    if (_selectedOccurrence == null) return;
    setState(() => _step = 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final titles = ['Choisir un créneau', 'Récapitulatif', 'Paiement Mobile Money'];
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
        child: switch (_step) {
          0 => _buildStepSlot(s),
          1 => _buildStepRecap(s),
          _ => _buildStepPayment(s),
        },
      ),
    );
  }

  // ---------------- Étape 1 : choix du créneau ----------------

  Widget _buildStepSlot(WinScheme s) {
    if (_loadingCalendar) return const Center(child: CircularProgressIndicator());
    final daySlots = _occurrences.where((o) =>
        o.date.year == _selectedDay.year && o.date.month == _selectedDay.month && o.date.day == _selectedDay.day).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Tuteur', style: WinType.labelM(s.onMuted)),
        const SizedBox(height: 4),
        Text(widget.profile.fullName ?? widget.profile.title ?? 'Tuteur', style: WinType.titleM(s.onStrong)),
        const SizedBox(height: 20),
        Text('Choisissez un jour', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        SizedBox(
          height: 64,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final day = _days[i];
              final active = day.year == _selectedDay.year && day.month == _selectedDay.month && day.day == _selectedDay.day;
              final bookable = _dayHasBookable(day);
              return GestureDetector(
                onTap: () => setState(() { _selectedDay = day; _selectedOccurrence = null; }),
                child: Container(
                  width: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: active ? s.primary : (bookable ? WinColors.successBg : s.chipBg),
                    border: Border.all(color: active ? s.primary : s.outline),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(_weekdayShort[day.weekday - 1], style: WinType.labelS(active ? Colors.white : s.onMuted)),
                    const SizedBox(height: 2),
                    Text('${day.day}', style: WinType.titleM(active ? Colors.white : (bookable ? WinColors.success : s.onStrong))),
                  ]),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        Text('Créneaux disponibles', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        if (daySlots.isEmpty)
          Text('Aucun créneau ce jour-là.', style: WinType.bodyS(s.onFaint))
        else
          Wrap(spacing: 8, runSpacing: 8, children: daySlots.map((occ) {
            final selected = _selectedOccurrence == occ;
            return GestureDetector(
              onTap: occ.isBookable ? () => setState(() => _selectedOccurrence = occ) : null,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? s.primary : (occ.isBookable ? WinColors.successBg : s.chipBg),
                  border: Border.all(color: selected ? s.primary : (occ.isBookable ? WinColors.success : s.outline)),
                ),
                child: Text('${occ.startTime} – ${occ.endTime}',
                    style: WinType.labelM(selected ? Colors.white : (occ.isBookable ? WinColors.success : s.onFaint))),
              ),
            );
          }).toList()),
        const SizedBox(height: 28),
        WinButton('Continuer', block: true, onTap: _selectedOccurrence != null ? _goToStep1 : null),
      ],
    );
  }

  // ---------------- Étape 2 : récapitulatif ----------------

  Widget _buildStepRecap(WinScheme s) {
    final occ = _selectedOccurrence!;
    final price = widget.profile.hourlyRateXaf;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _RecapRow(icon: Icons.person_outline, label: 'Tuteur',
                value: widget.profile.fullName ?? widget.profile.title ?? '—'),
            const SizedBox(height: 10),
            _RecapRow(icon: Icons.event_outlined, label: 'Date',
                value: '${occ.date.day.toString().padLeft(2, '0')}/${occ.date.month.toString().padLeft(2, '0')}/${occ.date.year}'),
            const SizedBox(height: 10),
            _RecapRow(icon: Icons.schedule_outlined, label: 'Heure', value: '${occ.startTime} – ${occ.endTime}'),
            const SizedBox(height: 10),
            _RecapRow(icon: Icons.payments_outlined, label: 'Prix',
                value: price != null ? '$price XAF' : 'Selon tarif du tuteur'),
          ]),
        ),
        const SizedBox(height: 20),
        Text('Mode de séance', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 8),
        if (_availableModes.isEmpty)
          const WinAlert('Ce tuteur n\'a pas encore configuré de mode de séance.', type: BadgeColor.warn)
        else
          Wrap(spacing: 8, runSpacing: 8, children: _availableModes.map((m) => GestureDetector(
                onTap: () => setState(() => _mode = m),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: _mode == m ? s.primary : s.chipBg,
                    border: Border.all(color: _mode == m ? s.primary : s.outline),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(_modeIcons[m], size: 16, color: _mode == m ? Colors.white : s.onMuted),
                    const SizedBox(width: 6),
                    Text(_modeLabels[m] ?? m, style: WinType.labelM(_mode == m ? Colors.white : s.onSurface)),
                  ]),
                ),
              )).toList()),
        const SizedBox(height: 28),
        WinButton('Payer maintenant', block: true,
            onTap: (_mode != null) ? () => setState(() => _step = 2) : null),
      ],
    );
  }

  // ---------------- Étape 3 : paiement Mobile Money ----------------

  Widget _buildStepPayment(WinScheme s) {
    final booking = _booking;

    if (booking == null) {
      // Saisie du numéro et soumission.
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Numéro Mobile Money', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          WinTextField(
            hint: '6XX XXX XXX',
            icon: Icons.phone_android_outlined,
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          Text('Numéro Cameroun sans indicatif pays (ex: 670000000).', style: WinType.labelS(s.onFaint)),
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            WinAlert(_submitError!, type: BadgeColor.error),
          ],
          const SizedBox(height: 24),
          WinButton(_submitting ? 'Envoi en cours…' : 'Payer', block: true, loading: _submitting,
              onTap: _submitting ? null : _submitBooking),
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
          Text('En attente de confirmation…', style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Valide le paiement via le message USSD envoyé sur ton téléphone.',
              style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
          if (booking.notchpayReference != null) ...[
            const SizedBox(height: 12),
            Text('Réf. : ${booking.notchpayReference}', style: WinType.labelS(s.onFaint)),
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
          Text('Toujours en attente', style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('Le paiement met plus de temps que prévu. Tu peux vérifier plus tard dans "Mes séances".',
              style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          WinButton('Vérifier maintenant', variant: WinButtonVariant.outline, onTap: () => _startPolling(booking.id)),
          const SizedBox(height: 10),
          WinButton('Fermer', variant: WinButtonVariant.ghost,
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
          Text('Réservation annulée', style: WinType.titleM(s.onStrong), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(booking.cancellationReason ?? 'Le paiement n\'a pas pu être confirmé.',
              style: WinType.bodyS(s.onMuted), textAlign: TextAlign.center),
          const SizedBox(height: 20),
          WinButton('Réessayer', onTap: () => setState(() { _booking = null; _phoneCtrl.clear(); })),
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
        const Icon(Icons.check_circle_outline, size: 56, color: WinColors.success),
        const SizedBox(height: 12),
        Center(
          child: Text(
            alreadyConfirmed ? 'Séance confirmée !' : 'Paiement reçu — en attente du tuteur',
            style: WinType.archivo(size: 20, color: s.onStrong),
            textAlign: TextAlign.center,
          ),
        ),
        if (!alreadyConfirmed) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Le tuteur doit accepter ta demande. Tu seras notifié·e dès sa réponse.',
              style: WinType.bodyS(s.onMuted),
              textAlign: TextAlign.center,
            ),
          ),
        ],
        const SizedBox(height: 20),
        WinCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _RecapRow(icon: Icons.person_outline, label: 'Tuteur', value: booking.tutorName ?? '—'),
            const SizedBox(height: 10),
            _RecapRow(icon: Icons.event_outlined, label: 'Date',
                value: '${booking.sessionDate.day.toString().padLeft(2, '0')}/${booking.sessionDate.month.toString().padLeft(2, '0')}/${booking.sessionDate.year}'),
            const SizedBox(height: 10),
            _RecapRow(icon: Icons.schedule_outlined, label: 'Heure', value: '${booking.startTime} – ${booking.endTime}'),
            const SizedBox(height: 10),
            _RecapRow(icon: Icons.payments_outlined, label: 'Prix', value: '${booking.priceXaf} XAF'),
            const SizedBox(height: 10),
            _RecapRow(icon: _modeIcons[booking.mode] ?? Icons.info_outline, label: 'Mode',
                value: _modeLabels[booking.mode] ?? booking.mode),
          ]),
        ),
        const SizedBox(height: 24),
        WinButton('Voir ma séance', block: true,
            onTap: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ],
    );
  }
}

class _RecapRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _RecapRow({required this.icon, required this.label, required this.value});
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
