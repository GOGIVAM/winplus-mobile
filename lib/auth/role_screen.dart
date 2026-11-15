import '../widgets/win_screen.dart';
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../services/auth_service.dart';
import 'google_login.dart';
import 'signup_screen.dart';

/// Sélection du rôle à l'inscription.
///
/// Avec [googleIdToken] (compte Google encore inconnu de WinPlus), le choix
/// du profil crée directement le compte, sans formulaire d'inscription.
class RoleScreen extends StatefulWidget {
  final String? googleIdToken;
  const RoleScreen({super.key, this.googleIdToken});
  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  WinRole? _sel;
  bool _loading = false;

  Future<void> _continuer() async {
    final role = _sel;
    if (role == null) return;
    final token = widget.googleIdToken;
    if (token == null) {
      Navigator.push(
          context, WinPageRoute(builder: (_) => SignupScreen(role: role)));
      return;
    }
    setState(() => _loading = true);
    final messenger = ScaffoldMessenger.of(context);
    final res = await AuthService.instance.googleSignIn(token, role: role.name);
    if (!mounted) return;
    if (!res.success) {
      setState(() => _loading = false);
      messenger.showSnackBar(SnackBar(
          content: Text(res.message ?? context.l10n.authGoogleFailed)));
      return;
    }
    await GoogleLogin.openAccountSpace(context, res.locale);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return WinAuthFrame(children: [
      WinAuthHeading(l10n.authIAm,
          subtitle: widget.googleIdToken != null
              ? l10n.authGoogleChooseProfile
              : l10n.authChooseProfile),
      LayoutBuilder(
          builder: (context, box) => Wrap(
              spacing: 10,
              runSpacing: 10,
              children: WinData.roles
                  .map((r) => SizedBox(
                        width: MediaQuery.sizeOf(context).width <= 380
                            ? box.maxWidth
                            : (box.maxWidth - 10) / 2,
                        child: _RoleCard(
                            info: r,
                            selected: _sel == r.role,
                            onTap: () => setState(() => _sel = r.role)),
                      ))
                  .toList())),
      const SizedBox(height: 24),
      WinButton(l10n.commonContinue,
          variant: WinButtonVariant.accent,
          block: true,
          loading: _loading,
          onTap: _sel == null || _loading ? null : _continuer),
    ]);
  }
}

class _RoleCard extends StatelessWidget {
  final RoleInfo info;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard(
      {required this.info, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l10n = context.l10n;
    // Libellés affichés selon la langue (WinData.roles reste en français).
    final (label, description) = switch (info.role) {
      WinRole.student => (l10n.authRoleStudentLabel, l10n.authRoleStudentDesc),
      WinRole.parent => (l10n.authRoleParentLabel, l10n.authRoleParentDesc),
      WinRole.teacher => (l10n.authRoleTeacherLabel, l10n.authRoleTeacherDesc),
      WinRole.institution => (
          l10n.authRoleInstitutionLabel,
          l10n.authRoleInstitutionDesc
        ),
    };
    return Semantics(
        button: true,
        selected: selected,
        child: Material(
          color: selected ? s.surface2 : s.cardBg,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: selected ? s.primary : s.cardBorder)),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(info.icon, color: s.primary, size: 24),
                        const Spacer(),
                        Icon(
                            selected
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: selected ? s.primary : s.outline2,
                            size: 20),
                      ]),
                      const SizedBox(height: 10),
                      Text(label,
                          style: WinType.archivo(
                              size: 15,
                              weight: FontWeight.w600,
                              color: s.onStrong)),
                      const SizedBox(height: 4),
                      Text(description, style: WinType.bodyS(s.onMuted)),
                    ])),
          ),
        ));
  }
}
