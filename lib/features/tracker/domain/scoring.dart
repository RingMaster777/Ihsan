import 'package:flutter/foundation.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

@immutable
class BonusActivity {
  const BonusActivity({required this.id, required this.label, required this.points});
  final String id;
  final String label;
  final double points;
}

/// Every bonus activity the app knows about, in display order. Which of them
/// a profile uses (and their points) is stored on the profile itself.
abstract final class BonusCatalog {
  static const Map<String, String> labels = {
    'quran': 'Read Quran',
    'parents': 'Helped Parents',
    'nolie': 'No Lying Today',
    'helped': 'Helped Someone',
    'dhikr': 'Daily Dhikr',
    'studies': 'Completed Studies',
    'exercise': 'Exercise',
    'fasting': 'Fasting',
  };

  static Iterable<String> get ids => labels.keys;

  /// Points an activity is worth when enabled for a profile of [mode].
  static double defaultPoints(String id, TrackingMode mode) =>
      mode == TrackingMode.simple && id != 'quran' ? 0.5 : 1.0;
}

/// All scoring rules in one place, resolved per profile.
abstract final class ScoringRules {
  /// Choices offered when logging a prayer.
  static List<PrayerStatus> optionsFor(Profile profile) =>
      profile.mode == TrackingMode.jamaat
          ? const [PrayerStatus.missed, PrayerStatus.solo, PrayerStatus.jamaat]
          : const [PrayerStatus.missed, PrayerStatus.prayed];

  static int prayerPoints(Profile profile, PrayerType prayer, PrayerStatus status) {
    if (status == PrayerStatus.missed) return 0;
    return switch (profile.mode) {
      TrackingMode.jamaat => status == PrayerStatus.jamaat ? 2 : 1,
      TrackingMode.simple => profile.simplePoints[prayer] ?? 0,
    };
  }

  static int maxPrayerPoints(Profile profile, PrayerType prayer) => switch (profile.mode) {
        TrackingMode.jamaat => 2,
        TrackingMode.simple => profile.simplePoints[prayer] ?? 0,
      };

  static int maxPrayerPointsPerDay(Profile profile) => PrayerType.values
      .fold(0, (sum, p) => sum + maxPrayerPoints(profile, p));

  /// This profile's enabled bonus activities, in catalog order.
  static List<BonusActivity> bonusFor(Profile profile) => [
        for (final id in BonusCatalog.ids)
          if (profile.bonus.containsKey(id))
            BonusActivity(
              id: id,
              label: BonusCatalog.labels[id]!,
              points: profile.bonus[id]!,
            ),
      ];

  static bool hasBonus(Profile profile) => profile.bonus.isNotEmpty;

  static double maxBonusPoints(Profile profile) =>
      bonusFor(profile).fold(0, (sum, b) => sum + b.points);

  static double bonusPoints(Profile profile, DayEntry? entry) {
    if (entry == null) return 0;
    var total = 0.0;
    for (final b in bonusFor(profile)) {
      if (entry.bonus.contains(b.id)) total += b.points;
    }
    return total;
  }

  static int prayerPointsFor(Profile profile, DayEntry? entry) {
    if (entry == null) return 0;
    return PrayerType.values
        .fold(0, (sum, p) => sum + prayerPoints(profile, p, entry.statusOf(p)));
  }

  /// Highest possible total for one day (prayers + bonus).
  static double maxDailyPoints(Profile profile) =>
      maxPrayerPointsPerDay(profile) + maxBonusPoints(profile);

  static double entryPoints(Profile profile, DayEntry? entry) =>
      prayerPointsFor(profile, entry) + bonusPoints(profile, entry);
}

/// "8" for whole numbers, "8.5" for halves (snaps away floating-point noise).
String formatPoints(double value) {
  final snapped = (value * 2).roundToDouble() / 2;
  return snapped == snapped.roundToDouble()
      ? snapped.toInt().toString()
      : snapped.toStringAsFixed(1);
}
