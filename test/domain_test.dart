import 'package:flutter/material.dart' show Color;
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_for_allah/core/services/prayer_times_service.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/tracker/domain/achievements.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/data/tracker_repository.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';
import 'package:tasks_for_allah/features/tracker/domain/stats.dart';

DayEntry _all(PrayerStatus s) => DayEntry(
      prayers: {for (final p in PrayerType.values) p: s},
    );

void main() {
  group('ScoringRules', () {
    test('maximum daily prayer points per profile', () {
      expect(ScoringRules.maxPrayerPointsPerDay(ProfilePresets.faisal), 10);
      expect(ScoringRules.maxPrayerPointsPerDay(ProfilePresets.aaraf), 12);
      expect(ScoringRules.maxPrayerPointsPerDay(ProfilePresets.kakon), 11);
    });

    test('jamaat mode scores alone=1 and jamaat=2', () {
      expect(ScoringRules.entryPoints(ProfilePresets.faisal, _all(PrayerStatus.solo)), 5);
      expect(ScoringRules.entryPoints(ProfilePresets.faisal, _all(PrayerStatus.jamaat)), 10);
    });

    test('missed and unset prayers score zero', () {
      const entry = DayEntry(prayers: {PrayerType.fajr: PrayerStatus.missed});
      expect(ScoringRules.entryPoints(ProfilePresets.kakon, entry), 0);
      expect(ScoringRules.entryPoints(ProfilePresets.kakon, null), 0);
    });

    test('bonus points follow the profile, halves included', () {
      final entry = _all(PrayerStatus.prayed).copyWith(bonus: {'quran', 'dhikr'});
      // 12 prayer pts + quran(1) + dhikr(0.5)
      expect(ScoringRules.entryPoints(ProfilePresets.aaraf, entry), 13.5);
      // Kakon has no dhikr bonus: 11 prayer pts + quran(1) only.
      expect(ScoringRules.entryPoints(ProfilePresets.kakon, entry), 12);
      // A'araf: 12 prayer pts + 4 bonus max (quran 1 + six halves).
      expect(ScoringRules.maxDailyPoints(ProfilePresets.aaraf), 16);
    });

    test('custom profiles are scored by their own mode', () {
      final child = ProfilePresets.blank(TrackingMode.simple);
      expect(ScoringRules.entryPoints(child, _all(PrayerStatus.prayed)), 12);
      final adult = ProfilePresets.blank(TrackingMode.jamaat);
      expect(ScoringRules.optionsFor(adult).length, 3);
      expect(ScoringRules.optionsFor(child).length, 2);
    });
  });

  group('formatPoints', () {
    test('prints halves, hides whole decimals', () {
      expect(formatPoints(8), '8');
      expect(formatPoints(8.5), '8.5');
      expect(formatPoints(7.49999), '7.5'); // snaps away float noise
      expect(formatPoints(0), '0');
    });
  });

  group('Profile', () {
    test('json round-trip keeps scoring config', () {
      const profile = ProfilePresets.aaraf;
      final restored = Profile.fromJson(profile.toJson());
      expect(restored.id, profile.id);
      expect(restored.mode, TrackingMode.simple);
      expect(restored.simplePoints[PrayerType.isha], 3);
      expect(restored.bonus['parents'], 0.5);
      expect(ScoringRules.maxDailyPoints(restored), 16);
    });

    test('initials come from the first letters of the name', () {
      const profile = Profile(id: 'x', name: 'Abu Bakr', role: '', accent: Color(0x00000000), mode: TrackingMode.jamaat);
      expect(profile.initials, 'AB');
      const single = Profile(id: 'x', name: 'maryam', role: '', accent: Color(0x00000000), mode: TrackingMode.jamaat);
      expect(single.initials, 'M');
    });
  });

  group('StatsCalculator.streak', () {
    final today = DateTime(2025, 3, 10);
    Map<String, DayEntry> entriesFor(List<int> daysAgo, {DayEntry? entry}) => {
          for (final d in daysAgo)
            toDateKey(addDays(today, -d)): entry ?? _all(PrayerStatus.prayed),
        };

    test('counts consecutive days ending today', () {
      expect(StatsCalculator.streak(entriesFor([0, 1, 2]), today), 3);
    });

    test('still counts when today is not logged yet', () {
      expect(StatsCalculator.streak(entriesFor([1, 2]), today), 2);
    });

    test('a gap or an all-missed day breaks the streak', () {
      expect(StatsCalculator.streak(entriesFor([0, 1, 3]), today), 2);
      final withMissed = {
        ...entriesFor([0, 2]),
        toDateKey(addDays(today, -1)): _all(PrayerStatus.missed),
      };
      expect(StatsCalculator.streak(withMissed, today), 1);
    });
  });

  group('StatsCalculator.month', () {
    test('sums points and computes achievement', () {
      final today = DateTime(2025, 3, 4);
      final entries = {
        '2025-03-01': _all(PrayerStatus.jamaat),
        '2025-03-02': _all(PrayerStatus.solo),
        '2025-02-28': _all(PrayerStatus.jamaat), // other month
      };
      final s = StatsCalculator.month(ProfilePresets.faisal, entries, 2025, 3, today);
      expect(s.points, 15);
      expect(s.daysLogged, 2);
      expect(s.daysElapsed, 4);
      expect(s.maxPossible, 4 * 13); // 10 prayer + 3 bonus per day
      expect(s.achievementPercent, 29);
      expect(s.average, 8);
      expect(s.jamaatCount, 5);
    });
  });

  group('PrayerTimesService', () {
    test('orders the five prayers sanely for Dhaka', () {
      final result = PrayerTimesService.compute(
        DateTime(2026, 11, 4),
        lat: 23.8103,
        lng: 90.4125,
        method: CalcMethod.karachi,
        madhab: AsrMadhab.hanafi,
      );
      expect(result.times[PrayerType.fajr]!.isBefore(result.sunrise), isTrue);
      expect(result.sunrise.isBefore(result.times[PrayerType.dhuhr]!), isTrue);
      expect(result.times[PrayerType.dhuhr]!.isBefore(result.times[PrayerType.asr]!), isTrue);
      expect(result.times[PrayerType.asr]!.isBefore(result.times[PrayerType.maghrib]!), isTrue);
      expect(result.times[PrayerType.maghrib]!.isBefore(result.times[PrayerType.isha]!), isTrue);
      // Fajr is around 5am, Isha around 6-7pm in Dhaka.
      expect(result.times[PrayerType.fajr]!.hour, inInclusiveRange(4, 6));
      expect(result.times[PrayerType.isha]!.hour, inInclusiveRange(17, 20));
    });

    test('finds the next prayer after a given moment', () {
      final result = PrayerTimesService.compute(
        DateTime(2026, 11, 4),
        lat: 23.8103,
        lng: 90.4125,
        method: CalcMethod.karachi,
        madhab: AsrMadhab.hanafi,
      );
      final afterFajr = result.timeFor(PrayerType.fajr).add(const Duration(minutes: 30));
      expect(result.nextAfter(afterFajr), PrayerType.dhuhr);
      // After Isha, everything has passed and the next is tomorrow's Fajr.
      final afterIsha = result.timeFor(PrayerType.isha).add(const Duration(minutes: 30));
      expect(result.nextAfter(afterIsha), PrayerType.fajr);
    });
  });

  group('Achievements', () {
    test('progress and unlocking derive from entries', () {
      final entries = {
        '2025-03-01': _all(PrayerStatus.prayed),
        '2025-03-02': _all(PrayerStatus.prayed),
        '2025-03-03': _all(PrayerStatus.prayed),
      };
      final list = Achievements.forProfile(ProfilePresets.kakon, entries);
      final byId = {for (final a in list) a.def.id: a};

      expect(byId['first_step']!.unlocked, isTrue);
      expect(byId['streak_3']!.unlocked, isTrue);
      expect(byId['streak_7']!.progress, 3);
      expect(byId['perfect_1']!.unlocked, isTrue);
      expect(byId['week_logged']!.unlocked, isFalse);
      // Jamaat badges don't apply to simple-mode profiles.
      expect(byId.containsKey('jamaat_25'), isFalse);
    });

    test('jamaat badges appear for jamaat-mode profiles', () {
      final list = Achievements.forProfile(ProfilePresets.faisal, {
        '2025-03-01': _all(PrayerStatus.jamaat),
      });
      final byId = {for (final a in list) a.def.id: a};
      expect(byId['jamaat_25']!.progress, 5);
      expect(byId['jamaat_25']!.unlocked, isFalse);
    });
  });

  group('TrackerRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trips data with profiles', () async {
      final repo = TrackerRepository(await SharedPreferences.getInstance());
      final data = TrackerData(
        profiles: ProfilePresets.seeds.toList(),
        activePerson: 'aaraf',
        entries: {
          'aaraf': {
            '2025-03-01': _all(PrayerStatus.prayed).copyWith(bonus: {'quran'}, updatedAt: 5),
          },
        },
      );
      await repo.save(data);
      final loaded = repo.load();
      expect(loaded.activePerson, 'aaraf');
      expect(loaded.profiles.length, 3);
      expect(loaded.entriesFor('aaraf')['2025-03-01'], data.entries['aaraf']!['2025-03-01']);
    });

    test('reads the legacy HTML backup format and seeds the family', () async {
      final repo = TrackerRepository(await SharedPreferences.getInstance());
      final data = repo.parseBackup(
        '{"person":"aaraf","aaraf":{"entries":{"2025-03-01":'
        '{"fajr":"prayed","isha":"missed","bonus":["quran"],"ts":1}}}}',
      );
      final e = data.entriesFor('aaraf')['2025-03-01']!;
      expect(e.statusOf(PrayerType.fajr), PrayerStatus.prayed);
      expect(e.isChosen(PrayerType.dhuhr), isFalse);
      expect(e.bonus, {'quran'});
      expect(data.profiles.length, 3);
      expect(data.profiles.any((p) => p.id == 'aaraf'), isTrue);
    });

    test('rejects files that are not backups', () async {
      final repo = TrackerRepository(await SharedPreferences.getInstance());
      expect(() => repo.parseBackup('[1,2]'), throwsFormatException);
      expect(() => repo.parseBackup('{"hello":1}'), throwsFormatException);
      expect(() => repo.parseBackup('nope'), throwsFormatException);
    });
  });
}
