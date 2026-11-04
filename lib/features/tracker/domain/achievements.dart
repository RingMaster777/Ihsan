import 'package:flutter/foundation.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';

enum AchievementMetric { loggedDays, perfectDays, bestStreak, fajrDays, jamaatCount, bonusCount, totalPoints }

@immutable
class AchievementDef {
  const AchievementDef(
    this.id,
    this.title,
    this.description,
    this.metric,
    this.target,
  );

  final String id;
  final String title;
  final String description;
  final AchievementMetric metric;
  final int target;
}

@immutable
class Achievement {
  const Achievement({required this.def, required this.progress});
  final AchievementDef def;
  final int progress;

  bool get unlocked => progress >= def.target;
}

/// Badges derived entirely from a profile's entries — nothing extra is stored,
/// so they can never drift out of sync with the record.
abstract final class Achievements {
  static const List<AchievementDef> defs = [
    AchievementDef('first_step', 'First Step', 'Log your first day', AchievementMetric.loggedDays, 1),
    AchievementDef('week_logged', 'Getting Going', 'Log 7 days', AchievementMetric.loggedDays, 7),
    AchievementDef('month_logged', 'True Habit', 'Log 30 days', AchievementMetric.loggedDays, 30),
    AchievementDef('perfect_1', 'Perfect Day', 'Pray all five in one day', AchievementMetric.perfectDays, 1),
    AchievementDef('perfect_7', 'Week of Light', '7 perfect days', AchievementMetric.perfectDays, 7),
    AchievementDef('perfect_30', 'Month of Light', '30 perfect days', AchievementMetric.perfectDays, 30),
    AchievementDef('streak_3', 'Habit Forming', '3-day streak', AchievementMetric.bestStreak, 3),
    AchievementDef('streak_7', 'One Week Strong', '7-day streak', AchievementMetric.bestStreak, 7),
    AchievementDef('streak_30', 'Steadfast', '30-day streak', AchievementMetric.bestStreak, 30),
    AchievementDef('streak_100', 'Legend', '100-day streak', AchievementMetric.bestStreak, 100),
    AchievementDef('fajr_10', 'Early Bird', 'Pray Fajr on 10 days', AchievementMetric.fajrDays, 10),
    AchievementDef('fajr_100', 'Dawn Regular', 'Pray Fajr on 100 days', AchievementMetric.fajrDays, 100),
    AchievementDef('jamaat_25', 'In Congregation', '25 prayers in jamaat', AchievementMetric.jamaatCount, 25),
    AchievementDef('jamaat_100', 'Jamaat Devotee', '100 prayers in jamaat', AchievementMetric.jamaatCount, 100),
    AchievementDef('bonus_25', 'Good Deeds Collector', 'Complete 25 bonus deeds', AchievementMetric.bonusCount, 25),
    AchievementDef('points_100', 'Century Club', 'Earn 100 points', AchievementMetric.totalPoints, 100),
    AchievementDef('points_500', 'Point Master', 'Earn 500 points', AchievementMetric.totalPoints, 500),
    AchievementDef('points_1000', '1000 Club', 'Earn 1000 points', AchievementMetric.totalPoints, 1000),
  ];

  /// All achievements with live progress for [profile].
  static List<Achievement> forProfile(Profile profile, Map<String, DayEntry> entries) {
    var loggedDays = 0, perfectDays = 0, fajrDays = 0, jamaatCount = 0, bonusCount = 0;
    var totalPoints = 0.0;
    var bestStreak = 0;
    var run = 0;
    DateTime? previous;

    final dates = entries.keys.toList()..sort();
    for (final key in dates) {
      final date = tryParseDateKey(key);
      final entry = entries[key]!;
      loggedDays++;
      if (entry.isPerfect) perfectDays++;
      if (entry.statusOf(PrayerType.fajr) != PrayerStatus.missed) fajrDays++;
      for (final prayer in PrayerType.values) {
        if (entry.statusOf(prayer) == PrayerStatus.jamaat) jamaatCount++;
      }
      bonusCount += entry.bonus.length;
      totalPoints += ScoringRules.entryPoints(profile, entry);

      if (date != null && previous != null && date.difference(previous).inDays == 1) {
        run++;
      } else {
        run = 1;
      }
      if (run > bestStreak) bestStreak = run;
      if (date != null) previous = date;
    }

    int metric(AchievementMetric m) => switch (m) {
          AchievementMetric.loggedDays => loggedDays,
          AchievementMetric.perfectDays => perfectDays,
          AchievementMetric.bestStreak => bestStreak,
          AchievementMetric.fajrDays => fajrDays,
          AchievementMetric.jamaatCount => jamaatCount,
          AchievementMetric.bonusCount => bonusCount,
          AchievementMetric.totalPoints => totalPoints.round(),
        };

    return [
      for (final def in defs)
        // Jamaat badges are unreachable in simple mode — don't tease them.
        if (def.metric != AchievementMetric.jamaatCount || profile.mode == TrackingMode.jamaat)
          Achievement(def: def, progress: metric(def.metric)),
    ];
  }
}
