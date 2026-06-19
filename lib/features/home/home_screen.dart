import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme.dart';
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
        title: Text(
          'PROTEIN\nPING',
          style: GoogleFonts.pressStart2p(
            fontSize: 11,
            color: kNeonGreen,
            height: 1.5,
            shadows: neonGlow(kNeonGreen, intensity: 0.9)
                .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                .toList(),
          ),
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
                    "TODAY'S LOG",
                    style: GoogleFonts.pressStart2p(
                      fontSize: 9,
                      color: kNeonGreen,
                      letterSpacing: 1,
                    ),
                  ),
                  const Spacer(),
                  if (logs.isNotEmpty)
                    Text(
                      '${logs.length} entries',
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
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

    final ringColor = isGoalHit ? cs.tertiary : cs.primary;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      padding: const EdgeInsets.symmetric(vertical: 28),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: ringColor.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: neonGlow(ringColor, intensity: 0.25),
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
                    progressColor: ringColor,
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${total.toStringAsFixed(0)}g',
                      style: GoogleFonts.pressStart2p(
                        fontSize: 28,
                        color: ringColor,
                        shadows: neonGlow(ringColor, intensity: 0.9)
                            .map((s) => Shadow(
                                  color: s.color,
                                  blurRadius: s.blurRadius,
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'of ${goal}g',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isGoalHit) ...[
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded, color: cs.tertiary, size: 16),
                const SizedBox(width: 8),
                Text(
                  'GOAL HIT!',
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: cs.tertiary,
                    shadows: neonGlow(cs.tertiary, intensity: 0.9)
                        .map((s) => Shadow(color: s.color, blurRadius: s.blurRadius))
                        .toList(),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 16),
            Text(
              '${(goal - total).ceil()}g remaining',
              style: GoogleFonts.orbitron(
                fontSize: 10,
                color: cs.onSurfaceVariant,
                letterSpacing: 1,
              ),
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
      // Glow pass
      final glowPaint = Paint()
        ..color = progressColor.withValues(alpha: 0.45)
        ..strokeWidth = strokeWidth + 8
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        glowPaint,
      );
      // Sharp arc on top
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: cs.outline, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cs.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: neonGlow(cs.primary, intensity: 0.35),
                ),
                alignment: Alignment.center,
                child: Text(
                  log.grams.toStringAsFixed(0),
                  style: GoogleFonts.pressStart2p(
                    fontSize: 10,
                    color: cs.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.label ?? '${log.grams.toStringAsFixed(0)}g protein',
                      style: GoogleFonts.orbitron(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      time,
                      style: GoogleFonts.orbitron(
                        fontSize: 9,
                        color: cs.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${log.grams.toStringAsFixed(0)}g',
                style: GoogleFonts.orbitron(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
