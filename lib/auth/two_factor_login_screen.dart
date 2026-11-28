import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_screen.dart';
import '../widgets/win_widgets.dart';
import 'google_login.dart';

/// Second facteur de la connexion (double authentification active sur le
/// compte) : après le mot de passe ou Google, le serveur renvoie un jeton de
/// 5 minutes à la place de la session. On demande le code de l'application
/// d'authentification, ou un code de secours, puis on ouvre l'espace du compte.
///
/// Jeton expiré ou trop d'essais : retour à l'écran de connexion avec le
/// message du serveur (il faut recommencer depuis le mot de passe).
class TwoFactorLoginScreen extends StatefulWidget {
  final String twoFactorToken;
  const TwoFactorLoginScreen({super.key, required this.twoFactorToken});

  @override
  State<TwoFactorLoginScreen> createState() => _TwoFactorLoginScreenState();
}

class _TwoFactorLoginScreenState extends State<TwoFactorLoginScreen> {
  final _code = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _error = context.l10n.authTwoFactorInvalid);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await AuthService.instance.verifyTwoFactorLogin(widget.twoFactorToken, code);
    if (!mounted) return;
    if (res.success) {
      await GoogleLogin.openAccountSpace(context, res.locale);
      return;
    }
    if (res.twoFactorRestart) {
      // L'écran de connexion affiche le message ; on y retourne.
      Navigator.pop(context, res.message);
      return;
    }
    final l = context.l10n;
    setState(() {
      _loading = false;
      _error = [
        res.message ?? l.authTwoFactorInvalid,
        if (res.attemptsLeft != null && res.attemptsLeft! > 0) l.authTwoFactorAttemptsLeft(res.attemptsLeft!),
      ].join(' ');
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return WinAuthFrame(children: [
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        WinAuthHeading(l.authTwoFactorTitle, subtitle: l.authTwoFactorSubtitle),
        const SizedBox(height: 22),
        WinTextField(
          label: l.authTwoFactorCode,
          controller: _code,
          keyboardType: TextInputType.visiblePassword,
        ),
        const SizedBox(height: 8),
        Text(l.authTwoFactorBackupHint, style: WinType.bodyS(s.onMuted)),
        if (_error != null) ...[
          const SizedBox(height: 12),
          WinAlert(_error!, type: BadgeColor.error),
        ],
        const SizedBox(height: 16),
        WinButton(l.authTwoFactorVerify,
            variant: WinButtonVariant.accent, block: true, loading: _loading, onTap: _verify),
      ]),
    ]);
  }
}
