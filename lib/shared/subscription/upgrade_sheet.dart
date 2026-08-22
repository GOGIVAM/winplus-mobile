import 'package:flutter/material.dart';
import '../../theme/win_colors.dart';
import '../../theme/win_theme.dart';
import '../../theme/win_typography.dart';
import '../../widgets/win_widgets.dart';

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
      builder: (_) => UpgradeSheet(
          featureName: featureName, requiredPlan: requiredPlan),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Container(
      decoration: BoxDecoration(color: s.surface, borderRadius: BorderRadius.zero),
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 40,
          height: 4,
          color: s.outline2,
          margin: const EdgeInsets.only(bottom: 24),
        ),
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
              color: WinColors.warnBg,
              shape: BoxShape.circle),
          child: const Icon(Icons.lock_outline,
              size: 36, color: WinColors.warn),
        ),
        const SizedBox(height: 20),
        Text('Fonctionnalité $requiredPlan',
            style: WinType.displayS(s.onStrong),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          '$featureName est disponible à partir du plan $requiredPlan.',
          style: WinType.bodyM(s.onMuted),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text('À partir de 2 500 XAF/mois',
            style: WinType.labelM(s.primary)
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 28),
        WinButton('Voir les plans',
            block: true, onTap: () => Navigator.pop(context)),
        const SizedBox(height: 10),
        WinButton('Plus tard',
            variant: WinButtonVariant.ghost,
            block: true,
            onTap: () => Navigator.pop(context)),
      ]),
    );
  }
}
