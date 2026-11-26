import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import 'win_motion_widgets.dart';
import 'win_mascot.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Widgets communs alignés sur la version téléphone du site.

/// Icône de WinAI : le robot du site (multicolore, affiché tel quel). Partout
/// où un widget attend une [IconData], passer [winAIIconData] l'affiche à la
/// place d'une icône Material (voir [winIcon]).
const winAIIconData = IconData(0xE000, fontFamily: 'WinAIRobot');

class WinAIIcon extends StatelessWidget {
  final double size;
  const WinAIIcon({super.key, this.size = 24});
  @override
  Widget build(BuildContext context) => Image.asset('assets/winai-bot.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      excludeFromSemantics: true);
}

/// [Icon] ordinaire, ou le robot WinAI quand [icon] vaut [winAIIconData]
/// (le robot garde ses couleurs : [color] ne s'applique pas).
Widget winIcon(IconData? icon, {double? size, Color? color}) =>
    icon == winAIIconData
        ? WinAIIcon(size: (size ?? 24) * 1.15)
        : Icon(icon, size: size, color: color);

enum WinButtonVariant { primary, accent, outline, ghost, danger, secondary }

class WinButton extends StatefulWidget {
  final String label;
  final WinButtonVariant variant;
  final bool block, small, loading;
  final IconData? icon;
  final VoidCallback? onTap;
  const WinButton(this.label,
      {super.key,
      this.variant = WinButtonVariant.accent,
      this.block = false,
      this.small = false,
      this.loading = false,
      this.icon,
      this.onTap});

  @override
  State<WinButton> createState() => _WinButtonState();
}

class _WinButtonState extends State<WinButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final label = widget.label;
    final variant = widget.variant;
    final block = widget.block;
    final small = widget.small;
    final loading = widget.loading;
    final icon = widget.icon;
    final onTap = widget.onTap;
    final s = WinTheme.of(context);
    late Color bg, fg, bd;
    switch (variant) {
      case WinButtonVariant.primary:
        // Sarcelle fonce des boutons du site : texte blanc lisible (5,6:1).
        bg = WinColors.teal700;
        fg = Colors.white;
        bd = Colors.transparent;
        break;
      case WinButtonVariant.accent:
        bg = s.dark ? s.primary : WinColors.teal700;
        fg = s.dark ? s.onPrimary : Colors.white;
        bd = Colors.transparent;
        break;
      case WinButtonVariant.secondary:
        bg = s.surface2;
        fg = s.onSurface;
        bd = s.outline;
        break;
      case WinButtonVariant.outline:
        bg = Colors.transparent;
        fg = s.onSurface;
        bd = s.outline2;
        break;
      case WinButtonVariant.ghost:
        bg = Colors.transparent;
        fg = s.primaryStrong;
        bd = Colors.transparent;
        break;
      case WinButtonVariant.danger:
        bg = WinColors.error;
        fg = Colors.white;
        bd = Colors.transparent;
        break;
    }
    double height = small ? 44 : 48;
    final child = loading
        ? Semantics(label: label, child: WinLoadingDots(color: fg))
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                if (icon != null) ...[
                  winIcon(icon, size: small ? 16 : 18, color: fg),
                  const SizedBox(width: 8)
                ],
                // Libellé coupé proprement plutôt que de déborder quand le
                // bouton est étroit (deux boutons côte à côte, petit écran).
                Flexible(
                  child: Text(label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: WinType.manrope(
                          size: small ? 13 : 15,
                          weight: FontWeight.w600,
                          color: fg)),
                ),
              ]);
    return AnimatedScale(
      scale: _pressed && !winReducedMotion(context) ? 0.97 : 1.0,
      duration: winReducedMotion(context) ? Duration.zero : WinDurations.fast,
      curve: WinCurves.tap,
      child: SizedBox(
        width: block ? double.infinity : null,
        height: height,
        child: Material(
          color: onTap == null && !loading ? bg.withValues(alpha: .45) : bg,
          borderRadius: BorderRadius.circular(WinRadii.sm),
          child: InkWell(
            borderRadius: BorderRadius.circular(WinRadii.sm),
            onTap: loading ? null : onTap,
            onHighlightChanged:
                loading ? null : (v) => setState(() => _pressed = v),
            // Pas de « alignment » sur le Container : il etirait un bouton
            // sans « block » sur toute la largeur disponible. Le Center a
            // facteur 1 garde la largeur du libelle ; un bouton « block » ou
            // place dans un Expanded remplit toujours sa place.
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(WinRadii.sm),
                  border: Border.all(color: bd)),
              child: Center(widthFactor: block ? null : 1, child: child),
            ),
          ),
        ),
      ),
    );
  }
}

class WinCard extends StatefulWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? bg;
  const WinCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.onTap,
      this.bg});

  @override
  State<WinCard> createState() => _WinCardState();
}

class _WinCardState extends State<WinCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = Container(
      padding: widget.padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: widget.bg ?? s.cardBg,
        borderRadius: BorderRadius.circular(WinRadii.lg),
        border: Border.all(color: s.cardBorder),
        boxShadow: WinShadows.sm,
      ),
      child: widget.child,
    );
    if (widget.onTap == null) return content;
    return AnimatedScale(
      scale: _pressed && !winReducedMotion(context) ? 0.98 : 1.0,
      duration: winReducedMotion(context) ? Duration.zero : WinDurations.fast,
      curve: WinCurves.tap,
      child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(WinRadii.lg),
          child: InkWell(
              borderRadius: BorderRadius.circular(WinRadii.lg),
              onTap: widget.onTap,
              onHighlightChanged: (v) => setState(() => _pressed = v),
              child: content)),
    );
  }
}

class WinChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback? onTap;
  const WinChip(this.label,
      {super.key, this.active = false, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return WinTapScale(
      onTap: onTap,
      pressedScale: 0.94,
      child: AnimatedContainer(
        duration: WinDurations.fast,
        curve: WinCurves.tap,
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: active ? s.chipActiveBg : s.chipBg,
          borderRadius: BorderRadius.circular(WinRadii.full),
          border: Border.all(color: active ? s.chipActiveBg : s.outline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            winIcon(icon, size: 15, color: active ? s.chipActiveFg : s.onMuted),
            const SizedBox(width: 6)
          ],
          Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: WinType.manrope(
                    size: 13,
                    weight: FontWeight.w600,
                    color: active ? s.chipActiveFg : s.onSurface)),
          ),
        ]),
      ),
    );
  }
}

enum BadgeColor { neutral, teal, blue, success, warn, error, gold }

/// Fond teinté et couleur de texte d'un ton (succès, alerte, sarcelle…),
/// lisibles dans les deux thèmes. En clair : le fond pâle et le ton foncé de
/// la palette. En sombre : le ton éclairci sur un voile du même ton (un fond
/// pâle y éblouit, et un texte clair posé dessus devient illisible).
({Color bg, Color fg}) winTone(WinScheme s, BadgeColor color) {
  if (!s.dark) {
    return switch (color) {
      BadgeColor.neutral => (bg: WinColors.ink50, fg: WinColors.ink700),
      BadgeColor.teal => (bg: WinColors.teal50, fg: WinColors.teal700),
      BadgeColor.blue => (bg: WinColors.blue50, fg: WinColors.blue700),
      BadgeColor.success => (bg: WinColors.successBg, fg: WinColors.success),
      BadgeColor.warn => (bg: WinColors.warnBg, fg: WinColors.warn),
      BadgeColor.error => (bg: WinColors.errorBg, fg: WinColors.error),
      BadgeColor.gold => (bg: WinColors.goldBg, fg: WinColors.gold),
    };
  }
  final Color fg = switch (color) {
    BadgeColor.neutral => s.onMuted,
    BadgeColor.teal => WinColors.teal300,
    BadgeColor.blue => const Color(0xFF8DB8DA),
    BadgeColor.success => const Color(0xFF5CCB9E),
    BadgeColor.warn => const Color(0xFFEBAE5B),
    BadgeColor.error => const Color(0xFFF0907E),
    BadgeColor.gold => const Color(0xFFE2B866),
  };
  return (bg: Color.alphaBlend(fg.withValues(alpha: 0.14), s.surface), fg: fg);
}

class WinBadge extends StatelessWidget {
  final String label;
  final BadgeColor color;
  const WinBadge(this.label, {super.key, this.color = BadgeColor.neutral});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final tone = winTone(s, color);
    // En clair, le badge garde ses fonds un peu plus soutenus que l'alerte.
    final pairs = [
      s.dark
          ? tone.bg
          : switch (color) {
              BadgeColor.teal => WinColors.teal100,
              BadgeColor.blue => WinColors.blue100,
              _ => tone.bg,
            },
      tone.fg,
    ];
    // Pas de « alignment » sur le Container : il l'etirait sur toute la
    // largeur disponible (badges en bandeaux dans les fiches). Le Center a
    // facteur 1 centre le texte en gardant la largeur du libelle.
    return Container(
      constraints: const BoxConstraints(minHeight: 20),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: pairs[0], borderRadius: BorderRadius.circular(WinRadii.full)),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(label,
            style: WinType.manrope(
                size: 11, weight: FontWeight.w600, color: pairs[1])),
      ),
    );
  }
}

class WinProgressBar extends StatelessWidget {
  final double value; // 0..100
  final Color? color;
  final double height;
  const WinProgressBar(this.value, {super.key, this.color, this.height = 4});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return SizedBox(
      height: height,
      child: LinearProgressIndicator(
        value: (value / 100).clamp(0, 1),
        minHeight: height,
        backgroundColor: s.skeleton,
        valueColor: AlwaysStoppedAnimation(color ?? s.primary),
        borderRadius: BorderRadius.circular(WinRadii.full),
      ),
    );
  }
}

class WinAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final double? progress;
  const WinAvatar(this.name,
      {super.key, this.size = 48, this.color, this.progress});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final initials = name
        .trim()
        .split(' ')
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0])
        .join()
        .toUpperCase();
    final inner = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
          color: color ?? s.primaryContainer, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials,
          style: WinType.manrope(
              size: size * 0.36,
              weight: FontWeight.w600,
              color: WinColors.teal700)),
    );
    if (progress == null) return inner;
    return SizedBox(
      width: size + 10,
      height: size + 10,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: size + 10,
            height: size + 10,
            child: CircularProgressIndicator(
                value: progress! / 100,
                strokeWidth: 3,
                backgroundColor: s.outline2,
                valueColor: AlwaysStoppedAnimation(s.primary))),
        inner,
      ]),
    );
  }
}

class WinTextField extends StatefulWidget {
  final String? label, hint, prefix;
  final IconData? icon, suffixIcon;
  final bool obscure;
  final TextEditingController? controller;
  final VoidCallback? onSuffixTap;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  const WinTextField(
      {super.key,
      this.label,
      this.hint,
      this.prefix,
      this.icon,
      this.suffixIcon,
      this.obscure = false,
      this.controller,
      this.onSuffixTap,
      this.keyboardType,
      this.onChanged});

  @override
  State<WinTextField> createState() => _WinTextFieldState();
}

class _WinTextFieldState extends State<WinTextField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.label != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(widget.label!,
                style: WinType.manrope(
                    size: 13, weight: FontWeight.w600, color: s.onStrong))),
      Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: Container(
          constraints: const BoxConstraints(minHeight: 54),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _focused ? s.onMuted : s.outline2),
          ),
          child: Row(children: [
            if (widget.prefix != null) ...[
              Text(widget.prefix!, style: WinType.bodyM(s.onMuted)),
              const SizedBox(width: 6)
            ],
            Expanded(
                child: TextField(
                    controller: widget.controller,
                    obscureText: widget.obscure,
                    keyboardType: widget.keyboardType,
                    onChanged: widget.onChanged,
                    style: WinType.manrope(size: 16, color: s.onStrong),
                    decoration: InputDecoration(
                        isDense: true,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                        filled: false, border: InputBorder.none,
                        hintText: widget.hint,
                        hintStyle:
                            WinType.manrope(size: 16, color: s.onFaint)))),
            if (widget.suffixIcon != null)
              IconButton(
                  onPressed: widget.onSuffixTap,
                  tooltip: widget.label,
                  constraints:
                      const BoxConstraints(minWidth: 44, minHeight: 44),
                  padding: EdgeInsets.zero,
                  icon: Icon(widget.suffixIcon, size: 20, color: s.onMuted)),
          ]),
        ),
      ),
    ]);
  }
}

/// WinAI : le robot, entouré d'anneaux qui respirent aux grandes tailles.
class WinAIOrb extends StatefulWidget {
  final double size;
  const WinAIOrb({super.key, this.size = 48});
  @override
  State<WinAIOrb> createState() => _WinAIOrbState();
}

class _WinAIOrbState extends State<WinAIOrb>
    with SingleTickerProviderStateMixin {
  // Créé seulement s'il sert (grande taille, animations permises) : le créer
  // dans dispose() levait une erreur sur les petites orbes.
  AnimationController? _ctl;
  AnimationController get _c => _ctl ??=
      AnimationController(vsync: this, duration: const Duration(seconds: 2))
        ..repeat();
  @override
  void dispose() {
    _ctl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    // Petite taille (en-tête, ligne de texte) : le robot seul, sans halo.
    if (widget.size <= 32 || winReducedMotion(context)) {
      return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Center(child: WinAIIcon(size: widget.size)));
    }
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        child: WinAIIcon(size: widget.size * 0.78),
        builder: (_, robot) => Stack(alignment: Alignment.center, children: [
          for (final d in [0.0, 0.5])
            Opacity(
              opacity: (1 - ((_c.value + d) % 1)).clamp(0, 1) * 0.35,
              child: Container(
                  width: widget.size * (0.8 + ((_c.value + d) % 1) * 0.4),
                  height: widget.size * (0.8 + ((_c.value + d) % 1) * 0.4),
                  decoration: BoxDecoration(
                      color: s.primary.withValues(alpha: 0.35),
                      shape: BoxShape.circle)),
            ),
          robot!,
        ]),
      ),
    );
  }
}

/// Indicateur de série (flamme + nombre de jours).
class WinStreakFlame extends StatelessWidget {
  final int days;
  final bool light;
  final double size;
  const WinStreakFlame(this.days,
      {super.key, this.light = false, this.size = 24});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final on = days > 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(PhosphorIconsFill.fire,
          size: size,
          color:
              on ? (light ? WinColors.teal400 : s.primary) : WinColors.ink300),
      const SizedBox(width: 6),
      Text('$days',
          style: WinType.archivo(
              size: size * 0.72,
              weight: FontWeight.w700,
              color: light ? WinColors.cream50 : s.onStrong)),
    ]);
  }
}

/// Séparateur horizontal avec label optionnel.
class WinDivider extends StatelessWidget {
  final String? label;
  const WinDivider({super.key, this.label});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (label == null) {
      return Divider(color: s.outline, height: 1, thickness: 1);
    }
    return Row(children: [
      Expanded(child: Divider(color: s.outline, height: 1, thickness: 1)),
      Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label!, style: WinType.labelM(s.onFaint))),
      Expanded(child: Divider(color: s.outline, height: 1, thickness: 1)),
    ]);
  }
}

/// Bannière d'alerte inline (info, warn, error, success).
class WinAlert extends StatelessWidget {
  final String message;
  final BadgeColor type;
  final IconData? icon;
  const WinAlert(this.message,
      {super.key, this.type = BadgeColor.warn, this.icon});

  @override
  Widget build(BuildContext context) {
    final (:bg, :fg) = winTone(WinTheme.of(context), type);
    final ic = icon ??
        switch (type) {
          BadgeColor.success => PhosphorIconsRegular.checkCircle,
          BadgeColor.warn => PhosphorIconsRegular.warning,
          BadgeColor.error => PhosphorIconsRegular.warningCircle,
          _ => PhosphorIconsRegular.info,
        };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(WinRadii.sm),
          border: Border.all(color: fg.withValues(alpha: 0.3))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        winIcon(ic, size: 16, color: fg),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: WinType.bodyS(fg))),
      ]),
    );
  }
}

/// Skeleton loading placeholder.
class WinSkeleton extends StatefulWidget {
  final double width, height;
  const WinSkeleton(
      {super.key, this.width = double.infinity, this.height = 16});
  @override
  State<WinSkeleton> createState() => _WinSkeletonState();
}

class _WinSkeletonState extends State<WinSkeleton>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  AnimationController get _c => _controller ??= AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1200));
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    if (winReducedMotion(context)) {
      _controller?.stop();
      return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
              color: s.skeleton,
              borderRadius: BorderRadius.circular(WinRadii.sm)));
    }
    if (!_c.isAnimating) _c.repeat(reverse: true);
    return AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                  color: Color.lerp(s.skeleton, s.surface2, _c.value),
                  borderRadius: BorderRadius.circular(WinRadii.sm)),
            ));
  }
}

/// Section header avec titre + action optionnelle.
class WinSectionHeader extends StatelessWidget {
  final String title;
  final String? action;
  final VoidCallback? onAction;
  const WinSectionHeader(this.title, {super.key, this.action, this.onAction});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Row(children: [
      Expanded(child: Text(title, style: WinType.headlineS(s.onStrong))),
      if (action != null)
        GestureDetector(
            onTap: onAction,
            child: Text(action!,
                style: WinType.labelM(s.primary)
                    .copyWith(fontWeight: FontWeight.w600))),
    ]);
  }
}

/// Bouton icône circulaire semi-transparent flottant sur une image héro
/// (retour/favori/partage), comme sur les fiches produit et pages de
/// formation Funica  jamais une IconButton plate sur fond uni au-dessus
/// d'une image.
class WinCircleIconButton extends StatelessWidget {
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onTap;
  const WinCircleIconButton(
      {super.key, required this.icon, this.iconColor, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Padding(
      padding: const EdgeInsets.all(4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            shape: BoxShape.circle,
          ),
          child: winIcon(icon, size: 19, color: iconColor ?? s.onStrong),
        ),
      ),
    );
  }
}

/// Stat card (valeur + label).
class WinStatCard extends StatelessWidget {
  final String value, label;
  final IconData? icon;
  final Color? color;
  const WinStatCard(this.value, this.label, {super.key, this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final c = color ?? s.primary;
    return WinCard(
        padding: const EdgeInsets.all(14),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                winIcon(icon, size: 20, color: c),
                const SizedBox(height: 8),
              ],
              Text(value,
                  style: WinType.displayS(s.onStrong).copyWith(fontSize: 24)),
              const SizedBox(height: 2),
              Text(label, style: WinType.labelM(s.onMuted)),
            ]));
  }
}
