import 'dart:async';
import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shell/role_shell.dart';
import '../shared/subscription/subscription_notifier.dart';
import 'forgot_password_screen.dart';
import 'role_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pwd   = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  WinRole _roleFromString(String? role) => switch (role) {
        'teacher'     => WinRole.teacher,
        'parent'      => WinRole.parent,
        'institution' => WinRole.institution,
        _             => WinRole.student,
      };

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final pwd   = _pwd.text;
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = l10n.fillAllFields);
      return;
    }
    setState(() { _loading = true; _error = null; });

    final result = await AuthService.instance.signIn(email, pwd);
    if (!mounted) return;

    if (result.success) {
      final roleStr = await SessionManager.getUserRole();
      if (!mounted) return;
      final role = _roleFromString(roleStr);
      final appState = WinAppScope.of(context);
      appState.setRole(role);
      // Applique la langue enregistrée sur le compte : seule façon de la
      // retrouver sur un nouvel appareil (le SharedPreferences local ne le
      // sait pas encore).
      if (result.locale != null) {
        unawaited(appState.setLocale(result.locale!));
      }
      SubscriptionScope.of(context).loadFromApi();
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const RoleShell()),
          (r) => false);
    } else {
      setState(() {
        _loading = false;
        _error = result.message ?? l10n.wrongCredentials;
      });
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _pwd.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Column(children: [
          const _BackBar(logo: true),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
              children: [
                // ── Animation ──────────────────────────────────────
                SizedBox(
                  height: 180,
                  child: Center(
                    child: Image.asset(
                      'assets/Login.gif',
                      height: 160,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                // ── Titre ──────────────────────────────────────────
                Center(
                  child: Text(l10n.loginTitle,
                      style: WinType.archivo(
                          size: 22,
                          weight: FontWeight.w700,
                          color: s.onStrong)),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(l10n.loginSubtitle,
                      style: WinType.bodyS(s.onMuted)),
                ),
                const SizedBox(height: 24),

                // ── Formulaire ─────────────────────────────────────
                WinTextField(
                    label: l10n.email,
                    icon: Icons.mail_outline,
                    controller: _email),
                const SizedBox(height: 14),
                WinTextField(
                    label: l10n.password,
                    icon: Icons.lock_outline,
                    controller: _pwd,
                    obscure: _obscure,
                    suffixIcon: _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    onSuffixTap: () => setState(() => _obscure = !_obscure)),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen())),
                    child: Text(l10n.forgotPassword,
                        style: WinType.labelM(s.primaryStrong)),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  WinAlert(_error!, type: BadgeColor.error),
                ],
                const SizedBox(height: 16),
                WinButton(l10n.login,
                    variant: WinButtonVariant.accent,
                    block: true,
                    loading: _loading,
                    onTap: _login),
                const SizedBox(height: 24),
                _Divider(label: l10n.orContinueWith),
                const SizedBox(height: 16),
                _SocialButton(
                    icon: Icons.g_mobiledata,
                    label: l10n.continueWithGoogle,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Google OAuth bientôt disponible !')));
                    }),
                const SizedBox(height: 10),
                _SocialButton(
                    icon: Icons.phone_outlined,
                    label: l10n.continueWithPhone,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Connexion par téléphone bientôt disponible !')));
                    }),
                const SizedBox(height: 24),
                GestureDetector(
                  onTap: () => Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const RoleScreen())),
                  child: Center(
                    child: Text.rich(TextSpan(
                      style: WinType.bodyS(s.onMuted),
                      children: [
                        TextSpan(text: l10n.noAccountYet),
                        TextSpan(
                            text: l10n.createAccount,
                            style: WinType.bodyS(s.primary)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ],
                    )),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Widgets partagés ─────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SocialButton(
      {required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Material(
      color: s.surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: s.outline2, width: 1.5)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 24, color: s.onStrong),
            const SizedBox(width: 10),
            Text(label,
                style: WinType.manrope(
                    size: 14.5,
                    weight: FontWeight.w600,
                    color: s.onStrong)),
          ]),
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(children: [
      Expanded(child: Container(height: 1, color: s.outline)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: WinType.labelM(s.onFaint))),
      Expanded(child: Container(height: 1, color: s.outline)),
    ]);
  }
}

class _BackBar extends StatelessWidget {
  final bool logo;
  const _BackBar({this.logo = false});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: s.surface2,
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(Icons.arrow_back, size: 20, color: s.onSurface)),
        ),
        if (logo)
          Expanded(
              child: Center(
                  child:
                      Image.asset('assets/winplus-logo.png', width: 52))),
        if (logo) const SizedBox(width: 40),
      ]),
    );
  }
}

// Réexport pour les autres écrans d'auth.
class AuthBackBar extends StatelessWidget {
  final bool logo;
  const AuthBackBar({super.key, this.logo = false});
  @override
  Widget build(BuildContext context) => _BackBar(logo: logo);
}
