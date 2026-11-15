import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/win_motion.dart';
import '../app_state.dart';
import '../data/models.dart';
import '../l10n/gen/app_localizations.dart';
import '../services/auth_service.dart';
import '../services/session_manager.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shell/role_shell.dart';
import '../shared/subscription/subscription_notifier.dart';
import 'forgot_password_screen.dart';
import 'role_screen.dart';

/// Connexion : premier écran de l'application sans session, sur le modèle
/// de la version téléphone du site (plein écran blanc, barre haute avec
/// retour rond et logo, contenu centré).
class LoginScreen extends StatefulWidget {
  /// Message affiché au-dessus du formulaire (session expirée, par exemple).
  final String? notice;
  const LoginScreen({super.key, this.notice});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _obscure = true, _loading = false;
  String? _error;

  Future<void> _login() async {
    final l10n = AppLocalizations.of(context);
    final email = _email.text.trim();
    final pwd = _pwd.text;
    if (email.isEmpty || pwd.isEmpty) {
      setState(() => _error = l10n.fillAllFields);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await AuthService.instance.signIn(email, pwd);
    if (!mounted) return;

    if (result.success) {
      final roleStr = await SessionManager.getUserRole();
      if (!mounted) return;
      final role = winRoleFromString(roleStr);
      final appState = WinAppScope.of(context);
      appState.setRole(role);
      // Lot 10.11 : l'application suit la langue du compte (User.Locale).
      unawaited(appState.applyAccountLocale(result.locale));
      SubscriptionScope.of(context).loadFromApi();
      Navigator.pushAndRemoveUntil(context,
          WinPageRoute(builder: (_) => const RoleShell()), (r) => false);
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
    // Premier écran de l'application sans session : pas de retour possible.
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, box) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: box.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AuthTopBar(showBack: canPop),
                      Expanded(
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 460),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
                              child: _form(context, s, l10n),
                            ),
                          ),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Contenu calqué sur la version téléphone du site (auth-mobile.css) :
  /// en-tête centrée (logo, titre, sous-titre), champs à libellé au-dessus,
  /// action principale pleine largeur, Google en secondaire, bascule vers
  /// l'inscription en bas.
  Widget _form(BuildContext context, WinScheme s, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      Image.asset('assets/winplus-logo.png', width: 96, height: 96),
      const SizedBox(height: 14),
      Text(l10n.loginTitle,
          textAlign: TextAlign.center,
          style: WinType.archivo(
                  size: 27, weight: FontWeight.w600, color: s.onStrong)
              .copyWith(letterSpacing: -0.8, height: 1.15)),
      const SizedBox(height: 8),
      Text(l10n.loginSubtitle,
          textAlign: TextAlign.center,
          style: WinType.manrope(size: 14.5, color: s.onMuted)
              .copyWith(height: 1.5)),
      const SizedBox(height: 22),
      if (widget.notice != null) ...[
        WinAlert(widget.notice!, type: BadgeColor.warn),
        const SizedBox(height: 12),
      ],
      WinTextField(
          label: l10n.email,
          controller: _email,
          keyboardType: TextInputType.emailAddress),
      const SizedBox(height: 12),
      WinTextField(
          label: l10n.password,
          controller: _pwd,
          obscure: _obscure,
          suffixIcon:
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          onSuffixTap: () => setState(() => _obscure = !_obscure)),
      Align(
        alignment: Alignment.centerRight,
        child: InkWell(
          onTap: () => Navigator.push(context,
              WinPageRoute(builder: (_) => const ForgotPasswordScreen())),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: Text(l10n.forgotPassword,
                  style: WinType.manrope(
                      size: 13.5, weight: FontWeight.w600, color: s.onStrong)),
            ),
          ),
        ),
      ),
      if (_error != null) ...[
        WinAlert(_error!, type: BadgeColor.error),
        const SizedBox(height: 8),
      ],
      const SizedBox(height: 4),
      WinButton(l10n.login,
          variant: WinButtonVariant.accent,
          block: true,
          loading: _loading,
          onTap: _login),
      const SizedBox(height: 18),
      _Divider(label: l10n.orContinueWith),
      const SizedBox(height: 18),
      _SocialButton(
          icon: Icons.g_mobiledata,
          label: l10n.continueWithGoogle,
          onTap: () => ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.authGoogleSoon)))),
      const Spacer(),
      const SizedBox(height: 28),
      // Bascule vers l'inscription : on y va par-dessus la connexion, le
      // retour ramène ici.
      InkWell(
        onTap: () => Navigator.push(
            context, WinPageRoute(builder: (_) => const RoleScreen())),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text.rich(
            TextSpan(
              style: WinType.manrope(size: 14, color: s.onMuted),
              children: [
                TextSpan(text: l10n.noAccountYet),
                TextSpan(
                    text: l10n.createAccount,
                    style: WinType.manrope(
                        size: 14, weight: FontWeight.w600, color: s.onStrong)),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ]);
  }
}

/// Barre haute des écrans d'authentification (version téléphone du site) :
/// retour rond à gauche quand il y a un écran derrière, logo « Win+ » à droite.
class _AuthTopBar extends StatelessWidget {
  final bool showBack;
  const _AuthTopBar({required this.showBack});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
      child: Row(children: [
        if (showBack)
          Material(
            color: s.surface,
            shape: CircleBorder(side: BorderSide(color: s.outline)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () => Navigator.maybePop(context),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.chevron_left_rounded,
                    size: 24, color: s.onStrong),
              ),
            ),
          )
        else
          const SizedBox(height: 44),
        const Spacer(),
        Image.asset('assets/winplus-logo.png', width: 26, height: 26),
        const SizedBox(width: 7),
        Text.rich(TextSpan(
          style: WinType.archivo(
                  size: 19, weight: FontWeight.w600, color: s.onStrong)
              .copyWith(letterSpacing: -0.7),
          children: const [
            TextSpan(text: 'Win'),
            TextSpan(
                text: '+',
                style: TextStyle(
                    color: WinColors.teal600, fontWeight: FontWeight.w500)),
          ],
        )),
      ]),
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
      borderRadius: BorderRadius.circular(WinRadii.full),
      child: InkWell(
        borderRadius: BorderRadius.circular(WinRadii.full),
        onTap: onTap,
        child: Container(
          height: 50,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WinRadii.full),
              border: Border.all(color: s.outline2, width: 1.5)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 24, color: s.onStrong),
            const SizedBox(width: 10),
            Text(label,
                style: WinType.manrope(
                    size: 14.5, weight: FontWeight.w600, color: s.onStrong)),
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

/// Bouton retour + logo utilisé par les autres écrans d'auth (formulaire
/// plein cadre sans panneau graphique : vérification, mot de passe...).
class AuthBackBar extends StatelessWidget {
  final bool logo;
  const AuthBackBar({super.key, this.logo = false});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(children: [
        InkWell(
          onTap: () => Navigator.maybePop(context),
          borderRadius: BorderRadius.circular(WinRadii.full),
          child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                  color: s.surface2,
                  borderRadius: BorderRadius.circular(WinRadii.full)),
              child: Icon(Icons.arrow_back, size: 20, color: s.onSurface)),
        ),
        if (logo)
          Expanded(
              child: Center(
                  child: Image.asset('assets/winplus-logo.png', width: 52))),
        if (logo) const SizedBox(width: 40),
      ]),
    );
  }
}
