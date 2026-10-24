import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

@immutable
class BonusActivity {
  const BonusActivity({required this.id, required this.label, required this.points});
  final String id;
  final String label;
  final int points;
}

/// All scoring rules in one place.
abstract final class ScoringRules {
  /// Bonus activities (A'araf only).
  static const List<BonusActivity> bonusActivities = [
    BonusActivity(id: 'quran', label: 'Read Quran', points: 2),
    BonusActivity(id: 'parents', label: 'Helped Parents', points: 2),
    BonusActivity(id: 'nolie', label: 'No Lying Today', points: 2),
    BonusActivity(id: 'helped', label: 'Helped Someone', points: 1),
    BonusActivity(id: 'dhikr', label: 'Daily Dhikr', points: 1),
  ];

  static const _faisalRow = <PrayerStatus, int>{
    PrayerStatus.solo: 1,
    PrayerStatus.jamaat: 2,
  };

  static const _table = <PersonId, Map<PrayerType, Map<PrayerStatus, int>>>{
    PersonId.faisal: {
      PrayerType.fajr: _faisalRow,
      PrayerType.dhuhr: _faisalRow,
      PrayerType.asr: _faisalRow,
      PrayerType.maghrib: _faisalRow,
      PrayerType.isha: _faisalRow,
    },
    PersonId.aaraf: {
      PrayerType.fajr: {PrayerStatus.prayed: 3},
      PrayerType.dhuhr: {PrayerStatus.prayed: 2},
      PrayerType.asr: {PrayerStatus.prayed: 2},
      PrayerType.maghrib: {PrayerStatus.prayed: 2},
      PrayerType.isha: {PrayerStatus.prayed: 3},
    },
    PersonId.kakon: {
      PrayerType.fajr: {PrayerStatus.prayed: 3},
      PrayerType.dhuhr: {PrayerStatus.prayed: 2},
      PrayerType.asr: {PrayerStatus.prayed: 2},
      PrayerType.maghrib: {PrayerStatus.prayed: 2},
      PrayerType.isha: {PrayerStatus.prayed: 2},
    },
  };

  /// Choices offered when logging a prayer.
  static List<PrayerStatus> optionsFor(PersonId person) => person == PersonId.faisal
      ? const [PrayerStatus.missed, PrayerStatus.solo, PrayerStatus.jamaat]
      : const [PrayerStatus.missed, PrayerStatus.prayed];

  static bool hasBonus(PersonId person) => person == PersonId.aaraf;

  static int prayerPoints(PersonId person, PrayerType prayer, PrayerStatus status) {
    if (status == PrayerStatus.missed) return 0;
    return _table[person]?[prayer]?[status] ?? 0;
  }

  static int maxPrayerPoints(PersonId person, PrayerType prayer) {
    final row = _table[person]![prayer]!;
    return row.values.reduce(math.max);
  }

  static int maxPrayerPointsPerDay(PersonId person) =>
      PrayerType.values.fold(0, (sum, p) => sum + maxPrayerPoints(person, p));

  static int get maxBonusPoints =>
      bonusActivities.fold(0, (sum, b) => sum + b.points);

  /// Highest possible total for one day (prayers + bonus where applicable).
  static int maxDailyPoints(PersonId person) =>
      maxPrayerPointsPerDay(person) + (hasBonus(person) ? maxBonusPoints : 0);

  static int bonusPoints(PersonId person, DayEntry? entry) {
    if (entry == null || !hasBonus(person)) return 0;
    var total = 0;
    for (final b in bonusActivities) {
      if (entry.bonus.contains(b.id)) total += b.points;
    }
    return total;
  }

  static int prayerPointsFor(PersonId person, DayEntry? entry) {
    if (entry == null) return 0;
    return PrayerType.values
        .fold(0, (sum, p) => sum + prayerPoints(person, p, entry.statusOf(p)));
  }

  static int entryPoints(PersonId person, DayEntry? entry) =>
      prayerPointsFor(person, entry) + bonusPoints(person, entry);
}
