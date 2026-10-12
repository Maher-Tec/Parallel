import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A slowly breathing moonlit landscape used as a story backdrop.
class DreamHorizon extends StatefulWidget {
  final bool fullBleed;
  final bool alternate;

  const DreamHorizon({
    super.key,
    this.fullBleed = false,
    this.alternate = false,
  });

  @override
  State<DreamHorizon> createState() => _DreamHorizonState();
}

class _DreamHorizonState extends State<DreamHorizon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = AnimatedBuilder(
      animation: _glow,
      builder: (context, _) => CustomPaint(
        painter: _HorizonPainter(
          _glow.value,
          widget.fullBleed,
          widget.alternate,
        ),
        child: const SizedBox.expand(),
      ),
    );

    if (widget.fullBleed) return IgnorePointer(child: scene);

    return Container(
      height: 154,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.accent.withAlpha(65)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF25243A), Color(0xFF191923), Color(0xFF292126)],
        ),
      ),
      child: scene,
    );
  }
}

class _HorizonPainter extends CustomPainter {
  final double glow;
  final bool fullBleed;
  final bool alternate;
  const _HorizonPainter(this.glow, this.fullBleed, this.alternate);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final moon = Offset(
      w * (alternate ? .76 : .72),
      h * (fullBleed ? .25 : .38),
    );
    final skyColor = fullBleed
        ? const Color(0xFF131725)
        : const Color(0xFF29243A);
    final glowColor = alternate ? const Color(0xFF8A9AB8) : AppTheme.accent;
    final auraStrength = alternate ? .38 : 1.0;

    final aura = Paint()
      ..shader =
          RadialGradient(
            colors: [
              glowColor.withAlpha(((20 + glow * 22) * auraStrength).round()),
              glowColor.withAlpha(0),
            ],
          ).createShader(
            Rect.fromCircle(
              center: moon,
              radius: (64 + glow * 10) * (fullBleed ? 1.5 : 1),
            ),
          );
    canvas.drawCircle(moon, fullBleed ? 105 : 70, aura);

    final moonPaint = Paint()
      ..color = (alternate ? const Color(0xFFAEB7C9) : const Color(0xFFFFE4A5))
          .withAlpha((alternate ? 130 + glow * 45 : 205 + glow * 45).round());
    canvas.drawCircle(moon, fullBleed ? 26 : 19, moonPaint);
    canvas.drawCircle(
      Offset(moon.dx + (alternate ? 16 : 8), moon.dy - (alternate ? 12 : 7)),
      fullBleed ? (alternate ? 26 : 23) : 17,
      Paint()..color = skyColor,
    );

    final stars = <Offset>[
      Offset(w * .12, h * .23),
      Offset(w * .29, h * .36),
      Offset(w * .48, h * .19),
      Offset(w * .9, h * .2),
      Offset(w * .88, h * .52),
      Offset(w * .36, h * .57),
    ];
    for (var i = 0; i < stars.length; i++) {
      final point = stars[i];
      final twinkle = .35 + .65 * (0.5 + .5 * math.sin(glow * math.pi * 2 + i));
      final starPaint = Paint()
        ..color = (alternate ? const Color(0xFFB3BDD2) : AppTheme.textPrimary)
            .withAlpha((twinkle * (alternate ? 75 : 145)).round());
      canvas.drawCircle(point, i.isEven ? 1.5 : 1, starPaint);
      if (i == 2 || i == 4) {
        final ray = Paint()
          ..color = glowColor.withAlpha(
            (twinkle * (alternate ? 52 : 110)).round(),
          )
          ..strokeWidth = .7
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(
          Offset(point.dx - 4, point.dy),
          Offset(point.dx + 4, point.dy),
          ray,
        );
        canvas.drawLine(
          Offset(point.dx, point.dy - 4),
          Offset(point.dx, point.dy + 4),
          ray,
        );
      }
    }

    final farHill = Path()
      ..moveTo(0, h * (fullBleed ? .81 : .82))
      ..cubicTo(
        w * .22,
        h * (fullBleed ? .68 : .57),
        w * .35,
        h * .96,
        w * .57,
        h * .78,
      )
      ..cubicTo(
        w * .77,
        h * .6,
        w * .85,
        h * .7,
        w,
        h * (fullBleed ? .69 : .62),
      )
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      farHill,
      Paint()
        ..color =
            (alternate ? const Color(0xFF212B3A) : const Color(0xFF302A3A))
                .withAlpha(fullBleed ? 155 : 220),
    );

    final nearHill = Path()
      ..moveTo(0, h * (fullBleed ? .89 : .91))
      ..cubicTo(w * .21, h * .73, w * .4, h * 1.02, w * .63, h * .88)
      ..cubicTo(w * .78, h * .77, w * .89, h * .86, w, h * .77)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(
      nearHill,
      Paint()
        ..shader = LinearGradient(
          colors: alternate
              ? const [Color(0xFF1D2634), Color(0xFF11151F)]
              : const [Color(0xFF29232F), Color(0xFF171820)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(Rect.fromLTWH(0, h * .75, w, h * .25)),
    );
  }

  @override
  bool shouldRepaint(covariant _HorizonPainter oldDelegate) =>
      oldDelegate.glow != glow ||
      oldDelegate.fullBleed != fullBleed ||
      oldDelegate.alternate != alternate;
}
