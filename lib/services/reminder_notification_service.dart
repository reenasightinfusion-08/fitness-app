import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color, TimeOfDay;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'package:fitness_app/features/profile/models/reminder.dart';

/// Schedules the user's stretch reminders as repeating local notifications, so
/// they fire at the right time even when the app is closed or offline. The
/// reminders themselves live on the server; this only mirrors them onto the
/// phone ([sync]) whenever they are loaded or changed.
class ReminderNotificationService {
  ReminderNotificationService._();
  static final ReminderNotificationService instance =
      ReminderNotificationService._();

  /// Same green as the app's accent, used to tint the small status-bar logo.
  static const _brandColor = Color(0xFF1C6A56);

  /// One message per weekday (index 0 = Monday), so the reminders feel fresh
  /// through the week instead of repeating one line.
  static const _messages = <(String, String)>[
    ('Start the week loose 🌿', 'A 5-minute reset wakes your body up.'),
    ('Your body is calling 🧘', 'Release yesterday\'s tension with one short routine.'),
    ('Midweek stretch break', 'Shoulders creeping up? Roll them out in a few minutes.'),
    ('Keep your streak alive 🔥', 'Stretch today and keep the momentum going.'),
    ('Finish the week feeling light ✨', 'Unwind with a gentle routine before the weekend.'),
    ('Slow down, stretch out', 'Give your body some weekend love.'),
    ('Ease into the week ahead 🌙', 'A calm stretch tonight sets up a better Monday.'),
  ];

  NotificationDetails _details(String title, String body) => NotificationDetails(
    android: AndroidNotificationDetails(
      'daily_reminders',
      'Daily reminders',
      channelDescription: 'Your daily stretch reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: 'ic_stat_logo',
      color: _brandColor,
      largeIcon: const DrawableResourceAndroidBitmap('notification_logo'),
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'Loosen',
      ),
      category: AndroidNotificationCategory.reminder,
      visibility: NotificationVisibility.public,
      ticker: title,
    ),
    iOS: const DarwinNotificationDetails(
      presentAlert: true,
      presentSound: true,
    ),
  );

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    try {
      tz_data.initializeTimeZones();
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      debugPrint('[Reminders] timezone setup failed, using UTC: $e');
    }
    try {
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('[Reminders] notification setup failed: $e');
    }
  }

  /// Asks the OS for permission to show notifications (Android 13+ and iOS).
  /// Returns whether it was granted.
  Future<bool> requestPermission() async {
    await init();
    if (!_ready) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final androidGranted = await android?.requestNotificationsPermission();
    final iosGranted = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidGranted ?? iosGranted ?? false;
  }

  /// Replaces everything scheduled with [reminders]: one weekly notification
  /// per switched-on reminder per chosen weekday, greeting [name] when known.
  Future<void> sync(List<ReminderEntry> reminders, {String name = ''}) async {
    await init();
    if (!_ready) return;
    await _plugin.cancelAll();
    for (var i = 0; i < reminders.length; i++) {
      final reminder = reminders[i];
      if (!reminder.isOn) continue;
      for (final weekday in reminder.days) {
        final (title, message) = _messages[weekday - 1];
        final body = name.trim().isEmpty ? message : '${name.trim()}, $message';
        await _plugin.zonedSchedule(
          i * 10 + weekday,
          title,
          body,
          _nextOccurrence(reminder.time, weekday),
          _details(title, body),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      }
    }
  }

  Future<void> cancelAll() async {
    await init();
    if (_ready) await _plugin.cancelAll();
  }

  /// The next [weekday] (1 = Monday) at [time], strictly in the future.
  tz.TZDateTime _nextOccurrence(TimeOfDay time, int weekday) {
    final now = tz.TZDateTime.now(tz.local);
    var at = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    while (at.weekday != weekday || !at.isAfter(now)) {
      at = at.add(const Duration(days: 1));
    }
    return at;
  }
}
