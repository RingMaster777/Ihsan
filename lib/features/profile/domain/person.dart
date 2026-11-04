import 'package:flutter/material.dart';
import 'package:tasks_for_allah/features/tracker/domain/prayer.dart';

/// How a profile logs prayers.
enum TrackingMode {
  /// Adult style: Missed / Alone (1 pt) / Jamaat (2 pts).
  jamaat,

  /// Child style: Missed / Prayed, with a fixed reward per prayer.
  simple;

  String get label => switch (this) {
        TrackingMode.jamaat => 'Jamaat (adult)',
        TrackingMode.simple => 'Simple (child)',
      };
}

/// One member of the family. Profiles are created by the user — there is no
/// fixed list. The [id] doubles as the storage key, so it must stay stable
/// once saved (existing entries and backups depend on it).
@immutable
class Profile {
  const Profile({
    required this.id,
    required this.name,
    required this.role,
    required this.accent,
    required this.mode,
    this.avatarAsset,
    this.simplePoints = defaultSimplePoints,
    this.bonus = const {},
  });

  final String id;
  final String name;
  final String role;

  /// Strong accent (names, icons, initials avatar).
  final Color accent;

  /// How prayers are logged and scored for this profile.
  final TrackingMode mode;

  /// Photo avatar; `null` renders initials on [accent].
  final String? avatarAsset;

  /// Points for a "prayed" prayer, per prayer (simple mode).
  final Map<PrayerType, int> simplePoints;

  /// Enabled bonus activities: id -> points. See `BonusCatalog` for ids.
  final Map<String, double> bonus;

  /// Default child-style rewards (Fajr & Isha are worth a little extra).
  static const Map<PrayerType, int> defaultSimplePoints = {
    PrayerType.fajr: 3,
    PrayerType.dhuhr: 2,
    PrayerType.asr: 2,
    PrayerType.maghrib: 2,
    PrayerType.isha: 3,
  };

  bool get usesInitials => avatarAsset == null;

  /// Up to two initials for the fallback avatar.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return _firstRune(parts.first).toUpperCase();
    return (_firstRune(parts.first) + _firstRune(parts.last)).toUpperCase();
  }

  static String _firstRune(String s) =>
      s.runes.isEmpty ? '' : String.fromCharCode(s.runes.first);

  /// Soft tint derived from [accent] (borders, rings).
  Color get accentSoft => Color.lerp(accent, Colors.white, 0.6)!;

  Profile copyWith({
    String? name,
    String? role,
    Color? accent,
    TrackingMode? mode,
    String? avatarAsset,
    bool clearAvatar = false,
    Map<PrayerType, int>? simplePoints,
    Map<String, double>? bonus,
  }) =>
      Profile(
        id: id,
        name: name ?? this.name,
        role: role ?? this.role,
        accent: accent ?? this.accent,
        mode: mode ?? this.mode,
        avatarAsset: clearAvatar ? null : (avatarAsset ?? this.avatarAsset),
        simplePoints: simplePoints ?? this.simplePoints,
        bonus: bonus ?? this.bonus,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'color': accent.value,
        'mode': mode.name,
        if (avatarAsset != null) 'avatar': avatarAsset,
        'bonus': bonus,
        'points': {
          for (final e in simplePoints.entries) e.key.name: e.value,
        },
      };

  factory Profile.fromJson(Map<String, dynamic> json) {
    final rawBonus = json['bonus'];
    final rawPoints = json['points'];
    return Profile(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      role: json['role'] as String? ?? '',
      accent: Color((json['color'] as num?)?.toInt() ?? 0xFF186888),
      mode: json['mode'] == 'simple' ? TrackingMode.simple : TrackingMode.jamaat,
      avatarAsset: json['avatar'] as String?,
      bonus: {
        if (rawBonus is Map)
          for (final e in rawBonus.entries)
            if (e.value is num) e.key as String: (e.value as num).toDouble(),
      },
      simplePoints: {
        if (rawPoints is Map)
          for (final e in rawPoints.entries)
            if (PrayerType.tryParse(e.key) != null && e.value is num)
              PrayerType.tryParse(e.key)!: (e.value as num).toInt(),
      },
    );
  }

  @override
  bool operator ==(Object other) => other is Profile && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// The family the app originally shipped with, plus defaults for new members.
abstract final class ProfilePresets {
  /// Seeds used when loading data that predates custom profiles. Their ids
  /// match the HTML prototype's storage keys.
  static const List<Profile> seeds = [faisal, aaraf, kakon];

  static const Profile faisal = Profile(
    id: 'faisal',
    name: 'Faisal',
    role: 'Father',
    accent: Color(0xFF186888),
    mode: TrackingMode.jamaat,
    avatarAsset: 'assets/images/faisal.jpg',
    bonus: {'exercise': 1, 'quran': 1, 'fasting': 1},
  );

  static const Profile aaraf = Profile(
    id: 'aaraf',
    name: "A'araf",
    role: 'Son',
    accent: Color(0xFF187848),
    mode: TrackingMode.simple,
    avatarAsset: 'assets/images/aaraf.jpg',
    bonus: {
      'quran': 1,
      'parents': 0.5,
      'nolie': 0.5,
      'helped': 0.5,
      'dhikr': 0.5,
      'studies': 0.5,
      'exercise': 0.5,
    },
  );

  static const Profile kakon = Profile(
    id: 'kakon',
    name: 'Kakon',
    role: 'Mother',
    accent: Color(0xFF983858),
    mode: TrackingMode.simple,
    avatarAsset: 'assets/images/kakon.jpg',
    simplePoints: {
      PrayerType.fajr: 3,
      PrayerType.dhuhr: 2,
      PrayerType.asr: 2,
      PrayerType.maghrib: 2,
      PrayerType.isha: 2,
    },
    bonus: {'quran': 1, 'exercise': 1},
  );

  /// Accent colors offered when creating a profile.
  static const List<Color> accentChoices = [
    Color(0xFF186888),
    Color(0xFF187848),
    Color(0xFF983858),
    Color(0xFFB07818),
    Color(0xFF6B5FB0),
    Color(0xFF0D7878),
  ];

  /// Bonus list a new profile starts with, by tracking mode.
  static Map<String, double> defaultBonusFor(TrackingMode mode) =>
      mode == TrackingMode.jamaat
          ? const {'quran': 1, 'exercise': 1, 'fasting': 1}
          : const {
              'quran': 1,
              'parents': 0.5,
              'nolie': 0.5,
              'helped': 0.5,
              'dhikr': 0.5,
              'studies': 0.5,
              'exercise': 0.5,
            };

  /// A fresh profile of [mode], ready for the user to name.
  static Profile blank(TrackingMode mode, {int colorIndex = 0}) => Profile(
        id: 'p${DateTime.now().millisecondsSinceEpoch}',
        name: '',
        role: '',
        accent: accentChoices[colorIndex % accentChoices.length],
        mode: mode,
        bonus: defaultBonusFor(mode),
      );
}
