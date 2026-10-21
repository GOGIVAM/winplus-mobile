import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/tutor_booking_service.dart';
import '../services/tutor_engagement_service.dart';
import '../student/tutors/tutor_pricing_widgets.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'tutor_session_material_screen.dart';

/// Lot 9.4 (suivi 17.7) : vue d'un engagement mensuel côté payeur,
/// participant et tuteur (parité web). Séances et état de chacune, argent
/// bloqué / versé / remboursé, accepter ou refuser (tuteur), annuler
/// l'engagement ou une séance seule, renouveler et renouvellement automatique.
/// Tous les montants viennent du serveur.

String _d(DateTime d) {
  return '${WinFormat.weekdayShort(d.weekday)} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
}

String _dt(DateTime d) {
  final l = d.toLocal();
  return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')} ${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
}

BadgeColor engagementBadgeColor(String status) => switch (status) {
      'active' || 'completed' => BadgeColor.success,
      'pending_tutor_approval' || 'pending_payment' => BadgeColor.warn,
      _ => BadgeColor.error,
    };

/// Ligne de liste d'un engagement (payeur, participant ou tuteur).
class EngagementListTile extends StatelessWidget {
  final TutorEngagementRecord engagement;
  final bool tutorView;
  final VoidCallback? onChanged;
  const EngagementListTile({super.key, required this.engagement, this.tutorView = false, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final e = engagement;
    final who = tutorView ? (e.participantNames.isNotEmpty ? e.participantNames : (e.payerName ?? context.l10n.roleStudent)) : (e.tutorName ?? context.l10n.tutoringTutor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinCard(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: e.id)));
          onChanged?.call();
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('$who · ${e.subject ?? context.l10n.tutoringTutoring}', style: WinType.titleM(s.onStrong))),
            WinBadge(e.statusLabel, color: engagementBadgeColor(e.status)),
          ]),
          const SizedBox(height: 4),
          Text(context.l10n.tutoringEngRangeSummary(_d(e.startDate), _d(e.endDate), e.slotsSummary), style: WinType.labelS(s.onMuted)),
          const SizedBox(height: 4),
          Text(context.l10n.tutoringEngTileTotal(fmtXaf(e.totalXaf), e.sessionsDone, e.sessionsCount), style: WinType.labelM(s.onStrong)),
        ]),
      ),
    );
  }
}

class TutorEngagementScreen extends StatefulWidget {
  final int engagementId;
  const TutorEngagementScreen({super.key, required this.engagementId});

  @override
  State<TutorEngagementScreen> createState() => _TutorEngagementScreenState();
}

class _TutorEngagementScreenState extends State<TutorEngagementScreen> {
  TutorEngagementRecord? _e;
  bool _loading = true;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final e = await TutorEngagementService.instance.get(widget.engagementId);
      if (!mounted) return;
      setState(() {
        _e = e;
        _loading = false;
        _error = null;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = TutorEngagementService.errorMessage(err) ?? L10n.current.tutoringEngNotFound;
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(success)));
      await _load();
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(TutorEngagementService.errorMessage(err) ?? L10n.current.tutoringActionFailed)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _ask(String title, {String? hint, bool required = false}) async {
    final ctrl = TextEditingController();
    final hintText = hint ?? context.l10n.tutoringReasonOptional;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hintText), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonBack)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.commonConfirm)),
        ],
      ),
    );
    final text = ctrl.text.trim();
    ctrl.dispose();
    if (ok != true) return null;
    if (required && text.isEmpty) return null;
    return text;
  }

  Future<void> _renewByMobileMoney(TutorEngagementRecord e) async {
    final phone = await _ask(context.l10n.tutoringMomoNumber, hint: '6XX XXX XXX', required: true);
    if (phone == null) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await _run(() async {
      final next = await TutorEngagementService.instance.renew(e.id, paymentMethod: 'mobile_money', phone: digits);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: next.id)));
    }, L10n.current.tutoringEngMmSent);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        iconTheme: IconThemeData(color: s.onStrong),
        title: Text(context.l10n.tutoringEngStagePlan, style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _e == null
                ? Center(child: Text(_error ?? context.l10n.tutoringEngNotFound, style: WinType.bodyS(s.onMuted)))
                : RefreshIndicator(onRefresh: _load, child: _content(s, _e!)),
      ),
    );
  }

  Widget _tile(WinScheme s, String label, num value) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: s.chipBg, borderRadius: BorderRadius.circular(12)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: WinType.labelS(s.onMuted)),
            const SizedBox(height: 2),
            Text('${fmtXaf(value)} XAF', style: WinType.titleM(s.onStrong)),
          ]),
        ),
      );

  Widget _content(WinScheme s, TutorEngagementRecord e) {
    final isTutor = e.viewerIsTutor;
    final isPayer = e.viewerIsPayer;
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Expanded(child: Text(isTutor ? e.participantNames : context.l10n.tutoringEngWith(e.tutorName ?? context.l10n.tutoringYourTutor), style: WinType.titleM(s.onStrong))),
        WinBadge(e.statusLabel, color: engagementBadgeColor(e.status)),
      ]),
      const SizedBox(height: 4),
      Text(context.l10n.tutoringEngRangeSummary(_d(e.startDate), _d(e.endDate), e.slotsSummary), style: WinType.bodyS(s.onMuted)),
      Text(context.l10n.tutoringEngPaidByLine(e.subject ?? context.l10n.tutoringTutoring, e.payerName ?? kPayerTypeLabels[e.payerType] ?? e.payerType,
          e.paymentMethod == 'wallet' ? context.l10n.tutoringWinplusBalance : 'Mobile Money'),
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 14),
      Row(children: [_tile(s, context.l10n.tutoringEngPaidAdvance, e.totalXaf), const SizedBox(width: 8), _tile(s, context.l10n.tutoringEngHeld, e.heldXaf)]),
      const SizedBox(height: 8),
      Row(children: [_tile(s, context.l10n.tutoringEngReleased, e.releasedXaf), const SizedBox(width: 8), _tile(s, context.l10n.tutoringEngRefundedTile, e.refundedXaf)]),
      const SizedBox(height: 8),
      Text(
          '${e.discountPercent > 0 ? context.l10n.tutoringEngDiscountNote(e.discountPercent, fmtXaf(e.discountXaf)) : ''}'
          '${context.l10n.tutoringEngMoneyFlow}'
          '${e.feesRetainedXaf > 0 ? context.l10n.tutoringEngFeesNote(fmtXaf(e.feesRetainedXaf)) : ''}',
          style: WinType.labelS(s.onFaint)),
      if (e.cancellationReason != null && e.status != 'active') ...[
        const SizedBox(height: 6),
        Text(context.l10n.tutoringEngReason('${e.cancellationReason}'), style: WinType.labelS(s.onMuted)),
      ],
      const SizedBox(height: 14),
      if (isTutor && e.status == 'pending_tutor_approval') ...[
        if (e.responseDeadlineAt != null)
          Text(context.l10n.tutoringEngReplyBefore(_dt(e.responseDeadlineAt!)), style: WinType.labelS(WinColors.error)),
        const SizedBox(height: 8),
        WinButton(context.l10n.tutoringEngAccept,
            block: true,
            loading: _busy,
            onTap: _busy ? null : () => _run(() => TutorEngagementService.instance.accept(e.id), context.l10n.tutoringEngAccepted)),
        const SizedBox(height: 8),
        WinButton(context.l10n.commonDecline,
            block: true,
            variant: WinButtonVariant.outline,
            onTap: _busy
                ? null
                : () async {
                    final reason = await _ask(context.l10n.tutoringEngDeclineConfirm);
                    if (reason == null) return;
                    await _run(() => TutorEngagementService.instance.decline(e.id, reason: reason.isEmpty ? null : reason),
                        L10n.current.tutoringEngDeclined);
                  }),
      ] else if (e.canCancel)
        WinButton(context.l10n.tutoringEngCancel,
            block: true,
            variant: WinButtonVariant.danger,
            onTap: _busy
                ? null
                : () async {
                    final reason = await _ask(isTutor
                        ? context.l10n.tutoringEngCancelTutorConfirm
                        : context.l10n.tutoringEngCancelPayerConfirm);
                    if (reason == null) return;
                    await _run(() => TutorEngagementService.instance.cancel(e.id, reason: reason.isEmpty ? null : reason),
                        L10n.current.tutoringEngCancelled);
                  }),
      if (isPayer && (e.status == 'active' || e.status == 'pending_tutor_approval')) ...[
        const SizedBox(height: 18),
        Text(context.l10n.tutoringEngRenewal, style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 6),
        if (e.renewedToEngagementId != null)
          WinButton(context.l10n.tutoringEngSeeNextMonth,
              variant: WinButtonVariant.outline,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: e.renewedToEngagementId!))))
        else ...[
          Text(context.l10n.tutoringEngSameSlots(_d(e.nextStartDate)),
              style: WinType.labelS(s.onFaint)),
          if (e.canSetAutoRenew)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: e.autoRenew,
              onChanged: _busy
                  ? null
                  : (v) => _run(() => TutorEngagementService.instance.setAutoRenew(e.id, v),
                      v ? context.l10n.tutoringEngAutoOn : context.l10n.tutoringEngAutoOff),
              title: Text(context.l10n.tutoringEngAutoRenewTitle, style: WinType.labelM(s.onStrong)),
              subtitle: Text(
                  e.autoRenewAt != null
                      ? context.l10n.tutoringEngAutoRenewAt(_dt(e.autoRenewAt!))
                      : context.l10n.tutoringEngAutoRenewIf,
                  style: WinType.labelS(s.onFaint)),
            )
          else if (e.paymentMethod != 'wallet')
            Text(context.l10n.tutoringEngAutoWalletOnly, style: WinType.labelS(s.onFaint)),
          if (e.autoRenewFailureReason != null)
            WinAlert(context.l10n.tutoringEngAutoFailed('${e.autoRenewFailureReason}'), type: BadgeColor.warn),
          if (e.canRenew) ...[
            const SizedBox(height: 8),
            WinButton(context.l10n.tutoringEngRenewWallet,
                block: true,
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final next = await TutorEngagementService.instance.renew(e.id, paymentMethod: 'wallet');
                          if (!mounted) return;
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: next.id)));
                        }, context.l10n.tutoringEngRenewedWallet)),
            const SizedBox(height: 8),
            WinButton(context.l10n.tutoringEngRenewMm, block: true, variant: WinButtonVariant.outline, onTap: _busy ? null : () => _renewByMobileMoney(e)),
          ],
        ],
      ],
      const SizedBox(height: 18),
      Text(context.l10n.tutoringEngSessions(e.sessionsDone, e.sessionsCount), style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 8),
      for (final x in e.sessions) _session(s, x),
    ]);
  }

  Widget _session(WinScheme s, EngagementSession x) {
    final refund = x.refundAmountXaf != null && x.refundAmountXaf! > 0
        ? ' · ${context.l10n.tutoringEngRefundedAmount(fmtXaf(x.refundAmountXaf!))}${x.refundPercent != null ? ' (${context.l10n.tutoringPercent('${x.refundPercent}')})' : ''}'
        : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: WinCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('${_d(x.sessionDate)} · ${x.startTime}-${x.endTime}', style: WinType.labelM(s.onStrong))),
            Text('${fmtXaf(x.priceXaf)} XAF', style: WinType.labelM(s.onStrong)),
          ]),
          const SizedBox(height: 2),
          Text('${kSessionStatusLabels[x.status] ?? x.status} · ${kMoneyStateLabels[x.moneyState] ?? x.moneyState}$refund'
              '${x.disputeDeadline != null ? ' · ${context.l10n.tutoringEngDisputeUntil(_dt(x.disputeDeadline!))}' : ''}',
              style: WinType.labelS(s.onMuted)),
          // Lot 9.6 : support de séance WinAI, séance par séance.
          if (const ['confirmed', 'completed', 'disputed'].contains(x.status)) ...[
            const SizedBox(height: 6),
            WinButton(context.l10n.tutoringMaterial,
                small: true,
                variant: WinButtonVariant.ghost,
                icon: Icons.menu_book_outlined,
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute(builder: (_) => TutorSessionMaterialScreen(bookingId: x.id)))),
          ],
          if (x.canMarkCompleted || x.canDispute || x.canCancel) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (x.canMarkCompleted)
                WinButton(context.l10n.tutoringStatusCompleted,
                    small: true,
                    onTap: _busy ? null : () => _run(() => TutorBookingService.instance.complete(x.id), context.l10n.tutoringEngMarkedCompleted)),
              if (x.canDispute)
                WinButton(context.l10n.tutoringDispute,
                    small: true,
                    variant: WinButtonVariant.outline,
                    onTap: _busy
                        ? null
                        : () async {
                            final reason = await _ask(context.l10n.tutoringEngDisputePrompt, hint: context.l10n.tutoringEngExplainProblem, required: true);
                            if (reason == null) return;
                            await _run(() => TutorBookingService.instance.dispute(x.id, reason),
                                L10n.current.tutoringEngDisputed);
                          }),
              if (x.canCancel)
                WinButton(context.l10n.tutoringEngCancelSession,
                    small: true,
                    variant: WinButtonVariant.ghost,
                    onTap: _busy
                        ? null
                        : () async {
                            final reason = await _ask(context.l10n.tutoringEngCancelSessionConfirm(_d(x.sessionDate)));
                            if (reason == null) return;
                            await _run(() => TutorBookingService.instance.cancel(x.id, reason: reason.isEmpty ? null : reason), L10n.current.tutoringEngSessionCancelled);
                          }),
            ]),
          ],
        ]),
      ),
    );
  }
}
