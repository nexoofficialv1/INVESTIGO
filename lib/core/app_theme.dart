import 'package:flutter/material.dart';

class AppTheme {
  static const Color deepGreen = Color(0xFF004739);
  static const Color emerald = Color(0xFF00745E);
  static const Color cream = Color(0xFFFFEFE2);
  static const Color cardBg = Color(0xFFFFFFFF);
  static const Color textDark = Color(0xFF173C34);
  static const Color gold = Color(0xFFE6A93A);
  static const Color teal = Color(0xFF20A7A7);
  static const Color purple = Color(0xFF9C27B0);
  static const Color blue = Color(0xFF2196D3);
  static const Color coral = Color(0xFFFF6E75);

  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: deepGreen,
        primary: deepGreen,
        secondary: emerald,
        surface: cardBg,
      ),
      scaffoldBackgroundColor: cream,
      fontFamily: 'Roboto',
      appBarTheme: const AppBarTheme(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        filled: true,
        fillColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: cardBg,
        elevation: 3,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: deepGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: deepGreen,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: deepGreen,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}
