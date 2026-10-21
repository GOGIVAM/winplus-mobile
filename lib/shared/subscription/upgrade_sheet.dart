import 'package:flutter/material.dart';
import '../../theme/win_motion.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';
import 'pricing_screen.dart';
import '../../app_state.dart';
import '../../data/models.dart';
import '../../l10n/l10n.dart';
import '../../services/subscription_service.dart';

Future<double?> _minMonthlyPrice(BuildContext context) async {
  final audience = switch (WinAppScope.of(context).role) {
    WinRole.student => 'student',
    WinRole.parent => 'parent',
    WinRole.teacher => 'teacher',
    WinRole.institution => null,
  };
  if (audience == null) return null;
  try {
    final plans = await SubscriptionService.instance.getCatalog(audience);
    final prices = plans.where((p) => !p.isFree).map((p) => p.priceFor('monthly')).whereType<double>().where((p) => p > 0).toList()
      ..sort();
    return prices.isEmpty ? null : prices.first;
  } catch (_) {
    return null;
  }
}

class UpgradeSheet extends StatelessWidget {
  final String featureName;
  final String requiredPlan;
  const UpgradeSheet(
      {super.key, required this.featureName, required this.requiredPlan});

  static void show(BuildContext context,
      {required String featureName, required String requiredPlan}) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) =>
          UpgradeSheet(featureName: featureName, requiredPlan: requiredPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(
          color: s.surface,
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(WinRadii.xl))),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
              color: s.outline2,
              borderRadius: BorderRadius.circular(WinRadii.full)),
          margin: const EdgeInsets.only(bottom: 24),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: const BoxDecoration(
              color: WinColors.warnBg, shape: BoxShape.circle),
          child:
              const Icon(Icons.lock_outline, size: 36, color: WinColors.warn),
        ),
        const SizedBox(height: 20),
        Text(context.l10n.subFeatureOfPlan(requiredPlan),
            style: WinType.displayS(s.onStrong), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          context.l10n.subFeatureAvailableFrom(featureName, requiredPlan),
          style: WinType.bodyM(s.onMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Lot 9.7b (étude section 3) : prix minimal lu dans la grille
        // publiée du public du compte, plus de « 2 500 XAF » écrit en dur.
        FutureBuilder<double?>(
          future: _minMonthlyPrice(context),
          builder: (_, snap) => snap.data == null
              ? const SizedBox.shrink()
              : Text(context.l10n.subFromPerMonth(fmtXaf(snap.data!.round())),
                  style: WinType.labelM(s.primary).copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 28),
        WinButton(context.l10n.subSeePlans, block: true, onTap: () {
          Navigator.pop(context);
          Navigator.push(
              context, WinPageRoute(builder: (_) => const PricingScreen()));
        }),
        const SizedBox(height: 10),
        WinButton(context.l10n.subLater,
            variant: WinButtonVariant.ghost,
            block: true,
            onTap: () => Navigator.pop(context)),
      ]),
    );
  }
}
