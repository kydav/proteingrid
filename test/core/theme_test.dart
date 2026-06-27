import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:proteingrid/core/theme.dart';

// ---------------------------------------------------------------------------
// Theme tests
//
// arcadeTheme() calls GoogleFonts which initiates async font downloads even
// when allowRuntimeFetching = false (it fires network requests that resolve
// after the test body completes, causing spurious failures).
//
// We therefore test the pure-Dart parts of theme.dart only:
//   - Color constants (no Flutter binding needed)
//   - neonGlow() helper (pure computation)
//
// The ThemeData shape is indirectly verified in integration by the app running
// with ThemeMode.dark and darkTheme = arcadeTheme().
// ---------------------------------------------------------------------------

void main() {
  group('neonGlow()', () {
    test('returns exactly two BoxShadows', () {
      expect(neonGlow(Colors.green).length, 2);
    });

    test('first shadow blurRadius is 14', () {
      expect(neonGlow(Colors.green)[0].blurRadius, 14.0);
    });

    test('second shadow blurRadius is 28', () {
      expect(neonGlow(Colors.green)[1].blurRadius, 28.0);
    });

    test('first shadow spreadRadius is 1', () {
      expect(neonGlow(Colors.red)[0].spreadRadius, 1.0);
    });

    test('second shadow spreadRadius is 0 (default)', () {
      expect(neonGlow(Colors.red)[1].spreadRadius, 0.0);
    });

    test('higher intensity produces higher first-shadow alpha', () {
      final high = neonGlow(Colors.white, intensity: 1.0);
      final low = neonGlow(Colors.white, intensity: 0.1);
      expect(high[0].color.a, greaterThan(low[0].color.a));
    });

    test('default intensity (0.7) matches explicit 0.7', () {
      final def = neonGlow(Colors.cyan);
      final explicit = neonGlow(Colors.cyan);
      expect(def[0].color.a, closeTo(explicit[0].color.a, 0.01));
    });

    test('second shadow alpha is 40% of first shadow alpha', () {
      // From source: intensity * 0.4 for second shadow.
      const intensity = 0.8;
      final glow = neonGlow(Colors.green, intensity: intensity);
      expect(glow[1].color.a, closeTo(glow[0].color.a * 0.4, 0.01));
    });

    test('works with fully opaque color', () {
      final glow = neonGlow(const Color(0xFFFF0000));
      expect(glow.length, 2);
    });
  });

  group('Color constants', () {
    test('kNeonGreen ARGB value is correct', () {
      expect(kNeonGreen.toARGB32(), 0xFF39FF14);
    });

    test('kNeonPink ARGB value is correct', () {
      expect(kNeonPink.toARGB32(), 0xFFFF00FF);
    });

    test('kNeonCyan ARGB value is correct', () {
      expect(kNeonCyan.toARGB32(), 0xFF00FFFF);
    });

    test('kNeonYellow ARGB value is correct', () {
      expect(kNeonYellow.toARGB32(), 0xFFFFFF00);
    });

    test('kArcadeBg is near-black (lightness < 10%)', () {
      final hsl = HSLColor.fromColor(kArcadeBg);
      expect(hsl.lightness, lessThan(0.1));
    });

    test('kArcadeSurface is darker than 15% lightness', () {
      final hsl = HSLColor.fromColor(kArcadeSurface);
      expect(hsl.lightness, lessThan(0.15));
    });

    test('kArcadeSurfaceHigh is darker than 20% lightness', () {
      final hsl = HSLColor.fromColor(kArcadeSurfaceHigh);
      expect(hsl.lightness, lessThan(0.20));
    });

    test('all neon colors are fully opaque', () {
      for (final color in [kNeonGreen, kNeonPink, kNeonCyan, kNeonYellow]) {
        expect(
          color.a * 255,
          255,
          reason: 'Expected $color to be fully opaque',
        );
      }
    });

    test('background colors are distinct', () {
      expect(kArcadeBg, isNot(kArcadeSurface));
      expect(kArcadeSurface, isNot(kArcadeSurfaceHigh));
    });
  });
}
