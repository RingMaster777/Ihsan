import 'package:flutter/material.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

extension PrayerTypeUi on PrayerType {
  IconData get icon => switch (this) {
        PrayerType.fajr => Icons.wb_twilight_rounded,
        PrayerType.dhuhr => Icons.wb_sunny_rounded,
        PrayerType.asr => Icons.wb_cloudy_rounded,
        PrayerType.maghrib => Icons.landscape_rounded,
        PrayerType.isha => Icons.nightlight_round,
      };

  Color get tint => switch (this) {
        PrayerType.fajr => const Color(0xFFEE8F6B),
        PrayerType.dhuhr => const Color(0xFFF2B01E),
        PrayerType.asr => const Color(0xFF3FA6D8),
        PrayerType.maghrib => const Color(0xFFD9647F),
        PrayerType.isha => const Color(0xFF6B73D6),
      };
}

/// Icon used when choosing a status in the log screen.
IconData optionIcon(PrayerStatus status) => switch (status) {
      PrayerStatus.missed => Icons.close_rounded,
      PrayerStatus.solo => Icons.person_rounded,
      PrayerStatus.jamaat => Icons.groups_rounded,
      PrayerStatus.prayed => Icons.check_rounded,
    };

/// Compact mark for a status on lists and calendars (`null` = nothing logged).
IconData markIcon(PrayerStatus? status) => switch (status) {
      null => Icons.remove_rounded,
      PrayerStatus.missed => Icons.close_rounded,
      PrayerStatus.solo || PrayerStatus.prayed => Icons.check_rounded,
      PrayerStatus.jamaat => Icons.star_rounded,
    };

IconData bonusIcon(String id) => switch (id) {
      'quran' => Icons.menu_book_rounded,
      'parents' => Icons.volunteer_activism_rounded,
      'nolie' => Icons.handshake_rounded,
      'helped' => Icons.favorite_rounded,
      'dhikr' => Icons.auto_awesome_rounded,
      _ => Icons.star_rounded,
    };
