import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Whether the non-default looks are a Pro perk. One switch, so it's easy to
/// give them away later.
const kStylesArePro = true;

/// The Today screen's look. Block Meter is the default; the others are
/// alternates picked in Settings.
enum HomeStyle {
  blockMeter(
    'Block Meter',
    'Fill the grid, one block at a time',
    HomePalette(
      bg: Color(0xFF050807),
      accent: Color(0xFF39FF14),
      accent2: Color(0xFFFFA61A),
      muted: Color(0xFF8FD18A),
      line: Color(0xFF1E3A1B),
      button: Color(0xFF39FF14),
      onButton: Color(0xFF050807),
    ),
    ('TODAY', 'HISTORY'),
  ),
  arcadeCabinet(
    'Arcade Cabinet',
    'Insert protein to continue',
    HomePalette(
      bg: Color(0xFF000000),
      accent: Color(0xFF39FF14),
      accent2: Color(0xFFFFB000),
      muted: Color(0xFF9FD99A),
      line: Color(0xFF1A3A17),
      button: Color(0xFFFFB000),
      onButton: Color(0xFF000000),
    ),
    ('PLAY', 'HIGH SCORES'),
  ),
  neonVector(
    'Neon Vector',
    'Synthwave ring and grid floor',
    HomePalette(
      bg: Color(0xFF050816),
      accent: Color(0xFF22E6FF),
      accent2: Color(0xFFFF3BD5),
      muted: Color(0xFF8A93B8),
      line: Color(0xFF1E2747),
      button: Color(0xFFFF3BD5),
      onButton: Color(0xFF050816),
    ),
    ('TODAY', 'HISTORY'),
  );

  const HomeStyle(this.label, this.tagline, this.palette, this.navLabels);

  final String label;
  final String tagline;
  final HomePalette palette;

  /// The two bottom tabs' names in this style.
  final (String, String) navLabels;
}

@immutable
class HomePalette {
  const HomePalette({
    required this.bg,
    required this.accent,
    required this.accent2,
    required this.muted,
    required this.line,
    required this.button,
    required this.onButton,
  });

  final Color bg;

  /// The main glow colour (green, or cyan).
  final Color accent;

  /// The second colour: amber "to go", or magenta.
  final Color accent2;
  final Color muted;

  /// Empty blocks, borders, dividers.
  final Color line;
  final Color button;
  final Color onButton;
}

const _key = 'home_style';

final homeStyleProvider = StateNotifierProvider<HomeStyleNotifier, HomeStyle>(
  (_) => HomeStyleNotifier(),
);

class HomeStyleNotifier extends StateNotifier<HomeStyle> {
  HomeStyleNotifier() : super(HomeStyle.blockMeter) {
    _load();
  }

  Future<void> _load() async {
    final name = (await SharedPreferences.getInstance()).getString(_key);
    state =
        HomeStyle.values.where((s) => s.name == name).firstOrNull ??
        HomeStyle.blockMeter;
  }

  Future<void> set(HomeStyle style) async {
    state = style;
    await (await SharedPreferences.getInstance()).setString(_key, style.name);
  }
}
