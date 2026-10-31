import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:proteingrid/core/home_style.dart';

// Neon palette
const kNeonGreen = Color(0xFF39FF14);
const kNeonPink = Color(0xFFFF00FF);
const kNeonCyan = Color(0xFF00FFFF);
const kNeonYellow = Color(0xFFFFFF00);
const kArcadeBg = Color(0xFF08080F);
const kArcadeSurface = Color(0xFF0D0D1A);
const kArcadeSurfaceHigh = Color(0xFF14142A);

/// Neon glow BoxShadow for any color.
List<BoxShadow> neonGlow(Color color, {double intensity = 0.7}) => [
  BoxShadow(
    color: color.withValues(alpha: intensity),
    blurRadius: 14,
    spreadRadius: 1,
  ),
  BoxShadow(color: color.withValues(alpha: intensity * 0.4), blurRadius: 28),
];

const _defaultPalette = HomePalette(
  bg: kArcadeBg,
  accent: kNeonGreen,
  accent2: kNeonPink,
  muted: Color(0xFF00CC10),
  line: Color(0xFF0D3009),
  button: kNeonGreen,
  onButton: kArcadeBg,
);

/// The app theme, coloured by the Today style's palette (Block Meter green
/// by default), so every screen matches the chosen look.
ThemeData arcadeTheme([HomePalette palette = _defaultPalette]) {
  final accent = palette.accent;
  final accent2 = palette.accent2;
  final bg = palette.bg;
  final text = palette.text ?? palette.accent;
  final muted = palette.muted;
  final line = palette.line;
  final outline = Color.lerp(palette.line, palette.accent, 0.25)!;
  final surface = Color.lerp(bg, accent, 0.04)!;
  final surfaceHigh = Color.lerp(bg, accent, 0.09)!;

  final cs = ColorScheme(
    brightness: Brightness.dark,
    primary: accent,
    onPrimary: bg,
    primaryContainer: Color.lerp(bg, accent, 0.12)!,
    onPrimaryContainer: accent,
    secondary: accent2,
    onSecondary: bg,
    secondaryContainer: Color.lerp(bg, accent2, 0.15)!,
    onSecondaryContainer: accent2,
    tertiary: accent,
    onTertiary: bg,
    tertiaryContainer: Color.lerp(bg, accent, 0.15)!,
    onTertiaryContainer: accent,
    error: const Color(0xFFFF4444),
    onError: bg,
    errorContainer: const Color(0xFF2A0808),
    onErrorContainer: const Color(0xFFFF4444),
    surface: bg,
    onSurface: text,
    surfaceContainerLowest: bg,
    surfaceContainerLow: surface,
    surfaceContainer: surface,
    surfaceContainerHigh: surfaceHigh,
    surfaceContainerHighest: surfaceHigh,
    onSurfaceVariant: muted,
    outline: outline,
    outlineVariant: line,
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: accent,
    onInverseSurface: bg,
    inversePrimary: bg,
  );

  // Press Start 2P for display/headline; body stays readable
  final textTheme = GoogleFonts.pressStart2pTextTheme().copyWith(
    // Only use pixel font for large display text
    displayLarge: GoogleFonts.pressStart2p(fontSize: 28, color: text),
    displayMedium: GoogleFonts.pressStart2p(fontSize: 22, color: text),
    headlineLarge: GoogleFonts.pressStart2p(fontSize: 18, color: text),
    headlineMedium: GoogleFonts.pressStart2p(fontSize: 14, color: text),
    headlineSmall: GoogleFonts.pressStart2p(
      fontSize: 12,
      color: text,
      height: 1.6,
    ),
    titleLarge: GoogleFonts.pressStart2p(
      fontSize: 11,
      color: text,
      height: 1.6,
    ),
    titleMedium: GoogleFonts.orbitron(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: text,
      letterSpacing: 1,
    ),
    titleSmall: GoogleFonts.orbitron(
      fontSize: 11,
      fontWeight: FontWeight.w600,
      color: text,
    ),
    // Body stays with Orbitron for readability but keeps the retro feel
    bodyLarge: GoogleFonts.orbitron(fontSize: 13, color: text),
    bodyMedium: GoogleFonts.orbitron(fontSize: 11, color: text),
    bodySmall: GoogleFonts.orbitron(fontSize: 10, color: muted),
    labelLarge: GoogleFonts.orbitron(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: text,
      letterSpacing: 1,
    ),
    labelMedium: GoogleFonts.orbitron(
      fontSize: 10,
      color: muted,
      letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.orbitron(fontSize: 9, color: muted),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: textTheme,
    scaffoldBackgroundColor: bg,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: accent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.pressStart2p(fontSize: 13, color: accent),
      iconTheme: IconThemeData(color: accent),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: accent.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? accent : outline,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.orbitron(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? accent : outline,
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style:
          FilledButton.styleFrom(
            backgroundColor: accent,
            foregroundColor: bg,
            minimumSize: const Size(64, 48),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(4)),
            ),
            textStyle: GoogleFonts.pressStart2p(fontSize: 10),
            elevation: 0,
          ).copyWith(
            // Glow effect on press
            overlayColor: WidgetStateProperty.all(
              accent.withValues(alpha: 0.2),
            ),
          ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: accent,
        side: BorderSide(color: accent, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        textStyle: GoogleFonts.orbitron(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: GoogleFonts.orbitron(
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: accent, width: 2),
      ),
      labelStyle: GoogleFonts.orbitron(fontSize: 10, color: muted),
      hintStyle: GoogleFonts.orbitron(fontSize: 10, color: outline),
      suffixStyle: GoogleFonts.orbitron(fontSize: 10, color: accent),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surface,
      selectedColor: accent.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.orbitron(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: accent,
      ),
      side: BorderSide(color: outline),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: accent,
      textColor: accent,
      tileColor: Colors.transparent,
    ),
    dividerTheme: DividerThemeData(color: line, thickness: 1),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surface,
      contentTextStyle: GoogleFonts.orbitron(fontSize: 10, color: accent),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: accent),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: accent, width: 1.5),
      ),
      titleTextStyle: GoogleFonts.pressStart2p(
        fontSize: 12,
        color: accent,
        height: 1.6,
      ),
      contentTextStyle: GoogleFonts.orbitron(fontSize: 11, color: muted),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? bg : outline,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? accent.withValues(alpha: 0.8)
            : surfaceHigh,
      ),
    ),
    iconTheme: IconThemeData(color: accent),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: accent,
      foregroundColor: bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
  );
}
