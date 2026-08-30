import 'package:flutter/material.dart';
import '../data/models.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shell/role_shell.dart';

class OnboardingSuccessScreen extends StatefulWidget {
  final String firstName;
  final WinRole role;
  const OnboardingSuccessScreen({
    super.key,
    this.firstName = 'toi',
    this.role = WinRole.student,
  });
  @override
  State<OnboardingSuccessScreen> createState() => _OnboardingSuccessScreenState();
}

class _OnboardingSuccessScreenState extends State<OnboardingSuccessScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  static const _features = <WinRole, List<String>>{
    WinRole.student: [
      'Accédez à 10 000+ ressources',
      'Quiz IA personnalisés',
      'Certifications reconnues',
    ],
    WinRole.parent: [
      'Suivez vos enfants en temps réel',
      'Alertes WinAI',
      'Achetez des contenus pour eux',
    ],
    WinRole.teacher: [
      'Publiez et monétisez vos contenus',
      'Gérez vos classes',
      '80% de commission',
    ],
    WinRole.institution: [
      'Dashboard centralisé',
      'Licences multi-élèves',
      'Analytics temps réel',
    ],
  };

  static const _subtitles = <WinRole, String>{
    WinRole.student: 'Votre profil est prêt. Commencez à réviser !',
    WinRole.parent: 'Vous pouvez maintenant suivre vos enfants.',
    WinRole.teacher: 'Publiez votre premier contenu !',
    WinRole.institution: 'Gérez votre établissement depuis votre tableau de bord.',
  };

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final features = _features[widget.role] ?? _features[WinRole.student]!;
    final subtitle = _subtitles[widget.role] ?? _subtitles[WinRole.student]!;

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const Spacer(),
            ScaleTransition(
              scale: _scale,
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  color: WinColors.goldBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.school_outlined, size: 54, color: WinColors.gold),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Bienvenue sur WinPlus, ${widget.firstName} !',
              style: WinType.displayS(s.onStrong),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(subtitle, style: WinType.bodyM(s.onMuted), textAlign: TextAlign.center),
            const SizedBox(height: 32),
            Column(children: features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: WinColors.successBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, size: 16, color: WinColors.success),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(f, style: WinType.bodyM(s.onStrong))),
              ]),
            )).toList()),
            const Spacer(),
            WinButton(
              'Commencer',
              block: true,
              onTap: () => Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const RoleShell()),
                (r) => false,
              ),
            ),
            const SizedBox(height: 16),
          ]),
        ),
      ),
    );
  }
}
