import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class OnboardingSuccessScreen extends StatelessWidget {
  const OnboardingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: WinColors.goldBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.school_outlined,
                          size: 50, color: WinColors.gold),
                    ),
                    const SizedBox(height: 24),
                    Text('Bienvenue sur WinPlus !',
                        style: WinType.displayS(s.onStrong),
                        textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    Text(
                      'Ton profil est prêt. Découvre le catalogue, commence un quiz ou planifie ton prochain examen.',
                      style: WinType.bodyM(s.onMuted),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    _FeatureRow(
                      Icons.layers_outlined,
                      s.primary,
                      'Catalogue complet',
                      'BAC, concours, BEPC et plus',
                    ),
                    const SizedBox(height: 8),
                    _FeatureRow(
                      Icons.quiz_outlined,
                      WinColors.teal500,
                      'Quiz interactifs',
                      'Teste-toi et suis ta progression',
                    ),
                    const SizedBox(height: 8),
                    _FeatureRow(
                      Icons.smart_toy_outlined,
                      WinColors.gold,
                      'WinAI',
                      "Ton assistant d'études personnel",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              WinButton(
                'Commencer →',
                block: true,
                onTap: () => Navigator.of(context).popUntil((r) => r.isFirst),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String sub;
  const _FeatureRow(this.icon, this.color, this.title, this.sub);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(children: [
      Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: color),
      ),
      const SizedBox(width: 12),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: WinType.titleM(s.onStrong)),
          Text(sub, style: WinType.labelM(s.onMuted)),
        ],
      ),
    ]);
  }
}
