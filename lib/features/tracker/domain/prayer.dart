enum PrayerType {
  fajr,
  dhuhr,
  asr,
  maghrib,
  isha;

  static PrayerType? tryParse(Object? value) {
    if (value is! String) return null;
    for (final t in PrayerType.values) {
      if (t.name == value) return t;
    }
    return null;
  }

  String get english => switch (this) {
        PrayerType.fajr => 'Fajr',
        PrayerType.dhuhr => 'Dhuhr',
        PrayerType.asr => 'Asr',
        PrayerType.maghrib => 'Maghrib',
        PrayerType.isha => 'Isha',
      };

  String get arabic => switch (this) {
        PrayerType.fajr => 'الفجر',
        PrayerType.dhuhr => 'الظهر',
        PrayerType.asr => 'العصر',
        PrayerType.maghrib => 'المغرب',
        PrayerType.isha => 'العشاء',
      };

  String get timeLabel => switch (this) {
        PrayerType.fajr => 'Dawn',
        PrayerType.dhuhr => 'Noon',
        PrayerType.asr => 'Afternoon',
        PrayerType.maghrib => 'Sunset',
        PrayerType.isha => 'Night',
      };

  String get abbreviation => english.substring(0, 3).toUpperCase();
}

enum PrayerStatus {
  missed,
  solo,
  jamaat,
  prayed;

  static PrayerStatus? tryParse(Object? value) {
    if (value is! String) return null;
    for (final s in PrayerStatus.values) {
      if (s.name == value) return s;
    }
    return null;
  }

  String get label => switch (this) {
        PrayerStatus.missed => 'Missed',
        PrayerStatus.solo => 'Alone',
        PrayerStatus.jamaat => 'Jamaat',
        PrayerStatus.prayed => 'Prayed',
      };
}
