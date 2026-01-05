import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette - Dark Mode
  static const Color background = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color surfaceLight = Color(0xFF21262D);
  static const Color primary = Color(0xFF00D084);
  static const Color accent = Color(0xFFFF6B6B);
  static const Color warning = Color(0xFFFFB347);
  static const Color text = Color(0xFFE6EDF3);
  static const Color textMuted = Color(0xFF8B949E);
  static const Color border = Color(0xFF30363D);

  // Battery level colors
  static Color getBatteryColor(int level) {
    if (level > 60) return primary;
    if (level > 30) return warning;
    return accent;
  }

  // Theme Data
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: accent,
        surface: surface,
        error: accent,
      ),
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.bold,
            color: text,
          ),
          displayMedium: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: text,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: text,
          ),
          titleLarge: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: text,
          ),
          titleMedium: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: text,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: text,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: textMuted,
          ),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: text,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      iconTheme: const IconThemeData(
        color: textMuted,
        size: 24,
      ),
    );
  }
}
