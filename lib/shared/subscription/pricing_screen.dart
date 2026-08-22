import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../data/models.dart';
import '../../services/subscription_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _yearly = false;
  List<ApiPlan>? _plans;
  ApiActiveSubscription? _current;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _roleCategory(WinRole role) => switch (role) {
        WinRole.student => 'student',
        WinRole.parent => 'parent',
        WinRole.teacher => 'teacher',
        WinRole.institution => 'institution',
      };

  Future<void> _load() async {
    setState(() { _plans = null; _hasError = false; });
    try {
      final role = WinAppScope.of(context).role;
      final results = await Future.wait([
        SubscriptionService.instance.getPlans(_roleCategory(role)),
        SubscriptionService.instance.getCurrent(),
      ]);
      if (!mounted) return;
      setState(() {
        _plans = results[0] as List<ApiPlan>;
        _current = results[1] as ApiActiveSubscription?;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _subscribe(ApiPlan plan) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await SubscriptionService.instance.subscribe(plan.id, yearly: _yearly);
    if (!mounted) return;
    if (ok) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Abonnement activé avec succès !')));
      _load();
    } else {
      messenger.showSnackBar(
          const SnackBar(content: Text('Échec du paiement. Réessayez.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Nos plans', style: WinType.headlineS(s.onStrong)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: s.onStrong),
            onPressed: _load,
          ),
        ],
      ),
      body: _hasError
          ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
              const SizedBox(height: 12),
              Text('Erreur de chargement', style: WinType.bodyM(s.onMuted)),
              const SizedBox(height: 12),
              WinButton('Réessayer', onTap: _load),
            ]))
          : _plans == null
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  children: [
                    Row(children: [
                      WinChip('Mensuel',
                          active: !_yearly,
                          onTap: () => setState(() => _yearly = false)),
                      const SizedBox(width: 8),
                      WinChip('Annuel',
                          active: _yearly,
                          onTap: () => setState(() => _yearly = true)),
                      if (_yearly) ...[
                        const SizedBox(width: 8),
                        const WinBadge('-17%', color: BadgeColor.gold),
                      ],
                    ]),
                    const SizedBox(height: 20),
                    ..._plans!.map((plan) {
                      final isCurrent = plan.tier == (_current?.tier ?? '');
                      final price =
                          (_yearly ? plan.priceYearly : plan.priceMonthly).round();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _PlanCard(
                          plan: plan,
                          price: price,
                          yearly: _yearly,
                          isCurrent: isCurrent,
                          onSubscribe: () => _subscribe(plan),
                        ),
                      );
                    }),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: s.surface2,
                        borderRadius: BorderRadius.zero,
                        border: Border.all(color: s.outline),
                      ),
                      child: Row(children: [
                        Icon(Icons.lock_outline, size: 16, color: s.onFaint),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Paiement sécurisé via MTN Mobile Money & Orange Money',
                            style: WinType.bodyS(s.onMuted),
                          ),
                        ),
                      ]),
                    ),
                  ],
                ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ApiPlan plan;
  final int price;
  final bool yearly, isCurrent;
  final VoidCallback onSubscribe;
  const _PlanCard({
    required this.plan,
    required this.price,
    required this.yearly,
    required this.isCurrent,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: s.cardBg,
        borderRadius: BorderRadius.zero,
        border: Border.all(
          color: isCurrent ? s.primary : s.cardBorder,
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: WinShadows.sm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(
                child: Text(plan.name, style: WinType.headlineS(s.onStrong))),
            if (plan.isPopular)
              const WinBadge('POPULAIRE', color: BadgeColor.teal),
            if (isCurrent)
              const WinBadge('ACTUEL', color: BadgeColor.success),
          ]),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(
              price == 0 ? 'Gratuit' : fmtXaf(price),
              style: WinType.displayM(s.onStrong),
            ),
            if (price > 0) ...[
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  yearly ? ' XAF/an' : ' XAF/mois',
                  style: WinType.labelM(s.onMuted),
                ),
              ),
            ],
          ]),
        ),
        Divider(color: s.outline, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: plan.features.map((f) => _FeatureRow(f)).toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: WinButton(
            isCurrent ? 'Plan actuel' : 'Choisir ce plan',
            block: true,
            variant: isCurrent
                ? WinButtonVariant.outline
                : WinButtonVariant.accent,
            onTap: isCurrent ? null : onSubscribe,
          ),
        ),
      ]),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String feature;
  const _FeatureRow(this.feature);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check, size: 16, color: WinColors.success),
        const SizedBox(width: 10),
        Expanded(
          child: Text(feature, style: WinType.bodyS(s.onSurface)),
        ),
      ]),
    );
  }
}
