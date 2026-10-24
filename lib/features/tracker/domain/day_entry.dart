import 'package:flutter/foundation.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

/// One day's record for one person.
///
/// [prayers] only contains the prayers the user explicitly chose. A prayer
/// without a value is treated as [PrayerStatus.missed] for scoring, which
/// matches the behaviour of the original prototype.
@immutable
class DayEntry {
  const DayEntry({
    this.prayers = const {},
    this.bonus = const {},
    this.updatedAt,
  });

  final Map<PrayerType, PrayerStatus> prayers;
  final Set<String> bonus;

  /// Milliseconds since epoch of the last save.
  final int? updatedAt;

  PrayerStatus statusOf(PrayerType prayer) => prayers[prayer] ?? PrayerStatus.missed;
  bool isChosen(PrayerType prayer) => prayers.containsKey(prayer);

  /// Number of prayers that were not missed.
  int get prayedCount =>
      PrayerType.values.where((p) => statusOf(p) != PrayerStatus.missed).length;

  bool get hasAnyPrayer => prayedCount > 0;
  bool get isPerfect => prayedCount == PrayerType.values.length;

  bool allPrayersAre(PrayerStatus status) =>
      PrayerType.values.every((p) => statusOf(p) == status);

  DayEntry withPrayer(PrayerType prayer, PrayerStatus status) =>
      copyWith(prayers: Map<PrayerType, PrayerStatus>.of(prayers)..[prayer] = status);

  DayEntry toggleBonus(String id) {
    final next = Set<String>.of(bonus);
    if (!next.remove(id)) next.add(id);
    return copyWith(bonus: next);
  }

  DayEntry copyWith({
    Map<PrayerType, PrayerStatus>? prayers,
    Set<String>? bonus,
    int? updatedAt,
  }) =>
      DayEntry(
        prayers: prayers ?? this.prayers,
        bonus: bonus ?? this.bonus,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  factory DayEntry.fromJson(Map<String, dynamic> json) {
    final prayers = <PrayerType, PrayerStatus>{};
    for (final prayer in PrayerType.values) {
      final status = PrayerStatus.tryParse(json[prayer.name]);
      if (status != null) prayers[prayer] = status;
    }
    final rawBonus = json['bonus'];
    final bonus = rawBonus is List ? rawBonus.whereType<String>().toSet() : <String>{};
    final ts = json['ts'];
    return DayEntry(
      prayers: prayers,
      bonus: bonus,
      updatedAt: ts is num ? ts.toInt() : null,
    );
  }

  Map<String, dynamic> toJson() => {
        for (final e in prayers.entries) e.key.name: e.value.name,
        'bonus': bonus.toList(),
        if (updatedAt != null) 'ts': updatedAt,
      };

  /// Equality ignores [updatedAt] so it can be used for "has unsaved changes".
  @override
  bool operator ==(Object other) =>
      other is DayEntry && mapEquals(prayers, other.prayers) && setEquals(bonus, other.bonus);

  @override
  int get hashCode => Object.hash(
        Object.hashAllUnordered(prayers.entries.map((e) => Object.hash(e.key, e.value))),
        Object.hashAllUnordered(bonus),
      );
}
