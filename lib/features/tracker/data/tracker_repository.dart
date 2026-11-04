import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';

@immutable
class TrackerData {
  const TrackerData({
    this.profiles = const [],
    this.activePerson,
    this.entries = const {},
  });

  /// All profiles on this device, in display order.
  final List<Profile> profiles;

  /// Id of the profile currently using the device (may be unset).
  final String? activePerson;

  final Map<String, Map<String, DayEntry>> entries;

  Map<String, DayEntry> entriesFor(String id) => entries[id] ?? const {};

  int get totalEntries => entries.values.fold(0, (s, m) => s + m.length);

  TrackerData copyWith({
    List<Profile>? profiles,
    String? activePerson,
    bool clearActivePerson = false,
    Map<String, Map<String, DayEntry>>? entries,
  }) =>
      TrackerData(
        profiles: profiles ?? this.profiles,
        activePerson: clearActivePerson ? null : (activePerson ?? this.activePerson),
        entries: entries ?? this.entries,
      );
}

/// Persists [TrackerData] as JSON in SharedPreferences.
///
/// The layout extends the HTML prototype's `tfa_v2` store with a `profiles`
/// list; the original shape — `{ "person": "faisal", "faisal": { "entries":
/// {...} } }` — is still read and written unchanged, so backups stay
/// interchangeable with the old app.
class TrackerRepository {
  TrackerRepository(this._prefs);

  final SharedPreferences _prefs;

  TrackerData load() {
    final raw = _prefs.getString(AppConstants.storageKey);
    if (raw == null || raw.isEmpty) return const TrackerData();
    try {
      return _decode(jsonDecode(raw));
    } catch (e) {
      debugPrint('TrackerRepository: could not read stored data ($e)');
      return const TrackerData();
    }
  }

  Future<void> save(TrackerData data) async {
    await _prefs.setString(AppConstants.storageKey, encode(data));
  }

  String encode(TrackerData data, {bool pretty = false}) {
    final map = <String, dynamic>{
      'person': data.activePerson,
      'profiles': [for (final p in data.profiles) p.toJson()],
      for (final p in data.entries.entries)
        p.key: {
          'entries': {for (final e in p.value.entries) e.key: e.value.toJson()},
        },
    };
    return pretty ? const JsonEncoder.withIndent('  ').convert(map) : jsonEncode(map);
  }

  /// Parses a backup file. Throws [FormatException] when it isn't one of ours.
  TrackerData parseBackup(String raw) {
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const FormatException('Not valid JSON');
    }
    if (decoded is! Map) throw const FormatException('Unexpected structure');
    final Map map = decoded;
    final looksValid = (map['profiles'] is List && (map['profiles'] as List).isNotEmpty) ||
        map.keys.any((k) => k != 'person' && k != 'profiles' && _isEntrySection(map[k]));
    if (!looksValid) throw const FormatException('Not an Ihsan backup');
    return _decode(map);
  }

  static bool _isEntrySection(Object? value) => value is Map && value['entries'] is Map;

  TrackerData _decode(Object? json) {
    if (json is! Map) return const TrackerData();

    List<Profile> profiles;
    final rawProfiles = json['profiles'];
    if (rawProfiles is List) {
      profiles = [
        for (final p in rawProfiles)
          if (p is Map && p['id'] is String && (p['id'] as String).isNotEmpty)
            Profile.fromJson(Map<String, dynamic>.from(p)),
      ];
    } else {
      // Data from before custom profiles: seed the original family. Ids
      // referenced by the data itself keep their entries below.
      profiles = ProfilePresets.seeds.toList();
    }

    final entries = <String, Map<String, DayEntry>>{};
    json.forEach((key, value) {
      if (key is! String || key == 'person' || key == 'profiles') return;
      if (value is! Map || value['entries'] is! Map) return;
      final parsed = <String, DayEntry>{};
      (value['entries'] as Map).forEach((dateKey, dayJson) {
        if (dateKey is String && dayJson is Map) {
          parsed[dateKey] = DayEntry.fromJson(Map<String, dynamic>.from(dayJson));
        }
      });
      entries[key] = parsed;
    });

    return TrackerData(activePerson: json['person'] as String?, entries: entries)
        .copyWith(profiles: profiles);
  }
}
