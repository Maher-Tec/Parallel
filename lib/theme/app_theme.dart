import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Parallel App Theme
/// Dark, literary aesthetic with calm contrast
class AppTheme {
  // Colors - Deep blacks and warm off-whites
  static const Color background = Color(0xFF0A0A0A);
  static const Color surface = Color(0xFF141414);
  static const Color textPrimary = Color(0xFFF5F0E8);
  static const Color textSecondary = Color(0xFFB8B0A0);
  static const Color accent = Color(0xFF8B7355);
  static const Color divider = Color(0xFF2A2A2A);

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
        primary: textPrimary,
        secondary: accent,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
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
