import 'dart:math' as math;

import 'package:hive_flutter/hive_flutter.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:uuid/uuid.dart';

const _boxName = 'protein_logs';
const _uuid = Uuid();

class LogRepository {
  Box<ProteinLog> get _box => Hive.box<ProteinLog>(_boxName);

  List<ProteinLog> logsForDay(DateTime day) {
    return _box.values.where((l) => _sameDay(l.timestamp, day)).toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  List<ProteinLog> allLogs() {
    return _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<ProteinLog> add({required double grams, String? label}) async {
    final log = ProteinLog(
      id: _uuid.v4(),
      grams: grams,
      label: label?.trim().isNotEmpty ?? false ? label!.trim() : null,
      timestamp: DateTime.now(),
    );
    await _box.put(log.id, log);
    return log;
  }

  Future<void> remove(String id) => _box.delete(id);

  /// Debug builds only: a believable year of logs (most days hit [goal]) so
  /// screenshots show a lit-up Grid. Ids start with `sample-` so
  /// [clearSampleYear] can take them out again.
  Future<void> fillSampleYear({required int goal}) async {
    final rand = math.Random(7);
    final now = DateTime.now();
    final entries = <String, ProteinLog>{};
    for (var d = 300; d >= 1; d--) {
      final day = DateTime(now.year, now.month, now.day - d);
      // About three in four days hit the goal; streaky, like real life.
      final hit = rand.nextDouble() < (d % 40 < 6 ? 0.2 : 0.8);
      final target = hit
          ? goal * (1.0 + rand.nextDouble() * 0.2)
          : goal * (0.3 + rand.nextDouble() * 0.6);
      var logged = 0.0;
      var hour = 7;
      while (logged < target && hour < 21) {
        final g = (20 + rand.nextInt(5) * 5).toDouble();
        final t = DateTime(
          day.year,
          day.month,
          day.day,
          hour,
          rand.nextInt(60),
        );
        final id = 'sample-${t.millisecondsSinceEpoch}';
        entries[id] = ProteinLog(id: id, grams: g, timestamp: t);
        logged += g;
        hour += 2 + rand.nextInt(2);
      }
    }
    await _box.putAll(entries);
  }

  Future<void> clearSampleYear() async {
    await _box.deleteAll(_box.keys.where((k) => '$k'.startsWith('sample-')));
  }

  List<String> recentLabels() {
    final seen = <String>{};
    return _box.values
        .toList()
        .reversed
        .where((l) => l.label != null)
        .map((l) => l.label!)
        .where(seen.add)
        .take(6)
        .toList();
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
