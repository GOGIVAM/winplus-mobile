import '../widgets/win_screen.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  String? _error;

  Future<void> _send() async {
    final email = _ctrl.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AuthService.instance.forgotPassword(email);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _loading = false;
        _sent = true;
      });
    } else {
      setState(() {
        _loading = false;
        _error = result.message ?? context.l10n.authErrNetwork;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    return WinAuthFrame(children: [
      WinAuthHeading(l10n.authForgotTitle,
          subtitle: l10n.authForgotIntro,
          icon: _sent
              ? PhosphorIconsRegular.envelopeOpen
              : PhosphorIconsRegular.lockKeyOpen),
      if (_sent) ...[
        WinAlert(
          l10n.authForgotSent(_ctrl.text.trim()),
          type: BadgeColor.success,
        ),
        const SizedBox(height: 24),
        Text(l10n.authForgotNotReceived, style: WinType.bodyM(s.onMuted)),
        const SizedBox(height: 12),
        WinButton(l10n.authResendEmail,
            variant: WinButtonVariant.outline,
            block: true,
            onTap: () => setState(() => _sent = false)),
      ] else ...[
        WinTextField(
          label: l10n.authEmailAddress,
          hint: l10n.authEmailHint,
          icon: PhosphorIconsRegular.envelopeSimple,
          controller: _ctrl,
          keyboardType: TextInputType.emailAddress,
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          WinAlert(_error!, type: BadgeColor.error),
        ],
        const SizedBox(height: 24),
        WinButton(l10n.authSendLink,
            block: true, loading: _loading, onTap: _send),
      ],
      const SizedBox(height: 16),
      Center(
        child: WinButton(l10n.authBackToLogin,
            variant: WinButtonVariant.ghost,
            onTap: () => Navigator.pop(context)),
      ),
    ]);
  }
}
