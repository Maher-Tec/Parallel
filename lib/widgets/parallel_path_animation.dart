import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Parallel Path Animation
/// Visualizes the core metaphor of Parallel:
/// A single origin stream diverging gracefully into two parallel paths (Act vs. Don't Act),
/// with traveling streams of light and breathing destination nodes.
class ParallelPathAnimation extends StatefulWidget {
  final double width;
  final double height;
  final bool showLabels;
  final String leftLabel;
  final String rightLabel;

  const ParallelPathAnimation({
    super.key,
    this.width = 220,
    this.height = 200,
    this.showLabels = true,
    this.leftLabel = 'ACT',
    this.rightLabel = "DON'T ACT",
  });

  @override
  State<ParallelPathAnimation> createState() => _ParallelPathAnimationState();
}

class _ParallelPathAnimationState extends State<ParallelPathAnimation>
    with TickerProviderStateMixin {
  late AnimationController _flowController;
  late AnimationController _breatheController;

  @override
  void initState() {
    super.initState();
    // Flow of energy traveling along the paths
    _flowController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    )..repeat();

    // Subtle breathing glow at nodes and fork
    _breatheController = AnimationController(
      duration: const Duration(milliseconds: 1600),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _flowController.dispose();
    _breatheController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flowController, _breatheController]),
        builder: (context, _) {
          return CustomPaint(
            size: Size(widget.width, widget.height),
            painter: _ParallelPathPainter(
              flowProgress: _flowController.value,
              breatheProgress: _breatheController.value,
              showLabels: widget.showLabels,
              leftLabel: widget.leftLabel,
              rightLabel: widget.rightLabel,
            ),
          );
        },
      ),
    );
  }
}

class _ParallelPathPainter extends CustomPainter {
  final double flowProgress;
  final double breatheProgress;
  final bool showLabels;
  final String leftLabel;
  final String rightLabel;

  _ParallelPathPainter({
    required this.flowProgress,
    required this.breatheProgress,
    required this.showLabels,
    required this.leftLabel,
    required this.rightLabel,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Geometric coordinates
    final origin = Offset(w * 0.5, h * 0.88);
    final fork = Offset(w * 0.5, h * 0.52);
    final leftEnd = Offset(w * 0.22, h * 0.18);
    final rightEnd = Offset(w * 0.78, h * 0.18);

    // Left full path (Origin -> Fork -> Left End)
    final pathLeft = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(fork.dx, fork.dy)
      ..cubicTo(
        fork.dx,
        fork.dy - h * 0.16,
        leftEnd.dx,
        fork.dy - h * 0.12,
        leftEnd.dx,
        leftEnd.dy,
      );

    // Right full path (Origin -> Fork -> Right End)
    final pathRight = Path()
      ..moveTo(origin.dx, origin.dy)
      ..lineTo(fork.dx, fork.dy)
      ..cubicTo(
        fork.dx,
        fork.dy - h * 0.16,
        rightEnd.dx,
        fork.dy - h * 0.12,
        rightEnd.dx,
        rightEnd.dy,
      );

    // 1. Draw Inactive / Guide Paths
    final guidePaint = Paint()
      ..color = AppTheme.withAlpha(AppTheme.textSecondary, 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(pathLeft, guidePaint);
    canvas.drawPath(pathRight, guidePaint);

    // 2. Fork Aura Glow
    final forkAuraRadius = 14.0 + (breatheProgress * 6.0);
    final forkAuraPaint = Paint()
      ..shader = ui.Gradient.radial(
        fork,
        forkAuraRadius,
        [
          AppTheme.withAlpha(AppTheme.accent, 0.45 * (0.6 + breatheProgress * 0.4)),
          AppTheme.withAlpha(AppTheme.accent, 0.0),
        ],
      );
    canvas.drawCircle(fork, forkAuraRadius, forkAuraPaint);

    // Fork center dot
    final forkDotPaint = Paint()
      ..color = AppTheme.withAlpha(AppTheme.textPrimary, 0.7 + breatheProgress * 0.3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(fork, 2.5, forkDotPaint);

    // 3. Draw Traveling Light Streams along both paths
    _drawLightStream(canvas, pathLeft, flowProgress, isLeft: true);
    _drawLightStream(canvas, pathRight, flowProgress, isLeft: false);

    // 4. Destination Nodes (Act & Don't Act tips)
    _drawDestinationNode(canvas, leftEnd, breatheProgress, isAct: true);
    _drawDestinationNode(canvas, rightEnd, breatheProgress, isAct: false);

    // 5. Origin Base Dot
    final originPaint = Paint()
      ..color = AppTheme.withAlpha(AppTheme.textSecondary, 0.4)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(origin, 2.0, originPaint);

    // 6. Draw Text Labels
    if (showLabels) {
      _drawTextLabel(canvas, leftLabel, Offset(leftEnd.dx, leftEnd.dy - 16), isAct: true);
      _drawTextLabel(canvas, rightLabel, Offset(rightEnd.dx, rightEnd.dy - 16), isAct: false);
    }
  }

  void _drawLightStream(Canvas canvas, Path fullPath, double progress, {required bool isLeft}) {
    final metrics = fullPath.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final metric = metrics.first;
    final totalLength = metric.length;
    final streamLength = totalLength * 0.38;

    // Cyclic position
    final headDistance = (progress * totalLength) % totalLength;
    final tailDistance = headDistance - streamLength;

    Path streamPath;
    if (tailDistance >= 0) {
      streamPath = metric.extractPath(tailDistance, headDistance);
    } else {
      // Wraparound stream
      streamPath = metric.extractPath(0, headDistance);
      streamPath.addPath(
        metric.extractPath(totalLength + tailDistance, totalLength),
        Offset.zero,
      );
    }

    // Outer glow paint
    final glowColor = isLeft ? AppTheme.accent : AppTheme.textSecondary;
    final glowPaint = Paint()
      ..color = AppTheme.withAlpha(glowColor, 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
    canvas.drawPath(streamPath, glowPaint);

    // Core bright line
    final corePaint = Paint()
      ..color = AppTheme.withAlpha(AppTheme.textPrimary, 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(streamPath, corePaint);

    // Leading particle at the head
    final tangent = metric.getTangentForOffset(headDistance);
    if (tangent != null) {
      final headPos = tangent.position;
      final particleGlow = Paint()
        ..color = AppTheme.withAlpha(AppTheme.textPrimary, 0.95)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
      canvas.drawCircle(headPos, 2.8, particleGlow);

      final particleCore = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(headPos, 1.4, particleCore);
    }
  }

  void _drawDestinationNode(Canvas canvas, Offset pos, double breathe, {required bool isAct}) {
    final auraRadius = 8.0 + (breathe * 4.0);
    final auraColor = isAct ? AppTheme.accent : AppTheme.textSecondary;

    // Glowing halo
    final haloPaint = Paint()
      ..shader = ui.Gradient.radial(
        pos,
        auraRadius,
        [
          AppTheme.withAlpha(auraColor, 0.5 * (0.6 + breathe * 0.4)),
          AppTheme.withAlpha(auraColor, 0.0),
        ],
      );
    canvas.drawCircle(pos, auraRadius, haloPaint);

    // Ring
    final ringPaint = Paint()
      ..color = AppTheme.withAlpha(AppTheme.textPrimary, 0.5 + breathe * 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(pos, 3.5, ringPaint);

    // Core dot
    final corePaint = Paint()
      ..color = isAct ? AppTheme.textPrimary : AppTheme.textSecondary
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 1.8, corePaint);
  }

  void _drawTextLabel(Canvas canvas, String text, Offset centerPos, {required bool isAct}) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: isAct
              ? AppTheme.withAlpha(AppTheme.textPrimary, 0.85)
              : AppTheme.withAlpha(AppTheme.textSecondary, 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final textOffset = Offset(
      centerPos.dx - (textPainter.width / 2),
      centerPos.dy - (textPainter.height / 2),
    );
    textPainter.paint(canvas, textOffset);
  }

  @override
  bool shouldRepaint(covariant _ParallelPathPainter oldDelegate) {
    return oldDelegate.flowProgress != flowProgress ||
        oldDelegate.breatheProgress != breatheProgress;
  }
}
