import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors (Based on existing app colors)
  static const Color lightPrimary = Color(0xFF0d9488);
  static const Color lightSecondary = Color(0xFF14b8a6);
  static const Color lightBackground = Color(0xFFF5FFFE);
  static const Color lightSurface = Colors.white;
  static const Color lightPrimaryText = Color(0xFF2D3748);
  static const Color lightSecondaryText = Color(0xFF718096);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBadge = Color(0xFFEF4444); // e.g. red for alerts

  // Dark Theme Colors (Provided by the user)
  static const Color darkPrimary = Color(0xFFa8d5b5); // Sage Glow
  static const Color darkSecondary = Color(0xFF1a3828); // Deep Forest
  static const Color darkBackground = Color(0xFF0d1f17); // Midnight Pine
  static const Color darkSurface = Color(0xFF112a1f); // Slightly lighter than background for cards
  static const Color darkPrimaryText = Color(0xFFc8dfd2); // Mist White
  static const Color darkSecondaryText = Color(0xFF8aa898); // Dusty Sage
  static const Color darkBorder = Color(0xFF6b9478); // Fern Muted
  static const Color darkBadge = Color(0xFFa8d5b5); // Using Sage Glow for badges to stand out

  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: lightPrimary,
      secondary: lightSecondary,
      surface: lightSurface,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: lightPrimaryText,
      outline: lightBorder,
      error: lightBadge,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: lightBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: lightPrimaryText),
      titleTextStyle: TextStyle(
        color: lightPrimaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: lightPrimaryText),
      bodyMedium: TextStyle(color: lightSecondaryText),
    ),
    iconTheme: const IconThemeData(color: lightPrimary),
    dividerColor: lightBorder,
  );

  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      onPrimary: darkBackground,
      onSecondary: darkPrimaryText,
      onSurface: darkPrimaryText,
      outline: darkBorder,
      error: darkBadge,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      iconTheme: IconThemeData(color: darkPrimaryText),
      titleTextStyle: TextStyle(
        color: darkPrimaryText,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkPrimaryText),
      bodyMedium: TextStyle(color: darkSecondaryText),
    ),
    iconTheme: const IconThemeData(color: darkPrimary),
    dividerColor: darkBorder,
  );
}
