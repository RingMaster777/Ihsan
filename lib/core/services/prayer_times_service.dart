import 'package:adhan/adhan.dart' as adhan;
import 'package:flutter/foundation.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

/// A city users can pick for prayer-time calculation.
@immutable
class City {
  const City(this.name, this.country, this.lat, this.lng);
  final String name;
  final String country;
  final double lat;
  final double lng;
}

/// Curated list — Bangladesh divisions first, then common expat hubs.
abstract final class Cities {
  static const list = [
    City('Dhaka', 'Bangladesh', 23.8103, 90.4125),
    City('Chattogram', 'Bangladesh', 22.3569, 91.7832),
    City('Sylhet', 'Bangladesh', 24.8949, 91.8687),
    City('Khulna', 'Bangladesh', 22.8456, 89.5403),
    City('Rajshahi', 'Bangladesh', 24.3745, 88.6042),
    City('Barishal', 'Bangladesh', 22.7010, 90.3535),
    City('Rangpur', 'Bangladesh', 25.7439, 89.2752),
    City('Mymensingh', 'Bangladesh', 24.7471, 90.4203),
    City('Makkah', 'Saudi Arabia', 21.4225, 39.8262),
    City('Madinah', 'Saudi Arabia', 24.4672, 39.6111),
    City('Dubai', 'UAE', 25.2048, 55.2708),
    City('London', 'UK', 51.5074, -0.1278),
    City('New York', 'USA', 40.7128, -74.0060),
    City('Toronto', 'Canada', 43.6532, -79.3832),
    City('Kuala Lumpur', 'Malaysia', 3.1390, 101.6869),
    City('Sydney', 'Australia', -33.8688, 151.2093),
  ];

  static City byName(String name) =>
      list.firstWhere((c) => c.name == name, orElse: () => list.first);
}

/// The calculation conventions offered in Settings.
enum CalcMethod {
  karachi('University of Islamic Sciences, Karachi'),
  muslimWorldLeague('Muslim World League'),
  northAmerica('ISNA — North America'),
  egyptian('Egyptian General Authority'),
  dubai('Dubai (UAE)'),
  ummAlQura('Umm al-Qura, Makkah'),
  kuwait('Kuwait'),
  qatar('Qatar'),
  singapore('Singapore'),
  turkey('Diyanet, Turkey');

  const CalcMethod(this.label);
  final String label;

  adhan.CalculationMethod get _method => switch (this) {
        CalcMethod.karachi => adhan.CalculationMethod.karachi,
        CalcMethod.muslimWorldLeague => adhan.CalculationMethod.muslim_world_league,
        CalcMethod.northAmerica => adhan.CalculationMethod.north_america,
        CalcMethod.egyptian => adhan.CalculationMethod.egyptian,
        CalcMethod.dubai => adhan.CalculationMethod.dubai,
        CalcMethod.ummAlQura => adhan.CalculationMethod.umm_al_qura,
        CalcMethod.kuwait => adhan.CalculationMethod.kuwait,
        CalcMethod.qatar => adhan.CalculationMethod.qatar,
        CalcMethod.singapore => adhan.CalculationMethod.singapore,
        CalcMethod.turkey => adhan.CalculationMethod.turkey,
      };

  static CalcMethod fromName(String? name) => CalcMethod.values
      .firstWhere((m) => m.name == name, orElse: () => CalcMethod.karachi);
}

/// Asr juristic method — Hanafi is standard in South Asia.
enum AsrMadhab { hanafi, shafi }

@immutable
class PrayerTimesResult {
  const PrayerTimesResult({required this.times, required this.sunrise});

  /// The five prayers, in canonical order.
  final Map<PrayerType, DateTime> times;
  final DateTime sunrise;

  /// The next prayer after [now], or Fajr of the same day if all have passed.
  PrayerType nextAfter(DateTime now) {
    for (final prayer in PrayerType.values) {
      if (times[prayer]!.isAfter(now)) return prayer;
    }
    return PrayerType.fajr;
  }

  DateTime timeFor(PrayerType prayer) => times[prayer]!;
}

/// Pure-Dart prayer time calculation (works fully offline).
abstract final class PrayerTimesService {
  static PrayerTimesResult compute(
    DateTime date, {
    required double lat,
    required double lng,
    required CalcMethod method,
    required AsrMadhab madhab,
  }) {
    final params = method._method.getParameters();
    params.madhab =
        madhab == AsrMadhab.hanafi ? adhan.Madhab.hanafi : adhan.Madhab.shafi;
    final calculated = adhan.PrayerTimes(
      adhan.Coordinates(lat, lng),
      adhan.DateComponents(date.year, date.month, date.day),
      params,
    );
    return PrayerTimesResult(
      times: {
        PrayerType.fajr: calculated.fajr,
        PrayerType.dhuhr: calculated.dhuhr,
        PrayerType.asr: calculated.asr,
        PrayerType.maghrib: calculated.maghrib,
        PrayerType.isha: calculated.isha,
      },
      sunrise: calculated.sunrise,
    );
  }
}
