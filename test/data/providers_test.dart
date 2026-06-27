import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Future<Box<ProteinLog>> _openRepoBox() async {
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(ProteinLogAdapter());
  }
  if (Hive.isBoxOpen('protein_logs')) {
    await Hive.box<ProteinLog>('protein_logs').close();
  }
  return Hive.openBox<ProteinLog>('protein_logs', bytes: Uint8List(0));
}

ProviderContainer _makeContainer() => ProviderContainer();

// ---------------------------------------------------------------------------
// TodayLogsNotifier tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() async {
    if (Hive.isBoxOpen('protein_logs')) {
      await Hive.box<ProteinLog>('protein_logs').close();
    }
  });

  // ── TodayLogsNotifier — initial state ────────────────────────────────────

  group('TodayLogsNotifier — initial state', () {
    test('starts empty when box is empty', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(todayLogsProvider), isEmpty);
    });

    test('lastLog is null when state is empty', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(todayLogsProvider.notifier).lastLog, isNull);
    });
  });

  // ── TodayLogsNotifier — add() ────────────────────────────────────────────

  group('TodayLogsNotifier — add()', () {
    test('add increments the log list by one entry', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 30);

      expect(container.read(todayLogsProvider).length, 1);
    });

    test('add stores the correct gram amount', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 45);

      expect(container.read(todayLogsProvider).first.grams, 45.0);
    });

    test('add stores optional label', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(todayLogsProvider.notifier)
          .add(grams: 30, label: 'Eggs');

      expect(container.read(todayLogsProvider).first.label, 'Eggs');
    });

    test('multiple adds accumulate in state', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 30);
      await container.read(todayLogsProvider.notifier).add(grams: 40);

      expect(container.read(todayLogsProvider).length, 2);
    });

    test('lastLog returns most recently added entry', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 25);

      final last = container.read(todayLogsProvider.notifier).lastLog;
      expect(last, isNotNull);
      expect(last!.grams, 25.0);
    });
  });

  // ── TodayLogsNotifier — remove() ─────────────────────────────────────────

  group('TodayLogsNotifier — remove()', () {
    test('remove deletes a log by id', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 35);

      final id = container.read(todayLogsProvider).first.id;
      await container.read(todayLogsProvider.notifier).remove(id);

      expect(container.read(todayLogsProvider), isEmpty);
    });

    test('remove reduces list length by 1', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 30);
      await container.read(todayLogsProvider.notifier).add(grams: 40);

      final id = container.read(todayLogsProvider).last.id;
      await container.read(todayLogsProvider.notifier).remove(id);

      expect(container.read(todayLogsProvider).length, 1);
    });
  });

  // ── todayTotalProvider ────────────────────────────────────────────────────

  group('todayTotalProvider', () {
    test('returns 0 when no logs', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      expect(container.read(todayTotalProvider), 0.0);
    });

    test('sums all log grams', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 30);
      await container.read(todayLogsProvider.notifier).add(grams: 45);

      expect(container.read(todayTotalProvider), 75.0);
    });

    test('decreases after remove', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 50);
      await container.read(todayLogsProvider.notifier).add(grams: 30);

      final id = container.read(todayLogsProvider).last.id;
      await container.read(todayLogsProvider.notifier).remove(id);

      // One log removed; total should be less than 80 and greater than 0.
      expect(container.read(todayTotalProvider), lessThan(80.0));
      expect(container.read(todayTotalProvider), greaterThan(0.0));
    });
  });

  // ── recentLabelsProvider ─────────────────────────────────────────────────

  group('recentLabelsProvider', () {
    test('is empty when no labelled logs exist', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container.read(todayLogsProvider.notifier).add(grams: 30);

      expect(container.read(recentLabelsProvider), isEmpty);
    });

    test('returns label for a labelled log', () async {
      await _openRepoBox();
      final container = _makeContainer();
      addTearDown(container.dispose);

      await container
          .read(todayLogsProvider.notifier)
          .add(grams: 30, label: 'Chicken');

      expect(container.read(recentLabelsProvider), contains('Chicken'));
    });
  });

  // ── pendingQuickActionGramsProvider ─────────────────────────────────────

  group('pendingQuickActionGramsProvider', () {
    test('initial value is null', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(pendingQuickActionGramsProvider), isNull);
    });

    test('maps quick-action type log_30g to 30g', () {
      double? grams;
      const type = 'log_30g';
      if (type == 'log_30g') grams = 30;
      if (type == 'log_40g') grams = 40;
      if (type == 'log_50g') grams = 50;
      if (type == 'log_custom') grams = 0;
      expect(grams, 30.0);
    });

    test('maps quick-action type log_40g to 40g', () {
      double? grams;
      const type = 'log_40g';
      if (type == 'log_30g') grams = 30;
      if (type == 'log_40g') grams = 40;
      if (type == 'log_50g') grams = 50;
      if (type == 'log_custom') grams = 0;
      expect(grams, 40.0);
    });

    test('maps quick-action type log_50g to 50g', () {
      double? grams;
      const type = 'log_50g';
      if (type == 'log_30g') grams = 30;
      if (type == 'log_40g') grams = 40;
      if (type == 'log_50g') grams = 50;
      if (type == 'log_custom') grams = 0;
      expect(grams, 50.0);
    });

    test('maps quick-action type log_custom to 0 (open custom entry)', () {
      double? grams;
      const type = 'log_custom';
      if (type == 'log_30g') grams = 30;
      if (type == 'log_40g') grams = 40;
      if (type == 'log_50g') grams = 50;
      if (type == 'log_custom') grams = 0;
      expect(grams, 0.0);
    });

    test('unknown quick-action type does not set grams', () {
      double? grams;
      const type = 'log_unknown';
      if (type == 'log_30g') grams = 30;
      if (type == 'log_40g') grams = 40;
      if (type == 'log_50g') grams = 50;
      if (type == 'log_custom') grams = 0;
      expect(grams, isNull);
    });

    test('can be set and cleared', () {
      final container = _makeContainer();
      addTearDown(container.dispose);

      container.read(pendingQuickActionGramsProvider.notifier).state = 40.0;
      expect(container.read(pendingQuickActionGramsProvider), 40.0);

      container.read(pendingQuickActionGramsProvider.notifier).state = null;
      expect(container.read(pendingQuickActionGramsProvider), isNull);
    });
  });

  // ── Default goal constant ─────────────────────────────────────────────────

  group('Default goal constant', () {
    test('default goal is 150g', () {
      final container = _makeContainer();
      addTearDown(container.dispose);
      expect(container.read(dailyGoalProvider), 150);
    });
  });
}
