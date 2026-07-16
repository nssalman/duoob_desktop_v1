import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryNavy = Color(0xFF102849);
  static const Color primaryAccentDark = Color(0xFF6BA8E5);
  static const String _fontFamily = 'OpenSans';

  static const TextTheme _customTextTheme = TextTheme(
    displayLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.bold),
    titleLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w600),
    bodyLarge: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w500),
    bodyMedium: TextStyle(fontFamily: _fontFamily, fontWeight: FontWeight.w400),
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
    scaffoldBackgroundColor: const Color(0xFF0F0F0F),
    colorScheme: const ColorScheme.dark(
      primary: primaryAccentDark,
      onPrimary: Colors.white,
      secondary: Color(0xFF8BB8E8),
      surface: Color(0xFF121212),
      onSurface: Color(0xFFE8E8E8),
      onSurfaceVariant: Color(0xFFB0B0B0),
      surfaceContainerHighest: Color(0xFF2A2A2A),
      outlineVariant: Color(0xFF3A3A3C),
    ),
    textTheme: _customTextTheme.apply(
      bodyColor: Colors.white,
      displayColor: Colors.white,
    ),
  );
}
