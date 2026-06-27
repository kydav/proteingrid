import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:proteingrid/data/protein_log.dart';

// ---------------------------------------------------------------------------
// CSV export logic tests
//
// The export code in SettingsScreen._exportCsv() builds a CSV string from
// all logs.  We extract and test the formatting logic in isolation:
//
//   Date,Time,Grams,Label\n
//   2024-06-15,09:30:00,30.0,Chicken breast\n
//
// Known issue to flag in PR: commas in label values are replaced with ';'
// which is correct, but the date format uses DateFormat('yyyy-MM-dd') which
// zero-pads — different from the non-padded format used in
// NotificationsService for the goal_hit_sent_date key.
// ---------------------------------------------------------------------------

// Mirror of the CSV generation logic from SettingsScreen._exportCsv.
String _buildCsv(List<ProteinLog> logs) {
  final dateFmt = DateFormat('yyyy-MM-dd');
  final timeFmt = DateFormat('HH:mm:ss');
  final buf = StringBuffer('Date,Time,Grams,Label\n');
  for (final log in logs) {
    final label = (log.label ?? '').replaceAll(',', ';');
    buf.writeln(
      '${dateFmt.format(log.timestamp)},${timeFmt.format(log.timestamp)},${log.grams.toStringAsFixed(1)},$label',
    );
  }
  return buf.toString();
}

ProteinLog _log({
  required String id,
  required double grams,
  required DateTime timestamp,
  String? label,
}) => ProteinLog(id: id, grams: grams, timestamp: timestamp, label: label);

void main() {
  group('CSV export format', () {
    test('header row is correct', () {
      final csv = _buildCsv([]);
      expect(csv, startsWith('Date,Time,Grams,Label\n'));
    });

    test('empty log list produces header only', () {
      final csv = _buildCsv([]);
      // Just the header line.
      expect(csv.trim(), 'Date,Time,Grams,Label');
    });

    test('date is formatted as yyyy-MM-dd (zero-padded)', () {
      final log = _log(
        id: '1',
        grams: 30,
        timestamp: DateTime(2024, 3, 5, 9, 30), // March 5th
      );
      final csv = _buildCsv([log]);
      expect(csv, contains('2024-03-05'));
    });

    test('time is formatted as HH:mm:ss (24-hour, zero-padded)', () {
      final log = _log(
        id: '1',
        grams: 30,
        timestamp: DateTime(2024, 6, 15, 9, 5, 3), // 9:05:03 AM
      );
      final csv = _buildCsv([log]);
      expect(csv, contains('09:05:03'));
    });

    test('grams are formatted to 1 decimal place', () {
      final log = _log(id: '1', grams: 30.0, timestamp: DateTime(2024, 6, 15));
      final csv = _buildCsv([log]);
      expect(csv, contains('30.0'));
    });

    test('fractional grams preserve one decimal', () {
      final log = _log(id: '1', grams: 27.5, timestamp: DateTime(2024, 6, 15));
      final csv = _buildCsv([log]);
      expect(csv, contains('27.5'));
    });

    test('null label exports as empty field', () {
      final log = _log(id: '1', grams: 30, timestamp: DateTime(2024, 6, 15));
      final lines = _buildCsv([log]).split('\n');
      // Second line: Date,Time,Grams,<empty>
      final parts = lines[1].split(',');
      expect(parts[3], '');
    });

    test('label with commas has commas replaced by semicolons', () {
      final log = _log(
        id: '1',
        grams: 30,
        timestamp: DateTime(2024, 6, 15),
        label: 'Eggs, bacon',
      );
      final csv = _buildCsv([log]);
      expect(csv, isNot(contains('"'))); // no quoting
      expect(csv, contains('Eggs; bacon'));
    });

    test('normal label is not modified', () {
      final log = _log(
        id: '1',
        grams: 30,
        timestamp: DateTime(2024, 6, 15),
        label: 'Chicken breast',
      );
      final csv = _buildCsv([log]);
      expect(csv, contains('Chicken breast'));
    });

    test('multiple logs produce multiple data rows', () {
      final logs = [
        _log(id: '1', grams: 30, timestamp: DateTime(2024, 6, 15, 8)),
        _log(id: '2', grams: 45, timestamp: DateTime(2024, 6, 15, 12)),
      ];
      final lines = _buildCsv(logs).trim().split('\n');
      // Header + 2 data rows
      expect(lines.length, 3);
    });

    test('each data row has exactly 4 comma-separated fields', () {
      final log = _log(
        id: '1',
        grams: 30,
        timestamp: DateTime(2024, 6, 15),
        label: 'Tuna',
      );
      final lines = _buildCsv([log]).trim().split('\n');
      final dataRow = lines[1];
      expect(dataRow.split(',').length, 4);
    });
  });

  group('CSV export edge cases', () {
    test('handles very large gram values', () {
      final log = _log(
        id: '1',
        grams: 9999.9,
        timestamp: DateTime(2024, 6, 15),
      );
      final csv = _buildCsv([log]);
      expect(csv, contains('9999.9'));
    });

    test('handles a label that is only semicolons after replacement', () {
      final log = _log(
        id: '1',
        grams: 30,
        timestamp: DateTime(2024, 6, 15),
        label: ',,,',
      );
      final csv = _buildCsv([log]);
      expect(csv, contains(';;;'));
    });
  });
}
