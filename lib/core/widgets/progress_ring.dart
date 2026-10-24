import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Animated circular progress indicator with a gradient stroke.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.size,
    required this.trackColor,
    required this.gradient,
    this.strokeWidth = 10,
    this.child,
    this.duration = const Duration(milliseconds: 1100),
  });

  final double progress;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradient;
  final Widget? child;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0, end: progress.clamp(0.0, 1.0)),
        duration: duration,
        curve: Curves.easeOutCubic,
        child: child,
        builder: (context, value, child) => CustomPaint(
          painter: _RingPainter(
            value: value,
            strokeWidth: strokeWidth,
            trackColor: trackColor,
            gradient: gradient,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradient,
  });

  final double value;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradient;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (size.shortestSide - strokeWidth) / 2;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = trackColor,
    );

    if (value <= 0) return;
    final arcRect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: 0,
        endAngle: math.pi * 2,
        colors: gradient.length > 1 ? gradient : [gradient.first, gradient.first],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(arcRect);
    canvas.drawArc(arcRect, -math.pi / 2, math.pi * 2 * value, false, paint);
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value ||
      old.strokeWidth != strokeWidth ||
      old.trackColor != trackColor ||
      old.gradient != gradient;
}
