import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/data/tracker_repository.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';
import 'package:tasks_for_allah/features/tracker/domain/stats.dart';

/// Overridden in `main()` once SharedPreferences has loaded.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden'),
);

final trackerRepositoryProvider = Provider<TrackerRepository>(
  (ref) => TrackerRepository(ref.watch(sharedPreferencesProvider)),
);

/// The current time. Refreshed when the app resumes so "today" stays correct.
final nowProvider = StateProvider<DateTime>((ref) => DateTime.now());
final todayProvider = Provider<DateTime>((ref) => dateOnly(ref.watch(nowProvider)));

class TrackerNotifier extends Notifier<TrackerData> {
  late TrackerRepository _repo;

  @override
  TrackerData build() {
    _repo = ref.watch(trackerRepositoryProvider);
    return _repo.load();
  }

  Future<void> selectPerson(PersonId id) => _commit(state.copyWith(activePerson: id));

  Future<void> clearPerson() => _commit(state.copyWith(clearActivePerson: true));

  Future<void> saveEntry(String dateKey, DayEntry entry) async {
    final person = state.activePerson;
    if (person == null) return;
    final personEntries = Map<String, DayEntry>.of(state.entriesFor(person))
      ..[dateKey] = entry;
    final next = Map<PersonId, Map<String, DayEntry>>.of(state.entries)
      ..[person] = personEntries;
    await _commit(state.copyWith(entries: next));
  }

  /// Replaces all entries with the ones from [backup]; keeps who is using the device.
  Future<void> restore(TrackerData backup) => _commit(TrackerData(
        activePerson: state.activePerson ?? backup.activePerson,
        entries: backup.entries,
      ));

  Future<void> resetAll() =>
      _commit(TrackerData(activePerson: state.activePerson));

  Future<void> _commit(TrackerData next) async {
    state = next;
    await _repo.save(next);
  }
}

final trackerProvider =
    NotifierProvider<TrackerNotifier, TrackerData>(TrackerNotifier.new);

final activePersonProvider = Provider<PersonId?>(
  (ref) => ref.watch(trackerProvider.select((d) => d.activePerson)),
);

final activeProfileProvider = Provider<Person?>((ref) {
  final id = ref.watch(activePersonProvider);
  return id == null ? null : Person.of(id);
});

/// Entries of the active person.
final entriesProvider = Provider<Map<String, DayEntry>>((ref) {
  final data = ref.watch(trackerProvider);
  final id = data.activePerson;
  return id == null ? const {} : data.entriesFor(id);
});

final streakProvider = Provider<int>((ref) {
  return StatsCalculator.streak(ref.watch(entriesProvider), ref.watch(todayProvider));
});

typedef MonthKey = ({int year, int month});

final monthSummaryProvider = Provider.family<MonthSummary, MonthKey>((ref, key) {
  final person = ref.watch(activePersonProvider);
  if (person == null) {
    return const MonthSummary(
      points: 0,
      daysLogged: 0,
      daysElapsed: 0,
      maxPossible: 0,
      breakdown: [],
      jamaatCount: 0,
      prayedTotal: 0,
    );
  }
  return StatsCalculator.month(
    person,
    ref.watch(entriesProvider),
    key.year,
    key.month,
    ref.watch(todayProvider),
  );
});

final lastDaysProvider = Provider.family<List<DayPoints>, int>((ref, count) {
  final person = ref.watch(activePersonProvider);
  if (person == null) return const [];
  return StatsCalculator.lastDays(
    person,
    ref.watch(entriesProvider),
    ref.watch(todayProvider),
    count,
  );
});

/// This month's points for everyone with data on this device (family board).
final familyMonthPointsProvider = Provider<Map<PersonId, int>>((ref) {
  final data = ref.watch(trackerProvider);
  final today = ref.watch(todayProvider);
  return {
    for (final id in PersonId.values)
      id: StatsCalculator.monthPoints(id, data.entriesFor(id), today.year, today.month),
  };
});
