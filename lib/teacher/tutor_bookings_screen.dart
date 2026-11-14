import 'package:flutter/material.dart';

import '../services/tutor_booking_service.dart';
import '../services/tutor_engagement_service.dart';
import '../services/tutor_session_material_service.dart';
import '../shared/tutor_engagement_screen.dart';
import '../shared/tutor_session_material_screen.dart';
import '../student/tutors/tutor_pricing_widgets.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

String? _modeLabel(BuildContext context, String mode) => switch (mode) {
      'online' => context.l10n.commonOnline,
      'student_home' => context.l10n.teacherBookingModeStudentHome,
      'tutor_home' => context.l10n.tutoringModeTutorHome,
      'neutral_place' => context.l10n.tutoringModeNeutralPlace,
      _ => null,
    };

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

/// Lot 9.1 : matière, sujets à travailler saisis par l'élève et détail du
/// prix figé à la réservation (absent pour les réservations antérieures).
class _BookingDetails extends StatefulWidget {
  final TutorBookingRecord booking;
  const _BookingDetails(this.booking);

  @override
  State<_BookingDetails> createState() => _BookingDetailsState();
}

class _BookingDetailsState extends State<_BookingDetails> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final b = widget.booking;
    final info = [
      if (b.subject != null) b.subject!,
      if (b.durationMinutes > 0) formatDurationMinutes(b.durationMinutes),
    ].join(' · ');
    // Lot 9.3 : participants, payeur et type de payeur.
    final names = b.participants.isNotEmpty
        ? b.participants.map((p) => p.label).join(', ')
        : (b.studentName ?? context.l10n.roleStudent);
    final payer = '${b.payerName ?? context.l10n.teacherBookingTheStudent} (${kPayerTypeLabels[b.payerType] ?? b.payerType}'
        '${b.studyGroupName != null ? ' · ${b.studyGroupName}' : ''})'
        '${b.tutorAssignmentId != null ? ' · ${context.l10n.teacherBookingViaAssignment}' : ''}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 8),
      Text(
          context.l10n.teacherBookingParticipants(
              b.participantCount > 1 ? context.l10n.teacherBookingGroupSession(b.participantCount) : context.l10n.roleStudent, names),
          style: WinType.labelM(s.onSurface)),
      Text(context.l10n.teacherBookingPaidBy(payer), style: WinType.labelM(s.onMuted)),
      if (info.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(info, style: WinType.labelM(s.onMuted)),
      ],
      if (b.topics.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text(context.l10n.teacherBookingTopics, style: WinType.labelS(s.onFaint)),
        const SizedBox(height: 4),
        TopicChipsRow(b.topics),
      ],
      // Lot 9.6 : support de séance WinAI (cours, quiz, exercices), préparé et partagé par le tuteur.
      if (const ['pending_tutor_approval', 'confirmed', 'completed', 'disputed'].contains(b.status)) ...[
        const SizedBox(height: 8),
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          WinButton(b.sessionMaterialStatus != null ? context.l10n.tutoringMaterial : context.l10n.teacherBookingPrepareMaterial,
              small: true,
              variant: WinButtonVariant.outline,
              icon: winAIIconData,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TutorSessionMaterialScreen(bookingId: b.id)))),
          if (b.sessionMaterialStatus != null)
            Text(kSessionMaterialStatusLabels[b.sessionMaterialStatus] ?? '', style: WinType.labelS(s.onFaint)),
        ]),
      ],
      if (b.priceBreakdown != null) ...[
        TextButton(
          style: TextButton.styleFrom(padding: EdgeInsets.zero),
          onPressed: () => setState(() => _open = !_open),
          child: Text(
              _open ? context.l10n.teacherBookingHidePrice : context.l10n.teacherBookingShowPrice),
        ),
        if (_open) TutorPriceBreakdownView(quote: b.priceBreakdown!),
      ],
    ]);
  }
}

/// Espace "Cours particuliers" du répétiteur : demandes en attente
/// (accepter/refuser avec compte à rebours) et séances à venir/à clôturer
/// (Module 6  professeur_complete.md, cycle de vie des réservations).
class TutorBookingsScreen extends StatefulWidget {
  const TutorBookingsScreen({super.key});

  @override
  State<TutorBookingsScreen> createState() => _TutorBookingsScreenState();
}

class _TutorBookingsScreenState extends State<TutorBookingsScreen> {
  List<TutorPendingBooking>? _pending;
  List<TutorBookingRecord>? _mine;
  // Lot 9.3 : attributions reçues (parent, institution).
  List<TutorAssignment> _assignments = [];
  // Lot 9.4 : demandes d'engagement mensuel (acceptées ou refusées en entier) et engagements.
  List<PendingEngagement> _pendingEngagements = [];
  List<TutorEngagementRecord> _engagements = [];
  bool _error = false;
  final Set<int> _busy = {};

  Future<void> _respond(TutorAssignment a, String action) async {
    setState(() => _busy.add(-a.id));
    try {
      final updated = await TutorBookingService.instance.respondAssignment(a.id, action: action);
      if (!mounted) return;
      setState(() => _assignments = _assignments.map((x) => x.id == a.id ? updated : x).toList());
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(L10n.current.tutoringActionFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(-a.id));
    }
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool? _autoMaterial;

  Future<void> _setAutoMaterial(bool value) async {
    try {
      final v = await TutorSessionMaterialService.instance.setAutoGenerate(value);
      if (mounted) setState(() => _autoMaterial = v);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(TutorSessionMaterialService.errorMessage(e) ?? L10n.current.teacherBookingSettingError)));
      }
    }
  }

  Future<void> _load() async {
    setState(() => _error = false);
    TutorSessionMaterialService.instance.getAutoGenerate().then((v) {
      if (mounted) setState(() => _autoMaterial = v);
    }).catchError((Object _) {});
    try {
      final results = await Future.wait([
        TutorBookingService.instance.getPending(),
        // Séances reçues en tant que tuteur (et non réservées en tant qu'élève).
        TutorBookingService.instance.getTutorMine(),
      ]);
      final assignments = await TutorBookingService.instance.getTutorAssignments().catchError((Object _) => <TutorAssignment>[]);
      final pendingEngagements = await TutorEngagementService.instance.pending().catchError((Object _) => <PendingEngagement>[]);
      final engagements = await TutorEngagementService.instance.tutorMine().catchError((Object _) => <TutorEngagementRecord>[]);
      if (!mounted) return;
      setState(() {
        _pendingEngagements = pendingEngagements;
        _engagements = engagements;
        _pending = results[0] as List<TutorPendingBooking>;
        _mine = results[1] as List<TutorBookingRecord>;
        _assignments = assignments;
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherBookingAcceptError)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _decline(int id) async {
    final reason = await _promptText(context,
        title: context.l10n.teacherBookingDeclineTitle,
        hint: context.l10n.teacherBookingReasonHint,
        // Lot 9.2 (17.9) : refuser rembourse l'élève, frais retenus au tuteur.
        message:
            context.l10n.teacherBookingDeclineMessage);
    if (reason == null) return; // annulé
    setState(() => _busy.add(id));
    try {
      final updated = await TutorBookingService.instance
          .decline(id, reason: reason.isEmpty ? null : reason);
      final fee = updated.tutorFeeChargedXaf ?? 0;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(fee > 0
                ? L10n.current.teacherBookingDeclinedFee(fmtXaf(fee))
                : L10n.current.teacherBookingDeclined)));
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherBookingDeclineError)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<void> _respondEngagement(TutorEngagementRecord e, bool accept) async {
    String? reason;
    if (!accept) {
      reason = await _promptText(context,
          title: context.l10n.teacherBookingDeclineEngagementTitle,
          hint: context.l10n.teacherBookingReasonHint,
          message:
              context.l10n.teacherBookingDeclineEngagementMessage);
      if (reason == null) return;
    }
    setState(() => _busy.add(-100000 - e.id));
    try {
      if (accept) {
        await TutorEngagementService.instance.accept(e.id);
      } else {
        await TutorEngagementService.instance.decline(e.id, reason: reason!.isEmpty ? null : reason);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(accept ? L10n.current.teacherBookingEngagementAccepted : L10n.current.tutoringEngDeclined)));
      }
      await _load();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(TutorEngagementService.errorMessage(err) ?? L10n.current.tutoringActionFailed)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(-100000 - e.id));
    }
  }

  Future<void> _complete(int id) async {
    setState(() => _busy.add(id));
    try {
      await TutorBookingService.instance.complete(id);
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(L10n.current.teacherBookingCompleteError)));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  Future<String?> _promptText(BuildContext context,
      {required String title, String? hint, String? message}) async {
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
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(WinRadii.xl)),
            ),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: WinType.archivo(size: 18, color: s.onStrong)),
                  if (message != null) ...[
                    const SizedBox(height: 8),
                    Text(message, style: WinType.bodyS(s.onMuted)),
                  ],
                  const SizedBox(height: 16),
                  WinTextField(hint: hint, controller: ctrl),
                  const SizedBox(height: 20),
                  Row(children: [
                    Expanded(
                      child: WinButton(ctx.l10n.commonCancel,
                          variant: WinButtonVariant.outline,
                          block: true,
                          onTap: () => Navigator.pop(ctx)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: WinButton(ctx.l10n.commonConfirm,
                          variant: WinButtonVariant.danger,
                          block: true,
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
        title: Text(context.l10n.tutoringPrivateLessons, style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_outlined, color: s.onMuted),
              onPressed: _load),
        ],
      ),
      body: pending == null && !_error
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
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      Text(context.l10n.teacherBookingPendingTitle,
                          style: WinType.archivo(size: 18, color: s.onStrong)),
                      const SizedBox(height: 10),
                      if ((pending ?? []).isEmpty)
                        WinCard(
                          child: Text(
                              context.l10n.teacherBookingPendingEmpty,
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
                      if (_pendingEngagements.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(context.l10n.teacherBookingEngagementRequests,
                            style: WinType.archivo(size: 18, color: s.onStrong)),
                        const SizedBox(height: 10),
                        for (final pe in _pendingEngagements)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: WinCard(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(pe.engagement.participantNames.isNotEmpty ? pe.engagement.participantNames : (pe.engagement.payerName ?? context.l10n.roleStudent),
                                    style: WinType.titleM(s.onStrong)),
                                const SizedBox(height: 4),
                                Text('${context.l10n.teacherBookingSessionsCount(pe.engagement.sessionsCount)} · ${pe.engagement.slotsSummary}',
                                    style: WinType.bodyS(s.onMuted)),
                                Text('${context.l10n.teacherBookingPaidInAdvance(fmtXaf(pe.engagement.totalXaf))}${pe.engagement.discountPercent > 0 ? ' ${context.l10n.teacherBookingDiscount(pe.engagement.discountPercent)}' : ''} · ${context.l10n.teacherBookingPaidPerSession}',
                                    style: WinType.labelS(s.onFaint)),
                                Text(pe.minutesRemaining > 0 ? context.l10n.teacherBookingMinutesToAnswer(pe.minutesRemaining) : context.l10n.teacherBookingExpiresSoon,
                                    style: WinType.labelS(WinColors.error)),
                                const SizedBox(height: 8),
                                Wrap(spacing: 8, runSpacing: 6, children: [
                                  WinButton(context.l10n.teacherBookingAcceptMonth,
                                      small: true,
                                      loading: _busy.contains(-100000 - pe.engagement.id),
                                      onTap: _busy.contains(-100000 - pe.engagement.id) ? null : () => _respondEngagement(pe.engagement, true)),
                                  WinButton(context.l10n.commonDecline,
                                      small: true,
                                      variant: WinButtonVariant.outline,
                                      onTap: _busy.contains(-100000 - pe.engagement.id) ? null : () => _respondEngagement(pe.engagement, false)),
                                  WinButton(context.l10n.teacherBookingDetail,
                                      small: true,
                                      variant: WinButtonVariant.ghost,
                                      onTap: () async {
                                        await Navigator.of(context).push(MaterialPageRoute(
                                            builder: (_) => TutorEngagementScreen(engagementId: pe.engagement.id)));
                                        _load();
                                      }),
                                ]),
                              ]),
                            ),
                          ),
                      ],
                      if (_engagements.any((e) => e.status == 'active' || e.status == 'completed')) ...[
                        const SizedBox(height: 24),
                        Text(context.l10n.tutoringEngagementsTitle,
                            style: WinType.archivo(size: 18, color: s.onStrong)),
                        const SizedBox(height: 10),
                        for (final e in _engagements.where((e) => e.status == 'active' || e.status == 'completed'))
                          EngagementListTile(engagement: e, tutorView: true, onChanged: _load),
                      ],
                      if (_assignments.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text(context.l10n.teacherBookingAssignments,
                            style: WinType.archivo(size: 18, color: s.onStrong)),
                        const SizedBox(height: 10),
                        ..._assignments.map((a) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: WinCard(
                                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Row(children: [
                                    Expanded(
                                      child: Text(
                                          '${a.assignerLabel}${a.groupName != null ? ' · ${a.groupName}' : ''}',
                                          style: WinType.titleM(s.onStrong)),
                                    ),
                                    WinBadge(a.statusLabel,
                                        color: a.isActive ? BadgeColor.success : a.isPending ? BadgeColor.warn : BadgeColor.neutral),
                                  ]),
                                  const SizedBox(height: 4),
                                  Text(
                                      '${a.assignerType == 'institution' ? context.l10n.authRoleInstitutionLabel : context.l10n.roleParent} · ${context.l10n.teacherBookingBeneficiaries(a.beneficiaries.length)} '
                                      '${a.beneficiaries.take(6).map((b) => b.label).join(', ')}${a.beneficiaries.length > 6 ? '…' : ''}'
                                      '${a.subject != null ? ' · ${a.subject}' : ''}',
                                      style: WinType.labelM(s.onMuted)),
                                  if (a.note != null) Text(context.l10n.teacherBookingQuote(a.note!), style: WinType.labelS(s.onFaint)),
                                  if (a.isPending || a.isActive) ...[
                                    const SizedBox(height: 10),
                                    Row(children: [
                                      if (a.isPending) ...[
                                        Expanded(
                                            child: WinButton(context.l10n.commonDecline,
                                                small: true,
                                                variant: WinButtonVariant.outline,
                                                loading: _busy.contains(-a.id),
                                                onTap: () => _respond(a, 'decline'))),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: WinButton(context.l10n.commonAccept,
                                                small: true,
                                                loading: _busy.contains(-a.id),
                                                onTap: () => _respond(a, 'accept'))),
                                      ] else
                                        Expanded(
                                            child: WinButton(context.l10n.tutoringEndAssignment,
                                                small: true,
                                                variant: WinButtonVariant.outline,
                                                loading: _busy.contains(-a.id),
                                                onTap: () => _respond(a, 'end'))),
                                    ]),
                                  ],
                                ]),
                              ),
                            )),
                      ],
                      const SizedBox(height: 24),
                      Text(context.l10n.teacherBookingUpcomingTitle,
                          style: WinType.archivo(size: 18, color: s.onStrong)),
                      // Lot 9.6 : génération automatique du support à l'acceptation (désactivée par défaut).
                      if (_autoMaterial != null)
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _autoMaterial!,
                          onChanged: _setAutoMaterial,
                          title: Text(context.l10n.teacherBookingAutoMaterial, style: WinType.labelM(s.onStrong)),
                          subtitle: Text(context.l10n.teacherBookingAutoMaterialHint,
                              style: WinType.labelS(s.onFaint)),
                        ),
                      const SizedBox(height: 10),
                      if (upcoming.isEmpty)
                        WinCard(
                          child: Text(context.l10n.teacherBookingConfirmedEmpty,
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
  const _PendingCard(
      {required this.pending,
      required this.busy,
      required this.onAccept,
      required this.onDecline});

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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(b.studentName ?? context.l10n.roleStudent,
                    style: WinType.titleM(s.onStrong)),
                Text(
                    '${_fmtDate(b.sessionDate)} · ${b.startTime} – ${b.endTime}',
                    style: WinType.labelM(s.onMuted)),
              ])),
          WinBadge(context.l10n.teacherBookingMinutes(pending.minutesRemaining),
              color: urgent ? BadgeColor.error : BadgeColor.warn),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          Icon(Icons.place_outlined, size: 14, color: s.onFaint),
          const SizedBox(width: 4),
          Text(_modeLabel(context, b.mode) ?? b.mode, style: WinType.labelM(s.onMuted)),
          const SizedBox(width: 12),
          Icon(Icons.payments_outlined, size: 14, color: s.onFaint),
          const SizedBox(width: 4),
          Text('${fmtXaf(b.priceXaf)} XAF', style: WinType.labelM(s.onMuted)),
        ]),
        _BookingDetails(b),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
            child: WinButton(context.l10n.commonDecline,
                variant: WinButtonVariant.outline,
                small: true,
                loading: busy,
                onTap: busy ? null : onDecline),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: WinButton(context.l10n.commonAccept,
                small: true, loading: busy, onTap: busy ? null : onAccept),
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
  const _UpcomingCard(
      {required this.booking, required this.busy, required this.onComplete});

  BadgeColor get _statusColor => switch (booking.status) {
        'confirmed' => BadgeColor.success,
        'completed' => BadgeColor.blue,
        'disputed' => BadgeColor.error,
        _ => BadgeColor.neutral,
      };

  String get _statusLabel => switch (booking.status) {
        'confirmed' => L10n.current.tutoringStatusConfirmed,
        'completed' => L10n.current.tutoringStatusCompleted,
        'disputed' => L10n.current.tutoringStatusDisputed,
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
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(b.studentName ?? context.l10n.roleStudent,
                    style: WinType.titleM(s.onStrong)),
                Text(
                    '${_fmtDate(b.sessionDate)} · ${b.startTime} – ${b.endTime}',
                    style: WinType.labelM(s.onMuted)),
              ])),
          WinBadge(_statusLabel, color: _statusColor),
        ]),
        _BookingDetails(b),
        if (b.isDisputed && (b.disputeReason ?? '').isNotEmpty) ...[
          const SizedBox(height: 8),
          WinAlert(context.l10n.teacherBookingDisputeReason(b.disputeReason!),
              type: BadgeColor.error),
        ],
        if (b.canMarkCompleted) ...[
          const SizedBox(height: 14),
          WinButton(context.l10n.teacherBookingMarkCompleted,
              block: true,
              small: true,
              loading: busy,
              icon: Icons.check_circle_outline,
              onTap: busy ? null : onComplete),
        ],
      ]),
    );
  }
}
