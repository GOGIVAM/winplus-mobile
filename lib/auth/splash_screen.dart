import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../services/session_manager.dart';
import '../shell/role_shell.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import 'periodic_confirm_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 800))
    ..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2300), _route);
  }

  WinRole _roleFromString(String? role) => switch (role) {
        'teacher'     => WinRole.teacher,
        'parent'      => WinRole.parent,
        'institution' => WinRole.institution,
        _             => WinRole.student,
      };

  Future<void> _route() async {
    if (!mounted) return;

    final loggedIn  = await SessionManager.isLoggedIn();
    if (!mounted) return;

    if (!loggedIn) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      );
      return;
    }

    final checkDue = await SessionManager.isPeriodicCheckDue();
    if (!mounted) return;

    if (checkDue) {
      final email = await SessionManager.getUserEmail() ?? '';
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => PeriodicConfirmScreen(email: email)),
      );
      return;
    }

    // Déjà connecté, vérification périodique non requise → RoleShell direct
    final roleStr = await SessionManager.getUserRole();
    if (!mounted) return;
    WinAppScope.of(context).setRole(_roleFromString(roleStr));
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RoleShell()),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WinColors.ink900,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ScaleTransition(
            scale: CurvedAnimation(parent: _c, curve: Curves.elasticOut),
            child: Image.asset('assets/winplus-logo.png', width: 120),
          ),
          const SizedBox(height: 18),
          Text('WinPlus',
              style: WinType.archivo(
                  size: 30,
                  weight: FontWeight.w700,
                  color: WinColors.cream50)),
          const SizedBox(height: 4),
          Text('Ta réussite, notre mission',
              style: WinType.bodyS(WinColors.ink300)),
        ]),
      ),
    );
  }
}
