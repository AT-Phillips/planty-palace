import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists the user's preferred unit system (metric/imperial),
/// shared across every feature that displays a measurement - not just
/// Weather. Mirrors [ThemeController]'s pattern.
class UnitPreferences {
  static final UnitPreferences instance = UnitPreferences._internal();
  UnitPreferences._internal();

  static const _useMetricKey = 'useMetric';

  final ValueNotifier<bool> useMetric = ValueNotifier(true);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    useMetric.value = prefs.getBool(_useMetricKey) ?? true;
  }

  Future<void> setUseMetric(bool value) async {
    useMetric.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_useMetricKey, value);
  }
}
