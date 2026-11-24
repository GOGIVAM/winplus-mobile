import 'package:flutter/material.dart';

import '../app_state.dart';
import '../data/models.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/session_manager.dart';
import '../shell/role_shell.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'login_screen.dart';
import '../widgets/win_logo.dart';

/// Application verrouillée : l'empreinte a été annulée ou refusée au
/// lancement. On peut réessayer ou se déconnecter (puis se reconnecter avec
/// son mot de passe).
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({super.key});

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  bool _busy = false;

  Future<void> _unlock() async {
    setState(() => _busy = true);
    final ok = await BiometricService.instance.authenticate();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) return;
    final role = await SessionManager.getUserRole();
    if (!mounted) return;
    WinAppScope.of(context).setRole(winRoleFromString(role));
    Navigator.of(context).pushAndRemoveUntil(
        WinPageRoute(builder: (_) => const RoleShell()), (r) => false);
  }

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        WinPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: WinColors.teal900,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const WinLogo(size: 104),
              const SizedBox(height: 24),
              const Icon(Icons.fingerprint, size: 56, color: WinColors.cream50),
              const SizedBox(height: 16),
              Text(l.biometricLockedTitle,
                  textAlign: TextAlign.center,
                  style: WinType.archivo(
                      size: 22, weight: FontWeight.w700, color: WinColors.cream50)),
              const SizedBox(height: 8),
              Text(l.biometricLockedHint,
                  textAlign: TextAlign.center,
                  style: WinType.bodyM(WinColors.teal200)),
              const SizedBox(height: 28),
              WinButton(l.biometricUnlock,
                  block: true,
                  icon: Icons.fingerprint,
                  loading: _busy,
                  onTap: _busy ? null : _unlock),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _busy ? null : _logout,
                child: Text(l.authLogMeOut,
                    style: WinType.labelM(WinColors.cream50)),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
