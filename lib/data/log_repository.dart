import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'protein_log.dart';

const _boxName = 'protein_logs';
const _uuid = Uuid();

class LogRepository {
  Box<ProteinLog> get _box => Hive.box<ProteinLog>(_boxName);

  List<ProteinLog> logsForDay(DateTime day) {
    return _box.values
        .where((l) => _sameDay(l.timestamp, day))
        .toList()
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
      label: label?.trim().isNotEmpty == true ? label!.trim() : null,
      timestamp: DateTime.now(),
    );
    await _box.put(log.id, log);
    return log;
  }

  Future<void> remove(String id) => _box.delete(id);

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
