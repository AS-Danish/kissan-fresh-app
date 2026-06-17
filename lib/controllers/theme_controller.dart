import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ThemeController extends GetxController {
  final _box = Hive.box('user_settings');
  final _key = 'isDarkMode';

  // Get the theme mode from the reactive state
  ThemeMode get themeMode =>
      isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  // Observable for UI switches depending on the theme state
  RxBool isDarkMode = false.obs;
  
  // Backend driven feature flags
  RxBool isChristmas = false.obs;
  RxBool isEid = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _loadThemeFromBox();
    
    // Simulate fetching theme config from backend
    _checkBackendForThemeConfig();
  }

  void _checkBackendForThemeConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('app_config').doc('versioning').get();
      if (doc.exists && doc.data() != null && doc.data()!.containsKey('themes')) {
        final themes = doc.data()!['themes'] as List<dynamic>;
        bool christmasActive = false;
        bool eidActive = false;
        for (var theme in themes) {
          if (theme is Map<String, dynamic>) {
            if (theme.containsKey('Christmas')) {
              christmasActive = theme['Christmas'] == true;
            }
            if (theme.containsKey('Eid') || theme.containsKey('Bakra Eid')) {
              if (theme['Eid'] == true || theme['Bakra Eid'] == true) {
                eidActive = true;
              }
            }
          }
        }
        isChristmas.value = christmasActive;
        isEid.value = eidActive;
      }
    } catch (e) {
      debugPrint('Failed to load theme config: $e');
    }
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
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
