import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';

/// WINPLUS — Widgets réutilisables (équivalents Flutter des composants Win*).

enum WinButtonVariant { primary, accent, outline, ghost, danger }

class WinButton extends StatelessWidget {
  final String label;
  final WinButtonVariant variant;
  final bool block, small, loading;
  final IconData? icon;
  final VoidCallback? onTap;
  const WinButton(this.label, {super.key, this.variant = WinButtonVariant.accent, this.block = false, this.small = false, this.loading = false, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    late Color bg, fg, bd;
    switch (variant) {
      case WinButtonVariant.primary: bg = WinColors.ink800; fg = WinColors.cream50; bd = Colors.transparent; break;
      case WinButtonVariant.accent: bg = s.primary; fg = s.onPrimary; bd = Colors.transparent; break;
      case WinButtonVariant.outline: bg = Colors.transparent; fg = s.onSurface; bd = WinColors.ink300; break;
      case WinButtonVariant.ghost: bg = Colors.transparent; fg = s.primaryStrong; bd = Colors.transparent; break;
      case WinButtonVariant.danger: bg = WinColors.error; fg = Colors.white; bd = Colors.transparent; break;
    }
    final child = loading
        ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(fg)))
        : Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
            if (icon != null) ...[Icon(icon, size: small ? 16 : 18, color: fg), const SizedBox(width: 8)],
            Text(label, style: WinType.manrope(size: small ? 13 : 14, weight: FontWeight.w600, color: fg)),
          ]);
    return SizedBox(
      width: block ? double.infinity : null,
      height: small ? 38 : 48,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(WinRadii.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(WinRadii.md),
          onTap: loading ? null : onTap,
          child: Container(
            alignment: Alignment.center,
            padding: EdgeInsets.symmetric(horizontal: small ? 14 : 20),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(WinRadii.md), border: Border.all(color: bd, width: 1.5)),
            child: child,
          ),
        ),
      ),
    );
  }
}

class WinCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? bg;
  final double radius;
  const WinCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.onTap, this.bg, this.radius = WinRadii.lg});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg ?? s.cardBg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: s.cardBorder),
        boxShadow: WinShadows.sm,
      ),
      child: child,
    );
    if (onTap == null) return content;
    return Material(color: Colors.transparent, child: InkWell(borderRadius: BorderRadius.circular(radius), onTap: onTap, child: content));
  }
}

class WinChip extends StatelessWidget {
  final String label;
  final bool active;
  final IconData? icon;
  final VoidCallback? onTap;
  const WinChip(this.label, {super.key, this.active = false, this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: active ? s.chipActiveBg : s.chipBg,
          borderRadius: BorderRadius.circular(WinRadii.full),
          border: Border.all(color: active ? s.chipActiveBg : s.outline),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[Icon(icon, size: 16, color: active ? s.chipActiveFg : s.onSurface), const SizedBox(width: 6)],
          Text(label, style: WinType.manrope(size: 13, weight: FontWeight.w600, color: active ? s.chipActiveFg : s.onSurface)),
        ]),
      ),
    );
  }
}

enum BadgeColor { neutral, teal, blue, success, warn, error, gold }

class WinBadge extends StatelessWidget {
  final String label;
  final BadgeColor color;
  const WinBadge(this.label, {super.key, this.color = BadgeColor.neutral});

  @override
  Widget build(BuildContext context) {
    final pairs = {
      BadgeColor.neutral: [WinColors.cream100, WinColors.ink700],
      BadgeColor.teal: [WinColors.teal100, WinColors.teal700],
      BadgeColor.blue: [WinColors.blue100, WinColors.blue700],
      BadgeColor.success: [WinColors.successBg, WinColors.success],
      BadgeColor.warn: [WinColors.warnBg, WinColors.warn],
      BadgeColor.error: [WinColors.errorBg, WinColors.error],
      BadgeColor.gold: [WinColors.goldBg, WinColors.gold],
    }[color]!;
    return Container(
      height: 20,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(color: pairs[0], borderRadius: BorderRadius.circular(WinRadii.full)),
      alignment: Alignment.center,
      child: Text(label, style: WinType.manrope(size: 11, weight: FontWeight.w600, color: pairs[1])),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(WinRadii.full),
      child: LinearProgressIndicator(
        value: (value / 100).clamp(0, 1),
        minHeight: height,
        backgroundColor: s.skeleton,
        valueColor: AlwaysStoppedAnimation(color ?? s.primary),
      ),
    );
  }
}

class WinAvatar extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  final double? progress;
  const WinAvatar(this.name, {super.key, this.size = 48, this.color, this.progress});

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final initials = name.trim().split(' ').where((w) => w.isNotEmpty).take(2).map((w) => w[0]).join().toUpperCase();
    final inner = Container(
      width: size, height: size,
      decoration: BoxDecoration(color: color ?? s.primaryContainer, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initials, style: WinType.manrope(size: size * 0.36, weight: FontWeight.w600, color: WinColors.teal700)),
    );
    if (progress == null) return inner;
    return SizedBox(
      width: size + 10, height: size + 10,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: size + 10, height: size + 10, child: CircularProgressIndicator(value: progress! / 100, strokeWidth: 3, backgroundColor: s.outline2, valueColor: AlwaysStoppedAnimation(s.primary))),
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
  const WinTextField({super.key, this.label, this.hint, this.prefix, this.icon, this.suffixIcon, this.obscure = false, this.controller, this.onSuffixTap});

  @override
  State<WinTextField> createState() => _WinTextFieldState();
}

class _WinTextFieldState extends State<WinTextField> {
  bool _focused = false;
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (widget.label != null) Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(widget.label!, style: WinType.manrope(size: 13, weight: FontWeight.w500, color: s.onStrong))),
      Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: s.surface,
            borderRadius: BorderRadius.circular(WinRadii.md),
            border: Border.all(color: _focused ? s.primary : s.outline, width: 1.5),
          ),
          child: Row(children: [
            if (widget.icon != null) ...[Icon(widget.icon, size: 18, color: s.onFaint), const SizedBox(width: 8)],
            if (widget.prefix != null) ...[Text(widget.prefix!, style: WinType.bodyM(s.onMuted)), const SizedBox(width: 6)],
            Expanded(child: TextField(controller: widget.controller, obscureText: widget.obscure, style: WinType.manrope(size: 15, color: s.onStrong), decoration: InputDecoration(isDense: true, border: InputBorder.none, hintText: widget.hint, hintStyle: WinType.manrope(size: 15, color: s.onFaint)))),
            if (widget.suffixIcon != null) GestureDetector(onTap: widget.onSuffixTap, child: Icon(widget.suffixIcon, size: 18, color: s.onFaint)),
          ]),
        ),
      ),
    ]);
  }
}

/// Orbe WinAI animé (anneaux pulsants).
class WinAIOrb extends StatefulWidget {
  final double size;
  const WinAIOrb({super.key, this.size = 48});
  @override
  State<WinAIOrb> createState() => _WinAIOrbState();
}

class _WinAIOrbState extends State<WinAIOrb> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return SizedBox(
      width: widget.size, height: widget.size,
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Stack(alignment: Alignment.center, children: [
          for (final d in [0.0, 0.4])
            Opacity(
              opacity: (1 - ((_c.value + d) % 1)).clamp(0, 1) * 0.4,
              child: Container(width: widget.size * (1 + ((_c.value + d) % 1) * 0.3), height: widget.size * (1 + ((_c.value + d) % 1) * 0.3), decoration: BoxDecoration(color: s.primary.withOpacity(0.4), shape: BoxShape.circle)),
            ),
          Container(width: widget.size * 0.6, height: widget.size * 0.6, decoration: BoxDecoration(color: s.primary, shape: BoxShape.circle, boxShadow: [BoxShadow(color: s.primary.withOpacity(0.4), blurRadius: widget.size * 0.3)])),
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
  const WinStreakFlame(this.days, {super.key, this.light = false, this.size = 24});
  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    final on = days > 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.local_fire_department, size: size, color: on ? (light ? WinColors.teal400 : s.primary) : WinColors.ink300),
      const SizedBox(width: 6),
      Text('$days', style: WinType.fraunces(size: size * 0.72, weight: FontWeight.w700, color: light ? WinColors.cream50 : s.onStrong)),
    ]);
  }
}
