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

  Future<void> selectPerson(String id) => _commit(state.copyWith(activePerson: id));

  Future<void> clearPerson() => _commit(state.copyWith(clearActivePerson: true));

  Future<void> saveEntry(String dateKey, DayEntry entry) async {
    final person = state.activePerson;
    if (person == null) return;
    final personEntries = Map<String, DayEntry>.of(state.entriesFor(person))
      ..[dateKey] = entry;
    final next = Map<String, Map<String, DayEntry>>.of(state.entries)
      ..[person] = personEntries;
    await _commit(state.copyWith(entries: next));
  }

  /// Adds [profile] and makes it the active one.
  Future<void> addProfile(Profile profile) async {
    final profiles = [...state.profiles, profile];
    await _commit(
      state.copyWith(profiles: profiles, activePerson: profile.id),
    );
  }

  Future<void> updateProfile(Profile profile) => _commit(state.copyWith(
        profiles: [for (final p in state.profiles) p.id == profile.id ? profile : p],
      ));

  /// Removes a profile and its entries. The last remaining profile cannot be
  /// deleted. Deleting the active one switches to the first survivor.
  Future<void> deleteProfile(String id) async {
    if (state.profiles.length <= 1) return;
    final profiles = [for (final p in state.profiles) if (p.id != id) p];
    final entries = Map<String, Map<String, DayEntry>>.of(state.entries)..remove(id);
    final active = state.activePerson == id ? profiles.first.id : state.activePerson;
    await _commit(state.copyWith(
      profiles: profiles,
      entries: entries,
      activePerson: active,
    ));
  }

  /// Replaces all entries with the ones from [backup]; keeps who is using the
  /// device when their profile still exists afterwards.
  Future<void> restore(TrackerData backup) => _commit(TrackerData(
        profiles: backup.profiles.isNotEmpty ? backup.profiles : state.profiles,
        activePerson: backup.profiles.any((p) => p.id == state.activePerson)
            ? state.activePerson
            : backup.activePerson,
        entries: backup.entries,
      ));

  Future<void> resetAll() => _commit(TrackerData(
        profiles: state.profiles,
        activePerson: state.activePerson,
      ));

  Future<void> _commit(TrackerData next) async {
    state = next;
    await _repo.save(next);
  }
}

final trackerProvider =
    NotifierProvider<TrackerNotifier, TrackerData>(TrackerNotifier.new);

/// Id of the profile using the device, or `null` when nobody is chosen.
final activePersonProvider = Provider<String?>(
  (ref) => ref.watch(trackerProvider.select((d) => d.activePerson)),
);

/// All profiles on this device.
final profilesProvider = Provider<List<Profile>>(
  (ref) => ref.watch(trackerProvider.select((d) => d.profiles)),
);

final activeProfileProvider = Provider<Profile?>((ref) {
  final data = ref.watch(trackerProvider);
  final id = data.activePerson;
  if (id == null) return null;
  for (final p in data.profiles) {
    if (p.id == id) return p;
  }
  return null;
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
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) {
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
    profile,
    ref.watch(entriesProvider),
    key.year,
    key.month,
    ref.watch(todayProvider),
  );
});

final lastDaysProvider = Provider.family<List<DayPoints>, int>((ref, count) {
  final profile = ref.watch(activeProfileProvider);
  if (profile == null) return const [];
  return StatsCalculator.lastDays(
    profile,
    ref.watch(entriesProvider),
    ref.watch(todayProvider),
    count,
  );
});

/// This month's points for every profile with data on this device.
final familyMonthPointsProvider = Provider<Map<Profile, double>>((ref) {
  final data = ref.watch(trackerProvider);
  final today = ref.watch(todayProvider);
  return {
    for (final profile in data.profiles)
      profile: StatsCalculator.monthPoints(
        profile,
        data.entriesFor(profile.id),
        today.year,
        today.month,
      ),
  };
});
