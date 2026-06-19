import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:proteingrid/data/providers.dart';

// Returns totals for each of the last 7 days, index 0 = oldest, 6 = today.
final weeklyTotalsProvider = Provider<List<({DateTime day, double total})>>((ref) {
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
  final repo = ref.read(logRepositoryProvider);
  ref.watch(todayLogsProvider);

  int streak = 0;
  final today = DateTime.now();

  // Check today first
  final todayLogs = repo.logsForDay(today);
  final todayTotal = todayLogs.fold(0.0, (s, l) => s + l.grams);
  if (todayTotal >= goal) streak++;

  // Walk backwards through past days
  for (int i = 1; i <= 365; i++) {
    final day = today.subtract(Duration(days: i));
    final logs = repo.logsForDay(day);
    final total = logs.fold(0.0, (s, l) => s + l.grams);
    if (total >= goal) {
      streak++;
    } else {
      break;
    }
  }
  return streak;
});

// All logs grouped by day for the history view.
final logsForDayProvider =
    Provider.family<List<dynamic>, DateTime>((ref, day) {
  ref.watch(todayLogsProvider);
  final repo = ref.read(logRepositoryProvider);
  return repo.logsForDay(day);
});

final selectedHistoryDayProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});
