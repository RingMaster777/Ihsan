import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/profile/domain/person.dart';
import 'package:tasks_for_allah/features/tracker/data/tracker_repository.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';
import 'package:tasks_for_allah/features/tracker/domain/scoring.dart';

/// Keeps the Android home screen widget ("Ihsan — today's prayers") in sync.
/// Everything is best-effort: a missing widget must never break the app.
abstract final class IhsanWidget {
  static const _androidName = 'IhsanWidget';

  static Future<void> update(TrackerData data) async {
    if (data.profiles.isEmpty) return;
    try {
      final id = data.activePerson;
      Profile? profile;
      for (final p in data.profiles) {
        if (p.id == id) profile = p;
      }
      if (profile == null) return;

      final entry = data.entriesFor(profile.id)[toDateKey(DateTime.now())];
      final prayed = entry?.prayedCount ?? 0;
      final points = entry == null ? '' : '${formatPoints(ScoringRules.entryPoints(profile, entry))} pts';

      await HomeWidget.saveWidgetData<String>('person', profile.name);
      await HomeWidget.saveWidgetData<String>('count', '$prayed/5 prayed today');
      await HomeWidget.saveWidgetData<String>('points', points);
      for (final prayer in PrayerType.values) {
        final done = entry != null && entry.statusOf(prayer) != PrayerStatus.missed;
        await HomeWidget.saveWidgetData<String>(
          'mark_${prayer.name}',
          '${prayer.abbreviation}\n${done ? '✓' : '·'}',
        );
      }
      await HomeWidget.updateWidget(androidName: _androidName);
    } catch (e) {
      debugPrint('IhsanWidget: update skipped ($e)');
    }
  }
}
