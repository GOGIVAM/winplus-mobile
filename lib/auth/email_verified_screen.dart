import 'dart:math';
import 'package:flutter/material.dart';
import '../services/session_manager.dart';
import '../shell/role_shell.dart';
import '../theme/win_colors.dart';
import '../theme/win_theme.dart';
import '../theme/win_typography.dart';
import '../widgets/win_widgets.dart';
import 'complete_profile_screen.dart';

class EmailVerifiedScreen extends StatefulWidget {
  const EmailVerifiedScreen({super.key});
  @override
  State<EmailVerifiedScreen> createState() => _EmailVerifiedScreenState();
}

class _EmailVerifiedScreenState extends State<EmailVerifiedScreen>
    with TickerProviderStateMixin {
  late final AnimationController _confettiCtrl;
  late final AnimationController _iconCtrl;
  late final Animation<double> _iconScale;
  late final List<_Particle> _particles;

  static const _colors = [
    WinColors.teal400, WinColors.gold, WinColors.blue500,
    WinColors.success,  WinColors.error, WinColors.teal500,
  ];

  @override
  void initState() {
    super.initState();

    _confettiCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..forward();

    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _iconScale = CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut);
    _iconCtrl.forward();

    final rand = Random();
    _particles = List.generate(60, (i) => _Particle(
      x: rand.nextDouble(),
      baseY: -0.05 - rand.nextDouble() * 0.3,
      speed: 0.55 + rand.nextDouble() * 0.45,
      drift: (rand.nextDouble() - 0.5) * 0.15,
      size: 5 + rand.nextDouble() * 8,
      color: _colors[rand.nextInt(_colors.length)],
      isRect: rand.nextBool(),
      rotation: rand.nextDouble() * pi * 2,
      rotSpeed: (rand.nextDouble() - 0.5) * pi * 3,
    ));
  }

  @override
  void dispose() {
    _confettiCtrl.dispose();
    _iconCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = WinTheme.of(context);
    return Scaffold(
      backgroundColor: s.bg,
      body: SafeArea(
        child: Stack(
          children: [
            // Confetti layer
            AnimatedBuilder(
              animation: _confettiCtrl,
              builder: (_, __) => CustomPaint(
                painter: _ConfettiPainter(_particles, _confettiCtrl.value),
                child: const SizedBox.expand(),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  ScaleTransition(
                    scale: _iconScale,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: const BoxDecoration(
                        color: WinColors.successBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.verified_outlined,
                          size: 54, color: WinColors.success),
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text('Email vérifié !',
                      style: WinType.displayS(s.onStrong),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  Text(
                    'Votre compte WinPlus est maintenant actif.',
                    style: WinType.bodyM(s.onMuted),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.workspace_premium_outlined,
                        size: 16, color: WinColors.gold),
                    const SizedBox(width: 6),
                    Text('+50 XP débloqués',
                        style: WinType.manrope(
                            size: 13,
                            weight: FontWeight.w700,
                            color: WinColors.gold)),
                  ]),
                  const Spacer(),
                  WinButton('Continuer',
                      block: true,
                      onTap: () async {
                        final role = await SessionManager.getUserRole();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => role != null
                              ? const RoleShell()
                              : const CompleteProfileScreen()),
                          (r) => false,
                        );
                      }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Particle {
  final double x, baseY, speed, drift, size, rotation, rotSpeed;
  final Color color;
  final bool isRect;
  const _Particle({
    required this.x, required this.baseY, required this.speed,
    required this.drift, required this.size, required this.color,
    required this.isRect, required this.rotation, required this.rotSpeed,
  });
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double t;
  const _ConfettiPainter(this.particles, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final fade = (1.0 - (t - 0.7).clamp(0.0, 1.0) / 0.3).clamp(0.0, 1.0);

    for (final p in particles) {
      final y = p.baseY + p.speed * t;
      if (y < -0.05 || y > 1.05) continue;
      final cx = (p.x + p.drift * t) * size.width;
      final cy = y * size.height;
      paint.color = p.color.withValues(alpha: fade * 0.85);

      canvas.save();
      canvas.translate(cx, cy);
      canvas.rotate(p.rotation + p.rotSpeed * t);

      if (p.isRect) {
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.5),
          paint,
        );
      } else {
        canvas.drawCircle(Offset.zero, p.size * 0.45, paint);
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
