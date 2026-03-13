import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';

class ThemeController extends GetxController {
  final _box = Hive.box('user_settings');
  final _key = 'isDarkMode';

  // Get the theme mode from the reactive state
  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  // Observable for UI switches depending on the theme state
  RxBool isDarkMode = false.obs;

  @override
  void onInit() {
    super.onInit();
    isDarkMode.value = _loadThemeFromBox();
  }

  // Check if dark mode is saved in Hive
  bool _loadThemeFromBox() {
    return _box.get(_key, defaultValue: false);
  }

  // Save the theme mode to Hive
  _saveThemeToBox(bool isDark) {
    _box.put(_key, isDark);
  }

  // Switch the theme mode and update the observable
  void switchTheme(bool isDark) {
    isDarkMode.value = isDark;
    _saveThemeToBox(isDark);
    Get.changeThemeMode(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}
