import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../theme/win_colors.dart';
import '../theme/win_typography.dart';
import 'periodic_confirm_screen.dart';
import 'welcome_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2300), () async {
      if (!mounted) return;
      final loggedIn = await SessionManager.isLoggedIn();
      if (!mounted) return;
      final checkDue = loggedIn && await SessionManager.isPeriodicCheckDue();
      if (!mounted) return;
      final email = checkDue ? (await SessionManager.getUserEmail() ?? '') : '';
      if (!mounted) return;
      final nav = Navigator.of(context);
      if (checkDue) {
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => PeriodicConfirmScreen(email: email)),
        );
      } else {
        nav.pushReplacement(
          MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() { _c.dispose(); super.dispose(); }

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
          Text('WinPlus', style: WinType.archivo(size: 30, weight: FontWeight.w700, color: WinColors.cream50)),
          const SizedBox(height: 4),
          Text('Ta réussite, notre mission', style: WinType.bodyS(WinColors.ink300)),
        ]),
      ),
    );
  }
}
