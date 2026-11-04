/// App-wide constants.
abstract final class AppConstants {
  static const appName = 'Ihsan';
  static const appNameArabic = 'إحسان';

  /// Ihsan: "Excellence in worship; to act as though you see Allah."
  static const tagline = 'Excellence in worship; to act as though you see Allah.';
  static const taglineShort = 'Excellence in worship';

  /// SharedPreferences key. Same as the original HTML prototype so that its
  /// JSON backups can be restored here unchanged.
  static const storageKey = 'tfa_v2';

  static const titleFont = 'Bliss';

  static const defaultReminderHour = 20;
  static const defaultReminderMinute = 0;

  /// First day of the week in the History calendar (DateTime.monday … DateTime.sunday).
  static const firstDayOfWeek = DateTime.monday;
}
