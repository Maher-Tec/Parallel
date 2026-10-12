import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A precision journey painter that connects milestone stations with a smooth,
/// glowing winding mountain path, ambient stardust, traveling sparks, and summit flares.
class DreamMapPainter extends CustomPainter {
  const DreamMapPainter({
    required this.stationPoints,
    required this.summitPoint,
    required this.startPoint,
    required this.completedCount,
    required this.pulse,
    this.drawLandscape = false,
  });

  /// Absolute pixel positions of the stations in the container
  final List<Offset> stationPoints;
  final Offset summitPoint;
  final Offset startPoint;
  final int completedCount;
  final double pulse; // 0.0 .. 1.0 animation
  final bool drawLandscape;

  static const Color _gold = Color(0xFFFFC65C);
  static const Color _lightGold = Color(0xFFFFE8A8);
  static const Color _amberGlow = Color(0xFFFF9E2C);

  /// Builds a smooth flowing S-curve through all waypoints to the summit
  Path buildPath() {
    final path = Path()..moveTo(startPoint.dx, startPoint.dy);
    final allPoints = [...stationPoints, summitPoint];

    Offset prev = startPoint;
    for (final pt in allPoints) {
      final midY = (prev.dy + pt.dy) / 2;
      path.cubicTo(
        prev.dx, midY,
        pt.dx, midY,
        pt.dx, pt.dy,
      );
      prev = pt;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    // 1. Draw floating ambient golden stardust
    _drawEmbers(canvas, size);

    if (stationPoints.isEmpty) return;

    final journeyPath = buildPath();
    final metrics = journeyPath.computeMetrics().toList();

    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final totalLen = metric.length;

    // Base Guide Path (Soft celestial golden trail)
    canvas.drawPath(
      journeyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6.0
        ..strokeCap = StrokeCap.round
        ..color = _gold.withAlpha(25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Subtle dashed/solid core guide
    canvas.drawPath(
      journeyPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..color = _lightGold.withAlpha(65),
    );

    // 2. Completed illuminated progress beam
    final totalSegments = stationPoints.length; // 1 segment per stage
    final progressFraction = totalSegments == 0
        ? 0.0
        : (completedCount / totalSegments).clamp(0.0, 1.0);

    if (progressFraction > 0) {
      // Find length up to completed station
      // Total points = stationPoints.length + 1 (summit).
      // If completedCount < totalSegments, progress goes to stationPoints[completedCount - 1]
      // If completedCount == totalSegments, progress reaches the summit!
      final targetFraction = completedCount >= totalSegments
          ? 1.0
          : (completedCount / (totalSegments + 0.3)).clamp(0.0, 1.0);

      final litLen = totalLen * targetFraction;
      final litPath = metric.extractPath(0, litLen);

      // Outer golden aura
      canvas.drawPath(
        litPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 10.0
          ..strokeCap = StrokeCap.round
          ..color = _amberGlow.withAlpha(120)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );

      // Inner intense core beam
      canvas.drawPath(
        litPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round
          ..shader = const LinearGradient(
            colors: [_gold, _lightGold, _gold],
          ).createShader(Offset.zero & size),
      );

      // Traveling golden spark at the front of progress
      final tangent = metric.getTangentForOffset(litLen);
      if (tangent != null) {
        final sparkPos = tangent.position;
        final radius = 5.0 + pulse * 3.0;

        canvas.drawCircle(
          sparkPos,
          radius * 2.5,
          Paint()
            ..color = _amberGlow.withAlpha(90)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
        canvas.drawCircle(sparkPos, radius, Paint()..color = _gold);
        canvas.drawCircle(sparkPos, radius * 0.45, Paint()..color = Colors.white);
      }
    }

    // 3. Glowing halos behind stations
    for (int i = 0; i < stationPoints.length; i++) {
      final pt = stationPoints[i];
      final isDone = i < completedCount;
      final isCurrent = i == completedCount;

      if (isDone) {
        canvas.drawCircle(
          pt,
          24.0,
          Paint()
            ..color = _gold.withAlpha(35)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      } else if (isCurrent) {
        final ringSize = 22.0 + pulse * 8.0;
        final alpha = ((1.0 - pulse) * 120).round().clamp(0, 255);

        canvas.drawCircle(
          pt,
          ringSize,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8
            ..color = _gold.withAlpha(alpha),
        );
        canvas.drawCircle(
          pt,
          18.0,
          Paint()
            ..color = _amberGlow.withAlpha(45)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
        );
      }
    }

    // 4. Summit Flag Radiance
    final isAllDone = totalSegments > 0 && completedCount >= totalSegments;
    _drawSummitGlow(canvas, summitPoint, isAllDone);
  }

  void _drawSummitGlow(Canvas canvas, Offset pos, bool isAllDone) {
    final baseRadius = isAllDone ? 32.0 : 16.0;
    final pulseOffset = pulse * (isAllDone ? 10.0 : 4.0);
    final radius = baseRadius + pulseOffset;

    canvas.drawCircle(
      pos,
      radius * 1.8,
      Paint()
        ..color = _amberGlow.withAlpha(isAllDone ? 130 : 45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
    );

    canvas.drawCircle(
      pos,
      radius * 0.7,
      Paint()..color = _gold.withAlpha(isAllDone ? 220 : 90),
    );

    canvas.drawCircle(
      pos,
      isAllDone ? 5.0 + pulse * 2.0 : 3.0,
      Paint()..color = Colors.white,
    );

    if (isAllDone) {
      final sparkLen = 14.0 + pulse * 5.0;
      final paint = Paint()
        ..color = Colors.white.withAlpha(210)
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(Offset(pos.dx, pos.dy - sparkLen), Offset(pos.dx, pos.dy + sparkLen), paint);
      canvas.drawLine(Offset(pos.dx - sparkLen, pos.dy), Offset(pos.dx + sparkLen, pos.dy), paint);
    }
  }

  void _drawEmbers(Canvas canvas, Size size) {
    const embers = [
      (0.18, 0.75, 1.5, 0.3),
      (0.82, 0.70, 1.3, 0.7),
      (0.24, 0.50, 1.6, 0.1),
      (0.78, 0.45, 1.4, 0.8),
      (0.30, 0.30, 1.8, 0.5),
      (0.70, 0.25, 1.2, 0.9),
      (0.15, 0.88, 1.4, 0.4),
      (0.85, 0.82, 1.5, 0.6),
    ];

    for (final ember in embers) {
      final cycle = (pulse + ember.$4) % 1.0;
      final yOffset = math.sin(cycle * math.pi * 2) * 5.0;
      final center = Offset(size.width * ember.$1, size.height * ember.$2 + yOffset);
      final alpha = (70 + math.sin(cycle * math.pi * 2).abs() * 130).round().clamp(0, 255);

      canvas.drawCircle(
        center,
        ember.$3 * 2.2,
        Paint()
          ..color = _amberGlow.withAlpha((alpha * 0.35).round())
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      canvas.drawCircle(
        center,
        ember.$3,
        Paint()..color = _lightGold.withAlpha(alpha),
      );
    }
  }

  @override
  bool shouldRepaint(covariant DreamMapPainter oldDelegate) =>
      oldDelegate.stationPoints != stationPoints ||
      oldDelegate.summitPoint != summitPoint ||
      oldDelegate.startPoint != startPoint ||
      oldDelegate.completedCount != completedCount ||
      oldDelegate.pulse != pulse;
}
