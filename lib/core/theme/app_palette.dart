import 'package:flutter/material.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

@immutable
class StatusStyle {
  const StatusStyle({required this.bg, required this.border, required this.fg});
  final Color bg;
  final Color border;
  final Color fg;
}

/// Colour tokens for both brightness modes. Access via `context.palette`.
@immutable
class AppPalette {
  const AppPalette({
    required this.isDark,
    required this.bgGradient,
    required this.headerGradient,
    required this.ctaGradient,
    required this.greenGradient,
    required this.goldGradient,
    required this.card,
    required this.cardBorder,
    required this.shadow,
    required this.textStrong,
    required this.textBody,
    required this.textMuted,
    required this.primary,
    required this.primaryStrong,
    required this.chip,
    required this.chipFg,
    required this.track,
    required this.gold,
    required this.goldFg,
    required this.missed,
    required this.solo,
    required this.jamaat,
    required this.partial,
    required this.none,
  });

  static const Color seed = Color(0xFF0D7878);

  final bool isDark;
  final List<Color> bgGradient;
  final List<Color> headerGradient;
  final List<Color> ctaGradient;
  final List<Color> greenGradient;
  final List<Color> goldGradient;
  final Color card;
  final Color cardBorder;
  final Color shadow;
  final Color textStrong;
  final Color textBody;
  final Color textMuted;
  final Color primary;
  final Color primaryStrong;
  final Color chip;
  final Color chipFg;
  final Color track;
  final Color gold;
  final Color goldFg;
  final StatusStyle missed;
  final StatusStyle solo;
  final StatusStyle jamaat;
  final StatusStyle partial;
  final StatusStyle none;

  StatusStyle styleFor(PrayerStatus? status) => switch (status) {
        null => none,
        PrayerStatus.missed => missed,
        PrayerStatus.solo || PrayerStatus.prayed => solo,
        PrayerStatus.jamaat => jamaat,
      };

  /// Lightens saturated accent colours so they stay readable on dark cards.
  Color tone(Color c) => isDark ? Color.lerp(c, Colors.white, 0.5)! : c;

  static const light = AppPalette(
    isDark: false,
    bgGradient: [Color(0xFFD4F5F0), Color(0xFFE0F8F5), Color(0xFFD8F4F8), Color(0xFFE4FAF5)],
    headerGradient: [Color(0xFF0D6870), Color(0xFF1A9090), Color(0xFF0E7878)],
    ctaGradient: [Color(0xFF0D7878), Color(0xFF28A898)],
    greenGradient: [Color(0xFF189858), Color(0xFF28C878)],
    goldGradient: [Color(0xFFFFF8D0), Color(0xFFFFF0A0)],
    card: Colors.white,
    cardBorder: Color(0xFFC8EEE8),
    shadow: Color(0x1A0D6870),
    textStrong: Color(0xFF0A3840),
    textBody: Color(0xFF2A7878),
    textMuted: Color(0xFF80B0A8),
    primary: Color(0xFF0D7878),
    primaryStrong: Color(0xFF0A6068),
    chip: Color(0xFFD8F4F0),
    chipFg: Color(0xFF1A8080),
    track: Color(0xFFD8F0EC),
    gold: Color(0xFFD8C040),
    goldFg: Color(0xFF806010),
    missed: StatusStyle(bg: Color(0xFFFEF0F0), border: Color(0xFFE8A0A0), fg: Color(0xFFB03838)),
    solo: StatusStyle(bg: Color(0xFFE0F8EE), border: Color(0xFF70C898), fg: Color(0xFF208848)),
    jamaat: StatusStyle(bg: Color(0xFFDCF0FC), border: Color(0xFF7CC8E8), fg: Color(0xFF1878A8)),
    partial: StatusStyle(bg: Color(0xFFFFF4CC), border: Color(0xFFE6C85A), fg: Color(0xFF8A6A10)),
    none: StatusStyle(bg: Color(0xFFEDF9F7), border: Color(0xFFC0E8E0), fg: Color(0xFF70A8A0)),
  );

  static const dark = AppPalette(
    isDark: true,
    bgGradient: [Color(0xFF071E20), Color(0xFF0A2629), Color(0xFF082226), Color(0xFF0B2A2C)],
    headerGradient: [Color(0xFF083E44), Color(0xFF0F5E60), Color(0xFF0A4F52)],
    ctaGradient: [Color(0xFF0D7878), Color(0xFF1F9A8B)],
    greenGradient: [Color(0xFF148A50), Color(0xFF22B06A)],
    goldGradient: [Color(0xFF3B3210), Color(0xFF2E280C)],
    card: Color(0xFF0F2F32),
    cardBorder: Color(0xFF1E4A4D),
    shadow: Color(0x33000000),
    textStrong: Color(0xFFE6F7F5),
    textBody: Color(0xFF9FD3CE),
    textMuted: Color(0xFF6FA39E),
    primary: Color(0xFF4DD0C0),
    primaryStrong: Color(0xFF7FE3D6),
    chip: Color(0xFF164547),
    chipFg: Color(0xFF7FE3D6),
    track: Color(0xFF1B3F42),
    gold: Color(0xFF8A7420),
    goldFg: Color(0xFFF2D56B),
    missed: StatusStyle(bg: Color(0xFF3A1D1F), border: Color(0xFF8A4A4C), fg: Color(0xFFFF9E9E)),
    solo: StatusStyle(bg: Color(0xFF123B2A), border: Color(0xFF2E8A5C), fg: Color(0xFF7FE0A8)),
    jamaat: StatusStyle(bg: Color(0xFF10334A), border: Color(0xFF2E7FA8), fg: Color(0xFF8AD3FA)),
    partial: StatusStyle(bg: Color(0xFF3A3010), border: Color(0xFF9A8030), fg: Color(0xFFF2D56B)),
    none: StatusStyle(bg: Color(0xFF133436), border: Color(0xFF235052), fg: Color(0xFF6FA39E)),
  );
}

extension PaletteContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;
}
