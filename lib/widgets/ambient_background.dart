import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Ambient Background Widget
/// Adds subtle life to screens with floating particles and soft gradient
/// Keeps the literary, reflective aesthetic while feeling alive
class AmbientBackground extends StatefulWidget {
  final Widget child;
  final bool showParticles;
  final bool showGradient;

  const AmbientBackground({
    super.key,
    required this.child,
    this.showParticles = true,
    this.showGradient = true,
  });

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_FloatingParticle> _particles;
  final int _particleCount = 22;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();

    _particles = List.generate(
      _particleCount,
      (_) => _FloatingParticle.random(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // A deep ink sky, warmed at the edges like distant starlight.
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF171827),
                  AppTheme.background,
                  Color(0xFF211B22),
                ],
              ),
            ),
          ),
        ),

        if (widget.showGradient) ...[
          Positioned(
            top: -130,
            left: -90,
            child: _DreamGlow(color: AppTheme.accent.withAlpha(54), size: 350),
          ),
          Positioned(
            right: -150,
            bottom: -180,
            child: _DreamGlow(color: AppTheme.rose.withAlpha(25), size: 390),
          ),
          Positioned(
            right: -70,
            top: MediaQuery.sizeOf(context).height * .28,
            child: _DreamGlow(
              color: const Color(0xFF8294B6).withAlpha(17),
              size: 220,
            ),
          ),
        ],

        // Soft gradient overlay
        if (widget.showGradient)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                return Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(
                        math.sin(progress * math.pi * 2) * 0.3,
                        math.cos(progress * math.pi * 2) * 0.3 - 0.5,
                      ),
                      radius: 1.5,
                      colors: [
                        AppTheme.accent.withAlpha(15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

        // Second subtle gradient from bottom
        if (widget.showGradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppTheme.background.withAlpha(0),
                    AppTheme.background.withAlpha(18),
                    AppTheme.background.withAlpha(55),
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),

        // Floating particles
        if (widget.showParticles)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ParticlePainter(
                  particles: _particles,
                  progress: _controller.value,
                ),
                size: Size.infinite,
              );
            },
          ),

        // Child content
        widget.child,
      ],
    );
  }
}

/// Individual floating particle data
class _FloatingParticle {
  final double x;
  final double y;
  final double size;
  final double speed;
  final double opacity;
  final double phase;

  _FloatingParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.phase,
  });

  factory _FloatingParticle.random() {
    final random = math.Random();
    return _FloatingParticle(
      x: random.nextDouble(),
      y: random.nextDouble(),
      size: 1.0 + random.nextDouble() * 2.0,
      speed: 0.3 + random.nextDouble() * 0.7,
      opacity: 0.12 + random.nextDouble() * 0.32,
      phase: random.nextDouble() * math.pi * 2,
    );
  }
}

/// Custom painter for floating particles
class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;

  _ParticlePainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate position with floating motion
      final x =
          particle.x * size.width +
          math.sin(progress * math.pi * 2 * particle.speed + particle.phase) *
              20;
      final y =
          (particle.y - progress * particle.speed * 0.5) % 1.0 * size.height;

      // Pulsing opacity
      final twinkle =
          0.28 +
          0.72 *
              (0.5 + 0.5 * math.sin(progress * math.pi * 4 + particle.phase));
      final pulsingOpacity = particle.opacity * twinkle;

      final particleColor = particle.phase > math.pi
          ? AppTheme.rose
          : AppTheme.accent;
      final paint = Paint()
        ..color = particleColor.withAlpha((pulsingOpacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);

      // A handful of particles catch the light as tiny four-point stars.
      if (particle.size > 2.15) {
        final glintPaint = Paint()
          ..color = particleColor.withAlpha((pulsingOpacity * 170).round())
          ..strokeWidth = 0.7
          ..strokeCap = StrokeCap.round;
        final radius = particle.size * 2.1;
        canvas.drawLine(
          Offset(x - radius, y),
          Offset(x + radius, y),
          glintPaint,
        );
        canvas.drawLine(
          Offset(x, y - radius),
          Offset(x, y + radius),
          glintPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _DreamGlow extends StatelessWidget {
  final Color color;
  final double size;
  const _DreamGlow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: 64, sigmaY: 64),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withAlpha(0)]),
        ),
      ),
    ),
  );
}

/// Simplified ambient wrapper for screens that just need the gradient
class AmbientGradient extends StatelessWidget {
  final Widget child;

  const AmbientGradient({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base background
        Container(color: AppTheme.background),

        // Subtle top-to-bottom gradient
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.accent.withAlpha(8),
                  AppTheme.background,
                  AppTheme.surface.withAlpha(50),
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
        ),

        // Content
        child,
      ],
    );
  }
}
