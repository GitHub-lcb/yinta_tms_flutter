import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const String _themeKey = 'isDarkMode';
  final SharedPreferences _prefs;
  final isDarkMode = false.obs;

  ThemeController(this._prefs) {
    _loadThemeMode();
  }

  void _loadThemeMode() {
    isDarkMode.value = _prefs.getBool(_themeKey) ?? false;
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _prefs.setBool(_themeKey, isDarkMode.value);
  }
}
