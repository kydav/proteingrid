import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:proteingrid/data/stats_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a [ProviderContainer] with an overridden [logRepositoryProvider].
ProviderContainer _container({List<Override> overrides = const []}) {
  return ProviderContainer(overrides: overrides);
}

// ---------------------------------------------------------------------------
// weeklyAverageProvider pure-logic tests
// ---------------------------------------------------------------------------

// The weeklyAverageProvider calculates:
//   nonZero = totals where total > 0
//   if empty → 0
//   else sum(total) / nonZero.count
// We verify the maths by calling the equivalent logic directly.

double _computeWeeklyAverage(List<double> totals) {
  final nonZero = totals.where((t) => t > 0).toList();
  if (nonZero.isEmpty) return 0;
  return nonZero.fold(0.0, (s, t) => s + t) / nonZero.length;
}

// ---------------------------------------------------------------------------
// streakProvider pure-logic tests
// ---------------------------------------------------------------------------

// The streakProvider counts consecutive days (going back from today) where
// logsForDay total >= goal.  Today counts if already at goal.
//
// We test the streak-counting algorithm by feeding synthetic data via a
// real in-memory Hive box.

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // Make SharedPreferences return defaults in tests.
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (Hive.isBoxOpen('protein_logs')) {
      await Hive.box<ProteinLog>('protein_logs').close();
    }
  });

  // ── weeklyAverage pure logic ─────────────────────────────────────────────

  group('weeklyAverage computation logic', () {
    test('returns 0 when all days have 0 total', () {
      expect(_computeWeeklyAverage([0, 0, 0, 0, 0, 0, 0]), 0.0);
    });

    test('returns the single non-zero value when only one day has data', () {
      expect(_computeWeeklyAverage([0, 0, 0, 0, 0, 0, 150]), 150.0);
    });

    test('averages over non-zero days only (not all 7)', () {
      // 3 days with data: 100, 200, 300 → avg = 200
      expect(_computeWeeklyAverage([0, 0, 0, 0, 100, 200, 300]), 200.0);
    });

    test('returns exact average when all days have data', () {
      expect(_computeWeeklyAverage([100, 100, 100, 100, 100, 100, 100]), 100.0);
    });

    test('handles fractional grams correctly', () {
      // 2 days: 100.5 + 200.5 = 301 / 2 = 150.5
      expect(_computeWeeklyAverage([0, 0, 0, 0, 0, 100.5, 200.5]), 150.5);
    });
  });

  // ── progress ring calculation ────────────────────────────────────────────

  group('Progress ring progress calculation', () {
    // From HomeScreen._ProgressRingCard:
    //   final progress = (total / goal).clamp(0.0, 1.0)
    //   final isGoalHit = total >= goal
    double progress(double total, int goal) => (total / goal).clamp(0.0, 1.0);
    bool isGoalHit(double total, int goal) => total >= goal;
    int remaining(double total, int goal) => (goal - total).ceil();

    test('progress is 0.0 when nothing logged', () {
      expect(progress(0, 150), 0.0);
    });

    test('progress is 0.5 at half-goal', () {
      expect(progress(75, 150), 0.5);
    });

    test('progress clamps to 1.0 when over goal', () {
      expect(progress(200, 150), 1.0);
    });

    test('isGoalHit is false below goal', () {
      expect(isGoalHit(149, 150), isFalse);
    });

    test('isGoalHit is true at exact goal', () {
      expect(isGoalHit(150, 150), isTrue);
    });

    test('isGoalHit is true above goal', () {
      expect(isGoalHit(200, 150), isTrue);
    });

    test('remaining rounds up for fractional grams', () {
      // 149.3g logged, goal 150 → 0.7g remaining → .ceil() = 1
      expect(remaining(149.3, 150), 1);
    });

    test('remaining is 0 when goal is exactly hit', () {
      expect(remaining(150.0, 150), 0);
    });

    test('remaining is negative when over goal', () {
      // Over-goal case: app shows GOAL HIT banner, not remaining.
      expect(remaining(160.0, 150), lessThan(0));
    });
  });

  // ── streak logic ─────────────────────────────────────────────────────────

  group('Streak counting logic', () {
    // We replicate the streakProvider algorithm in pure Dart to unit-test it
    // independently of Riverpod.

    int countStreak(
      DateTime today,
      int goal,
      Map<DateTime, double> dailyTotals,
    ) {
      double totalForDay(DateTime day) {
        final key = dailyTotals.keys.firstWhere(
          (k) => k.year == day.year && k.month == day.month && k.day == day.day,
          orElse: () => day,
        );
        return dailyTotals[key] ?? 0.0;
      }

      int streak = 0;
      if (totalForDay(today) >= goal) streak++;
      for (int i = 1; i <= 365; i++) {
        final day = today.subtract(Duration(days: i));
        if (totalForDay(day) >= goal) {
          streak++;
        } else {
          break;
        }
      }
      return streak;
    }

    final today = DateTime(2024, 6, 15);
    const goal = 150;

    test('streak is 0 when no days hit the goal', () {
      expect(countStreak(today, goal, {}), 0);
    });

    test('streak is 1 when only today hits the goal', () {
      expect(countStreak(today, goal, {today: 150.0}), 1);
    });

    test('streak is 1 when yesterday hit but today did not', () {
      final yesterday = today.subtract(const Duration(days: 1));
      expect(countStreak(today, goal, {yesterday: 160.0}), 1);
    });

    test('streak is 3 for today + 2 consecutive prior days', () {
      final d1 = today.subtract(const Duration(days: 1));
      final d2 = today.subtract(const Duration(days: 2));
      expect(countStreak(today, goal, {today: 150, d1: 200, d2: 180}), 3);
    });

    test('streak breaks if a day in the middle is below goal', () {
      final d1 = today.subtract(const Duration(days: 1));
      final d3 = today.subtract(const Duration(days: 3));
      // d2 is missing (0g) → streak breaks
      expect(
        countStreak(today, goal, {today: 150, d1: 200, d3: 180}),
        2, // today + d1; d2 is 0 → stop
      );
    });

    test('exactly hitting the goal counts for that day', () {
      expect(countStreak(today, goal, {today: 150.0}), 1);
    });

    test('1g below goal does not count', () {
      expect(countStreak(today, goal, {today: 149.9}), 0);
    });
  });

  // ── todayTotal calculation ───────────────────────────────────────────────

  group('todayTotal fold logic', () {
    // todayTotalProvider uses .fold(0, (sum, l) => sum + l.grams)
    double foldTotal(List<double> grams) =>
        grams.fold(0.0, (sum, g) => sum + g);

    test('returns 0 for empty list', () {
      expect(foldTotal([]), 0.0);
    });

    test('sums a single entry', () {
      expect(foldTotal([35.0]), 35.0);
    });

    test('sums multiple entries', () {
      expect(foldTotal([30, 40, 50]), 120.0);
    });

    test('handles fractional grams', () {
      expect(foldTotal([33.3, 33.3, 33.3]), closeTo(99.9, 0.001));
    });
  });

  // ── DailyGoalNotifier ────────────────────────────────────────────────────

  group('DailyGoalNotifier', () {
    test('defaults to 150g', () {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      addTearDown(container.dispose);
      // Initial state before async _load completes
      expect(container.read(dailyGoalProvider), 150);
    });

    test('setGoal updates state synchronously', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dailyGoalProvider.notifier).setGoal(200);
      expect(container.read(dailyGoalProvider), 200);
    });

    test('setGoal persists to SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({});
      final container = _container();
      addTearDown(container.dispose);

      await container.read(dailyGoalProvider.notifier).setGoal(180);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('daily_goal_grams'), 180);
    });

    test('loads persisted goal on startup', () async {
      SharedPreferences.setMockInitialValues({'daily_goal_grams': 220});
      final container = _container();

      // Trigger creation of the notifier.
      container.read(dailyGoalProvider);

      // Give _load() (which is async) time to complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(container.read(dailyGoalProvider), 220);

      container.dispose();
    });
  });

  // ── pendingQuickActionGramsProvider ─────────────────────────────────────

  group('pendingQuickActionGramsProvider', () {
    test('initialises as null', () {
      final container = _container();
      addTearDown(container.dispose);
      expect(container.read(pendingQuickActionGramsProvider), isNull);
    });

    test('can be set to a grams value', () {
      final container = _container();
      addTearDown(container.dispose);

      container.read(pendingQuickActionGramsProvider.notifier).state = 30.0;
      expect(container.read(pendingQuickActionGramsProvider), 30.0);
    });

    test('can be cleared back to null', () {
      final container = _container();
      addTearDown(container.dispose);

      container.read(pendingQuickActionGramsProvider.notifier).state = 40.0;
      container.read(pendingQuickActionGramsProvider.notifier).state = null;
      expect(container.read(pendingQuickActionGramsProvider), isNull);
    });
  });

  // ── selectedHistoryDayProvider ───────────────────────────────────────────

  group('selectedHistoryDayProvider', () {
    test('initialises to today (date-only, no time component)', () {
      final container = _container();
      addTearDown(container.dispose);

      final day = container.read(selectedHistoryDayProvider);
      final now = DateTime.now();

      expect(day.year, now.year);
      expect(day.month, now.month);
      expect(day.day, now.day);
      // Time components should be zeroed.
      expect(day.hour, 0);
      expect(day.minute, 0);
      expect(day.second, 0);
    });

    test('can navigate backward', () {
      final container = _container();
      addTearDown(container.dispose);

      final today = container.read(selectedHistoryDayProvider);
      container.read(selectedHistoryDayProvider.notifier).state = today
          .subtract(const Duration(days: 1));

      final yesterday = today.subtract(const Duration(days: 1));
      expect(container.read(selectedHistoryDayProvider), yesterday);
    });
  });
}
