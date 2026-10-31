import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proteingrid/data/providers.dart';

DateTime dayOf(DateTime t) => DateTime(t.year, t.month, t.day);

/// Total grams per day (midnight keys), over every log — one pass, so the
/// year grid and streaks don't rescan the box per day.
final dailyTotalsProvider = Provider<Map<DateTime, double>>((ref) {
  ref.watch(todayLogsProvider); // rebuild when logs change
  final totals = <DateTime, double>{};
  for (final l in ref.read(logRepositoryProvider).allLogs()) {
    final d = dayOf(l.timestamp);
    totals[d] = (totals[d] ?? 0) + l.grams;
  }
  return totals;
});

/// Longest run of goal days ever (against today's goal).
final bestStreakProvider = Provider<int>((ref) {
  final goal = ref.watch(dailyGoalProvider);
  final hit =
      ref
          .watch(dailyTotalsProvider)
          .entries
          .where((e) => e.value >= goal)
          .map((e) => e.key)
          .toList()
        ..sort();
  var best = 0;
  var run = 0;
  DateTime? prev;
  for (final d in hit) {
    final next = prev == null
        ? null
        : DateTime(prev.year, prev.month, prev.day + 1);
    run = next == d ? run + 1 : 1;
    if (run > best) best = run;
    prev = d;
  }
  return best;
});

/// Share of the last `days` days the goal was hit, 0–1.
final hitRateProvider = Provider.family<double, int>((ref, days) {
  final goal = ref.watch(dailyGoalProvider);
  final totals = ref.watch(dailyTotalsProvider);
  final today = dayOf(DateTime.now());
  var hits = 0;
  for (var i = 0; i < days; i++) {
    final d = DateTime(today.year, today.month, today.day - i);
    if ((totals[d] ?? 0) >= goal) hits++;
  }
  return hits / days;
});

// Returns totals for each of the last 7 days, index 0 = oldest, 6 = today.
final weeklyTotalsProvider = Provider<List<({DateTime day, double total})>>((
  ref,
) {
  ref.watch(todayLogsProvider); // rebuild when today's logs change
  final repo = ref.read(logRepositoryProvider);
  final today = DateTime.now();
  return List.generate(7, (i) {
    final day = today.subtract(Duration(days: 6 - i));
    final logs = repo.logsForDay(day);
    final total = logs.fold(0.0, (sum, l) => sum + l.grams);
    return (day: day, total: total);
  });
});

final weeklyAverageProvider = Provider<double>((ref) {
  final totals = ref.watch(weeklyTotalsProvider);
  final nonZero = totals.where((d) => d.total > 0).toList();
  if (nonZero.isEmpty) return 0;
  return nonZero.fold(0.0, (sum, d) => sum + d.total) / nonZero.length;
});

// Current streak: consecutive days (going back from yesterday) where total >= goal.
// Today counts only if the goal is already hit.
final streakProvider = Provider<int>((ref) {
  final goal = ref.watch(dailyGoalProvider);
  final totals = ref.watch(dailyTotalsProvider);
  final today = dayOf(DateTime.now());
  var streak = (totals[today] ?? 0) >= goal ? 1 : 0;
  for (var i = 1; i <= 3650; i++) {
    final day = DateTime(today.year, today.month, today.day - i);
    if ((totals[day] ?? 0) < goal) break;
    streak++;
  }
  return streak;
});

// All logs grouped by day for the history view.
final logsForDayProvider = Provider.family<List<dynamic>, DateTime>((ref, day) {
  ref.watch(todayLogsProvider);
  final repo = ref.read(logRepositoryProvider);
  return repo.logsForDay(day);
});

final selectedHistoryDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
