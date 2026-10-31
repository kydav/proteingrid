import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/features/home/styles/common.dart';

/// B. Arcade Cabinet: a 1UP / GOAL / STREAK scoreboard, a PWR bar, grams
/// left "to clear today", and the day's entries as a high-score table.
class ArcadeCabinetHome extends StatelessWidget {
  const ArcadeCabinetHome({required this.data, super.key});

  final HomeData data;

  static const _segments = 15;

  static String _three(double g) => g.toStringAsFixed(0).padLeft(3, '0');

  static String _ordinal(int n) {
    if (n % 100 >= 11 && n % 100 <= 13) return '${n}TH';
    return switch (n % 10) {
      1 => '${n}ST',
      2 => '${n}ND',
      3 => '${n}RD',
      _ => '${n}TH',
    };
  }

  @override
  Widget build(BuildContext context) {
    final p = HomeStyle.arcadeCabinet.palette;
    final filled = (data.progress * _segments).floor();
    final rows = data.chronological;
    final time = DateFormat('HH:mm');

    return ColoredBox(
      color: p.bg,
      child: Stack(
        children: [
          // CRT scanlines over the whole cabinet.
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: Scanlines(
                  color: Colors.white.withValues(alpha: 0.025),
                ),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                    children: [
                      // Scoreboard
                      Row(
                        children: [
                          _Score('1UP', _three(data.total), p.accent2, p),
                          _Score('GOAL', '${data.goal}', p.accent, p),
                          _Score(
                            'STREAK',
                            data.streak.toString().padLeft(2, '0'),
                            p.accent,
                            p,
                          ),
                          IconButton(
                            onPressed: data.onSettings,
                            icon: Icon(
                              Icons.settings_outlined,
                              color: p.accent.withValues(alpha: 0.6),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Center(
                        child: Text(
                          'PROTEIN\nGRID',
                          textAlign: TextAlign.center,
                          style: pixel(26, p.accent).copyWith(height: 1.35),
                        ),
                      ),
                      const SizedBox(height: 26),

                      // Power panel
                      Container(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 20),
                        decoration: BoxDecoration(
                          border: Border.all(color: p.accent, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: p.accent.withValues(alpha: 0.25),
                              blurRadius: 18,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text('PWR', style: pixel(9, p.accent)),
                                const SizedBox(width: 10),
                                for (var i = 0; i < _segments; i++)
                                  Expanded(
                                    child: Container(
                                      height: 30,
                                      margin: const EdgeInsets.only(left: 3),
                                      decoration: BoxDecoration(
                                        color: i < filled
                                            ? p.accent
                                            : p.accent.withValues(alpha: 0.1),
                                        boxShadow: i < filled
                                            ? [
                                                BoxShadow(
                                                  color: p.accent.withValues(
                                                    alpha: 0.5,
                                                  ),
                                                  blurRadius: 8,
                                                ),
                                              ]
                                            : null,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 22),
                            FittedBox(
                              child: Text(
                                data.hit ? 'CLEAR!' : '${grams(data.left)}G',
                                style: pixel(
                                  44,
                                  data.hit ? p.accent : p.accent2,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              data.hit ? 'STAGE COMPLETE' : 'TO CLEAR TODAY',
                              style: terminal(
                                24,
                                const Color(0xFFE8E8E8),
                                spacing: 6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),

                      // High scores
                      Center(
                        child: Text(
                          "— TODAY'S SCORES —",
                          style: pixel(11, p.accent2, glow: false),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _ScoreRow(
                        'RANK',
                        'TIME',
                        'GRAMS',
                        p.muted,
                        p.muted,
                        p.muted,
                      ),
                      const SizedBox(height: 6),
                      for (var i = 0; i < rows.length; i++)
                        DeletableLog(
                          log: rows[i],
                          child: _ScoreRow(
                            _ordinal(i + 1),
                            time.format(rows[i].timestamp),
                            _three(rows[i].grams),
                            p.accent2,
                            p.accent,
                            p.accent,
                          ),
                        ),
                      // Empty slots up to three, like an unbeaten table.
                      for (var i = rows.length; i < 3; i++)
                        _ScoreRow(
                          _ordinal(i + 1),
                          '--:--',
                          '---',
                          p.muted.withValues(alpha: 0.45),
                          p.muted.withValues(alpha: 0.45),
                          p.muted.withValues(alpha: 0.45),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: BigLogButton(
                    label: 'INSERT PROTEIN',
                    palette: p,
                    icon: false,
                    scanlines: true,
                    onTap: data.onLog,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score(this.label, this.value, this.color, this.palette);

  final String label;
  final String value;
  final Color color;
  final HomePalette palette;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(label, style: pixel(9, const Color(0xFFE8E8E8), glow: false)),
          const SizedBox(height: 6),
          Text(value, style: pixel(17, color)),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow(
    this.rank,
    this.time,
    this.grams,
    this.rankColor,
    this.timeColor,
    this.gramsColor,
  );

  final String rank;
  final String time;
  final String grams;
  final Color rankColor;
  final Color timeColor;
  final Color gramsColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        children: [
          Expanded(child: Text(rank, style: terminal(30, rankColor))),
          Expanded(
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: terminal(30, timeColor),
            ),
          ),
          Expanded(
            child: Text(
              grams,
              textAlign: TextAlign.end,
              style: terminal(30, gramsColor),
            ),
          ),
        ],
      ),
    );
  }
}
