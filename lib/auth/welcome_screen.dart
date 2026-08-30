import 'package:flutter/material.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'login_screen.dart';
import 'role_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(children: [
            Image.asset('assets/winplus-logo.png', width: 96),
            const SizedBox(height: 8),
            Text('WinPlus',
                style: WinType.archivo(
                    size: 28, weight: FontWeight.w700, color: s.onStrong)),
            Text('Ta réussite, notre mission',
                style: WinType.bodyS(s.onMuted)),
            Expanded(
              child: Center(
                child: Image.asset(
                  'assets/Login.gif',
                  width: 280,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            WinButton(
              'Créer un compte',
              variant: WinButtonVariant.accent,
              block: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoleScreen())),
            ),
            const SizedBox(height: 12),
            WinButton(
              'Se connecter',
              variant: WinButtonVariant.outline,
              block: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen())),
            ),
          ]),
        ),
      ),
    );
  }
}
