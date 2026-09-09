import 'package:flutter/material.dart';
import '../app_state.dart';
import '../l10n/gen/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          child: Column(children: [
            Align(
              alignment: Alignment.topRight,
              child: _LanguageToggle(),
            ),
            Image.asset('assets/winplus-logo.png', width: 96),
            const SizedBox(height: 8),
            Text('WinPlus',
                style: WinType.archivo(
                    size: 28, weight: FontWeight.w700, color: s.onStrong)),
            Text(l10n.welcomeTagline, style: WinType.bodyS(s.onMuted)),
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
              l10n.createAccount,
              variant: WinButtonVariant.accent,
              block: true,
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RoleScreen())),
            ),
            const SizedBox(height: 12),
            WinButton(
              l10n.login,
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

/// Bascule FR/EN manuelle (US onboarding). Persistée par WinAppState.setLocale
/// (SharedPreferences + synchro profil si connecté).
class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final state = WinAppScope.of(context);
    final current = state.locale.languageCode;
    Widget seg(String code) {
      final active = current == code;
      return GestureDetector(
        onTap: () => state.setLocale(code),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: active ? s.onStrong : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(code.toUpperCase(),
              style: WinType.manrope(
                  size: 12,
                  weight: FontWeight.w700,
                  color: active ? s.bg : s.onMuted)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(color: s.outline, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        seg('fr'),
        seg('en'),
      ]),
    );
  }
}
