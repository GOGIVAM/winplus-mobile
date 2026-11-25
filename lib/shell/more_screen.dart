import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../auth/login_screen.dart';
import '../l10n/l10n.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import '../shared/help_screen.dart';
import 'settings_screen.dart';

/// Entrée de l'onglet « Plus » : une fonction de l'espace qui n'a pas sa
/// place dans la barre du bas.
class MoreEntry {
  final String label;
  final IconData icon;

  /// Page ouverte par-dessus la coque.
  final WidgetBuilder page;
  const MoreEntry(this.label, this.icon, this.page);
}

/// Page poussée depuis « Plus » pour un ancien onglet (colonne sans
/// Scaffold) : barre du haut avec retour et titre.
class MorePage extends StatelessWidget {
  final String title;
  final Widget child;
  const MorePage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      appBar: AppBar(
        backgroundColor: s.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(PhosphorIconsRegular.arrowLeft, color: s.onStrong),
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: WinType.archivo(size: 20, color: s.onStrong)),
      ),
      body: SafeArea(top: false, child: child),
    );
  }
}

/// Onglet « Plus » (dernier de la barre du bas) : tout ce que l'espace
/// propose en dehors des quatre premiers onglets, comme le menu du site,
/// puis « Paramètres » et la déconnexion. Commun aux quatre espaces.
class MoreScreen extends StatefulWidget {
  final List<MoreEntry> entries;
  const MoreScreen({super.key, required this.entries});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String? _name;
  String? _email;

  @override
  void initState() {
    super.initState();
    UserService.instance.getProfile().then((p) {
      if (!mounted) return;
      setState(() {
        _name = '${p.firstName} ${p.lastName}'.trim();
        _email = p.email;
      });
    }).catchError((_) {});
  }

  void _open(WidgetBuilder page) =>
      Navigator.push(context, WinPageRoute(builder: page));

  Future<void> _logout() async {
    await AuthService.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
        WinPageRoute(builder: (_) => const LoginScreen()), (r) => false);
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final l = context.l10n;
    final name = _name ?? '';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        // Compte connecté.
        WinCard(
          child: Row(children: [
            WinAvatar(name.isEmpty ? '…' : name, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name.isEmpty ? '…' : name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.titleL(s.onStrong)),
                    if ((_email ?? '').isNotEmpty)
                      Text(_email!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: WinType.bodyS(s.onMuted)),
                  ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Fonctions de l'espace.
        if (widget.entries.isNotEmpty) ...[
          MoreGroup(children: [
            for (final e in widget.entries)
              MoreLine(icon: e.icon, label: e.label, onTap: () => _open(e.page)),
          ]),
          const SizedBox(height: 16),
        ],

        // Paramètres de l'application (langue, mode sombre, empreinte,
        // actions en attente, pages légales) sur leur propre page.
        MoreGroup(children: [
          MoreLine(
              icon: PhosphorIconsRegular.gearSix,
              label: l.settingsTitle,
              onTap: () => _open((_) => const SettingsScreen())),
          // Lot 7 : aide et contact à un appui, comme en bas du menu du site.
          MoreLine(
              icon: PhosphorIconsRegular.lifebuoy,
              label: l.helpTitle,
              onTap: () => _open((_) => const HelpScreen())),
        ]),
        const SizedBox(height: 20),

        WinButton(l.commonLogout,
            variant: WinButtonVariant.outline,
            block: true,
            icon: PhosphorIconsRegular.signOut,
            onTap: _logout),
      ],
    );
  }
}

/// Groupe de lignes dans une carte, séparées par un filet.
class MoreGroup extends StatelessWidget {
  final List<Widget> children;
  const MoreGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinCard(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) Divider(height: 1, color: s.outline, indent: 52),
          children[i],
        ],
      ]),
    );
  }
}

/// Ligne du menu : pictogramme, libellé, puis chevron (ou un réglage).
class MoreLine extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailing;
  const MoreLine(
      {super.key,
      required this.icon,
      required this.label,
      this.onTap,
      this.trailing});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(WinRadii.md),
      child: ConstrainedBox(
        // Zone tactile d'au moins 52 points.
        constraints: const BoxConstraints(minHeight: 52),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(children: [
            Icon(icon, size: 22, color: WinColors.teal600),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: WinType.manrope(
                        size: 15, weight: FontWeight.w500, color: s.onStrong))),
            if (trailing != null)
              trailing!
            else
              Icon(PhosphorIconsRegular.caretRight, size: 18, color: s.onFaint),
          ]),
        ),
      ),
    );
  }
}
