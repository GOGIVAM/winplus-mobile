import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/win_colors.dart';
import '../theme/win_motion.dart';

/// Retour tactile commun (léger effet d'enfoncement) pour tout élément
/// tapable — utilisé par [WinButton]/[WinCard]/[WinChip] eux-mêmes, donc
/// tout écran qui les utilise déjà en hérite sans rien changer.
class WinTapScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  const WinTapScale({
    super.key,
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
  });

  @override
  State<WinTapScale> createState() => _WinTapScaleState();
}

class _WinTapScaleState extends State<WinTapScale> {
  bool _pressed = false;

  void _set(bool v) {
    if (widget.onTap == null) return;
    setState(() => _pressed = v);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _set(true),
      onTapUp: (_) => _set(false),
      onTapCancel: () => _set(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: WinDurations.fast,
        curve: WinCurves.tap,
        child: widget.child,
      ),
    );
  }
}

/// Apparition en cascade pour les éléments de liste/grille : chaque élément
/// entre en fondu + léger glissement vertical, décalé de [index] *
/// [WinDurations.stagger] par rapport au précédent, pour que les grilles de
/// contenu (catalogue, favoris, quiz…) ne s'affichent plus d'un bloc.
class WinStaggerFade extends StatefulWidget {
  final int index;
  final Widget child;
  const WinStaggerFade({super.key, required this.index, required this.child});

  @override
  State<WinStaggerFade> createState() => _WinStaggerFadeState();
}

class _WinStaggerFadeState extends State<WinStaggerFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: WinDurations.slow,
  );
  late final Animation<double> _fade =
      CurvedAnimation(parent: _c, curve: WinCurves.enter);
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.08),
    end: Offset.zero,
  ).animate(_fade);

  @override
  void initState() {
    super.initState();
    final delay = Duration(
        milliseconds:
            (widget.index.clamp(0, 12) * WinDurations.stagger.inMilliseconds));
    Future.delayed(delay, () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

/// Coche de succès animée (cercle qui apparaît en rebond + trait dessiné en
/// deux segments) — remplace une simple icône statique sur les écrans de
/// confirmation (paiement, commande validée, action terminée).
class WinSuccessCheck extends StatefulWidget {
  final double size;
  final Color color;
  const WinSuccessCheck(
      {super.key, this.size = 72, this.color = WinColors.success});

  @override
  State<WinSuccessCheck> createState() => _WinSuccessCheckState();
}

class _WinSuccessCheckState extends State<WinSuccessCheck>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 600))
    ..forward();
  late final Animation<double> _scale = CurvedAnimation(
      parent: _c, curve: const Interval(0, 0.7, curve: Curves.elasticOut));
  late final Animation<double> _draw = CurvedAnimation(
      parent: _c, curve: const Interval(0.35, 1, curve: Curves.easeOut));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Transform.scale(
        scale: _scale.value,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: CustomPaint(
              painter:
                  _CheckPainter(progress: _draw.value, color: widget.color)),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  final double progress;
  final Color color;
  _CheckPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 2;
    canvas.drawCircle(
        center, radius, Paint()..color = color.withValues(alpha: 0.12));
    final ringWidth = size.width * 0.06;
    canvas.drawCircle(
        center,
        radius - ringWidth / 2,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = ringWidth
          ..strokeCap = StrokeCap.round);

    final p1 = Offset(size.width * 0.28, size.height * 0.52);
    final p2 = Offset(size.width * 0.44, size.height * 0.68);
    final p3 = Offset(size.width * 0.74, size.height * 0.34);
    final path = Path()..moveTo(p1.dx, p1.dy);
    if (progress <= 0.5) {
      final t = (progress / 0.5).clamp(0.0, 1.0);
      final p = Offset.lerp(p1, p2, t)!;
      path.lineTo(p.dx, p.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final t = ((progress - 0.5) / 0.5).clamp(0.0, 1.0);
      final p = Offset.lerp(p2, p3, t)!;
      path.lineTo(p.dx, p.dy);
    }
    canvas.drawPath(
        path,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = size.width * 0.08
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Secousse horizontale jouée une fois au montage — pour signaler un échec
/// (paiement refusé, formulaire invalide) sans texte d'alerte supplémentaire.
class WinErrorShake extends StatefulWidget {
  final Widget child;
  const WinErrorShake({super.key, required this.child});

  @override
  State<WinErrorShake> createState() => _WinErrorShakeState();
}

class _WinErrorShakeState extends State<WinErrorShake>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 500))
    ..forward();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) {
        final t = _c.value;
        final offset = t >= 1 ? 0.0 : math.sin(t * math.pi * 5) * (1 - t) * 10;
        return Transform.translate(
            offset: Offset(offset, 0), child: widget.child);
      },
    );
  }
}

/// Halo qui respire (pulsation d'opacité + échelle) derrière une icône ou un
/// indicateur de chargement — pour les états "en attente" (paiement en
/// traitement, sondage de statut) plutôt qu'un simple spinner isolé.
class WinPendingPulse extends StatefulWidget {
  final double size;
  final Color color;
  final Widget child;
  const WinPendingPulse({
    super.key,
    this.size = 88,
    this.color = WinColors.teal500,
    required this.child,
  });

  @override
  State<WinPendingPulse> createState() => _WinPendingPulseState();
}

class _WinPendingPulseState extends State<WinPendingPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600))
    ..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(alignment: Alignment.center, children: [
        AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = _c.value;
            return Opacity(
              opacity: (1 - t) * 0.35,
              child: Transform.scale(
                scale: 0.6 + t * 0.6,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle, color: widget.color),
                ),
              ),
            );
          },
        ),
        widget.child,
      ]),
    );
  }
}

/// Nombre qui défile jusqu'à sa valeur (solde, montant, statistique) au lieu
/// de s'afficher d'un coup — utilisable partout où un montant change.
class WinAnimatedCounter extends StatelessWidget {
  final int value;
  final TextStyle? style;
  final String Function(int)? format;
  const WinAnimatedCounter(
      {super.key, required this.value, this.style, this.format});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: WinDurations.slow,
      curve: WinCurves.enter,
      builder: (_, v, __) =>
          Text(format != null ? format!(v) : '$v', style: style),
    );
  }
}

/// Cœur favori avec rebond + petites particules à l'ajout — pour tout bouton
/// favori/like de l'app (contenus, formations, tuteurs).
class WinFavoriteHeart extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  final double size;
  final Color activeColor;
  final Color inactiveColor;
  const WinFavoriteHeart({
    super.key,
    required this.active,
    required this.onTap,
    this.size = 20,
    this.activeColor = WinColors.error,
    this.inactiveColor = WinColors.ink600,
  });

  @override
  State<WinFavoriteHeart> createState() => _WinFavoriteHeartState();
}

class _WinFavoriteHeartState extends State<WinFavoriteHeart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _handleTap() {
    final wasActive = widget.active;
    widget.onTap();
    if (!wasActive) _c.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: SizedBox(
        width: widget.size * 2,
        height: widget.size * 2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) {
            final t = _c.value;
            final scale = t < 0.4
                ? 1 + (t / 0.4) * 0.35
                : 1.35 - ((t - 0.4) / 0.6) * 0.35;
            return Stack(alignment: Alignment.center, children: [
              if (t > 0 && t < 1)
                ..._burstDots(t, widget.size, widget.activeColor),
              Transform.scale(
                scale: t == 0 ? 1.0 : scale,
                child: Icon(
                  widget.active ? Icons.favorite : Icons.favorite_border,
                  size: widget.size,
                  color:
                      widget.active ? widget.activeColor : widget.inactiveColor,
                ),
              ),
            ]);
          },
        ),
      ),
    );
  }

  List<Widget> _burstDots(double t, double size, Color color) {
    const angles = [0.0, 72.0, 144.0, 216.0, 288.0];
    final dist = t * size * 1.1;
    final opacity = (1 - t).clamp(0.0, 1.0);
    return angles.map((deg) {
      final rad = deg * math.pi / 180;
      final dx = math.cos(rad) * dist;
      final dy = math.sin(rad) * dist;
      return Transform.translate(
        offset: Offset(dx, dy),
        child: Opacity(
          opacity: opacity,
          child: Container(
            width: size * 0.14,
            height: size * 0.14,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
        ),
      );
    }).toList();
  }
}
