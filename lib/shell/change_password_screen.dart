import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../l10n/l10n.dart';
import '../services/user_service.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'more_screen.dart';

/// Changement du mot de passe, le même pour tous les comptes. Ouvert depuis
/// « Paramètres » : le parent, le professeur et l'établissement n'avaient
/// aucun écran pour le faire (seul le profil de l'élève le proposait).
class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = L10n.current;
    final cur = _current.text;
    final next = _next.text;
    String? error;
    if (cur.isEmpty || next.isEmpty || _confirm.text.isEmpty) {
      error = l.fillAllFields;
    } else if (next.length < 8) {
      error = l.authRule8;
    } else if (next != _confirm.text) {
      error = l.studentProfilePwdMismatch;
    }
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final ok = await UserService.instance.changePassword(cur, next);
    if (!mounted) return;
    if (!ok) {
      setState(() {
        _saving = false;
        _error = l.studentProfilePwdWrong;
      });
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l.studentProfilePwdChanged)));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    return MorePage(
      title: l.studentProfileChangePwd,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          WinTextField(
              controller: _current,
              label: l.studentProfileCurrentPwd,
              icon: PhosphorIconsRegular.lockKey,
              obscure: true),
          const SizedBox(height: 14),
          WinTextField(
              controller: _next,
              label: l.authNewPassword,
              icon: PhosphorIconsRegular.lock,
              obscure: true),
          const SizedBox(height: 4),
          Text(l.authRule8, style: WinType.labelS(s.onMuted)),
          const SizedBox(height: 14),
          WinTextField(
              controller: _confirm,
              label: l.authConfirmPassword,
              icon: PhosphorIconsRegular.lock,
              obscure: true),
          if (_error != null) ...[
            const SizedBox(height: 14),
            WinAlert(_error!, type: BadgeColor.error),
          ],
          const SizedBox(height: 20),
          WinButton(l.studentProfileChangePwd,
              block: true, onTap: _saving ? null : _save),
        ],
      ),
    );
  }
}
