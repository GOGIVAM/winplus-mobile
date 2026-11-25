import '../widgets/win_screen.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../services/session_manager.dart';
import '../shell/role_shell.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'complete_profile_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmailVerifiedScreen extends StatefulWidget {
  const EmailVerifiedScreen({super.key});
  @override
  State<EmailVerifiedScreen> createState() => _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends State<EmailVerifiedScreen> {
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinAuthFrame(showBack: false, children: [
      WinAuthHeading(context.l10n.authEmailVerified,
          subtitle: context.l10n.authAccountActive,
          icon: PhosphorIconsRegular.sealCheck),
      Text(context.l10n.authXpUnlocked,
          textAlign: TextAlign.center, style: WinType.bodyM(s.onStrong)),
      const SizedBox(height: 24),
      WinButton(context.l10n.commonContinue, block: true, onTap: () async {
        final role = await SessionManager.getUserRole();
        if (!context.mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          WinPageRoute(
              builder: (_) => role != null
                  ? const RoleShell()
                  : const CompleteProfileScreen()),
          (r) => false,
        );
      }),
    ]);
  }
}
