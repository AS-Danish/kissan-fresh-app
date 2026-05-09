import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors (Based on existing app colors)
  static const Color lightPrimary = Color(0xFF14B8A6);
  static const Color lightSecondary = Color(0xFF14B8A6);
  static const Color lightBackground = Color(0xFFF5FFFE);
  static const Color lightSurface = Colors.white;
  static const Color lightPrimaryText = Color(0xFF2D3748);
  static const Color lightSecondaryText = Color(0xFF718096);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBadge = Color(0xFFEF4444); // e.g. red for alerts

  // Signature Midnight & Teal Dark Theme (BlinkIt Style - Production Ready)
  static const Color darkPrimary = Color(0xFF14B8A6); // Professional Teal
  static const Color darkSecondary = Color(0xFF14B8A6); // Unified Teal
  static const Color darkBackground = Color(0xFF0C0E12); // Deep Midnight Blue-Gray (60% Base)
  static const Color darkSurface = Color(0xFF171B22); // Refined Slate Navy (30% Surface)
  static const Color darkPrimaryText = Color(0xFFF1F5F9); // Slate 50 (Text)
  static const Color darkSecondaryText = Color(0xFF94A3B8); // Slate 400 (Muted)
  static const Color darkBorder = Color(0xFF232936); // Subtle Slate (Borders)
  static const Color darkBadge = Color(0xFFF43F5E); // Rose 500

  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: lightPrimary,
    cardColor: lightSurface,
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
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: darkPrimary,
    cardColor: darkSurface,
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: darkPrimary,
      secondary: darkSecondary,
      surface: darkSurface,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      onSurface: darkPrimaryText,
      outline: darkBorder,
      error: darkBadge,
      surfaceContainerHighest: Color(0xFF1F242E),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkBackground,
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: darkPrimaryText),
      titleTextStyle: TextStyle(
        color: darkPrimaryText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
      elevation: 0,
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: darkPrimaryText, letterSpacing: 0.15),
      bodyMedium: TextStyle(color: darkSecondaryText, letterSpacing: 0.1),
      titleLarge: TextStyle(
        color: darkPrimaryText,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.2,
      ),
      titleMedium: TextStyle(
        color: darkPrimaryText,
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
    iconTheme: const IconThemeData(color: darkPrimary, size: 24),
    dividerColor: darkBorder,
    dialogTheme: DialogThemeData(
      backgroundColor: darkSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: const TextStyle(
        color: darkPrimaryText,
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: darkPrimary,
        foregroundColor: Colors.black,
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    ),
  );

  static const String darkMapStyle = '''
[
  {
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#242f3e"
      }
    ]
  },
  {
    "featureType": "administrative.locality",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#263c3f"
      }
    ]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#6b9a76"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#38414e"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#212a37"
      }
    ]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#9ca5b3"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#746855"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [
      {
        "color": "#1f2835"
      }
    ]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#f3d19c"
      }
    ]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#2f3948"
      }
    ]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#d59563"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "geometry",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [
      {
        "color": "#515c6d"
      }
    ]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.stroke",
    "stylers": [
      {
        "color": "#17263c"
      }
    ]
  }
]
''';
}
