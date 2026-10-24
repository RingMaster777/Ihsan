import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
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
    test('maximum daily prayer points per person', () {
      expect(ScoringRules.maxPrayerPointsPerDay(PersonId.faisal), 10);
      expect(ScoringRules.maxPrayerPointsPerDay(PersonId.aaraf), 12);
      expect(ScoringRules.maxPrayerPointsPerDay(PersonId.kakon), 11);
    });

    test('faisal scores alone=1 and jamaat=2', () {
      expect(ScoringRules.entryPoints(PersonId.faisal, _all(PrayerStatus.solo)), 5);
      expect(ScoringRules.entryPoints(PersonId.faisal, _all(PrayerStatus.jamaat)), 10);
    });

    test('missed and unset prayers score zero', () {
      const entry = DayEntry(prayers: {PrayerType.fajr: PrayerStatus.missed});
      expect(ScoringRules.entryPoints(PersonId.kakon, entry), 0);
      expect(ScoringRules.entryPoints(PersonId.kakon, null), 0);
    });

    test('bonus points only count for aaraf', () {
      final entry = _all(PrayerStatus.prayed).copyWith(bonus: {'quran', 'dhikr'});
      expect(ScoringRules.entryPoints(PersonId.aaraf, entry), 12 + 3);
      expect(ScoringRules.entryPoints(PersonId.kakon, entry), 11);
      expect(ScoringRules.maxDailyPoints(PersonId.aaraf), 12 + 8);
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
      final s = StatsCalculator.month(PersonId.faisal, entries, 2025, 3, today);
      expect(s.points, 15);
      expect(s.daysLogged, 2);
      expect(s.daysElapsed, 4);
      expect(s.maxPossible, 40);
      expect(s.achievementPercent, 38);
      expect(s.average, 8);
      expect(s.jamaatCount, 5);
    });
  });

  group('TrackerRepository', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('round-trips data', () async {
      final repo = TrackerRepository(await SharedPreferences.getInstance());
      final data = TrackerData(
        activePerson: PersonId.aaraf,
        entries: {
          PersonId.aaraf: {
            '2025-03-01': _all(PrayerStatus.prayed).copyWith(bonus: {'quran'}, updatedAt: 5),
          },
        },
      );
      await repo.save(data);
      final loaded = repo.load();
      expect(loaded.activePerson, PersonId.aaraf);
      expect(loaded.entriesFor(PersonId.aaraf)['2025-03-01'], data.entries[PersonId.aaraf]!['2025-03-01']);
    });

    test('reads the legacy HTML backup format', () async {
      final repo = TrackerRepository(await SharedPreferences.getInstance());
      final data = repo.parseBackup(
        '{"person":"aaraf","aaraf":{"entries":{"2025-03-01":'
        '{"fajr":"prayed","isha":"missed","bonus":["quran"],"ts":1}}}}',
      );
      final e = data.entriesFor(PersonId.aaraf)['2025-03-01']!;
      expect(e.statusOf(PrayerType.fajr), PrayerStatus.prayed);
      expect(e.isChosen(PrayerType.dhuhr), isFalse);
      expect(e.bonus, {'quran'});
    });

    test('rejects files that are not backups', () async {
      final repo = TrackerRepository(await SharedPreferences.getInstance());
      expect(() => repo.parseBackup('[1,2]'), throwsFormatException);
      expect(() => repo.parseBackup('{"hello":1}'), throwsFormatException);
      expect(() => repo.parseBackup('nope'), throwsFormatException);
    });
  });
}
