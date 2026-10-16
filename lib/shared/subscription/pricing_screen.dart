import 'package:flutter/material.dart';
import '../../app_state.dart';
import '../../data/models.dart';
import '../../services/subscription_service.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'subscribe_sheet.dart';
import 'subscription_notifier.dart';

/// Lot 9.7b (étapes 3 et 5) : tarifs servis par l'API (GET /pricing/catalog,
/// grille versionnée, prix TTC par période, droits réellement appliqués).
/// Corrige l'écran précédent (catégories « student » face à « students » en
/// base, réponse lue comme une liste, prix lus dans des champs inexistants :
/// tous les plans s'affichaient gratuits). Plus de remise « -17 % » inventée :
/// les périodes et leurs prix sont ceux saisis par l'administration.
class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

const _periods = [('monthly', 'Mensuel', 'mois'), ('quarterly', 'Trimestriel', 'trimestre'), ('yearly', 'Annuel', 'an')];

class _PricingScreenState extends State<PricingScreen> {
  String _period = 'monthly';
  List<ApiPlanCard>? _plans;
  bool _hasError = false;
  bool _institution = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_plans == null && !_hasError) _load();
  }

  String? _audience(WinRole role) => switch (role) {
        WinRole.student => 'student',
        WinRole.parent => 'parent',
        WinRole.teacher => 'teacher',
        WinRole.institution => null,
      };

  Future<void> _load() async {
    final audience = _audience(WinAppScope.of(context).role);
    if (audience == null) {
      setState(() {
        _institution = true;
        _plans = const [];
      });
      return;
    }
    setState(() {
      _plans = null;
      _hasError = false;
    });
    try {
      final plans = await SubscriptionService.instance.getCatalog(audience);
      if (!mounted) return;
      setState(() => _plans = plans);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _subscribe(ApiPlanCard plan) async {
    if (plan.isFree) return;
    await SubscribeSheet.show(context,
        planId: plan.planId,
        planName: plan.name,
        periods: _periods.map((p) => p.$1).where((p) => plan.prices.containsKey(p)).toList(),
        initialPeriod: _period);
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final sub = SubscriptionScope.of(context);
    final plans = _plans ?? [];
    final available = _periods.where((p) => p.$1 == 'monthly' || plans.any((c) => c.prices.containsKey(p.$1))).toList();
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(icon: Icon(Icons.arrow_back, color: s.onStrong), onPressed: () => Navigator.pop(context)),
        title: Text('Nos plans', style: WinType.headlineS(s.onStrong)),
        actions: [IconButton(icon: Icon(Icons.refresh_outlined, color: s.onStrong), onPressed: _load)],
      ),
      body: _hasError
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.wifi_off_outlined, size: 48, color: s.onFaint),
              const SizedBox(height: 12),
              Text('Erreur de chargement', style: WinType.bodyM(s.onMuted)),
              const SizedBox(height: 12),
              WinButton('Réessayer', onTap: _load),
            ]))
          : _plans == null
              ? const Center(child: CircularProgressIndicator())
              : _institution
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                          'Les établissements passent par une licence (sièges élèves, année scolaire) : gérez-la depuis l\'onglet Licence de votre espace établissement.',
                          style: WinType.bodyM(s.onMuted)))
                  : ListView(padding: const EdgeInsets.fromLTRB(16, 8, 16, 32), children: [
                      Wrap(spacing: 8, children: [
                        for (final p in available) WinChip(p.$2, active: _period == p.$1, onTap: () => setState(() => _period = p.$1)),
                      ]),
                      const SizedBox(height: 20),
                      ...plans.map((plan) {
                        final isCurrent = sub.hasPlan && sub.current?.pricingPlanId == plan.planId;
                        final price = plan.isFree ? 0.0 : plan.priceFor(_period);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _PlanCard(
                            plan: plan,
                            price: price,
                            unit: _periods.firstWhere((p) => p.$1 == _period).$3,
                            isCurrent: isCurrent || (plan.isFree && !sub.hasPlan),
                            onSubscribe: () => _subscribe(plan),
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: s.surface2,
                          borderRadius: BorderRadius.circular(WinRadii.md),
                          border: Border.all(color: s.outline),
                        ),
                        child: Row(children: [
                          Icon(Icons.lock_outline, size: 16, color: s.onFaint),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Prix TTC · MTN Mobile Money, Orange Money ou solde WinPlus · résiliable à tout moment, accès jusqu\'à la fin de la période payée',
                              style: WinType.bodyS(s.onMuted),
                            ),
                          ),
                        ]),
                      ),
                    ]),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ApiPlanCard plan;
  final double? price;
  final String unit;
  final bool isCurrent;
  final VoidCallback onSubscribe;
  const _PlanCard({required this.plan, required this.price, required this.unit, required this.isCurrent, required this.onSubscribe});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: s.cardBg,
        borderRadius: BorderRadius.circular(WinRadii.lg),
        border: Border.all(color: isCurrent ? s.primary : s.cardBorder, width: isCurrent ? 2 : 1),
        boxShadow: WinShadows.sm,
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(children: [
            Expanded(child: Text(plan.name, style: WinType.headlineS(s.onStrong))),
            if (plan.isPopular) const WinBadge('POPULAIRE', color: BadgeColor.teal),
            if (isCurrent) const WinBadge('ACTUEL', color: BadgeColor.success),
          ]),
        ),
        if (plan.description != null && plan.description!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(plan.description!, style: WinType.bodyS(s.onMuted)),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: price == null
              ? Text('Non proposé sur cette période', style: WinType.bodyS(s.onMuted))
              : Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(price == 0 ? 'Gratuit' : fmtXaf(price!.round()), style: WinType.displayM(s.onStrong)),
                  if (price! > 0) ...[
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(' XAF TTC / $unit', style: WinType.labelM(s.onMuted)),
                    ),
                  ],
                ]),
        ),
        Divider(color: s.outline, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(children: plan.features.map((f) => _FeatureRow(f)).toList()),
        ),
        if (!plan.isFree)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: WinButton(
              isCurrent ? 'Renouveler ou changer de période' : 'Choisir ce plan',
              block: true,
              variant: isCurrent ? WinButtonVariant.outline : WinButtonVariant.accent,
              onTap: price == null ? null : onSubscribe,
            ),
          ),
      ]),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final ApiPlanFeature feature;
  const _FeatureRow(this.feature);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final detail = feature.display.isNotEmpty && feature.display != 'Oui' && feature.display != 'Non' ? ' : ${feature.display}' : '';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: feature.included ? 1 : 0.45,
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(feature.included ? Icons.check : Icons.close, size: 16, color: feature.included ? WinColors.success : s.onFaint),
          const SizedBox(width: 10),
          Expanded(child: Text('${feature.label}$detail', style: WinType.bodyS(s.onSurface))),
        ]),
      ),
    );
  }
}
