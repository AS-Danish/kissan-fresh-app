import 'package:kissanfresh/core/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:kissanfresh/core/observable.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:kissanfresh/core/utils/app_theme.dart';

class ThemeController extends FeatureController {
  final _box = Hive.box('user_settings');
  final _key = 'isDarkMode';
  static const _cachedPaletteKey = 'active_theme_palette';
  static const _cachedThemeNameKey = 'active_theme_name';

  final ObservableMap<String, Color> palette = ObservableMap(<String, Color>{});
  final Observable<String> activeThemeName = Observable('Normal');
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _themeSubscription;

  // Get the theme mode from the reactive state
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  // Observable for UI switches depending on the theme state
  Observable<bool> isDarkMode = Observable(false);

  // Backend driven feature flags
  Observable<bool> isChristmas = Observable(false);
  Observable<bool> isEid = Observable(false);

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _loadThemeFromBox();

    _loadCachedPalette();
    _listenForThemeConfig();
  }

  ThemeData get lightTheme => AppTheme.lightThemeFor(palette);
  ThemeData get darkTheme => AppTheme.darkThemeFor(palette);

  void _loadCachedPalette() {
    final cached = _box.get(_cachedPaletteKey);
    if (cached is Map) {
      final parsed = <String, Color>{};
      cached.forEach((key, value) {
        final color = _parseColor(value?.toString());
        if (color != null) parsed[key.toString()] = color;
      });
      palette.assignAll(parsed);
    }
    activeThemeName.value = _box
        .get(_cachedThemeNameKey, defaultValue: 'Normal')
        .toString();
    if (palette.isEmpty) {
      palette.assignAll(_defaultPaletteForTheme(activeThemeName.value));
    }
    _setSeasonalFlags(activeThemeName.value);
  }

  void _listenForThemeConfig() {
    _themeSubscription = FirebaseFirestore.instance
        .collection('app_config')
        .doc('versioning')
        .snapshots()
        .listen(
          (doc) {
            final themes = doc.data()?['themes'];
            if (themes is! List) return;

            Map<dynamic, dynamic>? activeTheme;
            String name = 'Normal';
            for (final entry in themes) {
              if (entry is! Map) continue;
              final candidateName = entry.keys
                  .map((key) => key.toString())
                  .where((key) => key != 'imageURL' && key != 'colors')
                  .firstOrNull;
              if (candidateName != null && entry[candidateName] == true) {
                activeTheme = entry;
                name = candidateName;
                break;
              }
            }
            if (activeTheme == null) return;

            final rawColors = activeTheme['colors'];
            final nextPalette = _defaultPaletteForTheme(name);
            final cachedPalette = <String, String>{};
            if (rawColors is Map) {
              rawColors.forEach((key, value) {
                final color = _parseColor(value?.toString());
                if (color != null) {
                  nextPalette[key.toString()] = color;
                  cachedPalette[key.toString()] = value.toString();
                }
              });
            }

            activeThemeName.value = name;
            palette.assignAll(nextPalette);
            _setSeasonalFlags(name);
            _box.put(_cachedThemeNameKey, name);
            _box.put(_cachedPaletteKey, cachedPalette);
          },
          onError: (Object error) {
            debugPrint('Failed to load theme config: $error');
          },
        );
  }

  void _setSeasonalFlags(String name) {
    final normalized = name.toLowerCase();
    isChristmas.value = normalized == 'christmas';
    isEid.value = normalized == 'eid' || normalized == 'bakra eid';
  }

  Map<String, Color> _defaultPaletteForTheme(String name) {
    final normalized = name.toLowerCase();
    if (normalized == 'christmas') {
      return {
        'primary': const Color(0xFF2563EB),
        'accent': const Color(0xFFDC2626),
        'background': const Color(0xFFEFF6FF),
        'surface': Colors.white,
        'success': const Color(0xFF16A34A),
        'error': const Color(0xFFDC2626),
      };
    }
    if (normalized == 'eid' || normalized == 'bakra eid') {
      return {
        'primary': const Color(0xFF059669),
        'accent': const Color(0xFFD4AF37),
        'background': const Color(0xFFF0FDF4),
        'surface': Colors.white,
        'success': const Color(0xFF16A34A),
        'error': const Color(0xFFDC2626),
      };
    }
    if (normalized == 'ramazan') {
      return {
        'primary': const Color(0xFF6D28D9),
        'accent': const Color(0xFFF59E0B),
        'background': const Color(0xFFFAF5FF),
        'surface': Colors.white,
        'success': const Color(0xFF16A34A),
        'error': const Color(0xFFDC2626),
      };
    }
    return {
      'primary': AppTheme.lightPrimary,
      'accent': AppTheme.lightSecondary,
      'background': AppTheme.lightBackground,
      'surface': AppTheme.lightSurface,
      'success': const Color(0xFF16A34A),
      'error': AppTheme.lightBadge,
    };
  }

  Color? _parseColor(String? value) {
    if (value == null) return null;
    final hex = value.trim().replaceFirst('#', '');
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)) return null;
    return Color(int.parse('FF$hex', radix: 16));
  }

  // Check if dark mode is saved in Hive
  bool _loadThemeFromBox() {
    return _box.get(_key, defaultValue: false);
  }

  // Save the theme mode to Hive
  void _saveThemeToBox(bool isDark) {
    _box.put(_key, isDark);
  }

  // Switch the theme mode and update the observable
  void switchTheme(bool isDark) {
    isDarkMode.value = isDark;
    if (isDark && isChristmas.value) {
      // If user forces dark mode, maybe we disable christmas visually or keep it?
      // Since christmas is a light theme, we'll keep the logic to turn off christmas
      // if they explicitly want dark mode, or just let them switch.
      // For backend driven, maybe dark mode takes precedence or they can't use dark mode.
    }
    _saveThemeToBox(isDark);
  }

  @override
  void onClose() {
    _themeSubscription?.cancel();
    super.onClose();
  }
}

final themeControllerProvider = Provider(
  (ref) => startController(ref, ThemeController()),
);
