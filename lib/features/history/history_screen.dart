import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/protein_log.dart';
import '../../data/providers.dart';
import '../../data/stats_providers.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final goal = ref.watch(dailyGoalProvider);
    final weeklyTotals = ref.watch(weeklyTotalsProvider);
    final weeklyAvg = ref.watch(weeklyAverageProvider);
    final streak = ref.watch(streakProvider);
    final selectedDay = ref.watch(selectedHistoryDayProvider);

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // ── Stat cards ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Streak',
                      value: '${streak}d',
                      icon: Icons.local_fire_department_rounded,
                      color: streak > 0 ? Colors.orange : cs.outline,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: '7-day avg',
                      value: '${weeklyAvg.toStringAsFixed(0)}g',
                      icon: Icons.show_chart_rounded,
                      color: weeklyAvg >= goal ? cs.tertiary : cs.primary,
                      cs: cs,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Goal',
                      value: '${goal}g',
                      icon: Icons.flag_rounded,
                      color: cs.primary,
                      cs: cs,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── 7-day bar chart ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: _WeekChart(
                weeklyTotals: weeklyTotals,
                goal: goal.toDouble(),
                selectedDay: selectedDay,
                cs: cs,
                onDayTap: (day) => ref
                    .read(selectedHistoryDayProvider.notifier)
                    .state = day,
              ),
            ),
          ),

          // ── Day selector header ───────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
              child: _DaySelector(
                selectedDay: selectedDay,
                onPrev: () {
                  ref.read(selectedHistoryDayProvider.notifier).state =
                      selectedDay.subtract(const Duration(days: 1));
                },
                onNext: () {
                  final next = selectedDay.add(const Duration(days: 1));
                  final today = DateTime.now();
                  if (next.isBefore(DateTime(today.year, today.month, today.day + 1))) {
                    ref.read(selectedHistoryDayProvider.notifier).state = next;
                  }
                },
              ),
            ),
          ),

          // ── Log list for selected day ─────────────────────────────────────
          _DayLogList(selectedDay: selectedDay, goal: goal),
        ],
      ),
    );
  }
}

// ── Week bar chart ────────────────────────────────────────────────────────────

class _WeekChart extends StatelessWidget {
  const _WeekChart({
    required this.weeklyTotals,
    required this.goal,
    required this.selectedDay,
    required this.cs,
    required this.onDayTap,
  });

  final List<({DateTime day, double total})> weeklyTotals;
  final double goal;
  final DateTime selectedDay;
  final ColorScheme cs;
  final ValueChanged<DateTime> onDayTap;

  @override
  Widget build(BuildContext context) {
    final maxVal = math.max(
      goal,
      weeklyTotals.fold(0.0, (m, d) => math.max(m, d.total)),
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 days',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: weeklyTotals.map((d) {
                final isSelected = _sameDay(d.day, selectedDay);
                final isToday = _sameDay(d.day, DateTime.now());
                final frac = maxVal > 0 ? (d.total / maxVal).clamp(0.0, 1.0) : 0.0;
                final hitGoal = d.total >= goal && d.total > 0;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => onDayTap(d.day),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (d.total > 0)
                            Text(
                              d.total.toStringAsFixed(0),
                              style: TextStyle(
                                fontSize: 9,
                                color: cs.onSurfaceVariant,
                                fontWeight: isSelected ? FontWeight.bold : null,
                              ),
                            ),
                          const SizedBox(height: 2),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: math.max(4, 90 * frac),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary
                                  : hitGoal
                                      ? cs.tertiary.withValues(alpha: 0.7)
                                      : d.total > 0
                                          ? cs.primary.withValues(alpha: 0.4)
                                          : cs.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            DateFormat('E').format(d.day).substring(0, 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isToday || isSelected
                                  ? FontWeight.bold
                                  : null,
                              color: isSelected
                                  ? cs.primary
                                  : cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Goal line label
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Container(width: 12, height: 2, color: cs.tertiary),
                const SizedBox(width: 4),
                Text(
                  'Goal line',
                  style: TextStyle(fontSize: 10, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ── Day selector ──────────────────────────────────────────────────────────────

class _DaySelector extends StatelessWidget {
  const _DaySelector({
    required this.selectedDay,
    required this.onPrev,
    required this.onNext,
  });

  final DateTime selectedDay;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = selectedDay.year == today.year &&
        selectedDay.month == today.month &&
        selectedDay.day == today.day;

    final label = isToday
        ? 'Today'
        : DateFormat('EEEE, MMM d').format(selectedDay);

    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrev,
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isToday ? null : onNext,
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

// ── Log list for selected day ─────────────────────────────────────────────────

class _DayLogList extends ConsumerWidget {
  const _DayLogList({required this.selectedDay, required this.goal});

  final DateTime selectedDay;
  final int goal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final logs = ref.watch(logsForDayProvider(selectedDay)).cast<ProteinLog>();
    final total = logs.fold(0.0, (s, l) => s + l.grams);

    if (logs.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Text(
              'Nothing logged this day.',
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        // Day total banner
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Row(
            children: [
              Text(
                '${total.toStringAsFixed(0)}g total',
                style: TextStyle(
                  color: total >= goal ? cs.tertiary : cs.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (total >= goal) ...[
                const SizedBox(width: 6),
                Icon(Icons.check_circle_rounded,
                    color: cs.tertiary, size: 16),
              ],
            ],
          ),
        ),
        ...logs.map(
          (log) => ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                log.grams.toStringAsFixed(0),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: cs.onSurface,
                ),
              ),
            ),
            title: Text(
              log.label ?? '${log.grams.toStringAsFixed(0)}g protein',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(
              DateFormat('h:mm a').format(log.timestamp),
              style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
            ),
            trailing: Text(
              '${log.grams.toStringAsFixed(0)}g',
              style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ]),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.cs,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final ColorScheme cs;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
