import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:proteingrid/core/purchases_service.dart';
import 'package:proteingrid/core/theme.dart';
import 'package:proteingrid/data/providers.dart';
import 'package:proteingrid/data/stats_providers.dart';
import 'package:proteingrid/features/pro/pro_paywall_sheet.dart';

/// How many recent weeks free users see on the Grid.
const kFreeGridWeeks = 5;
const _weeks = 53;
const _cell = 13.0;
const _gap = 3.0;

/// THE GRID: one square per day for the last year, lit by how close that
/// day came to the goal (Monday-first columns, like a contribution graph).
/// Free shows the last [kFreeGridWeeks] weeks; the rest is Pro.
class YearGrid extends ConsumerStatefulWidget {
  const YearGrid({super.key});

  @override
  ConsumerState<YearGrid> createState() => _YearGridState();
}

class _YearGridState extends ConsumerState<YearGrid> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    // Start at the newest week (the right-hand end).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _unlock() async {
    await showProPaywall(context, reason: ProReason.grid);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pro = ref.watch(isProNowProvider);
    final totals = ref.watch(dailyTotalsProvider);
    final goal = ref.watch(dailyGoalProvider);
    final best = ref.watch(bestStreakProvider);
    final rate = ref.watch(hitRateProvider(30));
    final selected = ref.watch(selectedHistoryDayProvider);

    final today = dayOf(DateTime.now());
    // The first column starts on the Monday [_weeks - 1] weeks back.
    final thisMonday = DateTime(
      today.year,
      today.month,
      today.day - (today.weekday - 1),
    );
    final start = DateTime(
      thisMonday.year,
      thisMonday.month,
      thisMonday.day - 7 * (_weeks - 1),
    );
    final hitsThisYear = totals.entries
        .where((e) => e.key.year == today.year && e.value >= goal)
        .length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,

        border: Border.all(color: _accent(context).withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'THE GRID',
                style: GoogleFonts.pressStart2p(
                  fontSize: 10,
                  color: _accent(context),
                  shadows: neonGlow(_accent(context), intensity: 0.8)
                      .map(
                        (s) => Shadow(color: s.color, blurRadius: s.blurRadius),
                      )
                      .toList(),
                ),
              ),
              const Spacer(),
              if (!pro)
                InkWell(
                  onTap: _unlock,
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_rounded,
                        size: 12,
                        color: _accent(context),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'YOUR YEAR',
                        style: GoogleFonts.orbitron(
                          fontSize: 9,
                          color: _accent(context),
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 7 * (_cell + _gap),
            child: SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var w = 0; w < _weeks; w++)
                    _Week(
                      monday: DateTime(
                        start.year,
                        start.month,
                        start.day + 7 * w,
                      ),
                      today: today,
                      totals: totals,
                      goal: goal.toDouble(),
                      selected: selected,
                      locked: !pro && w < _weeks - kFreeGridWeeks,
                      onLocked: _unlock,
                      onDay: (d) =>
                          ref.read(selectedHistoryDayProvider.notifier).state =
                              d,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Stat(label: 'BEST RUN', value: pro ? '${best}d' : '—'),
              _Stat(label: '30-DAY HIT', value: '${(rate * 100).round()}%'),
              _Stat(
                label: '${today.year} HITS',
                value: pro ? '$hitsThisYear' : '—',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Week extends StatelessWidget {
  const _Week({
    required this.monday,
    required this.today,
    required this.totals,
    required this.goal,
    required this.selected,
    required this.locked,
    required this.onLocked,
    required this.onDay,
  });

  final DateTime monday;
  final DateTime today;
  final Map<DateTime, double> totals;
  final double goal;
  final DateTime selected;
  final bool locked;
  final VoidCallback onLocked;
  final ValueChanged<DateTime> onDay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: _gap),
      child: Column(
        children: [
          for (var i = 0; i < 7; i++)
            _day(context, DateTime(monday.year, monday.month, monday.day + i)),
        ],
      ),
    );
  }

  Widget _day(BuildContext context, DateTime d) {
    final future = d.isAfter(today);
    final ratio = goal <= 0 ? 0.0 : (totals[d] ?? 0) / goal;
    final hit = ratio >= 1;
    final alpha = future
        ? 0.0
        : locked
        ? 0.06
        : hit
        ? 1.0
        : ratio >= 0.5
        ? 0.45
        : ratio > 0
        ? 0.22
        : 0.08;
    final isSelected = d == selected;
    return GestureDetector(
      onTap: future
          ? null
          : locked
          ? onLocked
          : () => onDay(d),
      child: Tooltip(
        message: future || locked
            ? ''
            : '${DateFormat.MMMd().format(d)}: '
                  '${(totals[d] ?? 0).toStringAsFixed(0)}g',
        child: Container(
          width: _cell,
          height: _cell,
          margin: const EdgeInsets.only(bottom: _gap),
          decoration: BoxDecoration(
            color: _accent(context).withValues(alpha: alpha),
            borderRadius: BorderRadius.circular(2),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).colorScheme.secondary,
                    width: 1.5,
                  )
                : null,
            boxShadow: hit && !locked
                ? neonGlow(_accent(context), intensity: 0.2)
                : null,
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: GoogleFonts.pressStart2p(
              fontSize: 11,
              color: _accent(context),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.orbitron(
              fontSize: 8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

Color _accent(BuildContext context) => Theme.of(context).colorScheme.primary;
