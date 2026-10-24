import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/domain/day_entry.dart';

@immutable
class TrackerData {
  const TrackerData({this.activePerson, this.entries = const {}});

  final PersonId? activePerson;
  final Map<PersonId, Map<String, DayEntry>> entries;

  Map<String, DayEntry> entriesFor(PersonId id) => entries[id] ?? const {};

  int get totalEntries => entries.values.fold(0, (s, m) => s + m.length);

  TrackerData copyWith({
    PersonId? activePerson,
    bool clearActivePerson = false,
    Map<PersonId, Map<String, DayEntry>>? entries,
  }) =>
      TrackerData(
        activePerson: clearActivePerson ? null : (activePerson ?? this.activePerson),
        entries: entries ?? this.entries,
      );
}

/// Persists [TrackerData] as JSON in SharedPreferences.
///
/// The JSON layout is identical to the HTML prototype's `tfa_v2` store:
/// `{ "person": "faisal", "faisal": { "entries": { "2025-01-31": {...} } }, ... }`
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
      'person': data.activePerson?.name,
      for (final p in data.entries.entries)
        p.key.name: {
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
    final looksValid = PersonId.tryParse(map['person']) != null ||
        PersonId.values.any((id) => map[id.name] is Map);
    if (!looksValid) throw const FormatException('Not a Tasks for Allah backup');
    return _decode(map);
  }

  TrackerData _decode(Object? json) {
    if (json is! Map) return const TrackerData();
    final entries = <PersonId, Map<String, DayEntry>>{};
    for (final id in PersonId.values) {
      final section = json[id.name];
      if (section is Map && section['entries'] is Map) {
        final parsed = <String, DayEntry>{};
        (section['entries'] as Map).forEach((key, value) {
          if (key is String && value is Map) {
            parsed[key] = DayEntry.fromJson(Map<String, dynamic>.from(value));
          }
        });
        entries[id] = parsed;
      }
    }
    return TrackerData(activePerson: PersonId.tryParse(json['person']), entries: entries);
  }
}
