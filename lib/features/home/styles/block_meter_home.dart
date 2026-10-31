import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/features/home/styles/common.dart';

/// A. Block Meter (default): the day's protein as a 30-block grid, with
/// quick-add buttons and a dotted log.
class BlockMeterHome extends StatelessWidget {
  const BlockMeterHome({required this.data, super.key});

  final HomeData data;

  static const _blocks = 30;
  static const _perRow = 10;

  @override
  Widget build(BuildContext context) {
    final p = HomeStyle.blockMeter.palette;
    final perBlock = data.goal / _blocks;
    final lit = perBlock <= 0
        ? 0
        : (data.total / perBlock).floor().clamp(0, _blocks);
    final time = DateFormat('hh:mm a');

    return ColoredBox(
      color: p.bg,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                children: [
                  // Header
                  Row(
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'PROTEIN GRID',
                            style: pixel(14, p.accent),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: p.accent2.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'STREAK ${data.streak.toString().padLeft(2, '0')}',
                          style: terminal(20, p.accent2),
                        ),
                      ),
                      IconButton(
                        onPressed: data.onSettings,
                        icon: Icon(Icons.settings_outlined, color: p.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Total vs goal, and what's left
                  Text('TODAY', style: terminal(22, p.muted, spacing: 2)),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.bottomLeft,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                grams(data.total),
                                style: pixel(48, p.accent),
                              ),
                              const SizedBox(width: 12),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 2),
                                child: Text(
                                  '/ ${data.goal}G',
                                  style: terminal(30, p.muted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            data.hit ? 'GOAL' : 'TO GO',
                            style: terminal(22, p.muted, spacing: 2),
                          ),
                          Text(
                            data.hit ? 'HIT!' : '${grams(data.left)}G',
                            style: pixel(18, data.hit ? p.accent : p.accent2),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // The meter
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      border: Border.all(color: p.line, width: 2),
                    ),
                    child: Column(
                      children: [
                        for (var r = 0; r < _blocks / _perRow; r++)
                          Padding(
                            padding: EdgeInsets.only(top: r == 0 ? 0 : 8),
                            child: Row(
                              children: [
                                for (var c = 0; c < _perRow; c++)
                                  Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(
                                        left: c == 0 ? 0 : 8,
                                      ),
                                      child: _Block(
                                        index: r * _perRow + c,
                                        lit: lit,
                                        palette: p,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '1 BLOCK = ${perBlock.toStringAsFixed(perBlock % 1 == 0 ? 0 : 1)}G',
                            style: terminal(20, p.muted),
                          ),
                        ),
                      ),
                      const Spacer(),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '$lit / $_blocks BLOCKS',
                            style: terminal(20, p.muted),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Quick add
                  Text('QUICK ADD', style: pixel(11, p.accent, glow: false)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < data.quickAmounts.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(
                          child: _QuickAdd(
                            grams: data.quickAmounts[i],
                            palette: p,
                            onTap: () => data.onQuickAdd(data.quickAmounts[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 26),

                  // Today's log
                  Row(
                    children: [
                      Text(
                        "TODAY'S LOG",
                        style: pixel(11, p.accent, glow: false),
                      ),
                      const Spacer(),
                      Text(
                        '${data.logs.length} '
                        '${data.logs.length == 1 ? 'ENTRY' : 'ENTRIES'}',
                        style: terminal(20, p.muted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (data.logs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'NOTHING YET. TAP A QUICK ADD.',
                        style: terminal(20, p.muted.withValues(alpha: 0.6)),
                      ),
                    ),
                  for (final log in data.chronological)
                    DeletableLog(
                      log: log,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Flexible(
                              flex: 0,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  time.format(log.timestamp),
                                  style: terminal(26, p.muted),
                                ),
                              ),
                            ),
                            if (log.label != null) ...[
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  log.label!.toUpperCase(),
                                  overflow: TextOverflow.ellipsis,
                                  style: terminal(
                                    20,
                                    p.muted.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                            ],
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: CustomPaint(
                                  size: const Size(double.infinity, 2),
                                  painter: _DottedLine(p.line),
                                ),
                              ),
                            ),
                            Text(
                              '${grams(log.grams)}G',
                              style: terminal(26, p.accent),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: BigLogButton(
                label: 'LOG PROTEIN',
                palette: p,
                onTap: data.onLog,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.index, required this.lit, required this.palette});

  final int index;
  final int lit;
  final HomePalette palette;

  @override
  Widget build(BuildContext context) {
    final on = index < lit;
    // The next block to fill gets a bright outline.
    final next = index == lit;
    return AspectRatio(
      aspectRatio: 1,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 180 + index * 12),
        decoration: BoxDecoration(
          color: on ? palette.accent : palette.bg,
          border: Border.all(
            color: on
                ? palette.accent
                : next
                ? palette.accent.withValues(alpha: 0.6)
                : palette.line,
            width: next ? 2 : 1.5,
          ),
          boxShadow: on
              ? [
                  BoxShadow(
                    color: palette.accent.withValues(alpha: 0.5),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
      ),
    );
  }
}

class _QuickAdd extends StatelessWidget {
  const _QuickAdd({
    required this.grams,
    required this.palette,
    required this.onTap,
  });

  final double grams;
  final HomePalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Color.lerp(palette.bg, palette.accent, 0.04),
          border: Border(
            top: BorderSide(color: palette.accent, width: 2),
            left: BorderSide(color: palette.accent, width: 2),
            right: BorderSide(color: palette.accent, width: 2),
            bottom: BorderSide(color: palette.accent, width: 6),
          ),
        ),
        child: FittedBox(
          child: Text(
            '+${grams.toStringAsFixed(0)}',
            style: pixel(13, palette.accent, glow: false),
          ),
        ),
      ),
    );
  }
}

class _DottedLine extends CustomPainter {
  const _DottedLine(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var x = 0.0; x < size.width; x += 5) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 2, 2), p);
    }
  }

  @override
  bool shouldRepaint(_DottedLine old) => old.color != color;
}
