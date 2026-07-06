import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists whether the user has completed the first-run
/// onboarding flow. Mirrors [ThemeController]'s pattern.
class OnboardingPreferences {
  static final OnboardingPreferences instance = OnboardingPreferences._internal();
  OnboardingPreferences._internal();

  static const _prefsKey = 'onboardingCompleted';

  final ValueNotifier<bool> completed = ValueNotifier(false);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    completed.value = prefs.getBool(_prefsKey) ?? false;
  }

  Future<void> setCompleted(bool value) async {
    completed.value = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefsKey, value);
  }
}
