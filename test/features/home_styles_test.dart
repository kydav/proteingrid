import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:proteingrid/features/home/styles/arcade_cabinet_home.dart';
import 'package:proteingrid/features/home/styles/block_meter_home.dart';
import 'package:proteingrid/features/home/styles/common.dart';
import 'package:proteingrid/features/home/styles/neon_vector_home.dart';

void main() {
  // No network in tests: fonts fall back, layout is what's checked.
  GoogleFonts.config.allowRuntimeFetching = false;

  HomeData data({double total = 30, int logs = 2}) => HomeData(
    total: total,
    goal: 150,
    logs: [
      for (var i = 0; i < logs; i++)
        ProteinLog(
          id: '$i',
          grams: 15,
          timestamp: DateTime(2026, 10, 31, 7 + i * 4, 40),
          label: i.isEven ? 'Shake' : null,
        ),
    ],
    streak: 7,
    quickAmounts: const [10, 20, 30, 40],
    onLog: () {},
    onQuickAdd: (_) {},
    onSettings: () {},
  );

  final styles = <String, Widget Function(HomeData)>{
    'block meter': (d) => BlockMeterHome(data: d),
    'arcade cabinet': (d) => ArcadeCabinetHome(data: d),
    'neon vector': (d) => NeonVectorHome(data: d),
  };

  for (final MapEntry(key: name, value: build) in styles.entries) {
    for (final (label, d) in [
      ('empty', data(total: 0, logs: 0)),
      ('part way', data()),
      ('goal hit', data(total: 180, logs: 6)),
    ]) {
      testWidgets('$name lays out on a small phone ($label)', (tester) async {
        // Fonts can't load offline; that error isn't what's under test.
        final errors = <FlutterErrorDetails>[];
        final previous = FlutterError.onError;
        FlutterError.onError = errors.add;
        tester.view.physicalSize = const Size(375 * 3, 667 * 3);
        tester.view.devicePixelRatio = 3;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(MaterialApp(home: Scaffold(body: build(d))));
        await tester.pump(const Duration(seconds: 1));
        FlutterError.onError = previous;
        final overflows = errors
            .where((e) => e.exceptionAsString().contains('overflowed'))
            .map((e) => e.exceptionAsString())
            .toList();
        expect(overflows, isEmpty);
      });
    }
  }
}
