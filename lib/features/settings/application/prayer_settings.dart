import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tasks_for_allah/core/services/prayer_times_service.dart';
import 'package:tasks_for_allah/features/tracker/application/tracker_providers.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

@immutable
class PrayerSettings {
  const PrayerSettings({
    required this.city,
    required this.method,
    required this.madhab,
    required this.notifyPrayers,
  });

  final City city;
  final CalcMethod method;
  final AsrMadhab madhab;

  /// Reminder at each prayer time ("It's Asr — did you pray?").
  final bool notifyPrayers;

  PrayerSettings copyWith({
    City? city,
    CalcMethod? method,
    AsrMadhab? madhab,
    bool? notifyPrayers,
  }) =>
      PrayerSettings(
        city: city ?? this.city,
        method: method ?? this.method,
        madhab: madhab ?? this.madhab,
        notifyPrayers: notifyPrayers ?? this.notifyPrayers,
      );
}

class PrayerSettingsNotifier extends Notifier<PrayerSettings> {
  static const _kCity = 'tfa_pt_city';
  static const _kMethod = 'tfa_pt_method';
  static const _kMadhab = 'tfa_pt_madhab';
  static const _kNotify = 'tfa_pt_notify';

  @override
  PrayerSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    return PrayerSettings(
      city: Cities.byName(prefs.getString(_kCity) ?? ''),
      method: CalcMethod.fromName(prefs.getString(_kMethod)),
      madhab: prefs.getString(_kMadhab) == 'shafi' ? AsrMadhab.shafi : AsrMadhab.hanafi,
      // On by default: prayer-time nudges are the app's core promise.
      notifyPrayers: prefs.getBool(_kNotify) ?? true,
    );
  }

  Future<void> _set(String key, Object value) async {
    await ref.read(sharedPreferencesProvider).setString(key, value as String);
  }

  Future<void> setCity(City city) async {
    state = state.copyWith(city: city);
    await _set(_kCity, city.name);
  }

  Future<void> setMethod(CalcMethod method) async {
    state = state.copyWith(method: method);
    await _set(_kMethod, method.name);
  }

  Future<void> setMadhab(AsrMadhab madhab) async {
    state = state.copyWith(madhab: madhab);
    await _set(_kMadhab, madhab.name);
  }

  Future<void> setNotifyPrayers(bool value) async {
    state = state.copyWith(notifyPrayers: value);
    await ref.read(sharedPreferencesProvider).setBool(_kNotify, value);
  }
}

final prayerSettingsProvider =
    NotifierProvider<PrayerSettingsNotifier, PrayerSettings>(PrayerSettingsNotifier.new);

/// Today's prayer times for the configured location.
final prayerTimesTodayProvider = Provider<PrayerTimesResult>((ref) {
  final settings = ref.watch(prayerSettingsProvider);
  final today = ref.watch(todayProvider);
  return PrayerTimesService.compute(
    today,
    lat: settings.city.lat,
    lng: settings.city.lng,
    method: settings.method,
    madhab: settings.madhab,
  );
});

extension PrayerTimeFormat on PrayerType {
  String get shortTimeLabel => name[0].toUpperCase();
}
