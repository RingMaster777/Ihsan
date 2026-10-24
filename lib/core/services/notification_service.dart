import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Thin wrapper around flutter_local_notifications for the daily reminder.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const int _reminderId = 8001;

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  bool get _supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);

  Future<void> init() async {
    if (_ready || !_supported) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final zone = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(zone.identifier));
      } catch (e) {
        debugPrint('NotificationService: timezone lookup failed ($e), using UTC');
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const darwin = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      await _plugin.initialize(
        const InitializationSettings(android: android, iOS: darwin, macOS: darwin),
      );
      _ready = true;
    } catch (e) {
      debugPrint('NotificationService: init failed ($e)');
    }
  }

  /// Returns `true` when notifications may be shown.
  Future<bool> requestPermission() async {
    if (!_ready) return false;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      final mac = _plugin
          .resolvePlatformSpecificImplementation<MacOSFlutterLocalNotificationsPlugin>();
      final a = await android?.requestNotificationsPermission();
      final i = await ios?.requestPermissions(alert: true, badge: true, sound: true);
      final m = await mac?.requestPermissions(alert: true, badge: true, sound: true);
      return a ?? i ?? m ?? true;
    } catch (e) {
      debugPrint('NotificationService: permission request failed ($e)');
      return false;
    }
  }

  /// Schedules a repeating daily reminder.
  ///
  /// When today's prayers are already logged, the first fire is pushed to
  /// tomorrow so the reminder never nags after the job is done.
  Future<void> scheduleDaily({
    required int hour,
    required int minute,
    required String personName,
    required bool loggedToday,
  }) async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_reminderId);
      final now = tz.TZDateTime.now(tz.local);
      var next = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
      if (loggedToday || !next.isAfter(now)) {
        next = tz.TZDateTime(tz.local, now.year, now.month, now.day + 1, hour, minute);
      }

      await _plugin.zonedSchedule(
        _reminderId,
        'Tasks for Allah',
        "Time to record today's prayers, $personName",
        next,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'daily_reminder',
            'Daily reminder',
            channelDescription: 'Evening reminder to log the day\'s prayers',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      debugPrint('NotificationService: scheduling failed ($e)');
    }
  }

  Future<void> cancelReminder() async {
    if (!_ready) return;
    try {
      await _plugin.cancel(_reminderId);
    } catch (e) {
      debugPrint('NotificationService: cancel failed ($e)');
    }
  }
}
