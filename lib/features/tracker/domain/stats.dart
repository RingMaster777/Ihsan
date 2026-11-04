import 'package:flutter/foundation.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';

@immutable
class PrayerBreakdown {
  const PrayerBreakdown({
    required this.prayer,
    required this.prayedCount,
    required this.points,
    required this.loggedDays,
  });
  final PrayerType prayer;
  final int prayedCount;
  final int points;
  final int loggedDays;

  double get rate => loggedDays == 0 ? 0 : prayedCount / loggedDays;
}

@immutable
class MonthSummary {
  const MonthSummary({
    required this.points,
    required this.daysLogged,
    required this.daysElapsed,
    required this.maxPossible,
    required this.breakdown,
    required this.jamaatCount,
    required this.prayedTotal,
  });

  final double points;
  final int daysLogged;
  final int daysElapsed;
  final double maxPossible;
  final List<PrayerBreakdown> breakdown;
  final int jamaatCount;
  final int prayedTotal;

  int get average => daysLogged == 0 ? 0 : (points / daysLogged).round();
  int get achievementPercent =>
      maxPossible == 0 ? 0 : (points * 100 / maxPossible).round().clamp(0, 100);
}

@immutable
class DayPoints {
  const DayPoints({required this.date, required this.points, required this.isToday});
  final DateTime date;

  /// `null` when nothing was logged that day.
  final double? points;
  final bool isToday;
}

abstract final class StatsCalculator {
  /// Consecutive days (ending today, or yesterday if today isn't logged yet)
  /// with at least one prayer performed.
  static int streak(Map<String, DayEntry> entries, DateTime today) {
    var cursor = dateOnly(today);
    if (entries[toDateKey(cursor)] == null) cursor = addDays(cursor, -1);
    var count = 0;
    for (var i = 0; i < 366; i++) {
      final entry = entries[toDateKey(cursor)];
      if (entry == null || !entry.hasAnyPrayer) break;
      count++;
      cursor = addDays(cursor, -1);
    }
    return count;
  }

  /// [month] is 1-based.
  static Map<String, DayEntry> entriesInMonth(
    Map<String, DayEntry> entries, int year, int month,
  ) {
    final prefix = '$year-${month.toString().padLeft(2, '0')}-';
    return {
      for (final e in entries.entries)
        if (e.key.startsWith(prefix)) e.key: e.value,
    };
  }

  static double monthPoints(
    Profile profile, Map<String, DayEntry> entries, int year, int month,
  ) {
    var total = 0.0;
    for (final e in entriesInMonth(entries, year, month).values) {
      total += ScoringRules.entryPoints(profile, e);
    }
    return total;
  }

  static MonthSummary month(
    Profile profile,
    Map<String, DayEntry> entries,
    int year,
    int month,
    DateTime today,
  ) {
    final monthEntries = entriesInMonth(entries, year, month).values.toList();
    final points =
        monthEntries.fold(0.0, (s, e) => s + ScoringRules.entryPoints(profile, e));

    final int elapsed;
    if (year == today.year && month == today.month) {
      elapsed = today.day;
    } else if (DateTime(year, month).isAfter(today)) {
      elapsed = 0;
    } else {
      elapsed = daysInMonth(year, month);
    }

    var jamaat = 0;
    var prayedTotal = 0;
    final breakdown = <PrayerBreakdown>[];
    for (final prayer in PrayerType.values) {
      var count = 0;
      var pts = 0;
      for (final e in monthEntries) {
        final status = e.statusOf(prayer);
        if (status == PrayerStatus.missed) continue;
        count++;
        pts += ScoringRules.prayerPoints(profile, prayer, status);
        if (status == PrayerStatus.jamaat) jamaat++;
      }
      prayedTotal += count;
      breakdown.add(PrayerBreakdown(
        prayer: prayer,
        prayedCount: count,
        points: pts,
        loggedDays: monthEntries.length,
      ));
    }

    return MonthSummary(
      points: points,
      daysLogged: monthEntries.length,
      daysElapsed: elapsed,
      maxPossible: elapsed * ScoringRules.maxDailyPoints(profile),
      breakdown: breakdown,
      jamaatCount: jamaat,
      prayedTotal: prayedTotal,
    );
  }

  /// The last [count] days ending today, oldest first.
  static List<DayPoints> lastDays(
    Profile profile,
    Map<String, DayEntry> entries,
    DateTime today,
    int count,
  ) {
    return [
      for (var i = count - 1; i >= 0; i--)
        () {
          final date = addDays(today, -i);
          final entry = entries[toDateKey(date)];
          return DayPoints(
            date: date,
            points: entry == null ? null : ScoringRules.entryPoints(profile, entry),
            isToday: i == 0,
          );
        }(),
    ];
  }
}
