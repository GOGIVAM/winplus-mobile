import '../l10n/class_levels.dart';
import 'package:flutter/material.dart';
import '../data/models.dart';
import '../services/parent_service.dart';
import '../services/payment_service.dart';
import '../services/subscription_service.dart';
import '../shared/subscription/pricing_screen.dart';
import '../shared/subscription/subscribe_sheet.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../l10n/l10n.dart';

class SubscriptionStatusScreen extends StatefulWidget {
  const SubscriptionStatusScreen({super.key});
  @override
  State<SubscriptionStatusScreen> createState() =>
      _SubscriptionStatusScreenState();
}

class _SubscriptionStatusScreenState extends State<SubscriptionStatusScreen> {
  ApiActiveSubscription? _sub;
  List<ApiChild>? _children;
  List<Map<String, dynamic>> _paymentHistory = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _loadError = false;

  Future<void> _load() async {
    setState(() => _loadError = false);
    try {
      final sub = await SubscriptionService.instance.getCurrent();
      final children = await ParentService.instance.getChildren();
      // L'historique n'est qu'indicatif  s'il échoue, la carte se contente
      // d'un état vide plutôt que de bloquer tout l'écran.
      final history = await PaymentService.instance
          .getHistory()
          .catchError((_) => <Map<String, dynamic>>[]);
      if (mounted)
        setState(() {
          _sub = sub;
          _children = children;
          _paymentHistory = history;
        });
    } catch (_) {
      if (mounted) setState(() => _loadError = true);
    }
  }

  String _fmtDate(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = _sub;
    final children = _children ?? [];

    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(context.l10n.parentSubTitle, style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: () {
              setState(() {
                _sub = null;
                _children = null;
              });
              _load();
            },
          ),
        ],
      ),
      body: _loadError
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
              const SizedBox(height: 12),
              Text(context.l10n.parentSubLoadError,
                  style: WinType.bodyM(s.onMuted)),
              const SizedBox(height: 12),
              WinButton(context.l10n.commonRetry, onTap: () {
                setState(() {
                  _sub = null;
                  _children = null;
                });
                _load();
              }),
            ]))
          : sub == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: s.cardBg,
                        borderRadius: BorderRadius.circular(WinRadii.lg),
                        border: Border(
                          top: BorderSide(color: s.primary, width: 4),
                          left: BorderSide(color: s.cardBorder),
                          right: BorderSide(color: s.cardBorder),
                          bottom: BorderSide(color: s.cardBorder),
                        ),
                        boxShadow: WinShadows.md,
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(sub.planName,
                                  style: WinType.displayS(s.onStrong)),
                              const Spacer(),
                              WinBadge(
                                  !sub.hasPlan
                                      ? context.l10n.commonFree
                                      : sub.isInGrace
                                          ? context.l10n.parentSubPaymentPending
                                          : sub.isTrial
                                              ? context.l10n.parentSubTrial
                                              : context.l10n.commonActive,
                                  color: sub.isInGrace
                                      ? BadgeColor.warn
                                      : BadgeColor.success),
                            ]),
                            const SizedBox(height: 6),
                            if (sub.expiresAt != null)
                              Text(
                                  sub.cancelAtPeriodEnd
                                      ? context.l10n.parentSubCancelledUntil(_fmtDate(sub.expiresAt!))
                                      : context.l10n.parentSubPeriodUntil(_fmtDate(sub.expiresAt!)),
                                  style: WinType.bodyS(s.onMuted)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.refresh, size: 14, color: s.onFaint),
                              const SizedBox(width: 4),
                              Text(
                                  sub.autoRenew
                                      ? context.l10n.parentSubAutoRenewOn
                                      : context.l10n.parentSubManualRenew,
                                  style: WinType.labelM(s.onFaint)),
                            ]),
                          ]),
                    ),
                    const SizedBox(height: 20),
                    // Lot 9.7b : droits réellement appliqués (plus de
                    // téléchargements ni de quiz par jour fictifs).
                    Text(context.l10n.parentSubIncludes,
                        style: WinType.headlineS(s.onStrong)),
                    const SizedBox(height: 12),
                    _UsageRow(
                        icon: Icons.family_restroom_outlined,
                        label: context.l10n.parentSubChildrenFollowed,
                        used: children.length,
                        limit: sub.entitlements.limit('children.max'),
                        unlimited: sub.entitlements.isUnlimited('children.max')),
                    const SizedBox(height: 10),
                    // Partie 8.3 : usage WinAI présenté en relatif au plan
                    // gratuit, jamais en compteur brut de tokens.
                    _AiUsageRow(
                        multiplier: sub.aiUsageMultiplier,
                        label: sub.aiUsageLabel,
                        exhausted: sub.aiQuotaExhausted,
                        limitMessage: sub.aiLimitMessage),
                    if (children.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(context.l10n.parentSubMyChildren, style: WinType.headlineS(s.onStrong)),
                      const SizedBox(height: 12),
                      ...children.map((child) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: WinCard(
                              padding: const EdgeInsets.all(12),
                              child: Row(children: [
                                WinAvatar(child.fullName, size: 40),
                                const SizedBox(width: 12),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text(child.fullName,
                                          style: WinType.titleM(s.onStrong)),
                                      Text(
                                          (child.level != null ? ClassLevels.label(child.level) : null) ??
                                              child.schoolName ??
                                              context.l10n.roleStudent,
                                          style: WinType.labelM(s.onMuted)),
                                    ])),
                                WinBadge(context.l10n.commonActive, color: BadgeColor.teal),
                              ]),
                            ),
                          )),
                    ],
                    const SizedBox(height: 20),
                    Text(context.l10n.parentSubPaymentHistory,
                        style: WinType.headlineS(s.onStrong)),
                    const SizedBox(height: 12),
                    if (_paymentHistory.isEmpty)
                      Text(context.l10n.parentSubNoPayment,
                          style: WinType.bodyM(s.onMuted))
                    else
                      ..._paymentHistory.map((p) {
                        final status =
                            (p['status'] as String? ?? '').toLowerCase();
                        final (label, color) = switch (status) {
                          'complete' || 'completed' || 'succeeded' => (
                              context.l10n.parentSubPaid,
                              BadgeColor.success
                            ),
                          'failed' || 'expired' || 'cancelled' => (
                              context.l10n.parentSubFailed,
                              BadgeColor.error
                            ),
                          _ => (context.l10n.commonPending, BadgeColor.warn),
                        };
                        final amount = ((p['amount'] ?? 0) as num).round();
                        final initiatedAt = DateTime.tryParse(
                            p['initiatedAt'] as String? ?? '');
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: WinCard(
                            padding: const EdgeInsets.all(12),
                            child: Row(children: [
                              Icon(Icons.receipt_long_outlined,
                                  size: 18, color: s.onFaint),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                    Text(sub.planName,
                                        style: WinType.titleM(s.onStrong)),
                                    Text(
                                        initiatedAt != null
                                            ? _fmtDate(initiatedAt)
                                            : '',
                                        style: WinType.labelM(s.onMuted)),
                                  ])),
                              Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('${fmtXaf(amount)} XAF',
                                        style: WinType.titleM(s.onStrong)),
                                    WinBadge(label, color: color),
                                  ]),
                            ]),
                          ),
                        );
                      }),
                    const SizedBox(height: 24),
                    // Lot 9.7b (18.15) : renouvellement d'une période de plus
                    // sans perte de jours, changement de plan (montée au
                    // prorata, descente à l'échéance), résiliation en fin de
                    // période, reprise, renouvellement automatique par le solde.
                    if (sub.pendingPlanName != null) ...[
                      WinAlert(context.l10n.parentSubPendingSwitch(sub.pendingPlanName!), type: BadgeColor.neutral),
                      const SizedBox(height: 8),
                      WinButton(context.l10n.parentSubCancelChange, variant: WinButtonVariant.ghost, block: true, onTap: () async {
                        await SubscriptionService.instance.cancelPending();
                        _load();
                      }),
                      const SizedBox(height: 10),
                    ],
                    if (sub.hasPlan)
                      WinButton(context.l10n.parentSubRenewNow,
                          block: true,
                          icon: Icons.refresh,
                          onTap: () async {
                            await SubscribeSheet.show(context,
                                planId: sub.pricingPlanId, planName: sub.planName, initialPeriod: sub.billingPeriod ?? 'monthly');
                            _load();
                          }),
                    const SizedBox(height: 10),
                    WinButton(sub.hasPlan ? context.l10n.parentSubChangePlan : context.l10n.studentCoachSeePlans,
                        variant: WinButtonVariant.outline,
                        block: true,
                        onTap: () async {
                          await Navigator.push(context, MaterialPageRoute(builder: (_) => const PricingScreen()));
                          _load();
                        }),
                    if (sub.hasPlan) ...[
                      const SizedBox(height: 10),
                      if (!sub.cancelAtPeriodEnd)
                        WinButton(sub.autoRenew ? context.l10n.parentSubDisableAutoRenew : context.l10n.parentSubEnableAutoRenew,
                            variant: WinButtonVariant.ghost,
                            block: true,
                            onTap: () async {
                              await SubscriptionService.instance.setAutoRenew(!sub.autoRenew);
                              _load();
                            }),
                      WinButton(sub.cancelAtPeriodEnd ? context.l10n.parentSubResume : context.l10n.parentSubCancel,
                          variant: WinButtonVariant.ghost,
                          block: true,
                          onTap: () async {
                            if (sub.cancelAtPeriodEnd) {
                              await SubscriptionService.instance.resume();
                            } else {
                              final ok = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(ctx.l10n.parentSubCancelConfirmTitle),
                                  content: Text(sub.expiresAt == null
                                      ? ctx.l10n.parentSubBackToFree
                                      : ctx.l10n.parentSubKeepAccessUntil(_fmtDate(sub.expiresAt!))),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(ctx.l10n.commonCancel)),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(ctx.l10n.parentSubCancel)),
                                  ],
                                ),
                              );
                              if (ok == true) await SubscriptionService.instance.cancel();
                            }
                            _load();
                          }),
                    ],
                  ],
                ),
    );
  }
}

class _AiUsageRow extends StatelessWidget {
  final int multiplier;
  final String label;
  final bool exhausted;

  /// Message serveur (8.10) : quelle limite est atteinte et quand elle se
  /// réinitialise. Jamais de nombre de tokens.
  final String? limitMessage;
  const _AiUsageRow(
      {required this.multiplier,
      required this.label,
      required this.exhausted,
      this.limitMessage});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final text = label.isNotEmpty
        ? label
        : (multiplier <= 1
            ? context.l10n.parentSubAiFree
            : context.l10n.parentSubAiMultiplier(multiplier));
    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.auto_awesome_outlined, size: 16, color: s.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: WinType.titleM(s.onStrong))),
          // 8.10 : plus de plafond mensuel ; limite de session ou de semaine.
          if (exhausted)
            Text(context.l10n.parentSubLimitReached,
                style: WinType.labelM(WinColors.error)
                    .copyWith(fontWeight: FontWeight.w700)),
        ]),
        if (exhausted && (limitMessage?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 6),
          Text(limitMessage!, style: WinType.labelM(s.onMuted)),
        ],
      ]),
    );
  }
}

class _UsageRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int used, limit;
  final bool unlimited;
  const _UsageRow(
      {required this.icon,
      required this.label,
      required this.used,
      required this.limit,
      required this.unlimited});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.all(12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: 16, color: s.primary),
          const SizedBox(width: 8),
          Text(label, style: WinType.titleM(s.onStrong)),
          const Spacer(),
          Text(unlimited ? context.l10n.teacherProfileUnlimited : '$used/$limit',
              style: WinType.labelM(unlimited ? WinColors.success : s.onMuted)
                  .copyWith(fontWeight: FontWeight.w700)),
        ]),
        if (!unlimited) ...[
          const SizedBox(height: 8),
          WinProgressBar(limit == 0 ? 0 : used / limit * 100),
        ],
      ]),
    );
  }
}
