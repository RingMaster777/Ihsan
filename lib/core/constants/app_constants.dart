/// App-wide constants.
abstract final class AppConstants {
  static const appName = 'Tasks for Allah';
  static const tagline = 'Daily Prayer Tracker';

  /// SharedPreferences key. Same as the original HTML prototype so that its
  /// JSON backups can be restored here unchanged.
  static const storageKey = 'tfa_v2';

  static const titleFont = 'Bliss';

  static const defaultReminderHour = 20;
  static const defaultReminderMinute = 0;

  /// First day of the week in the History calendar (DateTime.monday … DateTime.sunday).
  static const firstDayOfWeek = DateTime.monday;
}
