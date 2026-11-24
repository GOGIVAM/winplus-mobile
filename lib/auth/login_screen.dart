import '../widgets/win_screen.dart';
export '../widgets/win_screen.dart' show AuthBackBar;
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
import 'google_login.dart';
import 'role_screen.dart';
import '../widgets/win_logo.dart';

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

    return WinAuthFrame(showBack: canPop, children: [_form(context, s, l10n)]);
  }

  /// Contenu calqué sur la version téléphone du site (auth-mobile.css) :
  /// en-tête centrée (logo, titre, sous-titre), champs à libellé au-dessus,
  /// action principale pleine largeur, Google en secondaire, bascule vers
  /// l'inscription en bas.
  Widget _form(BuildContext context, WinScheme s, AppLocalizations l10n) {
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 8),
      const Center(child: WinLogo(size: 96)),
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
          suffixIcon: _obscure
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
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
          label: l10n.continueWithGoogle,
          onTap: () => GoogleLogin.start(context)),
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

// ── Widgets partagés ─────────────────────────────────────────────────────────

/// Bouton « Continuer avec Google » : logo officiel en couleurs (le même que
/// le site), conformément aux règles d'usage de la marque Google.
class _SocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SocialButton({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Material(
      color: s.surface,
      borderRadius: BorderRadius.circular(WinRadii.sm),
      child: InkWell(
        borderRadius: BorderRadius.circular(WinRadii.sm),
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(WinRadii.sm),
              border: Border.all(color: s.outline2, width: 1)),
          alignment: Alignment.center,
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Image.asset('assets/google-g.png',
                width: 20, height: 20, excludeFromSemantics: true),
            const SizedBox(width: 12),
            Flexible(
                child: Text(label,
                    textAlign: TextAlign.center,
                    style: WinType.manrope(
                        size: 14.5,
                        weight: FontWeight.w600,
                        color: s.onStrong))),
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
    // Deux traits égaux qui occupent toute la largeur, texte au centre
    // (comme .or-divider du site).
    // Sur petit écran ou avec un grand texte système, le libellé passe à la
    // ligne au-delà de 60 % de la largeur au lieu de déborder.
    return LayoutBuilder(
        builder: (context, box) => Row(children: [
              Expanded(child: Container(height: 1, color: s.outline)),
              ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: box.maxWidth * 0.6),
                  child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: WinType.labelM(s.onFaint)))),
              Expanded(child: Container(height: 1, color: s.outline)),
            ]));
  }
}
