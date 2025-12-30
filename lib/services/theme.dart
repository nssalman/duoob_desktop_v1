import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF102849);
  static const String _fontFamily = 'OpenSans';

  // Custom TextTheme to ensure specific weights are used
  static const TextTheme _customTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600), // SemiBold
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),  // Medium
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400), // Regular
  );

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: _fontFamily,
    primaryColor: primaryNavy,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNavy,
      brightness: Brightness.light,
      primary: primaryNavy,
      surface: Colors.white,
    ),
    textTheme: _customTextTheme,
  );

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: _fontFamily,
    primaryColor: primaryNavy,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryNavy,
      brightness: Brightness.dark,
      primary: primaryNavy,
      surface: const Color(0xFF121212),
    ),
    textTheme: _customTextTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}