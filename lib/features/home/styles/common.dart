import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proteingrid/core/home_style.dart';
import 'package:proteingrid/data/protein_log.dart';
import 'package:proteingrid/data/providers.dart';

/// Everything a Today style shows, and the actions it can take.
class HomeData {
  const HomeData({
    required this.total,
    required this.goal,
    required this.logs,
    required this.streak,
    required this.quickAmounts,
    required this.onLog,
    required this.onQuickAdd,
    required this.onSettings,
  });

  final double total;
  final int goal;

  /// Newest first (as stored).
  final List<ProteinLog> logs;
  final int streak;

  /// One-tap amounts (the first few quick-log buttons).
  final List<double> quickAmounts;
  final VoidCallback onLog;
  final ValueChanged<double> onQuickAdd;
  final VoidCallback onSettings;

  double get left => (goal - total).clamp(0, double.infinity);
  bool get hit => total >= goal;
  double get progress => goal <= 0 ? 0 : (total / goal).clamp(0, 1);

  /// Oldest first, for logs read top to bottom through the day.
  List<ProteinLog> get chronological => logs.reversed.toList();
}

String grams(double g) => g.toStringAsFixed(0);

/// Pixel display text (Press Start 2P), optionally glowing.
TextStyle pixel(double size, Color color, {bool glow = true}) =>
    GoogleFonts.pressStart2p(
      fontSize: size,
      color: color,
      height: 1.2,
      shadows: glow
          ? [
              Shadow(color: color.withValues(alpha: 0.8), blurRadius: 10),
              Shadow(color: color.withValues(alpha: 0.4), blurRadius: 24),
            ]
          : null,
    );

/// Terminal text (VT323): numbers, labels, the log.
TextStyle terminal(double size, Color color, {double spacing = 1}) =>
    GoogleFonts.vt323(fontSize: size, color: color, letterSpacing: spacing);

/// Swipe a log row left to delete it, with an undo-free snackbar like before.
class DeletableLog extends ConsumerWidget {
  const DeletableLog({required this.log, required this.child, super.key});

  final ProteinLog log;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(log.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        ref.read(todayLogsProvider.notifier).remove(log.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Removed ${grams(log.grams)}g'),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        color: const Color(0xFF3A0A0A),
        child: const Icon(Icons.delete_outline, color: Color(0xFFFF4444)),
      ),
      child: child,
    );
  }
}

/// The big full-width log button at the bottom of each style.
class BigLogButton extends StatelessWidget {
  const BigLogButton({
    required this.label,
    required this.palette,
    required this.onTap,
    this.icon = true,
    this.scanlines = false,
    this.offsetShadow,
    super.key,
  });

  final String label;
  final HomePalette palette;
  final VoidCallback onTap;
  final bool icon;
  final bool scanlines;

  /// A hard drop shadow in another colour (Neon Vector), instead of a glow.
  final Color? offsetShadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        onTap();
      },
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: palette.button,
          boxShadow: offsetShadow != null
              ? [BoxShadow(color: offsetShadow!, offset: const Offset(6, 6))]
              : [
                  BoxShadow(
                    color: palette.button.withValues(alpha: 0.35),
                    blurRadius: 24,
                  ),
                  BoxShadow(
                    color: Color.lerp(palette.button, Colors.black, 0.5)!,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (scanlines)
              CustomPaint(
                painter: Scanlines(color: Colors.black.withValues(alpha: 0.18)),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon) ...[
                  Icon(Icons.add, color: palette.onButton, size: 26),
                  const SizedBox(width: 12),
                ],
                Text(label, style: pixel(13, palette.onButton, glow: false)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// CRT scanlines: a thin dark line every few pixels.
class Scanlines extends CustomPainter {
  const Scanlines({required this.color, this.gap = 3});

  final Color color;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var y = 0.0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(Scanlines old) => old.color != color || old.gap != gap;
}
