import 'package:flutter/material.dart';
import '../app_state.dart';
import '../data/mock_data.dart';
import '../data/models.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shell/role_shell.dart';
import 'login_screen.dart';

/// Sélection du rôle à l'inscription.
class RoleScreen extends StatefulWidget {
  const RoleScreen({super.key});
  @override
  State<RoleScreen> createState() => _RoleScreenState();
}

class _RoleScreenState extends State<RoleScreen> {
  WinRole? _sel;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Column(children: [
          const AuthBackBar(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              children: [
                Center(child: Text('Je suis…', style: WinType.archivo(size: 26, weight: FontWeight.w700, color: s.onStrong))),
                const SizedBox(height: 6),
                Center(child: Text('Choisis ton profil pour une expérience personnalisée.', textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted))),
                const SizedBox(height: 24),
                ...WinData.roles.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _RoleCard(info: r, selected: _sel == r.role, onTap: () => setState(() => _sel = r.role)),
                    )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
            child: WinButton(
              'Continuer',
              variant: WinButtonVariant.accent,
              block: true,
              onTap: _sel == null
                  ? null
                  : () {
                      WinAppScope.of(context).setRole(_sel!);
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const RoleShell()), (r) => false);
                    },
            ),
          ),
        ]),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final RoleInfo info;
  final bool selected;
  final VoidCallback onTap;
  const _RoleCard({required this.info, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? s.surface2 : s.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? s.onStrong : s.cardBorder, width: selected ? 2 : 1),
        ),
        child: Row(children: [
          Container(width: 48, height: 48, decoration: BoxDecoration(color: info.color, borderRadius: BorderRadius.circular(12)), child: Icon(info.icon, color: Colors.white, size: 24)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(info.label, style: WinType.titleL(s.onStrong)),
            const SizedBox(height: 2),
            Text(info.description, style: WinType.bodyS(s.onMuted)),
          ])),
          Container(
            width: 22, height: 22,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: selected ? s.primary : s.outline2, width: 2)),
            child: selected ? Center(child: Container(width: 12, height: 12, decoration: BoxDecoration(color: s.primary, shape: BoxShape.circle))) : null,
          ),
        ]),
      ),
    );
  }
}
