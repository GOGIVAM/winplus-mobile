import 'package:flutter/material.dart';

import '../../services/tutor_booking_service.dart';
import '../../services/tutor_review_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

const _modeLabels = {
  'online': 'En ligne',
  'student_home': 'À domicile',
  'tutor_home': 'Chez le répétiteur',
  'neutral_place': 'Lieu neutre',
};

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

(BadgeColor, String) _statusInfo(String status) => switch (status) {
      'pending_payment' => (BadgeColor.neutral, 'Paiement en cours'),
      'pending_tutor_approval' => (BadgeColor.warn, 'En attente du répétiteur'),
      'confirmed' => (BadgeColor.success, 'Confirmée'),
      'completed' => (BadgeColor.blue, 'Effectuée'),
      'disputed' => (BadgeColor.error, 'Contestée'),
      'rejected' => (BadgeColor.error, 'Refusée'),
      'expired' => (BadgeColor.error, 'Expirée'),
      'cancelled' => (BadgeColor.neutral, 'Annulée'),
      _ => (BadgeColor.neutral, status),
    };

/// "Mes réservations" élève : historique des séances de répétition avec
/// possibilité de laisser un avis (séances effectuées) ou de contester dans
/// la fenêtre de 2h (Module 6 — professeur_complete.md).
class MyTutorBookingsScreen extends StatefulWidget {
  const MyTutorBookingsScreen({super.key});

  @override
  State<MyTutorBookingsScreen> createState() => _MyTutorBookingsScreenState();
}

class _MyTutorBookingsScreenState extends State<MyTutorBookingsScreen> {
  List<TutorBookingRecord>? _bookings;
  bool _error = false;
  final Set<int> _reviewed = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    try {
      final list = await TutorBookingService.instance.getMine();
      list.sort((a, b) => b.sessionDate.compareTo(a.sessionDate));
      if (mounted) setState(() => _bookings = list);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  Future<void> _dispute(TutorBookingRecord b) async {
    final reason = await _promptReason(context);
    if (reason == null || reason.trim().isEmpty) return;
    try {
      await TutorBookingService.instance.dispute(b.id, reason.trim());
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Votre signalement a été envoyé.')));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Impossible d\'envoyer le signalement.')));
      }
    }
  }

  Future<String?> _promptReason(BuildContext context) async {
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
              Text('Signaler un problème', style: WinType.archivo(size: 18, color: s.onStrong)),
              const SizedBox(height: 6),
              Text('Décrivez le problème rencontré pendant cette séance.',
                  style: WinType.bodyS(s.onMuted)),
              const SizedBox(height: 16),
              WinTextField(hint: 'Ex : le répétiteur ne s\'est pas présenté…', controller: ctrl),
              const SizedBox(height: 20),
              WinButton('Envoyer', block: true, variant: WinButtonVariant.danger,
                  onTap: () => Navigator.pop(ctx, ctrl.text)),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final bookings = _bookings;
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Mes réservations', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(icon: Icon(Icons.refresh_outlined, color: s.onMuted), onPressed: _load),
        ],
      ),
      body: bookings == null && !_error
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
              : bookings!.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('Aucune réservation pour le moment.', style: WinType.bodyM(s.onMuted)),
                    ))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        itemCount: bookings.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) => _BookingCard(
                          booking: bookings[i],
                          reviewSent: _reviewed.contains(bookings[i].id),
                          onReviewed: () => setState(() => _reviewed.add(bookings[i].id)),
                          onDispute: () => _dispute(bookings[i]),
                        ),
                      ),
                    ),
    );
  }
}

class _BookingCard extends StatefulWidget {
  final TutorBookingRecord booking;
  final bool reviewSent;
  final VoidCallback onReviewed;
  final VoidCallback onDispute;
  const _BookingCard({
    required this.booking,
    required this.reviewSent,
    required this.onReviewed,
    required this.onDispute,
  });

  @override
  State<_BookingCard> createState() => _BookingCardState();
}

class _BookingCardState extends State<_BookingCard> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      setState(() => _error = 'Choisissez une note avant d\'envoyer.');
      return;
    }
    setState(() { _submitting = true; _error = null; });
    try {
      await TutorReviewService.instance.submit(widget.booking.id, _rating,
          comment: _commentCtrl.text.trim().isEmpty ? null : _commentCtrl.text.trim());
      if (!mounted) return;
      widget.onReviewed();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Merci pour votre avis !')));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final b = widget.booking;
    final (color, label) = _statusInfo(b.status);
    return WinCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          WinAvatar(b.tutorName ?? '?', size: 40),
          const SizedBox(width: 10),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.tutorName ?? 'Répétiteur', style: WinType.titleM(s.onStrong)),
            Text('${_fmtDate(b.sessionDate)} · ${b.startTime} – ${b.endTime}',
                style: WinType.labelM(s.onMuted)),
          ])),
          WinBadge(label, color: color),
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
        if (b.isDisputed && (b.disputeReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          WinAlert('Signalement envoyé : ${b.disputeReason}', type: BadgeColor.error),
        ],
        if (b.isCompleted && !widget.reviewSent) ...[
          const SizedBox(height: 14),
          const WinDivider(),
          const SizedBox(height: 12),
          Text('Laisser un avis', style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Row(children: List.generate(5, (i) {
            final filled = i < _rating;
            return GestureDetector(
              onTap: () => setState(() => _rating = i + 1),
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(filled ? Icons.star : Icons.star_border,
                    size: 28, color: filled ? WinColors.gold : s.onFaint),
              ),
            );
          })),
          const SizedBox(height: 8),
          WinTextField(hint: 'Commentaire (optionnel, 300 caractères max)', controller: _commentCtrl),
          if (_error != null) ...[
            const SizedBox(height: 8),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 10),
          WinButton('Envoyer mon avis', block: true, small: true, loading: _submitting,
              onTap: _submitting ? null : _submitReview),
          if (b.canDispute) ...[
            const SizedBox(height: 8),
            WinButton('Signaler un problème', block: true, small: true,
                variant: WinButtonVariant.outline, onTap: widget.onDispute),
          ],
        ] else if (b.isCompleted && widget.reviewSent) ...[
          const SizedBox(height: 10),
          const WinAlert('Merci pour votre avis !', type: BadgeColor.success),
        ] else if (b.canDispute) ...[
          const SizedBox(height: 12),
          WinButton('Signaler un problème', block: true, small: true,
              variant: WinButtonVariant.outline, onTap: widget.onDispute),
        ],
      ]),
    );
  }
}
