import 'dart:math' as math;
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
  final int _particleCount = 15;

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
        // Base background
        Container(color: AppTheme.background),

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
                        AppTheme.background.withAlpha(0),
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
                    AppTheme.background,
                    AppTheme.surface.withAlpha(100),
                    AppTheme.background,
                  ],
                  stops: const [0.0, 0.5, 1.0],
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
      opacity: 0.1 + random.nextDouble() * 0.3,
      phase: random.nextDouble() * math.pi * 2,
    );
  }
}

/// Custom painter for floating particles
class _ParticlePainter extends CustomPainter {
  final List<_FloatingParticle> particles;
  final double progress;

  _ParticlePainter({
    required this.particles,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final particle in particles) {
      // Calculate position with floating motion
      final x = particle.x * size.width +
          math.sin(progress * math.pi * 2 * particle.speed + particle.phase) *
              20;
      final y = (particle.y - progress * particle.speed * 0.5) % 1.0 *
          size.height;

      // Pulsing opacity
      final pulsingOpacity = particle.opacity *
          (0.5 + 0.5 * math.sin(progress * math.pi * 4 + particle.phase));

      final paint = Paint()
        ..color = AppTheme.textPrimary.withAlpha((pulsingOpacity * 255).round())
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particle.size, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
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
