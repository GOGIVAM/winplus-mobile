import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;
  const ResetPasswordScreen({super.key, required this.token});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pwCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPw = false, _showConfirm = false, _done = false, _loading = false;
  String? _error;

  bool get _has8 => _pwCtrl.text.length >= 8;
  bool get _hasMaj => _pwCtrl.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNum => _pwCtrl.text.contains(RegExp(r'[0-9]'));
  bool get _matches =>
      _pwCtrl.text == _confirmCtrl.text && _pwCtrl.text.isNotEmpty;

  Future<void> _submit() async {
    if (!_has8 || !_hasMaj || !_hasNum || !_matches) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result =
        await AuthService.instance.resetPassword(widget.token, _pwCtrl.text);
    if (!mounted) return;
    if (result.success) {
      setState(() {
        _loading = false;
        _done = true;
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
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: s.onStrong),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Text(l10n.authNewPassword, style: WinType.displayS(s.onStrong)),
            const SizedBox(height: 8),
            Text(l10n.authChooseSecure,
                style: WinType.bodyM(s.onMuted)),
            const SizedBox(height: 32),
            if (_done) ...[
              WinAlert(
                l10n.authPwdUpdated,
                type: BadgeColor.success,
              ),
              const SizedBox(height: 24),
              WinButton(l10n.authGoToLogin,
                  block: true, onTap: () => Navigator.pop(context)),
            ] else ...[
              WinTextField(
                label: l10n.authNewPassword,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: !_showPw,
                controller: _pwCtrl,
                suffixIcon: _showPw
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _showPw = !_showPw),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              WinTextField(
                label: l10n.authConfirmPassword,
                hint: '••••••••',
                icon: Icons.lock_outline,
                obscure: !_showConfirm,
                controller: _confirmCtrl,
                suffixIcon: _showConfirm
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                onSuffixTap: () => setState(() => _showConfirm = !_showConfirm),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              _Constraint(l10n.authRule8, _has8),
              const SizedBox(height: 6),
              _Constraint(l10n.authRuleUpper, _hasMaj),
              const SizedBox(height: 6),
              _Constraint(l10n.authRuleDigit, _hasNum),
              const SizedBox(height: 6),
              _Constraint(l10n.authRuleMatch, _matches),
              const SizedBox(height: 28),
              if (_error != null) ...[
                WinAlert(_error!, type: BadgeColor.error),
                const SizedBox(height: 14),
              ],
              WinButton(l10n.authReset,
                  block: true, loading: _loading, onTap: _submit),
            ],
          ]),
        ),
      ),
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
