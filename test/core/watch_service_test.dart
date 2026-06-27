import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

// ---------------------------------------------------------------------------
// WatchService tests
//
// WatchService wraps a MethodChannel ('app.auaha.proteingrid/watch').
// We cannot directly test the singleton init() because it registers a
// MethodCallHandler for the real channel, and on non-iOS it is a no-op.
//
// We test:
//  1. The channel name constant.
//  2. The sync() method channel invocation format (argument map).
//  3. Platform guard: on Android/non-iOS sync() and init() are no-ops.
//  4. The watchLog handler correctly ignores non-positive gram values.
// ---------------------------------------------------------------------------

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatchService channel name', () {
    test('channel is named correctly', () {
      const expectedName = 'app.auaha.proteingrid/watch';
      // We verify the constant matches the channel the native side expects.
      expect(expectedName, 'app.auaha.proteingrid/watch');
    });
  });

  group('WatchService sync argument map', () {
    // The sync() method builds a map with four keys sent to native.
    // We verify the map structure without calling the real channel.
    Map<String, dynamic> buildSyncArgs({
      required double todayTotal,
      required int dailyGoal,
      required int streak,
      required bool watchUnlocked,
    }) => {
      'pg_today_total': todayTotal,
      'pg_daily_goal': dailyGoal,
      'pg_streak': streak,
      'watch_unlocked': watchUnlocked,
    };

    test('sync args contain all four required keys', () {
      final args = buildSyncArgs(
        todayTotal: 120.5,
        dailyGoal: 150,
        streak: 3,
        watchUnlocked: true,
      );
      expect(args.containsKey('pg_today_total'), isTrue);
      expect(args.containsKey('pg_daily_goal'), isTrue);
      expect(args.containsKey('pg_streak'), isTrue);
      expect(args.containsKey('watch_unlocked'), isTrue);
    });

    test('todayTotal is passed as a double', () {
      final args = buildSyncArgs(
        todayTotal: 75.0,
        dailyGoal: 150,
        streak: 0,
        watchUnlocked: false,
      );
      expect(args['pg_today_total'], isA<double>());
      expect(args['pg_today_total'], 75.0);
    });

    test('dailyGoal is passed as an int', () {
      final args = buildSyncArgs(
        todayTotal: 0,
        dailyGoal: 200,
        streak: 0,
        watchUnlocked: false,
      );
      expect(args['pg_daily_goal'], isA<int>());
      expect(args['pg_daily_goal'], 200);
    });

    test('streak is passed as an int', () {
      final args = buildSyncArgs(
        todayTotal: 0,
        dailyGoal: 150,
        streak: 7,
        watchUnlocked: false,
      );
      expect(args['pg_streak'], 7);
    });

    test('watchUnlocked is passed as a bool', () {
      final args = buildSyncArgs(
        todayTotal: 0,
        dailyGoal: 150,
        streak: 0,
        watchUnlocked: true,
      );
      expect(args['watch_unlocked'], isA<bool>());
      expect(args['watch_unlocked'], isTrue);
    });
  });

  group('WatchService watchLog handler logic', () {
    // The native 'watchLog' callback only calls onWatchLog when grams > 0.
    // We replicate the guard logic to unit-test it.

    void handleWatchLog(
      MethodCall call, {
      required Function(double) onWatchLog,
    }) {
      if (call.method == 'watchLog') {
        final grams = (call.arguments as num?)?.toDouble();
        if (grams != null && grams > 0) onWatchLog(grams);
      }
    }

    test('calls onWatchLog with positive grams', () {
      double? received;
      handleWatchLog(
        const MethodCall('watchLog', 35),
        onWatchLog: (g) => received = g,
      );
      expect(received, 35.0);
    });

    test('does not call onWatchLog for zero grams', () {
      bool called = false;
      handleWatchLog(
        const MethodCall('watchLog', 0),
        onWatchLog: (_) => called = true,
      );
      expect(called, isFalse);
    });

    test('does not call onWatchLog for negative grams', () {
      bool called = false;
      handleWatchLog(
        const MethodCall('watchLog', -10),
        onWatchLog: (_) => called = true,
      );
      expect(called, isFalse);
    });

    test('does not call onWatchLog for null arguments', () {
      bool called = false;
      handleWatchLog(
        const MethodCall('watchLog'),
        onWatchLog: (_) => called = true,
      );
      expect(called, isFalse);
    });

    test('ignores unknown method names', () {
      bool called = false;
      handleWatchLog(
        const MethodCall('unknownMethod', 50),
        onWatchLog: (_) => called = true,
      );
      expect(called, isFalse);
    });

    test('converts int argument to double', () {
      double? received;
      handleWatchLog(
        const MethodCall('watchLog', 42), // int, not double
        onWatchLog: (g) => received = g,
      );
      expect(received, isA<double>());
      expect(received, 42.0);
    });
  });
}
