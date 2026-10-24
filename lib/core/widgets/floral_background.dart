import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';

/// Soft aqua gradient with a tiled floral pattern (ported from the HTML prototype).
class FloralBackground extends StatelessWidget {
  const FloralBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: p.bgGradient,
          stops: const [0, 0.4, 0.7, 1],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(child: CustomPaint(painter: _GlowPainter(dark: p.isDark))),
          RepaintBoundary(child: CustomPaint(painter: _FloralPainter(dark: p.isDark))),
          child,
        ],
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final k = dark ? 0.35 : 1.0;
    void glow(double ax, double ay, double r, Color color, double alpha) {
      final center = Offset(size.width * ax, size.height * ay);
      final radius = size.shortestSide * r;
      final paint = Paint()
        ..shader = RadialGradient(
          colors: [color.withOpacity(alpha * k), color.withOpacity(0)],
        ).createShader(Rect.fromCircle(center: center, radius: radius));
      canvas.drawCircle(center, radius, paint);
    }

    glow(0.10, 0.10, 0.95, const Color(0xFF82DCD2), 0.28);
    glow(0.92, 0.06, 0.85, const Color(0xFF64C8E6), 0.22);
    glow(0.05, 0.80, 0.85, const Color(0xFF78E6C8), 0.20);
    glow(0.92, 0.90, 0.85, const Color(0xFF5AD2DC), 0.18);
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.dark != dark;
}

class _FloralPainter extends CustomPainter {
  const _FloralPainter({required this.dark});
  final bool dark;

  static const double _tile = 380;

  @override
  void paint(Canvas canvas, Size size) {
    final cols = (size.width / _tile).ceil();
    final rows = (size.height / _tile).ceil();
    for (var r = 0; r < rows; r++) {
      for (var c = 0; c < cols; c++) {
        canvas.save();
        canvas.translate(c * _tile, r * _tile);
        _paintTile(canvas);
        canvas.restore();
      }
    }
  }

  void _paintTile(Canvas canvas) {
    final k = dark ? 0.4 : 1.0;

    void flower(double x, double y, int petals, double rx, double ry, double off,
        Color color, double alpha, double centerR, Color centerColor, double centerAlpha) {
      canvas.save();
      canvas.translate(x, y);
      final paint = Paint()..color = color.withOpacity(alpha * k);
      for (var i = 0; i < petals; i++) {
        canvas.save();
        canvas.rotate(i * 2 * math.pi / petals);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(0, -off), width: rx * 2, height: ry * 2),
          paint,
        );
        canvas.restore();
      }
      canvas.drawCircle(
        Offset.zero,
        centerR,
        Paint()..color = centerColor.withOpacity(centerAlpha * k),
      );
      canvas.restore();
    }

    void star(double x, double y, double r, Color color, double alpha) {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final radius = i.isEven ? r : r * 0.4;
        final angle = -math.pi / 2 + i * math.pi / 5;
        final pt = Offset(x + radius * math.cos(angle), y + radius * math.sin(angle));
        if (i == 0) {
          path.moveTo(pt.dx, pt.dy);
        } else {
          path.lineTo(pt.dx, pt.dy);
        }
      }
      path.close();
      canvas.drawPath(path, Paint()..color = color.withOpacity(alpha * k));
    }

    void dot(double x, double y, double r, Color color, double alpha) {
      canvas.drawCircle(Offset(x, y), r, Paint()..color = color.withOpacity(alpha * k));
    }

    const yellow = Color(0xFFFFE870);
    flower(58, 58, 5, 6, 13, 14, const Color(0xFF80D8C8), 0.30, 5, yellow, 0.40);
    flower(230, 100, 6, 5, 10, 11, const Color(0xFF60C8D8), 0.28, 4, yellow, 0.38);
    flower(115, 268, 4, 7, 11, 11, const Color(0xFF90E0C0), 0.26, 4.5, yellow, 0.38);
    flower(310, 230, 8, 3, 8, 9, const Color(0xFFA8EAD8), 0.28, 4, yellow, 0.40);

    star(170, 42, 9, const Color(0xFF70D0C0), 0.28);
    star(48, 175, 7, const Color(0xFF50C8D8), 0.26);
    star(290, 58, 6, const Color(0xFF88DCC8), 0.30);
    star(190, 310, 8, const Color(0xFF68C8D0), 0.26);
    star(340, 155, 5, const Color(0xFF90DCC0), 0.30);

    dot(148, 22, 2.5, const Color(0xFF68C8C8), 0.28);
    dot(338, 320, 2, const Color(0xFF78D0C0), 0.26);
    dot(28, 330, 3, const Color(0xFF60C0D8), 0.28);
    dot(360, 80, 2.5, const Color(0xFF80D8C0), 0.26);
  }

  @override
  bool shouldRepaint(_FloralPainter old) => old.dark != dark;
}
