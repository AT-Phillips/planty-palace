import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../styles/app_theme.dart';

/// Holds and persists the user's chosen [ThemeMode] (system/light/dark) and
/// background palette.
///
/// There is deliberately no accent-color setting. See the comment on
/// `primary` in AppTheme for why: a configurable accent repainted half the
/// app while the designed tokens held the other half, which made the built
/// app look unlike its own design no matter how the design was tuned.
class ThemeController {
  static final ThemeController instance = ThemeController._internal();
  ThemeController._internal();

  static const _prefsKey = 'themeMode';
  static const _backgroundPrefsKey = 'backgroundPaletteIndex';

  /// Selectable app background tones (Forest/Midnight/Slate/Charcoal), chosen
  /// independently of [accentColors]. See AppTheme.backgroundPalettes - which
  /// is now derived from [Palette.variants] at runtime, so this can't be
  /// `const`.
  static final List<BackgroundPalette> backgroundPalettes =
      AppTheme.backgroundPalettes;

  final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.system);
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

  Future<void> setBackgroundPalette(int index) async {
    backgroundPaletteIndex.value = index;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backgroundPrefsKey, index);
  }
}
