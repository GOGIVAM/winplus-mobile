import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../theme/win_motion.dart';
import '../theme/win_theme.dart';

enum WinMascotScene { welcome, waiting }

/// Planches du site, découpées en 29 images. Une seule animation par attente.
class WinMascot extends StatefulWidget {
  final WinMascotScene scene;
  final double height;
  const WinMascot(
      {super.key, this.scene = WinMascotScene.waiting, this.height = 80});
  @override
  State<WinMascot> createState() => _WinMascotState();
}

class _WinMascotState extends State<WinMascot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 3625));

  void _updateAnimation() {
    if (winReducedMotion(context)) {
      _controller.stop();
      _controller.value = widget.scene == WinMascotScene.welcome ? 1 : 0;
    } else if (widget.scene == WinMascotScene.waiting) {
      _controller.repeat();
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateAnimation();
  }

  @override
  void didUpdateWidget(WinMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) _updateAnimation();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final waiting = widget.scene == WinMascotScene.waiting;
    final width = widget.height * (waiting ? 167 / 160 : 196 / 200);
    final sheetWidth = width * 29;
    final image = Image.asset(
      waiting ? 'assets/kame-mouche.webp' : 'assets/kame-salut.webp',
      width: sheetWidth,
      height: widget.height,
      fit: BoxFit.fill,
      cacheWidth: math
          .min(4096, sheetWidth * MediaQuery.devicePixelRatioOf(context))
          .round(),
      excludeFromSemantics: true,
      filterQuality: FilterQuality.medium,
    );
    return ExcludeSemantics(
        child: SizedBox(
      width: width,
      height: widget.height,
      child: ClipRect(
          child: OverflowBox(
        alignment: Alignment.topLeft,
        minWidth: sheetWidth,
        maxWidth: sheetWidth,
        minHeight: widget.height,
        maxHeight: widget.height,
        child: AnimatedBuilder(
            animation: _controller,
            child: image,
            builder: (_, child) => Transform.translate(
                offset: Offset(
                    -math.min(28, (_controller.value * 29).floor()) * width, 0),
                child: child)),
      )),
    ));
  }
}

class WinLoadingDots extends StatefulWidget {
  final Color? color;
  final double size;
  const WinLoadingDots({super.key, this.color, this.size = 5});
  @override
  State<WinLoadingDots> createState() => _WinLoadingDotsState();
}

class _WinLoadingDotsState extends State<WinLoadingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1300));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (winReducedMotion(context)) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = winReducedMotion(context);
    return ExcludeSemantics(
        child: AnimatedBuilder(
      animation: _controller,
      builder: (_, __) => Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 0; i < 3; i++)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: widget.size / 2),
            child: Opacity(
                opacity: reduced
                    ? 1
                    : .3 +
                        .7 *
                            math.max(
                                0,
                                math.sin((_controller.value - i * .14) *
                                    math.pi *
                                    2)),
                child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.color ?? WinTheme.of(context).primary))),
          ),
      ]),
    ));
  }
}

class WinLoadingState extends StatelessWidget {
  const WinLoadingState({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        label: context.l10n.commonLoading,
        liveRegion: true,
        child: const Column(mainAxisSize: MainAxisSize.min, children: [
          WinMascot(),
          SizedBox(height: 16),
          WinLoadingDots(),
        ]),
      );
}
