import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/features/home/styles/common.dart';

/// C. Neon Vector: a segmented cyan ring, three stat boxes, boxed log rows
/// and a synthwave grid floor under it all.
class NeonVectorHome extends StatelessWidget {
  const NeonVectorHome({required this.data, super.key});

  final HomeData data;

  @override
  Widget build(BuildContext context) {
    final p = HomeStyle.neonVector.palette;
    final time = DateFormat('hh:mm a');

    return ColoredBox(
      color: p.bg,
      child: Stack(
        children: [
          // The grid floor, fixed behind the bottom of the screen.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 220,
            child: IgnorePointer(
              child: CustomPaint(painter: _GridFloor(p.accent2)),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                    children: [
                      Row(
                        children: [
                          Text('PROTEIN GRID', style: pixel(14, p.accent2)),
                          const Spacer(),
                          IconButton(
                            onPressed: data.onSettings,
                            icon: Icon(
                              Icons.settings_outlined,
                              color: p.accent,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: SizedBox(
                          width: 290,
                          height: 290,
                          child: CustomPaint(
                            painter: _SegmentRing(
                              progress: data.progress,
                              on: p.accent,
                              off: p.line,
                              dots: p.accent2,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        grams(data.total),
                                        style: pixel(44, p.accent),
                                      ),
                                      Text('G', style: pixel(18, p.accent)),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    'OF ${data.goal}G',
                                    style: terminal(26, p.muted, spacing: 3),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: [
                          _StatBox(
                            'LEFT',
                            data.hit ? 'DONE' : '${grams(data.left)}G',
                            p.accent2,
                            p,
                            highlight: true,
                          ),
                          const SizedBox(width: 12),
                          _StatBox(
                            'ENTRIES',
                            '${data.logs.length}',
                            p.accent,
                            p,
                          ),
                          const SizedBox(width: 12),
                          _StatBox('STREAK', '${data.streak}D', p.accent, p),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        "TODAY'S LOG",
                        style: pixel(11, p.accent2, glow: false),
                      ),
                      const SizedBox(height: 10),
                      if (data.logs.isEmpty)
                        Text(
                          'NOTHING LOGGED YET',
                          style: terminal(22, p.muted.withValues(alpha: 0.6)),
                        ),
                      for (final log in data.chronological)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: DeletableLog(
                            log: log,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: p.bg.withValues(alpha: 0.85),
                                border: Border.all(color: p.line, width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    time.format(log.timestamp),
                                    style: terminal(26, p.muted),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      log.label?.toUpperCase() ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      style: terminal(
                                        20,
                                        p.muted.withValues(alpha: 0.6),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '+${grams(log.grams)}G',
                                    style: terminal(26, p.accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 26, 22),
                  child: BigLogButton(
                    label: 'LOG PROTEIN',
                    palette: p,
                    offsetShadow: p.accent,
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

class _StatBox extends StatelessWidget {
  const _StatBox(
    this.label,
    this.value,
    this.color,
    this.palette, {
    this.highlight = false,
  });

  final String label;
  final String value;
  final Color color;
  final HomePalette palette;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: palette.bg,
          border: Border.all(
            color: highlight ? palette.accent2 : palette.line,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(label, style: terminal(20, palette.muted, spacing: 2)),
            const SizedBox(height: 4),
            FittedBox(child: Text(value, style: terminal(30, color))),
          ],
        ),
      ),
    );
  }
}

/// A ring of 16 segments, lit clockwise from the top, with a dotted inner
/// circle.
class _SegmentRing extends CustomPainter {
  const _SegmentRing({
    required this.progress,
    required this.on,
    required this.off,
    required this.dots,
  });

  final double progress;
  final Color on;
  final Color off;
  final Color dots;

  static const _segments = 16;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 16;
    const gap = 0.07; // radians between segments
    const sweep = 2 * math.pi / _segments;
    final lit = (progress * _segments).floor();
    final rect = Rect.fromCircle(center: c, radius: r);

    for (var i = 0; i < _segments; i++) {
      final start = -math.pi / 2 + i * sweep + gap / 2;
      final isOn = i < lit;
      if (isOn) {
        canvas.drawArc(
          rect,
          start,
          sweep - gap,
          false,
          Paint()
            ..color = on.withValues(alpha: 0.45)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 30
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
        );
      }
      canvas.drawArc(
        rect,
        start,
        sweep - gap,
        false,
        Paint()
          ..color = isOn ? on : off
          ..style = PaintingStyle.stroke
          ..strokeWidth = 26,
      );
    }

    // Dotted inner circle.
    final dot = Paint()..color = dots.withValues(alpha: 0.7);
    final inner = r - 42;
    for (var a = 0.0; a < 2 * math.pi; a += 0.06) {
      canvas.drawCircle(
        c + Offset(math.cos(a) * inner, math.sin(a) * inner),
        1,
        dot,
      );
    }
  }

  @override
  bool shouldRepaint(_SegmentRing old) =>
      old.progress != progress || old.on != on;
}

/// A synthwave perspective grid receding to a horizon.
class _GridFloor extends CustomPainter {
  const _GridFloor(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final line = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..strokeWidth = 1;
    const horizon = 0.0;
    final cx = size.width / 2;
    // Converging verticals.
    for (var i = -12; i <= 12; i++) {
      final bottomX = cx + i * size.width / 6;
      final topX = cx + i * size.width / 60;
      canvas.drawLine(
        Offset(topX, horizon),
        Offset(bottomX, size.height),
        line,
      );
    }
    // Horizontals, closer together toward the horizon.
    for (var i = 1; i <= 10; i++) {
      final t = i / 10;
      final y = horizon + size.height * t * t;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), line);
    }
    // Fade the grid into the background at the horizon.
    canvas.drawRect(
      Offset.zero & Size(size.width, size.height * 0.5),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF050816),
            const Color(0xFF050816).withValues(alpha: 0),
          ],
        ).createShader(Offset.zero & Size(size.width, size.height * 0.5)),
    );
  }

  @override
  bool shouldRepaint(_GridFloor old) => old.color != color;
}
