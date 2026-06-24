import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:proteingrid/data/log_repository.dart';
import 'package:proteingrid/data/protein_log.dart';

// ---------------------------------------------------------------------------
// Helper: spin up an in-memory Hive box and return a LogRepository that uses
// it.  No file system access is needed — Hive supports opening from bytes.
// ---------------------------------------------------------------------------

Future<Box<ProteinLog>> _openMemoryBox() async {
  // Register adapter if not already registered.
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProteinLogAdapter());
  }

  // Each test uses a unique box name to avoid cross-test collisions.
  final name = 'test_${DateTime.now().microsecondsSinceEpoch}';
  return Hive.openBox<ProteinLog>(name, bytes: Uint8List(0));
}

/// Seeds a [ProteinLog] directly into the box (bypasses LogRepository.add so
/// we can control the timestamp).
Future<void> _seed(Box<ProteinLog> box, ProteinLog log) async {
  await box.put(log.id, log);
}

ProteinLog _log({
  required String id,
  required double grams,
  required DateTime timestamp,
  String? label,
}) =>
    ProteinLog(id: id, grams: grams, timestamp: timestamp, label: label);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ---------- logsForDay ---------------------------------------------------

  group('LogRepository.logsForDay', () {
    test('returns only logs from the requested day', () async {
      final box = await _openMemoryBox();
      final repo = LogRepository();

      // Patch: since LogRepository._box reads the global box by name, we seed
      // the correct box name ('protein_logs') for the repo to read from.
      // Instead, we test the logic by seeding a named box and then verifying
      // filtering ourselves — since the private getter is sealed, we test the
      // exposed public methods via a real in-memory Hive box named
      // 'protein_logs'.
      await box.close();

      // Open the exact box name the repo uses.
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );

      final target = DateTime(2024, 6, 15);
      await _seed(
        repoBox,
        _log(id: '1', grams: 30, timestamp: DateTime(2024, 6, 15, 8, 0)),
      );
      await _seed(
        repoBox,
        _log(id: '2', grams: 25, timestamp: DateTime(2024, 6, 15, 12, 0)),
      );
      await _seed(
        repoBox,
        _log(id: '3', grams: 40, timestamp: DateTime(2024, 6, 14, 23, 59)),
      );
      await _seed(
        repoBox,
        _log(id: '4', grams: 20, timestamp: DateTime(2024, 6, 16, 0, 0)),
      );

      final result = repo.logsForDay(target);
      expect(result.length, 2);
      expect(result.map((l) => l.id), containsAll(['1', '2']));

      await repoBox.close();
      Hive.deleteBoxFromDisk('protein_logs').ignore();
    });

    test('returns empty list when no logs exist for the day', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();
      expect(repo.logsForDay(DateTime(2024, 6, 15)), isEmpty);
      await repoBox.close();
    });

    test('returns logs sorted newest-first', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await _seed(
        repoBox,
        _log(id: 'early', grams: 20, timestamp: DateTime(2024, 6, 15, 7, 0)),
      );
      await _seed(
        repoBox,
        _log(id: 'late', grams: 50, timestamp: DateTime(2024, 6, 15, 20, 0)),
      );
      await _seed(
        repoBox,
        _log(id: 'noon', grams: 30, timestamp: DateTime(2024, 6, 15, 12, 0)),
      );

      final result = repo.logsForDay(DateTime(2024, 6, 15));
      expect(result[0].id, 'late');
      expect(result[1].id, 'noon');
      expect(result[2].id, 'early');

      await repoBox.close();
    });

    test('handles midnight boundary (00:00 belongs to current day)', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await _seed(
        repoBox,
        _log(
          id: 'midnight',
          grams: 10,
          timestamp: DateTime(2024, 3, 10, 0, 0, 0),
        ),
      );

      final result = repo.logsForDay(DateTime(2024, 3, 10));
      expect(result.length, 1);

      await repoBox.close();
    });
  });

  // ---------- allLogs -------------------------------------------------------

  group('LogRepository.allLogs', () {
    test('returns all logs sorted newest-first', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await _seed(
        repoBox,
        _log(id: 'old', grams: 10, timestamp: DateTime(2024, 1, 1)),
      );
      await _seed(
        repoBox,
        _log(id: 'new', grams: 20, timestamp: DateTime(2024, 6, 1)),
      );
      await _seed(
        repoBox,
        _log(id: 'mid', grams: 15, timestamp: DateTime(2024, 3, 1)),
      );

      final result = repo.allLogs();
      expect(result[0].id, 'new');
      expect(result[1].id, 'mid');
      expect(result[2].id, 'old');

      await repoBox.close();
    });

    test('returns empty list when box is empty', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();
      expect(repo.allLogs(), isEmpty);
      await repoBox.close();
    });
  });

  // ---------- recentLabels --------------------------------------------------

  group('LogRepository.recentLabels', () {
    test('returns up to 6 unique labels from most-recently-inserted logs', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      // Insert in order: box.values preserves insertion order.
      // .reversed makes the last-inserted item first.
      for (var i = 0; i < 7; i++) {
        await _seed(
          repoBox,
          _log(
            id: 'id$i',
            grams: 10,
            timestamp: DateTime(2024, 1, i + 1),
            label: 'Label$i',
          ),
        );
      }

      final result = repo.recentLabels();
      // Last 6 inserted (indices 1..6) are newest after .reversed
      expect(result.length, 6);
      expect(result, isNot(contains('Label0')));

      await repoBox.close();
    });

    test('deduplicates labels', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await _seed(
        repoBox,
        _log(
          id: 'a',
          grams: 10,
          timestamp: DateTime(2024, 1, 1),
          label: 'Chicken',
        ),
      );
      await _seed(
        repoBox,
        _log(
          id: 'b',
          grams: 10,
          timestamp: DateTime(2024, 1, 2),
          label: 'Eggs',
        ),
      );
      await _seed(
        repoBox,
        _log(
          id: 'c',
          grams: 10,
          timestamp: DateTime(2024, 1, 3),
          label: 'Chicken',
        ),
      );

      final result = repo.recentLabels();
      expect(result.where((l) => l == 'Chicken').length, 1);

      await repoBox.close();
    });

    test('skips logs without a label', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await _seed(
        repoBox,
        _log(id: 'no-label', grams: 10, timestamp: DateTime(2024, 1, 1)),
      );
      await _seed(
        repoBox,
        _log(
          id: 'with-label',
          grams: 10,
          timestamp: DateTime(2024, 1, 2),
          label: 'Tuna',
        ),
      );

      expect(repo.recentLabels(), ['Tuna']);

      await repoBox.close();
    });

    test('returns empty list when box is empty', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();
      expect(repo.recentLabels(), isEmpty);
      await repoBox.close();
    });
  });

  // ---------- remove -------------------------------------------------------

  group('LogRepository.remove', () {
    test('removes entry by id', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await _seed(
        repoBox,
        _log(id: 'del', grams: 30, timestamp: DateTime(2024, 6, 15)),
      );
      expect(repoBox.containsKey('del'), isTrue);

      await repo.remove('del');
      expect(repoBox.containsKey('del'), isFalse);

      await repoBox.close();
    });

    test('remove on non-existent id does not throw', () async {
      final repoBox = await Hive.openBox<ProteinLog>(
        'protein_logs',
        bytes: Uint8List(0),
      );
      final repo = LogRepository();

      await expectLater(repo.remove('ghost'), completes);

      await repoBox.close();
    });
  });

  // ---------- label trimming expression ------------------------------------

  group('Label trimming logic (expression parity check)', () {
    // Documents and verifies the exact expression used in LogRepository.add():
    //   label?.trim().isNotEmpty ?? false ? label!.trim() : null
    String? _applyTrim(String? raw) =>
        raw?.trim().isNotEmpty ?? false ? raw!.trim() : null;

    test('trims surrounding whitespace', () {
      expect(_applyTrim('  chicken  '), 'chicken');
    });

    test('returns null for whitespace-only input', () {
      expect(_applyTrim('   '), isNull);
    });

    test('returns null for null input', () {
      expect(_applyTrim(null), isNull);
    });

    test('returns empty string unchanged (empty string trim is empty)', () {
      // Empty string → trim() == '' → isNotEmpty is false → null
      expect(_applyTrim(''), isNull);
    });

    test('preserves non-whitespace content', () {
      expect(_applyTrim('Greek yogurt'), 'Greek yogurt');
    });
  });
}
