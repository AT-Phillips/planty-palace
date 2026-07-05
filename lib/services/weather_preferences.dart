import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists whether the weather card is shown and which
/// temperature unit to display it in. Mirrors [ThemeController]'s pattern.
class WeatherPreferences {
  static final WeatherPreferences instance = WeatherPreferences._internal();
  WeatherPreferences._internal();

  static const _enabledKey = 'weatherEnabled';
  static const _celsiusKey = 'weatherUseCelsius';

  final ValueNotifier<bool> enabled = ValueNotifier(true);
  final ValueNotifier<bool> useCelsius = ValueNotifier(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    enabled.value = prefs.getBool(_enabledKey) ?? true;
    useCelsius.value = prefs.getBool(_celsiusKey) ?? false;
  }

  Future<void> setEnabled(bool value) async {
    enabled.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, value);
  }

  Future<void> setUseCelsius(bool value) async {
    useCelsius.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_celsiusKey, value);
  }
}
