import 'package:flutter/material.dart';
import 'dart:math' as math;

class ActivityRings extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double moveValue;
  final double exerciseValue;
  final double standValue;

  const ActivityRings({
    super.key,
    this.size = 100,
    this.strokeWidth = 10,
    required this.moveValue,
    required this.exerciseValue,
    required this.standValue,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: ActivityRingsPainter(
          strokeWidth: strokeWidth,
          moveValue: moveValue,
          exerciseValue: exerciseValue,
          standValue: standValue,
        ),
      ),
    );
  }
}

class ActivityRingsPainter extends CustomPainter {
  final double strokeWidth;
  final double moveValue;
  final double exerciseValue;
  final double standValue;

  ActivityRingsPainter({
    required this.strokeWidth,
    required this.moveValue,
    required this.exerciseValue,
    required this.standValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - strokeWidth / 2;
    final middleRadius = outerRadius - strokeWidth - 1;
    final innerRadius = middleRadius - strokeWidth - 1;

    _drawRing(
      canvas: canvas,
      center: center,
      radius: outerRadius,
      value: moveValue,
      color: const Color(0xFFFA114F), // Apple Fitness Move (Red)
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: middleRadius,
      value: exerciseValue,
      color: const Color(0xFF92E82A), // Apple Fitness Exercise (Green)
    );

    _drawRing(
      canvas: canvas,
      center: center,
      radius: innerRadius,
      value: standValue,
      color: const Color(0xFF1EE4FF), // Apple Fitness Stand (Blue)
    );
  }

  void _drawRing({
    required Canvas canvas,
    required Offset center,
    required double radius,
    required double value,
    required Color color,
  }) {
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background track
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    if (value <= 0) return;

    // Outer glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    final sweepAngle = 2 * math.pi * value.clamp(0.0, 1.0);
    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);

    // Solid arc
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant ActivityRingsPainter oldDelegate) {
    return oldDelegate.moveValue != moveValue ||
        oldDelegate.exerciseValue != exerciseValue ||
        oldDelegate.standValue != standValue;
  }
}
