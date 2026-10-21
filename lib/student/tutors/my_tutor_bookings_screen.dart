import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/tutor_booking_service.dart';
import '../../services/tutor_review_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'tutor_policy_widgets.dart';
import 'tutor_pricing_widgets.dart';
import 'tutor_public_profile_screen.dart';
import 'tutor_report_sheet.dart';
import '../../services/tutor_engagement_service.dart';
import '../../shared/tutor_engagement_screen.dart';
import '../../shared/tutor_session_material_screen.dart';

String? _modeLabel(String mode) => switch (mode) {
      'online' => L10n.current.commonOnline,
      'student_home' => L10n.current.tutoringModeStudentHome,
      'tutor_home' => L10n.current.tutoringModeTutorHome,
      'neutral_place' => L10n.current.tutoringModeNeutralPlace,
      _ => null,
    };

String _fmtDate(DateTime d) => WinFormat.dateNumeric(d);

(BadgeColor, String) _statusInfo(String status) => switch (status) {
      'pending_payment' => (BadgeColor.neutral, L10n.current.tutoringStatusPendingPayment),
      'pending_tutor_approval' => (BadgeColor.warn, L10n.current.tutoringStatusPendingTutor),
      'confirmed' => (BadgeColor.success, L10n.current.tutoringStatusConfirmed),
      'completed' => (BadgeColor.blue, L10n.current.tutoringStatusCompleted),
      'disputed' => (BadgeColor.error, L10n.current.tutoringStatusDisputed),
      'rejected' => (BadgeColor.error, L10n.current.tutoringStatusRejected),
      'expired' => (BadgeColor.error, L10n.current.tutoringStatusExpired),
      'cancelled' => (BadgeColor.neutral, L10n.current.tutoringStatusCancelled),
      _ => (BadgeColor.neutral, status),
    };

/// "Mes réservations" élève : historique des séances de répétition avec
/// possibilité de laisser un avis (séances effectuées) ou de contester dans
/// la fenêtre de contestation (24 h par défaut, réglée côté serveur, lot 9.2),
/// et remboursements automatiques crédités au portefeuille (lot 9.2).
class MyTutorBookingsScreen extends StatefulWidget {
  const MyTutorBookingsScreen({super.key});

  @override
  State<MyTutorBookingsScreen> createState() => _MyTutorBookingsScreenState();
}

class _MyTutorBookingsScreenState extends State<MyTutorBookingsScreen> {
  List<TutorBookingRecord>? _bookings;
  bool _error = false;
  final Set<int> _reviewed = {};
  // Lot 9.5 : séances dont le tuteur a été signalé dans cette session.
  final Set<int> _reported = {};
  // Lot 9.3 : répétiteurs attribués par un parent ou une institution.
  List<TutorAssignment> _assigned = [];
  // Lot 9.4 : engagements mensuels (payeur ou participant).
  List<TutorEngagementRecord> _engagements = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = false);
    TutorBookingService.instance.getAssignmentsForMe().then((a) {
      if (mounted) setState(() => _assigned = a);
    }).catchError((Object _) {});
    TutorEngagementService.instance.mine().then((e) {
      if (mounted) setState(() => _engagements = e);
    }).catchError((Object _) {});
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(L10n.current.tutoringBookingsDisputeSent)));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.tutoringBookingsDisputeError)));
      }
    }
  }

  Future<void> _report(TutorBookingRecord b) async {
    final sent = await showTutorReportSheet(context, bookingId: b.id, tutorName: b.tutorName);
    if (sent == true && mounted) setState(() => _reported.add(b.id));
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
          padding:
              EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            decoration: BoxDecoration(
              color: s.surface,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ctx.l10n.tutoringReportProblem,
                      style: WinType.archivo(size: 18, color: s.onStrong)),
                  const SizedBox(height: 6),
                  Text(ctx.l10n.tutoringReportProblemHint,
                      style: WinType.bodyS(s.onMuted)),
                  const SizedBox(height: 16),
                  WinTextField(
                      hint: ctx.l10n.tutoringReportProblemPlaceholder,
                      controller: ctrl),
                  const SizedBox(height: 20),
                  WinButton(ctx.l10n.commonSend,
                      block: true,
                      variant: WinButtonVariant.danger,
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
        title: Text(context.l10n.tutoringBookingsTitle, style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
              tooltip: context.l10n.studentHubTutorPolicy,
              icon: Icon(Icons.policy_outlined, color: s.onMuted),
              onPressed: () => openTutorPolicy(context)),
          IconButton(
              icon: Icon(Icons.refresh_outlined, color: s.onMuted),
              onPressed: _load),
        ],
      ),
      body: bookings == null && !_error
          ? const Center(child: CircularProgressIndicator())
          : _error
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
                  const SizedBox(height: 12),
                  Text(context.l10n.tutoringBookingsLoadError,
                      style: WinType.bodyM(s.onMuted)),
                  const SizedBox(height: 12),
                  WinButton(context.l10n.commonRetry, onTap: _load),
                ]))
              : bookings!.isEmpty && _engagements.isEmpty
                  ? Center(
                      child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(context.l10n.tutoringBookingsEmpty,
                          style: WinType.bodyM(s.onMuted)),
                    ))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                        children: [
                          if (_assigned.isNotEmpty) ...[
                            Text(context.l10n.tutoringAssignedTitle, style: WinType.labelM(s.onStrong)),
                            const SizedBox(height: 8),
                            ..._assigned.map((a) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: WinCard(
                                    child: Row(children: [
                                      WinAvatar(a.tutorName ?? '?', size: 36),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                          Text(a.tutorName ?? context.l10n.roleTutor, style: WinType.titleM(s.onStrong)),
                                          Text('${a.subject != null ? '${a.subject} · ' : ''}${context.l10n.tutoringAssignedBy(a.assignerLabel)}',
                                              style: WinType.labelS(s.onMuted)),
                                        ]),
                                      ),
                                      WinButton(context.l10n.tutoringBook,
                                          small: true,
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => TutorPublicProfileScreen(
                                                      userId: a.tutorUserId, assignment: a)))),
                                      const SizedBox(width: 6),
                                      WinButton(context.l10n.tutoringMonthly,
                                          small: true,
                                          variant: WinButtonVariant.outline,
                                          onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) => TutorPublicProfileScreen(
                                                      userId: a.tutorUserId, assignment: a, openMonthly: true)))),
                                    ]),
                                  ),
                                )),
                            const SizedBox(height: 8),
                          ],
                          if (_engagements.isNotEmpty) ...[
                            Text(context.l10n.tutoringEngagementsTitle, style: WinType.labelM(s.onStrong)),
                            const SizedBox(height: 8),
                            for (final e in _engagements) EngagementListTile(engagement: e, onChanged: _load),
                            const SizedBox(height: 8),
                          ],
                          for (final b in bookings) ...[
                            _BookingCard(
                              booking: b,
                              reviewSent: _reviewed.contains(b.id),
                              onReviewed: () => setState(() => _reviewed.add(b.id)),
                              onDispute: () => _dispute(b),
                              reported: _reported.contains(b.id),
                              onReport: () => _report(b),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ],
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
  // Lot 9.5 : signaler le tuteur.
  final bool reported;
  final VoidCallback onReport;
  const _BookingCard({
    required this.booking,
    required this.reviewSent,
    required this.onReviewed,
    required this.onDispute,
    required this.reported,
    required this.onReport,
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
      setState(() => _error = context.l10n.tutoringReviewChooseRating);
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await TutorReviewService.instance.submit(widget.booking.id, _rating,
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim());
      if (!mounted) return;
      widget.onReviewed();
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.tutoringReviewThanks)));
    } catch (e) {
      if (mounted)
        setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(b.tutorName ?? context.l10n.tutoringTutor,
                    style: WinType.titleM(s.onStrong)),
                Text(
                    '${_fmtDate(b.sessionDate)} · ${b.startTime} – ${b.endTime}',
                    style: WinType.labelM(s.onMuted)),
              ])),
          WinBadge(label, color: color),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.place_outlined, size: 14, color: s.onFaint),
          const SizedBox(width: 4),
          Text(_modeLabel(b.mode) ?? b.mode, style: WinType.labelM(s.onMuted)),
          const SizedBox(width: 12),
          Icon(Icons.payments_outlined, size: 14, color: s.onFaint),
          const SizedBox(width: 4),
          Text('${fmtXaf(b.priceXaf)} XAF', style: WinType.labelM(s.onMuted)),
        ]),
        if (b.subject != null || b.topics.isNotEmpty) ...[
          const SizedBox(height: 8),
          if (b.subject != null)
            Text(b.subject!, style: WinType.labelM(s.onMuted)),
          if (b.topics.isNotEmpty) ...[
            const SizedBox(height: 6),
            TopicChipsRow(b.topics),
          ],
        ],
        // Lot 9.3 : pour qui, payée par qui (séance réservée par un parent,
        // une institution ou un membre du groupe d'étude).
        if (b.partiesSummary != null) ...[
          const SizedBox(height: 8),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.groups_outlined, size: 14, color: s.onFaint),
            const SizedBox(width: 4),
            Expanded(child: Text(b.partiesSummary!, style: WinType.labelM(s.onMuted))),
          ]),
        ],
        if (b.refundSummary != null) ...[
          const SizedBox(height: 10),
          WinAlert(b.refundSummary!,
              type: (b.refundAmountXaf ?? 0) > 0
                  ? BadgeColor.success
                  : BadgeColor.neutral),
        ],
        if (b.isCompleted && b.canDispute && b.disputeDeadline != null) ...[
          const SizedBox(height: 10),
          Text(
              context.l10n.tutoringDisputeUntil(_fmtDate(b.disputeDeadline!.toLocal()), WinFormat.time(b.disputeDeadline!.toLocal()), b.disputeWindowHours),
              style: WinType.labelS(s.onMuted)),
        ],
        if (b.isDisputed && (b.disputeReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 10),
          WinAlert(context.l10n.tutoringDisputeSentReason('${b.disputeReason}'),
              type: BadgeColor.error),
        ],
        // Lot 9.6 : support de séance WinAI partagé par le tuteur.
        if (b.sessionMaterialStatus == 'shared') ...[
          const SizedBox(height: 10),
          WinButton(b.viewerIsParticipant == true ? context.l10n.tutoringMaterialFull : context.l10n.tutoringMaterial,
              block: true,
              small: true,
              icon: Icons.menu_book_outlined,
              variant: WinButtonVariant.outline,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TutorSessionMaterialScreen(bookingId: b.id)))),
        ],
        // Lot 9.5 (17.12, 17.16) : notent les participants et le payeur, une
        // fois par séance et par personne (décidé par le serveur : canReview).
        if (b.myReviewRating != null) ...[
          const SizedBox(height: 10),
          Text(context.l10n.tutoringMyRating('${b.myReviewRating}'), style: WinType.labelM(s.onMuted)),
        ],
        if (b.hasReported || widget.reported) ...[
          const SizedBox(height: 8),
          WinAlert(context.l10n.tutoringReportSentTeam, type: BadgeColor.neutral),
        ] else if (b.canReport) ...[
          const SizedBox(height: 10),
          WinButton(context.l10n.tutoringReportTutor,
              block: true,
              small: true,
              icon: Icons.flag_outlined,
              variant: WinButtonVariant.ghost,
              onTap: widget.onReport),
        ],
        if (!widget.reviewSent && (b.canReview ?? (b.isCompleted && b.viewerIsParticipant != false))) ...[
          const SizedBox(height: 14),
          const WinDivider(),
          const SizedBox(height: 12),
          Text(context.l10n.tutoringLeaveReview, style: WinType.labelM(s.onStrong)),
          const SizedBox(height: 8),
          Row(
              children: List.generate(5, (i) {
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
          WinTextField(
              hint: context.l10n.tutoringReviewCommentHint,
              controller: _commentCtrl),
          if (_error != null) ...[
            const SizedBox(height: 8),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 10),
          WinButton(context.l10n.tutoringReviewSubmit,
              block: true,
              small: true,
              loading: _submitting,
              onTap: _submitting ? null : _submitReview),
          if (b.canDispute) ...[
            const SizedBox(height: 8),
            WinButton(context.l10n.tutoringDisputeSession,
                block: true,
                small: true,
                variant: WinButtonVariant.outline,
                onTap: widget.onDispute),
          ],
        ] else if (b.isCompleted && widget.reviewSent) ...[
          const SizedBox(height: 10),
          WinAlert(context.l10n.tutoringReviewThanks, type: BadgeColor.success),
        ] else if (b.canDispute) ...[
          const SizedBox(height: 12),
          WinButton(context.l10n.tutoringDisputeSession,
              block: true,
              small: true,
              variant: WinButtonVariant.outline,
              onTap: widget.onDispute),
        ],
      ]),
    );
  }
}
