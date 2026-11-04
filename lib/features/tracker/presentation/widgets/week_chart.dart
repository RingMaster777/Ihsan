import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/domain/stats.dart';

/// Animated bar chart of the last few days' points.
class WeekChart extends StatelessWidget {
  const WeekChart({super.key, required this.days, required this.maxPoints});

  final List<DayPoints> days;
  final double maxPoints;

  static const double _barArea = 92;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SizedBox(
      height: _barArea + 46,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(child: _Bar(day: days[i], index: i, maxPoints: maxPoints, palette: p)),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.day,
    required this.index,
    required this.maxPoints,
    required this.palette,
  });

  final DayPoints day;
  final int index;
  final double maxPoints;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    final p = palette;
    final pts = day.points;
    final target = pts == null
        ? 6.0
        : math.max(8.0, (pts / math.max(1.0, maxPoints)) * WeekChart._barArea);

    final gradient = day.isToday
        ? p.greenGradient.reversed.toList()
        : [p.ctaGradient.last, p.ctaGradient.first];

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          pts == null ? '' : formatPoints(pts),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: day.isToday ? p.primaryStrong : p.textBody,
          ),
        ),
        const SizedBox(height: 4),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: Duration(milliseconds: 550 + index * 70),
          curve: Curves.easeOutCubic,
          builder: (context, h, _) => Container(
            width: 18,
            height: math.max(h, 0),
            decoration: BoxDecoration(
              gradient: pts == null ? null : LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: gradient,
              ),
              color: pts == null ? p.track : null,
              borderRadius: BorderRadius.circular(7),
            ),
          ),
        ),
        const SizedBox(height: 7),
        Text(
          weekdayInitial(day.date),
          style: TextStyle(
            fontSize: 11,
            fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
            color: day.isToday ? p.primary : p.textMuted,
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}
