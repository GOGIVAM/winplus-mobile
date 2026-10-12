import 'package:flutter/material.dart';

import '../services/tutor_booking_service.dart';
import '../services/tutor_engagement_service.dart';
import '../student/tutors/tutor_pricing_widgets.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

/// Lot 9.4 (suivi 17.7) : vue d'un engagement mensuel côté payeur,
/// participant et tuteur (parité web). Séances et état de chacune, argent
/// bloqué / versé / remboursé, accepter ou refuser (tuteur), annuler
/// l'engagement ou une séance seule, renouveler et renouvellement automatique.
/// Tous les montants viennent du serveur.

String _d(DateTime d) {
  const days = ['lun.', 'mar.', 'mer.', 'jeu.', 'ven.', 'sam.', 'dim.'];
  return '${days[d.weekday - 1]} ${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
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
    final who = tutorView ? (e.participantNames.isNotEmpty ? e.participantNames : (e.payerName ?? 'Élève')) : (e.tutorName ?? 'Tuteur');
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: WinCard(
        onTap: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: e.id)));
          onChanged?.call();
        },
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text('$who · ${e.subject ?? 'Tutorat'}', style: WinType.titleM(s.onStrong))),
            WinBadge(e.statusLabel, color: engagementBadgeColor(e.status)),
          ]),
          const SizedBox(height: 4),
          Text('Du ${_d(e.startDate)} au ${_d(e.endDate)} · ${e.slotsSummary}', style: WinType.labelS(s.onMuted)),
          const SizedBox(height: 4),
          Text('${fmtXaf(e.totalXaf)} XAF · ${e.sessionsDone}/${e.sessionsCount} séances effectuées', style: WinType.labelM(s.onStrong)),
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
        _error = TutorEngagementService.errorMessage(err) ?? 'Engagement introuvable.';
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
          .showSnackBar(SnackBar(content: Text(TutorEngagementService.errorMessage(err) ?? 'Action impossible.')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _ask(String title, {String hint = 'Motif (facultatif)', bool required = false}) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: InputDecoration(hintText: hint), maxLines: 2),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Retour')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Confirmer')),
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
    final phone = await _ask('Numéro Mobile Money', hint: '6XX XXX XXX', required: true);
    if (phone == null) return;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    await _run(() async {
      final next = await TutorEngagementService.instance.renew(e.id, paymentMethod: 'mobile_money', phone: digits);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: next.id)));
    }, 'Demande de paiement envoyée sur ton téléphone.');
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
        title: Text('Engagement mensuel', style: WinType.headlineS(s.onStrong)),
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _e == null
                ? Center(child: Text(_error ?? 'Engagement introuvable.', style: WinType.bodyS(s.onMuted)))
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
        Expanded(child: Text(isTutor ? e.participantNames : 'Avec ${e.tutorName ?? 'ton tuteur'}', style: WinType.titleM(s.onStrong))),
        WinBadge(e.statusLabel, color: engagementBadgeColor(e.status)),
      ]),
      const SizedBox(height: 4),
      Text('Du ${_d(e.startDate)} au ${_d(e.endDate)} · ${e.slotsSummary}', style: WinType.bodyS(s.onMuted)),
      Text('${e.subject ?? 'Tutorat'} · payé par ${e.payerName ?? kPayerTypeLabels[e.payerType] ?? e.payerType} · '
          '${e.paymentMethod == 'wallet' ? 'solde WinPlus' : 'Mobile Money'}',
          style: WinType.labelS(s.onFaint)),
      const SizedBox(height: 14),
      Row(children: [_tile(s, 'Payé d\'avance', e.totalXaf), const SizedBox(width: 8), _tile(s, 'Bloqué', e.heldXaf)]),
      const SizedBox(height: 8),
      Row(children: [_tile(s, 'Versé au tuteur', e.releasedXaf), const SizedBox(width: 8), _tile(s, 'Remboursé', e.refundedXaf)]),
      const SizedBox(height: 8),
      Text(
          '${e.discountPercent > 0 ? 'Remise mensuelle ${e.discountPercent} % (${fmtXaf(e.discountXaf)} XAF). ' : ''}'
          'L\'argent est versé au tuteur séance par séance, après chaque séance effectuée et non contestée.'
          '${e.feesRetainedXaf > 0 ? ' Frais Mobile Money retenus sur les remboursements : ${fmtXaf(e.feesRetainedXaf)} XAF.' : ''}',
          style: WinType.labelS(s.onFaint)),
      if (e.cancellationReason != null && e.status != 'active') ...[
        const SizedBox(height: 6),
        Text('Motif : ${e.cancellationReason}', style: WinType.labelS(s.onMuted)),
      ],
      const SizedBox(height: 14),
      if (isTutor && e.status == 'pending_tutor_approval') ...[
        if (e.responseDeadlineAt != null)
          Text('Réponds avant le ${_dt(e.responseDeadlineAt!)}', style: WinType.labelS(WinColors.error)),
        const SizedBox(height: 8),
        WinButton('Accepter l\'engagement',
            block: true,
            loading: _busy,
            onTap: _busy ? null : () => _run(() => TutorEngagementService.instance.accept(e.id), 'Engagement accepté : les séances sont confirmées.')),
        const SizedBox(height: 8),
        WinButton('Refuser',
            block: true,
            variant: WinButtonVariant.outline,
            onTap: _busy
                ? null
                : () async {
                    final reason = await _ask('Refuser l\'engagement ? Le payeur est remboursé intégralement.');
                    if (reason == null) return;
                    await _run(() => TutorEngagementService.instance.decline(e.id, reason: reason.isEmpty ? null : reason),
                        'Engagement refusé : le payeur est remboursé.');
                  }),
      ] else if (e.canCancel)
        WinButton('Annuler l\'engagement',
            block: true,
            variant: WinButtonVariant.danger,
            onTap: _busy
                ? null
                : () async {
                    final reason = await _ask(isTutor
                        ? 'Annuler ? Les séances à venir sont remboursées intégralement au payeur.'
                        : 'Annuler ? Les séances passées restent dues ; chaque séance à venir est remboursée selon la politique du tuteur.');
                    if (reason == null) return;
                    await _run(() => TutorEngagementService.instance.cancel(e.id, reason: reason.isEmpty ? null : reason),
                        'Engagement annulé, remboursements crédités.');
                  }),
      if (isPayer && (e.status == 'active' || e.status == 'pending_tutor_approval')) ...[
        const SizedBox(height: 18),
        Text('Renouvellement', style: WinType.labelM(s.onStrong)),
        const SizedBox(height: 6),
        if (e.renewedToEngagementId != null)
          WinButton('Voir le mois suivant',
              variant: WinButtonVariant.outline,
              onTap: () => Navigator.of(context)
                  .push(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: e.renewedToEngagementId!))))
        else ...[
          Text('Mêmes créneaux à partir du ${_d(e.nextStartDate)}. Manuel par défaut ; rappel 7 jours avant la fin.',
              style: WinType.labelS(s.onFaint)),
          if (e.canSetAutoRenew)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: e.autoRenew,
              onChanged: _busy
                  ? null
                  : (v) => _run(() => TutorEngagementService.instance.setAutoRenew(e.id, v),
                      v ? 'Renouvellement automatique activé.' : 'Renouvellement automatique désactivé.'),
              title: Text('Renouvellement automatique sur le solde', style: WinType.labelM(s.onStrong)),
              subtitle: Text(
                  e.autoRenewAt != null
                      ? 'Tentative le ${_dt(e.autoRenewAt!)}, si les créneaux sont encore libres et le solde suffisant.'
                      : 'Si les créneaux sont encore libres et le solde suffisant.',
                  style: WinType.labelS(s.onFaint)),
            )
          else if (e.paymentMethod != 'wallet')
            Text('Le renouvellement automatique n\'est possible que pour un engagement payé par solde.', style: WinType.labelS(s.onFaint)),
          if (e.autoRenewFailureReason != null)
            WinAlert('Renouvellement automatique impossible : ${e.autoRenewFailureReason}', type: BadgeColor.warn),
          if (e.canRenew) ...[
            const SizedBox(height: 8),
            WinButton('Renouveler (payer avec le solde)',
                block: true,
                onTap: _busy
                    ? null
                    : () => _run(() async {
                          final next = await TutorEngagementService.instance.renew(e.id, paymentMethod: 'wallet');
                          if (!mounted) return;
                          Navigator.of(context)
                              .pushReplacement(MaterialPageRoute(builder: (_) => TutorEngagementScreen(engagementId: next.id)));
                        }, 'Mois suivant réservé et payé par solde.')),
            const SizedBox(height: 8),
            WinButton('Renouveler par Mobile Money', block: true, variant: WinButtonVariant.outline, onTap: _busy ? null : () => _renewByMobileMoney(e)),
          ],
        ],
      ],
      const SizedBox(height: 18),
      Text('Séances (${e.sessionsDone} effectuée(s) sur ${e.sessionsCount})', style: WinType.labelM(s.onStrong)),
      const SizedBox(height: 8),
      for (final x in e.sessions) _session(s, x),
    ]);
  }

  Widget _session(WinScheme s, EngagementSession x) {
    final refund = x.refundAmountXaf != null && x.refundAmountXaf! > 0
        ? ' · ${fmtXaf(x.refundAmountXaf!)} XAF remboursés${x.refundPercent != null ? ' (${x.refundPercent} %)' : ''}'
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
              '${x.disputeDeadline != null ? ' · contestation possible jusqu\'au ${_dt(x.disputeDeadline!)}' : ''}',
              style: WinType.labelS(s.onMuted)),
          if (x.canMarkCompleted || x.canDispute || x.canCancel) ...[
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 6, children: [
              if (x.canMarkCompleted)
                WinButton('Effectuée',
                    small: true,
                    onTap: _busy ? null : () => _run(() => TutorBookingService.instance.complete(x.id), 'Séance marquée effectuée.')),
              if (x.canDispute)
                WinButton('Contester',
                    small: true,
                    variant: WinButtonVariant.outline,
                    onTap: _busy
                        ? null
                        : () async {
                            final reason = await _ask('Pourquoi contestes-tu cette séance ?', hint: 'Explique le problème', required: true);
                            if (reason == null) return;
                            await _run(() => TutorBookingService.instance.dispute(x.id, reason),
                                'Séance contestée : le support va examiner. Les autres séances ne sont pas bloquées.');
                          }),
              if (x.canCancel)
                WinButton('Annuler cette séance',
                    small: true,
                    variant: WinButtonVariant.ghost,
                    onTap: _busy
                        ? null
                        : () async {
                            final reason = await _ask('Annuler seulement la séance du ${_d(x.sessionDate)} ?');
                            if (reason == null) return;
                            await _run(() => TutorBookingService.instance.cancel(x.id, reason: reason.isEmpty ? null : reason), 'Séance annulée.');
                          }),
            ]),
          ],
        ]),
      ),
    );
  }
}
