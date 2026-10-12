import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Holmi's golden dreamscape palette and shared component styles.
class AppTheme {
  static const Color background = Color(0xFF10111B);
  static const Color surface = Color(0xFF1C1B27);
  static const Color surfaceRaised = Color(0xFF292634);
  static const Color textPrimary = Color(0xFFF7F0E4);
  static const Color textSecondary = Color(0xFFC7BDAE);
  static const Color accent = Color(0xFFD6B36A);
  static const Color rose = Color(0xFFE9D3A2);
  static const Color mint = Color(0xFFF0DDAE);
  static const Color divider = Color(0xFF514632);

  /// Helper to create color with opacity (avoids deprecated withOpacity)
  static Color withAlpha(Color color, double opacity) {
    return color.withAlpha((opacity * 255).round());
  }

  /// Title text style - Playfair Display
  static TextStyle titleLarge(BuildContext context) {
    return GoogleFonts.playfairDisplay(
      fontSize: 32,
      fontWeight: FontWeight.w600,
      color: textPrimary,
      height: 1.3,
    );
  }

  static TextStyle titleMedium(BuildContext context) {
    return GoogleFonts.playfairDisplay(
      fontSize: 24,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.3,
    );
  }

  static TextStyle titleSmall(BuildContext context) {
    return GoogleFonts.playfairDisplay(
      fontSize: 18,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      height: 1.3,
    );
  }

  /// Body text style - Source Serif for reading
  static TextStyle bodyLarge(BuildContext context) {
    return GoogleFonts.sourceSerif4(
      fontSize: 18,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.8,
    );
  }

  static TextStyle bodyMedium(BuildContext context) {
    return GoogleFonts.sourceSerif4(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: textPrimary,
      height: 1.7,
    );
  }

  static TextStyle bodySmall(BuildContext context) {
    return GoogleFonts.sourceSerif4(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: textSecondary,
      height: 1.6,
    );
  }

  /// Button text style
  static TextStyle button(BuildContext context) {
    return GoogleFonts.sourceSerif4(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: textPrimary,
      letterSpacing: 1.5,
    );
  }

  /// App Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        surface: background,
        primary: accent,
        secondary: rose,
        onSurface: textPrimary,
        onPrimary: Color(0xFF211B10),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface.withAlpha(235),
        elevation: 0,
        margin: const EdgeInsets.symmetric(vertical: 9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: accent.withAlpha(38)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface.withAlpha(235),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: textSecondary),
        hintStyle: TextStyle(color: textSecondary.withAlpha(150)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: accent.withAlpha(45)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: accent.withAlpha(45)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style:
            FilledButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: const Color(0xFF211B10),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 17),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: rose.withAlpha(150), width: 0.8),
              ),
              elevation: 3,
              shadowColor: accent.withAlpha(90),
              animationDuration: const Duration(milliseconds: 220),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.pressed)
                    ? Colors.white.withAlpha(45)
                    : null,
              ),
            ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? accent.withAlpha(90)
              : surfaceRaised,
        ),
      ),
      dividerColor: divider,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: textPrimary,
        selectionColor: withAlpha(accent, 0.3),
        selectionHandleColor: accent,
      ),
    );
  }
}
