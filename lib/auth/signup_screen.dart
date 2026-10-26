import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/models.dart';
import '../services/auth_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'verify_code_screen.dart';

/// Formulaire de création de compte (A05). Appelé depuis [RoleScreen] une
/// fois le rôle choisi ; branche réellement AuthService.signUp() puis envoie
/// vers la vérification email  jusqu'ici "Continuer" sur RoleScreen entrait
/// directement dans l'app sans jamais créer de compte.
class SignupScreen extends StatefulWidget {
  final WinRole role;
  const SignupScreen({super.key, required this.role});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _pwdCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePwd = true, _obscureConfirm = true, _loading = false;
  String? _error;

  bool get _has8 => _pwdCtrl.text.length >= 8;
  bool get _hasMaj => _pwdCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNum => _pwdCtrl.text.contains(RegExp(r'[0-9]'));
  // Même règle que le serveur (minuscule et caractère spécial exigés) :
  // sans elles, le serveur refusait un mot de passe validé ici.
  bool get _hasMin => _pwdCtrl.text.contains(RegExp(r'\p{Ll}', unicode: true));
  bool get _hasSpecial =>
      _pwdCtrl.text.contains(RegExp(r'[^\p{L}\p{N}]', unicode: true));
  bool get _matches =>
      _pwdCtrl.text == _confirmCtrl.text && _pwdCtrl.text.isNotEmpty;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _pwdCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();
    if (_firstNameCtrl.text.trim().isEmpty ||
        _lastNameCtrl.text.trim().isEmpty ||
        email.isEmpty) {
      setState(() => _error = context.l10n.authFillRequired);
      return;
    }
    if (!_has8 || !_hasMaj || !_hasMin || !_hasNum || !_hasSpecial || !_matches) {
      setState(() => _error = context.l10n.authPwdCriteria);
      return;
    }
    // Téléphone facultatif, mais complet : 9 chiffres au Cameroun, ou un
    // numéro international commençant par « + ». Un numéro tronqué rendait
    // le paiement Mobile Money impossible.
    final rawPhone = _phoneCtrl.text.trim();
    final phoneDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final phone = rawPhone.isEmpty
        ? null
        : rawPhone.startsWith('+') || rawPhone.startsWith('00')
            ? '+${phoneDigits.startsWith('00') ? phoneDigits.substring(2) : phoneDigits}'
            : phoneDigits;
    if (phone != null &&
        !(phone.startsWith('+') ? phoneDigits.length >= 10 : phoneDigits.length == 9)) {
      setState(() => _error = context.l10n.authPhoneInvalid);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.instance.signUp(
      email: email,
      password: _pwdCtrl.text,
      firstName: _firstNameCtrl.text.trim(),
      lastName: _lastNameCtrl.text.trim(),
      phone: phone,
      role: widget.role,
    );
    if (!mounted) return;
    if (result.success) {
      Navigator.pushReplacement(
        context,
        WinPageRoute(builder: (_) => VerifyCodeScreen(email: email)),
      );
    } else {
      setState(() {
        _loading = false;
        _error = result.message ?? context.l10n.authSignupFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    final topHeight = 128 + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: s.bg,
      body: Column(children: [
        // ── Panneau graphique compact (formulaire plus long) ─────────
        SizedBox(
          height: topHeight,
          child: Stack(children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [s.heroFrom, s.heroTo],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Image.asset('assets/winplus-logo.png', width: 56),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: WinCircleIconButton(
                  icon: Icons.arrow_back,
                  iconColor: WinColors.ink800,
                  onTap: () => Navigator.maybePop(context),
                ),
              ),
            ),
          ]),
        ),

        // ── Feuille blanche qui remonte par-dessus ────────────────────
        Expanded(
          child: Transform.translate(
            offset: const Offset(0, -20),
            child: Container(
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(WinRadii.xl)),
              ),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                children: [
                  Text(l10n.createAccount,
                      style: WinType.archivo(
                          size: 22,
                          weight: FontWeight.w700,
                          color: s.onStrong)),
                  const SizedBox(height: 4),
                  Text(l10n.authSignupIntro,
                      style: WinType.bodyS(s.onMuted)),
                  const SizedBox(height: 24),
                  Row(children: [
                    Expanded(
                        child: WinTextField(
                            label: l10n.authFirstName,
                            icon: Icons.person_outline,
                            controller: _firstNameCtrl)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: WinTextField(
                            label: l10n.authLastName, controller: _lastNameCtrl)),
                  ]),
                  const SizedBox(height: 14),
                  WinTextField(
                      label: l10n.authEmailAddress,
                      hint: l10n.authEmailHint,
                      icon: Icons.mail_outline,
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  WinTextField(
                      label: l10n.authPhoneOptional,
                      hint: '+237 6XX XXX XXX',
                      icon: Icons.phone_outlined,
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  WinTextField(
                      label: l10n.password,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscurePwd,
                      controller: _pwdCtrl,
                      suffixIcon: _obscurePwd
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixTap: () =>
                          setState(() => _obscurePwd = !_obscurePwd),
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 14),
                  WinTextField(
                      label: l10n.authConfirmPassword,
                      hint: '••••••••',
                      icon: Icons.lock_outline,
                      obscure: _obscureConfirm,
                      controller: _confirmCtrl,
                      suffixIcon: _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixTap: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                      onChanged: (_) => setState(() {})),
                  const SizedBox(height: 16),
                  _Constraint(l10n.authRule8, _has8),
                  const SizedBox(height: 6),
                  _Constraint(l10n.authRuleUpper, _hasMaj),
                  const SizedBox(height: 6),
                  _Constraint(l10n.authRuleLower, _hasMin),
                  const SizedBox(height: 6),
                  _Constraint(l10n.authRuleDigit, _hasNum),
                  const SizedBox(height: 6),
                  _Constraint(l10n.authRuleSpecial, _hasSpecial),
                  const SizedBox(height: 6),
                  _Constraint(l10n.authRuleMatch, _matches),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    WinAlert(_error!, type: BadgeColor.error),
                  ],
                  const SizedBox(height: 24),
                  WinButton(l10n.authCreateMyAccount,
                      variant: WinButtonVariant.accent,
                      block: true,
                      loading: _loading,
                      onTap: _submit),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Center(
                      child: Text.rich(TextSpan(
                        style: WinType.bodyS(s.onMuted),
                        children: [
                          TextSpan(text: l10n.authAlreadyAccount),
                          TextSpan(
                              text: l10n.login,
                              style: WinType.bodyS(s.primary)
                                  .copyWith(fontWeight: FontWeight.w700)),
                        ],
                      )),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _Constraint extends StatelessWidget {
  final String label;
  final bool ok;
  const _Constraint(this.label, this.ok);
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(children: [
      Icon(ok ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16, color: ok ? s.primary : s.onFaint),
      const SizedBox(width: 8),
      Text(label, style: WinType.bodyS(ok ? s.primary : s.onMuted)),
    ]);
  }
}
