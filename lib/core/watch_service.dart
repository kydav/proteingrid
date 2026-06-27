import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class WatchService {
  WatchService._();
  static final instance = WatchService._();

  static const _channel = MethodChannel('app.auaha.proteingrid/watch');

  Future<void> init({required Function(double grams) onWatchLog}) async {
    if (!Platform.isIOS) return;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'watchLog') {
        final grams = (call.arguments as num?)?.toDouble();
        if (grams != null && grams > 0) onWatchLog(grams);
      }
    });
  }

  Future<void> sync({
    required double todayTotal,
    required int dailyGoal,
    required int streak,
    required bool watchUnlocked,
  }) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('syncWatch', {
        'pg_today_total': todayTotal,
        'pg_daily_goal': dailyGoal,
        'pg_streak': streak,
        'watch_unlocked': watchUnlocked,
      });
    } catch (e) {
      debugPrint('WatchService sync error: $e');
    }
  }
}
