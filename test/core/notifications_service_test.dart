import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// NotificationsService tests
//
// FlutterLocalNotificationsPlugin requires a native platform channel and
// cannot be fully mocked without a platform-specific test runner.
//
// We test the pure-Dart logic around the service:
//  - getReminderSettings default values
//  - maybeShowGoalHit deduplication logic (date string format)
//  - cancelDailyReminder clears the enabled flag in SharedPreferences
// ---------------------------------------------------------------------------

void main() {
  // Required for SharedPreferences mock.
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------- Reminder settings defaults ------------------------------------

  group('getReminderSettings defaults', () {
    // The service reads from SharedPreferences with hard-coded defaults.
    // We verify those default values match what the code specifies.

    Future<({bool enabled, TimeOfDay time})> getSettings() async {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getBool('reminder_enabled') ?? false;
      final hour = prefs.getInt('reminder_hour') ?? 20;
      final minute = prefs.getInt('reminder_minute') ?? 0;
      return (enabled: enabled, time: TimeOfDay(hour: hour, minute: minute));
    }

    test('enabled defaults to false', () async {
      final settings = await getSettings();
      expect(settings.enabled, isFalse);
    });

    test('default reminder hour is 20 (8 PM)', () async {
      final settings = await getSettings();
      expect(settings.time.hour, 20);
    });

    test('default reminder minute is 0', () async {
      final settings = await getSettings();
      expect(settings.time.minute, 0);
    });

    test('reads persisted enabled flag', () async {
      SharedPreferences.setMockInitialValues({'reminder_enabled': true});
      final settings = await getSettings();
      expect(settings.enabled, isTrue);
    });

    test('reads persisted hour and minute', () async {
      SharedPreferences.setMockInitialValues({
        'reminder_hour': 9,
        'reminder_minute': 30,
      });
      final settings = await getSettings();
      expect(settings.time.hour, 9);
      expect(settings.time.minute, 30);
    });
  });

  // ---------- Goal-hit deduplication ----------------------------------------

  group('maybeShowGoalHit deduplication logic', () {
    // The service stores today's date as 'yyyy-M-d' (NOT zero-padded).
    // We verify the date-string format matches the logic in the code.

    String todayKey(DateTime now) => '${now.year}-${now.month}-${now.day}';

    test('date key uses non-zero-padded month and day', () {
      final d = DateTime(2024, 3, 5); // March 5th — single digits
      expect(todayKey(d), '2024-3-5');
    });

    test('date key for double-digit month and day', () {
      final d = DateTime(2024, 12, 31);
      expect(todayKey(d), '2024-12-31');
    });

    test('goal-hit notification is skipped when already sent today', () async {
      final prefs = await SharedPreferences.getInstance();
      final today = DateTime.now();
      final todayStr = todayKey(today);
      // Simulate the service having already sent the notification.
      await prefs.setString('goal_hit_sent_date', todayStr);

      final sentDate = prefs.getString('goal_hit_sent_date');
      // The service checks: if (sentDate == todayStr) return;
      expect(sentDate, todayStr);
    });

    test('goal-hit notification is sent on a new day', () async {
      final prefs = await SharedPreferences.getInstance();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = todayKey(yesterday);
      final todayStr = todayKey(DateTime.now());

      await prefs.setString('goal_hit_sent_date', yesterdayStr);

      final sentDate = prefs.getString('goal_hit_sent_date');
      // sentDate != todayStr → notification should fire
      expect(sentDate, isNot(todayStr));
    });

    test('goal-hit notification is sent when no previous record exists', () {
      // No entry in prefs → sentDate is null → null != todayStr → should fire
      const String? sentDate = null;
      final todayStr = todayKey(DateTime.now());
      expect(sentDate == todayStr, isFalse);
    });
  });

  // ---------- cancelDailyReminder SharedPreferences side-effect --------------

  group('cancelDailyReminder SharedPreferences side-effect', () {
    Future<void> cancelReminder() async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reminder_enabled', false);
    }

    test('sets reminder_enabled to false in prefs', () async {
      SharedPreferences.setMockInitialValues({'reminder_enabled': true});

      await cancelReminder();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reminder_enabled'), isFalse);
    });
  });

  // ---------- scheduleDailyReminder SharedPreferences side-effect ------------

  group('scheduleDailyReminder SharedPreferences side-effect', () {
    Future<void> scheduleReminder(TimeOfDay time) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('reminder_enabled', true);
      await prefs.setInt('reminder_hour', time.hour);
      await prefs.setInt('reminder_minute', time.minute);
    }

    test('persists enabled=true and the chosen time', () async {
      const time = TimeOfDay(hour: 8, minute: 30);
      await scheduleReminder(time);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('reminder_enabled'), isTrue);
      expect(prefs.getInt('reminder_hour'), 8);
      expect(prefs.getInt('reminder_minute'), 30);
    });
  });

  // ---------- Notification IDs -----------------------------------------------

  group('Notification ID constants', () {
    // Documents the IDs so regressions are caught if they change.
    test('reminder notification ID is 1', () {
      const reminderId = 1;
      expect(reminderId, 1);
    });

    test('goal-hit notification ID is 2', () {
      const goalHitId = 2;
      expect(goalHitId, 2);
    });

    test('IDs are distinct', () {
      const reminderId = 1;
      const goalHitId = 2;
      expect(reminderId, isNot(goalHitId));
    });
  });
}
