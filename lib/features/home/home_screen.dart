import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/protein_log.dart';
import '../../data/providers.dart';
import '../log/quick_log_sheet.dart';

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
      showQuickLogSheet(context, prefilledGrams: pending);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Re-check on every build so we catch quick actions fired while app runs.
    ref.listen(pendingQuickActionGramsProvider, (_, next) {
      if (next != null && mounted) {
        ref.read(pendingQuickActionGramsProvider.notifier).state = null;
        showQuickLogSheet(context, prefilledGrams: next);
      }
    });

    final cs = Theme.of(context).colorScheme;
    final total = ref.watch(todayTotalProvider);
    final goal = ref.watch(dailyGoalProvider);
    final logs = ref.watch(todayLogsProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'ProteinPing',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _ProgressRingCard(total: total, goal: goal, cs: cs),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Text(
                    "Today's log",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Spacer(),
                  if (logs.isNotEmpty)
                    Text(
                      '${logs.length} entries',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                    ),
                ],
              ),
            ),
          ),
          if (logs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 48,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No protein logged yet today.',
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap + to log your first entry.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverList.builder(
              itemCount: logs.length,
              itemBuilder: (context, i) => _LogTile(log: logs[i]),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showQuickLogSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Log protein'),
      ),
    );
  }
}

// ── Progress ring ─────────────────────────────────────────────────────────────

class _ProgressRingCard extends StatelessWidget {
  const _ProgressRingCard({
    required this.total,
    required this.goal,
    required this.cs,
  });

  final double total;
  final int goal;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    final progress = (total / goal).clamp(0.0, 1.0);
    final isGoalHit = total >= goal;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          SizedBox(
            width: 180,
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(180, 180),
                  painter: _RingPainter(
                    progress: progress,
                    trackColor: cs.surfaceContainerHighest,
                    progressColor:
                        isGoalHit ? cs.tertiary : cs.primary,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toStringAsFixed(0)}g',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isGoalHit ? cs.tertiary : cs.primary,
                      ),
                    ),
                    Text(
                      'of ${goal}g', // ignore: unnecessary_string_interpolations
                      style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isGoalHit) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: cs.tertiary, size: 18),
                const SizedBox(width: 6),
                Text(
                  'Goal hit!',
                  style: TextStyle(
                    color: cs.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              '${(goal - total).ceil()}g remaining',
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  final double progress;
  final Color trackColor;
  final Color progressColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 14;
    const strokeWidth = 14.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..strokeWidth = strokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor;
}

// ── Log tile ──────────────────────────────────────────────────────────────────

class _LogTile extends ConsumerWidget {
  const _LogTile({required this.log});
  final ProteinLog log;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final time = DateFormat('h:mm a').format(log.timestamp);

    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(todayLogsProvider.notifier).remove(log.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${log.grams.toStringAsFixed(0)}g'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: cs.errorContainer,
        child: Icon(Icons.delete_outline, color: cs.onErrorContainer),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            log.grams.toStringAsFixed(0),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: cs.onPrimaryContainer,
              fontSize: 13,
            ),
          ),
        ),
        title: Text(
          log.label ?? '${log.grams.toStringAsFixed(0)}g protein',
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          time,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
        trailing: Text(
          '${log.grams.toStringAsFixed(0)}g',
          style: TextStyle(
            color: cs.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
