import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/notifications_service.dart';
import 'protein_log.dart';
import 'log_repository.dart';

const _goalKey = 'daily_goal_grams';
const _defaultGoal = 150;

final logRepositoryProvider = Provider<LogRepository>((_) => LogRepository());

// Notifier for the today's log list — call .refresh() to trigger rebuild.
final todayLogsProvider =
    StateNotifierProvider<TodayLogsNotifier, List<ProteinLog>>((ref) {
  return TodayLogsNotifier(ref.read(logRepositoryProvider));
});

class TodayLogsNotifier extends StateNotifier<List<ProteinLog>> {
  TodayLogsNotifier(this._repo) : super([]) {
    _load();
  }

  final LogRepository _repo;

  void _load() {
    state = _repo.logsForDay(DateTime.now());
  }

  Future<void> add({required double grams, String? label, int goal = 150}) async {
    await _repo.add(grams: grams, label: label);
    _load();
    // Fire goal-hit notification if we just crossed the threshold.
    final total = state.fold(0.0, (s, l) => s + l.grams);
    if (total >= goal) {
      NotificationsService.maybeShowGoalHit();
    }
  }

  Future<void> remove(String id) async {
    await _repo.remove(id);
    _load();
  }

  ProteinLog? get lastLog => state.isEmpty ? null : state.first;
}

final todayTotalProvider = Provider<double>((ref) {
  return ref.watch(todayLogsProvider).fold(0, (sum, l) => sum + l.grams);
});

final dailyGoalProvider =
    StateNotifierProvider<DailyGoalNotifier, int>((ref) {
  return DailyGoalNotifier();
});

class DailyGoalNotifier extends StateNotifier<int> {
  DailyGoalNotifier() : super(_defaultGoal) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getInt(_goalKey) ?? _defaultGoal;
  }

  Future<void> setGoal(int grams) async {
    state = grams;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_goalKey, grams);
  }
}

final recentLabelsProvider = Provider<List<String>>((ref) {
  ref.watch(todayLogsProvider); // rebuild when logs change
  return ref.read(logRepositoryProvider).recentLabels();
});

// Used by the quick action handler to pass a pre-filled gram value
// to the home screen so it can auto-open the log sheet.
final pendingQuickActionGramsProvider = StateProvider<double?>((ref) => null);
