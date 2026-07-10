import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../styles/app_theme.dart';

/// Holds and persists the user's chosen [ThemeMode] (system/light/dark),
/// accent color, and background palette.
class ThemeController {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const _prefsKey = 'themeMode';
  static const _accentPrefsKey = 'accentColorIndex';
  static const _backgroundPrefsKey = 'backgroundPaletteIndex';

  static const List<Color> accentColors = [
    AppTheme.defaultSeedColor, // Sage
    Color(0xFF2A6F97), // Ocean
    Color(0xFFB5533C), // Terracotta
    Color(0xFF6B4E8E), // Plum
    Color(0xFFB8860B), // Amber
  ];

  /// Selectable app background tones (Forest/Midnight/Slate/Charcoal), chosen
  /// independently of [accentColors]. See AppTheme.backgroundPalettes.
  static const List<BackgroundPalette> backgroundPalettes =
      AppTheme.backgroundPalettes;

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
  final ValueNotifier<int> accentColorIndex = ValueNotifier(0);
  final ValueNotifier<int> backgroundPaletteIndex = ValueNotifier(0);

  BackgroundPalette get backgroundPalette =>
      backgroundPalettes[backgroundPaletteIndex.value];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_prefsKey);
    themeMode.value = switch (saved) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    final savedAccent = prefs.getInt(_accentPrefsKey) ?? 0;
    accentColorIndex.value =
        savedAccent >= 0 && savedAccent < accentColors.length ? savedAccent : 0;
    final savedBackground = prefs.getInt(_backgroundPrefsKey) ?? 0;
    backgroundPaletteIndex.value =
        savedBackground >= 0 && savedBackground < backgroundPalettes.length
            ? savedBackground
            : 0;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, mode.name);
  }

  Future<void> setAccentColor(int index) async {
    accentColorIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentPrefsKey, index);
  }

  Future<void> setBackgroundPalette(int index) async {
    backgroundPaletteIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundPrefsKey, index);
  }
}
