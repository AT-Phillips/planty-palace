import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists the user's chosen [ThemeMode] (system/light/dark).
class ThemeController {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const _prefsKey = 'themeMode';

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    themeMode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }
}
