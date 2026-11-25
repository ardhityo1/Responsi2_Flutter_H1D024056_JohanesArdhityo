import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../data/models/daily_forecast.dart';

/// Grafik garis suhu maksimum (atas) dan minimum (bawah) per hari.
class TemperatureLineChart extends StatelessWidget {
  final List<DailyForecast> days;
  final double itemWidth;
  final double height;

  const TemperatureLineChart({
    super.key,
    required this.days,
    required this.itemWidth,
    this.height = 62,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(days.length * itemWidth, height),
      painter: _TemperatureLinePainter(
        days: days,
        itemWidth: itemWidth,
      ),
    );
  }
}

class _TemperatureLinePainter extends CustomPainter {
  final List<DailyForecast> days;
  final double itemWidth;

  _TemperatureLinePainter({required this.days, required this.itemWidth});

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    final maxTemps = days.map((day) => day.temperatureMax).toList();
    final minTemps = days.map((day) => day.temperatureMin).toList();

    final maxPoints = _points(
      maxTemps,
      size,
      top: 5,
      bottom: size.height / 2 - 7,
    );
    final minPoints = _points(
      minTemps,
      size,
      top: size.height / 2 + 7,
      bottom: size.height - 5,
    );

    _drawLine(canvas, maxPoints, Colors.white);
    _drawLine(
      canvas,
      minPoints,
      Colors.white.withValues(alpha: 0.82),
    );
    _drawDots(canvas, maxPoints, Colors.white);
    _drawDots(
      canvas,
      minPoints,
      Colors.white.withValues(alpha: 0.9),
    );
  }

  List<Offset> _points(
    List<double> values,
    Size size, {
    required double top,
    required double bottom,
  }) {
    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final range = maxValue - minValue;

    return List.generate(values.length, (index) {
      final x = itemWidth * index + itemWidth / 2;
      final y = range.abs() < 0.1
          ? (top + bottom) / 2
          : bottom - ((values[index] - minValue) / range) * (bottom - top);
      return Offset(x, y);
    });
  }

  void _drawLine(Canvas canvas, List<Offset> points, Color color) {
    if (points.isEmpty) return;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final middleX = (current.dx + next.dx) / 2;
      path.cubicTo(
        middleX,
        current.dy,
        middleX,
        next.dy,
        next.dx,
        next.dy,
      );
    }
    canvas.drawPath(path, paint);
  }

  void _drawDots(Canvas canvas, List<Offset> points, Color color) {
    final paint = Paint()..color = color;
    for (final point in points) {
      canvas.drawCircle(point, 3.4, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TemperatureLinePainter oldDelegate) {
    return oldDelegate.days != days || oldDelegate.itemWidth != itemWidth;
  }
}
