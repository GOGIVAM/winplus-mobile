import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'win_widgets.dart';

/// Barre commune : retour rond de 44 px, titre ou marque, action à droite.
class WinScreenHeader extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final bool showBack, showBrand;
  final Widget? action;
  final VoidCallback? onBack;
  const WinScreenHeader(
      {super.key,
      this.title,
      this.showBack = true,
      this.showBrand = false,
      this.action,
      this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return ColoredBox(
      color: s.bg,
      child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Row(children: [
              if (showBack)
                Material(
                  color: s.surface,
                  shape: CircleBorder(side: BorderSide(color: s.outline)),
                  child: IconButton(
                    tooltip:
                        MaterialLocalizations.of(context).backButtonTooltip,
                    constraints:
                        const BoxConstraints.tightFor(width: 44, height: 44),
                    icon: Icon(Icons.chevron_left_rounded, color: s.onStrong),
                    onPressed: onBack ?? () => Navigator.maybePop(context),
                  ),
                )
              else
                const SizedBox(height: 44),
              if (title != null) ...[
                const SizedBox(width: 12),
                Expanded(
                    child: Text(title!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: WinType.archivo(
                            size: 20,
                            weight: FontWeight.w600,
                            color: s.onStrong))),
              ] else
                const Spacer(),
              if (showBrand) ...[
                Image.asset('assets/winplus-logo.png',
                    width: 26, height: 26, excludeFromSemantics: true),
                const SizedBox(width: 7),
                Text.rich(TextSpan(
                  style: WinType.archivo(
                      size: 19,
                      weight: FontWeight.w600,
                      color: s.onStrong,
                      letterSpacing: -.7),
                  children: const [
                    TextSpan(text: 'Win'),
                    TextSpan(
                        text: '+', style: TextStyle(color: WinColors.teal600))
                  ],
                )),
              ],
              if (action != null) action!,
            ]),
          )),
    );
  }
}

/// Compatibilité avec les écrans existants, sans dépendance à LoginScreen.
class AuthBackBar extends StatelessWidget {
  final bool logo;
  const AuthBackBar({super.key, this.logo = true});
  @override
  Widget build(BuildContext context) => WinScreenHeader(showBrand: logo);
}

/// Formulaire défilant, limité à 460 px, y compris avec le clavier ouvert.
class WinAuthFrame extends StatelessWidget {
  final List<Widget> children;
  final bool showBack, centered;
  const WinAuthFrame(
      {super.key,
      required this.children,
      this.showBack = true,
      this.centered = true});
  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WinTheme.of(context).bg,
        appBar: WinScreenHeader(showBrand: true, showBack: showBack),
        body: SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, box) => SingleChildScrollView(
                  child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: Align(
                  alignment: centered ? Alignment.center : Alignment.topCenter,
                  child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              MediaQuery.sizeOf(context).width <= 380 ? 18 : 22,
                              16,
                              MediaQuery.sizeOf(context).width <= 380 ? 18 : 22,
                              32),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: children))),
                ),
              )),
            )),
      );
}

class WinAuthHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final bool logo;
  const WinAuthHeading(this.title,
      {super.key, this.subtitle, this.icon, this.logo = false});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(children: [
      if (logo) ...[
        Image.asset('assets/winplus-logo.png',
            width: 96, height: 96, excludeFromSemantics: true),
        const SizedBox(height: 14),
      ] else if (icon != null) ...[
        Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(color: s.inkCard, shape: BoxShape.circle),
            child: Icon(icon,
                size: 28, color: s.dark ? s.onStrong : Colors.white)),
        const SizedBox(height: 18),
      ],
      Text(title,
          textAlign: TextAlign.center,
          style: WinType.archivo(
              size: 27,
              weight: FontWeight.w600,
              height: 1.15,
              letterSpacing: -.8,
              color: s.onStrong)),
      if (subtitle != null) ...[
        const SizedBox(height: 8),
        Text(subtitle!,
            textAlign: TextAlign.center,
            style: WinType.manrope(size: 14.5, height: 1.5, color: s.onMuted))
      ],
      const SizedBox(height: 24),
    ]);
  }
}

class WinEmptyState extends StatelessWidget {
  final String title;
  final String? message, actionLabel;
  final IconData icon;
  final VoidCallback? onAction;
  const WinEmptyState(
      {super.key,
      required this.title,
      this.message,
      this.icon = Icons.inbox_outlined,
      this.actionLabel,
      this.onAction});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: s.onMuted),
            const SizedBox(height: 16),
            Text(title,
                textAlign: TextAlign.center,
                style: WinType.headlineM(s.onStrong)),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(message!,
                  textAlign: TextAlign.center, style: WinType.bodyM(s.onMuted))
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              WinButton(actionLabel!, onTap: onAction)
            ],
          ],
        ));
  }
}

class WinErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const WinErrorState(
      {super.key, required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) => WinEmptyState(
      title: message,
      icon: Icons.error_outline,
      actionLabel: context.l10n.commonRetry,
      onAction: onRetry);
}

Future<T?> showWinBottomSheet<T>(
        {required BuildContext context,
        required String title,
        required Widget child}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: WinTheme.of(context).surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(14))),
      builder: (c) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(c).bottom),
          child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(title,
                        style: WinType.headlineM(WinTheme.of(c).onStrong)),
                    const SizedBox(height: 20),
                    child,
                  ]))),
    );
