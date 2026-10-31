import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _reminderEnabledKey = 'reminder_enabled';
const _reminderHourKey = 'reminder_hour';
const _reminderMinuteKey = 'reminder_minute';
const _goalHitSentTodayKey = 'goal_hit_sent_date';
const _extraRemindersKey = 'extra_reminders';
const _reminderId = 1;
const _goalHitId = 2;
const _extraReminderIds = [3, 4];

/// Extra reminder times beyond the main one (Pro).
const kMaxExtraReminders = 2;

class NotificationsService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _plugin.initialize(
      const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final granted =
        await ios?.requestPermissions(alert: true, badge: true, sound: true) ??
        false;
    return granted;
  }

  /// Whether today's goal is already hit; reminders skip today if so.
  static bool _goalHitToday = false;

  /// Schedules one repeating daily reminder at [time], starting today, or
  /// tomorrow when today's time has passed or the goal is already hit.
  static Future<void> _schedule(int id, TimeOfDay time) async {
    await _plugin.cancel(id);
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );
    if (scheduled.isBefore(now) || _goalHitToday) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    await _plugin.zonedSchedule(
      id,
      "Don't forget your protein 💪",
      "Tap to log what you've had today.",
      scheduled,
      const NotificationDetails(
        android: AndroidNotificationDetails('daily_reminder', 'Daily reminder'),
        iOS: DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Re-plans every reminder for whether today's goal is hit: once it is,
  /// today's remaining reminders are skipped (they resume tomorrow).
  static Future<void> refreshForToday({required bool goalHit}) async {
    if (goalHit == _goalHitToday && _planned) return;
    _goalHitToday = goalHit;
    _planned = true;
    final main = await getReminderSettings();
    if (main.enabled) await _schedule(_reminderId, main.time);
    final extras = await getExtraReminders();
    for (var i = 0; i < extras.length && i < _extraReminderIds.length; i++) {
      await _schedule(_extraReminderIds[i], extras[i]);
    }
  }

  static bool _planned = false;

  static Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _schedule(_reminderId, time);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, true);
    await prefs.setInt(_reminderHourKey, time.hour);
    await prefs.setInt(_reminderMinuteKey, time.minute);
  }

  static Future<void> cancelDailyReminder() async {
    await _plugin.cancel(_reminderId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_reminderEnabledKey, false);
  }

  /// The extra reminder times (Pro), in order.
  static Future<List<TimeOfDay>> getExtraReminders() async {
    final prefs = await SharedPreferences.getInstance();
    return [
      for (final s in prefs.getStringList(_extraRemindersKey) ?? const [])
        if (s.split(':') case [final h, final m])
          TimeOfDay(hour: int.parse(h), minute: int.parse(m)),
    ];
  }

  /// Replaces the extra reminders with [times] (at most [kMaxExtraReminders]).
  static Future<void> setExtraReminders(List<TimeOfDay> times) async {
    final kept = times.take(kMaxExtraReminders).toList();
    for (final id in _extraReminderIds) {
      await _plugin.cancel(id);
    }
    for (var i = 0; i < kept.length; i++) {
      await _schedule(_extraReminderIds[i], kept[i]);
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_extraRemindersKey, [
      for (final t in kept) '${t.hour}:${t.minute}',
    ]);
  }

  static Future<({bool enabled, TimeOfDay time})> getReminderSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_reminderEnabledKey) ?? false;
    final hour = prefs.getInt(_reminderHourKey) ?? 20;
    final minute = prefs.getInt(_reminderMinuteKey) ?? 0;
    return (enabled: enabled, time: TimeOfDay(hour: hour, minute: minute));
  }

  static Future<void> maybeShowGoalHit() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    final sentDate = prefs.getString(_goalHitSentTodayKey);
    if (sentDate == todayStr) return; // already sent today

    await prefs.setString(_goalHitSentTodayKey, todayStr);
    await _plugin.show(
      _goalHitId,
      'Goal hit! 🎉',
      "You've hit your daily protein goal. Great work!",
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'goal_hit',
          'Goal achieved',
          importance: Importance.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
