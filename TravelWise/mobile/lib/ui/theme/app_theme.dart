import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// TravelWise design tokens and dark theme.
///
/// Colour palette inspired by deep-ocean gradients — dark surfaces with
/// cyan/teal accents that complement the Liquid Glass aesthetic.
abstract final class AppTheme {
  // ── Colour Palette ──────────────────────────────────────────────────

  /// Deep navy background.
  static const Color bgPrimary = Color(0xFF0A0E21);

  /// Slightly lighter surface for cards / sheets.
  static const Color bgSurface = Color(0xFF111633);

  /// Muted surface for secondary panels.
  static const Color bgSurfaceVariant = Color(0xFF1A1F44);

  /// Vibrant teal accent — buttons, links, highlights.
  static const Color accent = Color(0xFF00D9C0);

  /// Secondary accent — warm amber for warnings / badges.
  static const Color accentSecondary = Color(0xFFFFC857);

  /// Error / destructive colour.
  static const Color error = Color(0xFFFF5C8A);

  /// Success green.
  static const Color success = Color(0xFF34D399);

  /// Primary text — nearly white.
  static const Color textPrimary = Color(0xFFF0F0F5);

  /// Secondary text — muted.
  static const Color textSecondary = Color(0xFF9CA3C4);

  /// Tertiary text / placeholders.
  static const Color textTertiary = Color(0xFF5C6194);

  /// Glass tint (for GlassContainer default override).
  static const Color glassTint = Color(0x0FFFFFFF); // ~6 % white

  /// Glass border.
  static const Color glassBorder = Color(0x1FFFFFFF); // ~12 % white

  // ── Gradient presets ─────────────────────────────────────────────

  /// Background gradient used behind the app shell.
  static const LinearGradient bgGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF0A0E21),
      Color(0xFF141B3D),
      Color(0xFF0F2027),
    ],
  );

  /// Accent gradient for CTA buttons.
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF00D9C0), Color(0xFF00B4D8)],
  );

  // ── Spacing / Radius ────────────────────────────────────────────

  static const double radiusSm = 12;
  static const double radiusMd = 20;
  static const double radiusLg = 28;

  // ── ThemeData ───────────────────────────────────────────────────

  /// The dark [ThemeData] for the entire app.
  static ThemeData get darkTheme {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: bgPrimary,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accentSecondary,
        surface: bgSurface,
        error: error,
        onPrimary: bgPrimary,
        onSecondary: bgPrimary,
        onSurface: textPrimary,
        onError: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      textTheme: GoogleFonts.interTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgSurfaceVariant.withOpacity(0.5),
        hintStyle: const TextStyle(color: textTertiary),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: accent, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusSm),
          borderSide: const BorderSide(color: error),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: bgPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusSm),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            letterSpacing: 0.3,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: accent,
        unselectedItemColor: textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
    );
  }
}
