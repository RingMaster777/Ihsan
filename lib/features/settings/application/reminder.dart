import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/constants/app_constants.dart';
import 'package:tasks_for_allah/core/services/notification_service.dart';
import 'package:tasks_for_allah/core/utils/date_helpers.dart';
import 'package:tasks_for_allah/features/settings/application/prayer_settings.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';

@immutable
class ReminderSettings {
  const ReminderSettings({required this.enabled, required this.hour, required this.minute});

  final bool enabled;
  final int hour;
  final int minute;

  TimeOfDay get time => TimeOfDay(hour: hour, minute: minute);

  ReminderSettings copyWith({bool? enabled, int? hour, int? minute}) => ReminderSettings(
        enabled: enabled ?? this.enabled,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
      );
}

class ReminderNotifier extends Notifier<ReminderSettings> {
  static const _kEnabled = 'tfa_reminder_enabled';
  static const _kHour = 'tfa_reminder_hour';
  static const _kMinute = 'tfa_reminder_minute';

  @override
  ReminderSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return ReminderSettings(
      enabled: prefs.getBool(_kEnabled) ?? true,
      hour: prefs.getInt(_kHour) ?? AppConstants.defaultReminderHour,
      minute: prefs.getInt(_kMinute) ?? AppConstants.defaultReminderMinute,
    );
  }

  Future<void> setEnabled(bool value) async {
    state = state.copyWith(enabled: value);
    await ref.read(sharedPreferencesProvider).setBool(_kEnabled, value);
  }

  Future<void> setTime(TimeOfDay time) async {
    state = state.copyWith(hour: time.hour, minute: time.minute);
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_kHour, time.hour);
    await prefs.setInt(_kMinute, time.minute);
  }
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderSettings>(ReminderNotifier.new);

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

/// Keeps the scheduled notification in sync with settings, the active person
/// and whether today's prayers have been logged.
class ReminderCoordinator {
  ReminderCoordinator(this._ref);
  final Ref _ref;

  Future<void> sync() async {
    final service = _ref.read(notificationServiceProvider);
    final settings = _ref.read(reminderProvider);
    final prayerSettings = _ref.read(prayerSettingsProvider);
    final person = _ref.read(activeProfileProvider);

    if (!settings.enabled || person == null) {
      await service.cancelReminder();
    } else {
      final today = dateOnly(DateTime.now());
      final logged = _ref.read(entriesProvider).containsKey(toDateKey(today));
      await service.scheduleDaily(
        hour: settings.hour,
        minute: settings.minute,
        personName: person.name,
        loggedToday: logged,
      );
    }

    // Nudges at each prayer time, independent of the evening reminder.
    if (prayerSettings.notifyPrayers && person != null) {
      await service.schedulePrayerTimes(_ref.read(prayerTimesTodayProvider).times);
    } else {
      await service.cancelPrayerTimes();
    }
  }
}

final reminderCoordinatorProvider =
    Provider<ReminderCoordinator>((ref) => ReminderCoordinator(ref));
