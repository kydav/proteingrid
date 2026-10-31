import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/data/presets.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:proteingrid/data/stats_providers.dart';
import 'package:proteingrid/features/home/styles/arcade_cabinet_home.dart';
import 'package:proteingrid/features/home/styles/block_meter_home.dart';
import 'package:proteingrid/features/home/styles/common.dart';
import 'package:proteingrid/features/home/styles/neon_vector_home.dart';
import 'package:proteingrid/features/log/quick_log_sheet.dart';

/// Today, in whichever look is picked in Settings (Block Meter by default).
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Watch for quick-action launches and auto-open the log sheet
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkQuickAction());
  }

  void _checkQuickAction() {
    final pending = ref.read(pendingQuickActionGramsProvider);
    if (pending != null) {
      ref.read(pendingQuickActionGramsProvider.notifier).state = null;
      showQuickLogSheet(
        context,
        prefilledGrams: pending.grams,
        prefilledLabel: pending.label,
      );
    }
  }

  Future<void> _quickAdd(double grams) async {
    await ref
        .read(todayLogsProvider.notifier)
        .add(grams: grams, goal: ref.read(dailyGoalProvider));
    await HapticFeedback.mediumImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Re-check on every build so we catch quick actions fired while app runs.
    ref.listen(pendingQuickActionGramsProvider, (_, next) {
      if (next != null && mounted) {
        ref.read(pendingQuickActionGramsProvider.notifier).state = null;
        showQuickLogSheet(
          context,
          prefilledGrams: next.grams,
          prefilledLabel: next.label,
        );
      }
    });

    final presets = ref.watch(presetsProvider);
    final data = HomeData(
      total: ref.watch(todayTotalProvider),
      goal: ref.watch(dailyGoalProvider),
      logs: ref.watch(todayLogsProvider),
      streak: ref.watch(streakProvider),
      quickAmounts: [for (final p in presets.take(4)) p.grams],
      onLog: () => showQuickLogSheet(context),
      onQuickAdd: _quickAdd,
      onSettings: () => Navigator.pushNamed(context, '/settings'),
    );

    return Scaffold(
      body: switch (ref.watch(homeStyleProvider)) {
        HomeStyle.blockMeter => BlockMeterHome(data: data),
        HomeStyle.arcadeCabinet => ArcadeCabinetHome(data: data),
        HomeStyle.neonVector => NeonVectorHome(data: data),
      },
    );
  }
}
