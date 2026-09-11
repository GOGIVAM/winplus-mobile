import 'package:flutter/material.dart';

import '../services/tutor_booking_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

const _modeLabels = {
  'online': 'En ligne',
  'student_home': 'À domicile (élève)',
  'tutor_home': 'Chez le tuteur',
  'neutral_place': 'Lieu neutre',
};

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Espace "Cours particuliers" du répétiteur : demandes en attente
/// (accepter/refuser avec compte à rebours) et séances à venir/à clôturer
/// (Module 6 — professeur_complete.md, cycle de vie des réservations).
class TutorBookingsScreen extends StatefulWidget {
  const TutorBookingsScreen({super.key});

  @override
  State<TutorBookingsScreen> createState() => _TutorBookingsScreenState();
}

class _TutorBookingsScreenState extends State<TutorBookingsScreen> {
  List<TutorPendingBooking>? _pending;
  List<TutorBookingRecord>? _mine;
  bool _error = false;
  final Set<int> _busy = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final results = await Future.wait([
        TutorBookingService.instance.getPending(),
        TutorBookingService.instance.getMine(),
      ]);
      if (!mounted) return;
      setState(() {
        _pending = results[0] as List<TutorPendingBooking>;
        _mine = results[1] as List<TutorBookingRecord>;
      });
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _confirm(int id) async {
    setState(() => _busy.add(id));
    try {
      await TutorBookingService.instance.confirm(id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossible d\'accepter cette demande.')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _decline(int id) async {
    final reason = await _promptText(context, title: 'Refuser la demande', hint: 'Motif (optionnel)');
    if (reason == null) return; // annulé
    setState(() => _busy.add(id));
    try {
      await TutorBookingService.instance.decline(id, reason: reason.isEmpty ? null : reason);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossible de refuser cette demande.')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _complete(int id) async {
    setState(() => _busy.add(id));
    try {
      await TutorBookingService.instance.complete(id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossible de clôturer cette séance.')));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<String?> _promptText(BuildContext context, {required String title, String? hint}) async {
    final ctrl = TextEditingController();
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final s = WinTheme.of(ctx);
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 16),
              WinTextField(hint: hint, controller: ctrl),
              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: WinButton('Annuler', variant: WinButtonVariant.outline, block: true,
                      onTap: () => Navigator.pop(ctx)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: WinButton('Confirmer', variant: WinButtonVariant.danger, block: true,
                      onTap: () => Navigator.pop(ctx, ctrl.text.trim())),
                ),
              ]),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final pending = _pending;
    final mine = _mine;
    final upcoming = (mine ?? [])
        .where((b) => b.isConfirmed || b.isCompleted || b.isDisputed)
        .toList()
      ..sort((a, b) => a.sessionDate.compareTo(b.sessionDate));

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Cours particuliers', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(icon: Icon(Icons.refresh_outlined, color: s.onMuted), onPressed: _load),
        ],
      ),
      body: pending == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text('Impossible de charger vos réservations.', style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 12),
                  WinButton('Réessayer', onTap: _load),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text('Demandes en attente', style: WinType.archivo(size: 18, color: s.onStrong)),
                      const SizedBox(height: 10),
                      if ((pending ?? []).isEmpty)
                        WinCard(
                          child: Text('Aucune demande en attente pour le moment.',
                              style: WinType.bodyS(s.onMuted)),
                        )
                      else
                        ...pending!.map((p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PendingCard(
                                pending: p,
                                busy: _busy.contains(p.booking.id),
                                onAccept: () => _confirm(p.booking.id),
                                onDecline: () => _decline(p.booking.id),
                              ),
                            )),
                      const SizedBox(height: 24),
                      Text('Séances à venir / à clôturer', style: WinType.archivo(size: 18, color: s.onStrong)),
                      const SizedBox(height: 10),
                      if (upcoming.isEmpty)
                        WinCard(
                          child: Text('Aucune séance confirmée pour le moment.',
                              style: WinType.bodyS(s.onMuted)),
                        )
                      else
                        ...upcoming.map((b) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UpcomingCard(
                                booking: b,
                                busy: _busy.contains(b.id),
                                onComplete: () => _complete(b.id),
                              ),
                            )),
                    ],
                  ),
                ),
    );
  }
}

class _PendingCard extends StatelessWidget {
  final TutorPendingBooking pending;
  final bool busy;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _PendingCard({required this.pending, required this.busy, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final b = pending.booking;
    final urgent = pending.minutesRemaining <= 60;
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WinAvatar(b.studentName ?? '?', size: 40),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.studentName ?? 'Élève', style: WinType.titleM(s.onStrong)),
            Text('${_fmtDate(b.sessionDate)} · ${b.startTime} – ${b.endTime}',
                style: WinType.labelM(s.onMuted)),
          ])),
          WinBadge('${pending.minutesRemaining} min',
              color: urgent ? BadgeColor.error : BadgeColor.warn),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.place_outlined, size: 14, color: s.onFaint),
          const SizedBox(width: 4),
          Text(_modeLabels[b.mode] ?? b.mode, style: WinType.labelM(s.onMuted)),
          const SizedBox(width: 12),
          Icon(Icons.payments_outlined, size: 14, color: s.onFaint),
          const SizedBox(width: 4),
          Text('${b.priceXaf} XAF', style: WinType.labelM(s.onMuted)),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: WinButton('Refuser', variant: WinButtonVariant.outline, small: true,
                loading: busy, onTap: busy ? null : onDecline),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: WinButton('Accepter', small: true, loading: busy,
                onTap: busy ? null : onAccept),
          ),
        ]),
      ]),
    );
  }
}

class _UpcomingCard extends StatelessWidget {
  final TutorBookingRecord booking;
  final bool busy;
  final VoidCallback onComplete;
  const _UpcomingCard({required this.booking, required this.busy, required this.onComplete});

  BadgeColor get _statusColor => switch (booking.status) {
        'confirmed' => BadgeColor.success,
        'completed' => BadgeColor.blue,
        'disputed' => BadgeColor.error,
        _ => BadgeColor.neutral,
      };

  String get _statusLabel => switch (booking.status) {
        'confirmed' => 'Confirmée',
        'completed' => 'Effectuée',
        'disputed' => 'Contestée',
        _ => booking.status,
      };

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final b = booking;
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WinAvatar(b.studentName ?? '?', size: 40),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.studentName ?? 'Élève', style: WinType.titleM(s.onStrong)),
            Text('${_fmtDate(b.sessionDate)} · ${b.startTime} – ${b.endTime}',
                style: WinType.labelM(s.onMuted)),
          ])),
          WinBadge(_statusLabel, color: _statusColor),
        ]),
        if (b.isDisputed && (b.disputeReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          WinAlert('Motif de contestation : ${b.disputeReason}', type: BadgeColor.error),
        ],
        if (b.canMarkCompleted) ...[
          const SizedBox(height: 14),
          WinButton('Marquer effectuée', block: true, small: true, loading: busy,
              icon: Icons.check_circle_outline, onTap: busy ? null : onComplete),
        ],
      ]),
    );
  }
}
