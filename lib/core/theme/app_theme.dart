import 'package:flutter/material.dart';
import 'package:tasks_for_allah/core/theme/app_palette.dart';

abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final p = brightness == Brightness.dark ? AppPalette.dark : AppPalette.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppPalette.seed,
      brightness: brightness,
    ).copyWith(
      primary: p.primary,
      surface: p.card,
      onSurface: p.textStrong,
      outlineVariant: p.cardBorder,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Emirates',
    );

    return base.copyWith(
      scaffoldBackgroundColor: p.bgGradient.first,
      textTheme: base.textTheme.apply(
        fontFamily: 'Emirates',
        bodyColor: p.textStrong,
        displayColor: p.textStrong,
      ),
      splashFactory: InkRipple.splashFactory,
      dividerColor: p.cardBorder,
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF0D5A5C),
        contentTextStyle: const TextStyle(color: Colors.white, fontFamily: 'Emirates'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? Colors.white : p.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? p.primary : p.track,
        ),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),
    );
  }
}
