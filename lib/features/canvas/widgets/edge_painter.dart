import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:ui';

class EdgePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final bool isPreview;
  final bool isSelected;
  final String? startSide;
  final String? endSide;
  final String? type;

  const EdgePainter({
    required this.start,
    required this.end,
    this.isPreview = false,
    this.isSelected = false,
    this.startSide,
    this.endSide,
    this.type,
  });

  static Path getBezierPath(Offset start, Offset end, String? startSide, String? endSide) {
    final distance = (end - start).distance;
    final controlOffset = (distance * 0.35).clamp(60.0, 240.0);

    Offset getControlPoint(Offset pt, String? side, bool isStart) {
      final defaultSide = isStart ? 'right' : 'left';
      final actualSide = side ?? defaultSide;
      
      switch (actualSide) {
        case 'top': return pt + Offset(0, -controlOffset);
        case 'bottom': return pt + Offset(0, controlOffset);
        case 'left': return pt + Offset(-controlOffset, 0);
        case 'right': return pt + Offset(controlOffset, 0);
        default: return pt + Offset(isStart ? controlOffset : -controlOffset, 0);
      }
    }

    final c1 = getControlPoint(start, startSide, true);
    final c2 = getControlPoint(end, endSide, false);

    return Path()
      ..moveTo(start.dx, start.dy)
      ..cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, end.dx, end.dy);
  }

  static bool hitTestEdge(Offset point, Offset start, Offset end, String? startSide, String? endSide, {double tolerance = 15.0}) {
    final path = getBezierPath(start, end, startSide, endSide);
    for (final metric in path.computeMetrics()) {
      final length = metric.length;
      for (double i = 0; i < length; i += 10.0) {
        final tangent = metric.getTangentForOffset(i);
        if (tangent != null) {
          if ((tangent.position - point).distance <= tolerance) {
            return true;
          }
        }
      }
    }
    return false;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final path = getBezierPath(start, end, startSide, endSide);

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = isSelected ? 3.5 : 1.5
      ..color = isPreview
          ? Colors.blue.withValues(alpha: 0.4)
          : isSelected
              ? Colors.blue.withValues(alpha: 0.8)
              : Colors.blue.withValues(alpha: 0.4);

    if (type == 'dashed') {
      final dashedPath = Path();
      const dashWidth = 8.0;
      const dashSpace = 8.0;
      for (final metric in path.computeMetrics()) {
        double distance = 0.0;
        bool draw = true;
        while (distance < metric.length) {
          final len = draw ? dashWidth : dashSpace;
          if (draw) {
            dashedPath.addPath(
              metric.extractPath(distance, distance + len),
              Offset.zero,
            );
          }
          distance += len;
          draw = !draw;
        }
      }
      canvas.drawPath(dashedPath, paint);
    } else {
      canvas.drawPath(path, paint);
    }

    if (type == 'arrow') { // Default is now solid, arrow must be explicitly set
      final metricsList = path.computeMetrics().toList();
      if (metricsList.isNotEmpty) {
        final metric = metricsList.first;
        // Draw arrow very close to the end (0.1px before) to avoid getTangentForOffset returning null
        final tangentOffset = max(0.0, metric.length - 0.1);
        final tangent = metric.getTangentForOffset(tangentOffset); 
        if (tangent != null) {
          final angle = -tangent.angle;
          final arrowSize = isSelected ? 12.0 : 10.0;
          final p1 = Offset(
            tangent.position.dx - arrowSize * cos(angle - pi / 6),
            tangent.position.dy + arrowSize * sin(angle - pi / 6),
          );
          final p2 = Offset(
            tangent.position.dx - arrowSize * cos(angle + pi / 6),
            tangent.position.dy + arrowSize * sin(angle + pi / 6),
          );

          final arrowPath = Path()
            ..moveTo(tangent.position.dx, tangent.position.dy)
            ..lineTo(p1.dx, p1.dy)
            ..lineTo(p2.dx, p2.dy)
            ..close();

          final arrowPaint = Paint()
            ..style = PaintingStyle.fill
            ..color = paint.color;
          
          canvas.drawPath(arrowPath, arrowPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant EdgePainter oldDelegate) {
    return oldDelegate.start != start ||
        oldDelegate.end != end ||
        oldDelegate.isPreview != isPreview ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.type != type;
  }
}
