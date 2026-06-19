import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      BoxShadow(color: color.withValues(alpha: intensity), blurRadius: 14, spreadRadius: 1),
      BoxShadow(color: color.withValues(alpha: intensity * 0.4), blurRadius: 28),
    ];

ThemeData arcadeTheme() {
  const cs = ColorScheme(
    brightness: Brightness.dark,
    primary: kNeonGreen,
    onPrimary: kArcadeBg,
    primaryContainer: Color(0xFF0A2A08),
    onPrimaryContainer: kNeonGreen,
    secondary: kNeonPink,
    onSecondary: kArcadeBg,
    secondaryContainer: Color(0xFF2A002A),
    onSecondaryContainer: kNeonPink,
    tertiary: kNeonCyan,
    onTertiary: kArcadeBg,
    tertiaryContainer: Color(0xFF002A2A),
    onTertiaryContainer: kNeonCyan,
    error: Color(0xFFFF4444),
    onError: kArcadeBg,
    errorContainer: Color(0xFF2A0808),
    onErrorContainer: Color(0xFFFF4444),
    surface: kArcadeBg,
    onSurface: kNeonGreen,
    surfaceContainerLowest: kArcadeBg,
    surfaceContainerLow: kArcadeSurface,
    surfaceContainer: kArcadeSurface,
    surfaceContainerHigh: kArcadeSurfaceHigh,
    surfaceContainerHighest: kArcadeSurfaceHigh,
    onSurfaceVariant: Color(0xFF00CC10),
    outline: Color(0xFF1A5C12),
    outlineVariant: Color(0xFF0D3009),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: kNeonGreen,
    onInverseSurface: kArcadeBg,
    inversePrimary: kArcadeBg,
  );

  // Press Start 2P for display/headline; body stays readable
  final textTheme = GoogleFonts.pressStart2pTextTheme().copyWith(
    // Only use pixel font for large display text
    displayLarge: GoogleFonts.pressStart2p(
      fontSize: 28, color: kNeonGreen,
    ),
    displayMedium: GoogleFonts.pressStart2p(
      fontSize: 22, color: kNeonGreen,
    ),
    headlineLarge: GoogleFonts.pressStart2p(
      fontSize: 18, color: kNeonGreen,
    ),
    headlineMedium: GoogleFonts.pressStart2p(
      fontSize: 14, color: kNeonGreen,
    ),
    headlineSmall: GoogleFonts.pressStart2p(
      fontSize: 12, color: kNeonGreen,
      height: 1.6,
    ),
    titleLarge: GoogleFonts.pressStart2p(
      fontSize: 11, color: kNeonGreen,
      height: 1.6,
    ),
    titleMedium: GoogleFonts.orbitron(
      fontSize: 13, fontWeight: FontWeight.w700, color: kNeonGreen,
      letterSpacing: 1,
    ),
    titleSmall: GoogleFonts.orbitron(
      fontSize: 11, fontWeight: FontWeight.w600, color: kNeonGreen,
    ),
    // Body stays with Orbitron for readability but keeps the retro feel
    bodyLarge: GoogleFonts.orbitron(
      fontSize: 13, color: kNeonGreen,
    ),
    bodyMedium: GoogleFonts.orbitron(
      fontSize: 11, color: kNeonGreen,
    ),
    bodySmall: GoogleFonts.orbitron(
      fontSize: 10, color: Color(0xFF00CC10),
    ),
    labelLarge: GoogleFonts.orbitron(
      fontSize: 11, fontWeight: FontWeight.w700,
      color: kNeonGreen, letterSpacing: 1,
    ),
    labelMedium: GoogleFonts.orbitron(
      fontSize: 10, color: Color(0xFF00CC10), letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.orbitron(
      fontSize: 9, color: Color(0xFF00CC10),
    ),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    textTheme: textTheme,
    scaffoldBackgroundColor: kArcadeBg,
    appBarTheme: AppBarTheme(
      backgroundColor: kArcadeBg,
      foregroundColor: kNeonGreen,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: GoogleFonts.pressStart2p(
        fontSize: 13, color: kNeonGreen,
      ),
      iconTheme: const IconThemeData(color: kNeonGreen),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: kArcadeSurface,
      indicatorColor: kNeonGreen.withValues(alpha: 0.15),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? kNeonGreen
              : const Color(0xFF1A5C12),
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.orbitron(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected)
              ? kNeonGreen
              : const Color(0xFF1A5C12),
        );
      }),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kNeonGreen,
        foregroundColor: kArcadeBg,
        minimumSize: const Size(64, 48),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        textStyle: GoogleFonts.pressStart2p(fontSize: 10),
        elevation: 0,
      ).copyWith(
        // Glow effect on press
        overlayColor: WidgetStateProperty.all(
          kNeonGreen.withValues(alpha: 0.2),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kNeonGreen,
        side: const BorderSide(color: kNeonGreen, width: 1.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(4)),
        ),
        textStyle: GoogleFonts.orbitron(
          fontSize: 10, fontWeight: FontWeight.w700,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: kNeonGreen,
        textStyle: GoogleFonts.orbitron(
          fontSize: 10, fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kArcadeSurface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF1A5C12)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF1A5C12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: kNeonGreen, width: 2),
      ),
      labelStyle: GoogleFonts.orbitron(
        fontSize: 10, color: Color(0xFF00CC10),
      ),
      hintStyle: GoogleFonts.orbitron(
        fontSize: 10, color: Color(0xFF1A5C12),
      ),
      suffixStyle: GoogleFonts.orbitron(
        fontSize: 10, color: kNeonGreen,
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kArcadeSurface,
      selectedColor: kNeonGreen.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.orbitron(
        fontSize: 10, fontWeight: FontWeight.w700, color: kNeonGreen,
      ),
      side: const BorderSide(color: Color(0xFF1A5C12)),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: kNeonGreen,
      textColor: kNeonGreen,
      tileColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF0D3009),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: kArcadeSurface,
      contentTextStyle: GoogleFonts.orbitron(
        fontSize: 10, color: kNeonGreen,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: kNeonGreen),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kArcadeSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(4)),
        side: BorderSide(color: kNeonGreen, width: 1.5),
      ),
      titleTextStyle: GoogleFonts.pressStart2p(
        fontSize: 12, color: kNeonGreen, height: 1.6,
      ),
      contentTextStyle: GoogleFonts.orbitron(
        fontSize: 11, color: Color(0xFF00CC10),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kArcadeBg : const Color(0xFF1A5C12),
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? kNeonGreen.withValues(alpha: 0.8)
            : kArcadeSurfaceHigh,
      ),
    ),
    iconTheme: const IconThemeData(color: kNeonGreen),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: kNeonGreen,
      foregroundColor: kArcadeBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(6)),
      ),
    ),
  );
}
