import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists whether the weather card is shown. Mirrors
/// [ThemeController]'s pattern.
class WeatherPreferences {
  static final WeatherPreferences instance = WeatherPreferences._internal();
  WeatherPreferences._internal();

  static const _enabledKey = 'weatherEnabled';

  final ValueNotifier<bool> enabled = ValueNotifier(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? true;
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }
}
