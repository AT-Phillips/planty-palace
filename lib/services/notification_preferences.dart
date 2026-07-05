import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds and persists the user's preferred daily watering-reminder time.
/// Mirrors [ThemeController]'s ValueNotifier + shared_preferences pattern.
class NotificationPreferences {
  static final NotificationPreferences instance = NotificationPreferences._internal();
  NotificationPreferences._internal();

  static const _prefsKey = 'reminderTimeMinutes';
  static const TimeOfDay _defaultTime = TimeOfDay(hour: 9, minute: 0);

  final ValueNotifier<TimeOfDay> reminderTime = ValueNotifier(_defaultTime);

  /// Called whenever the reminder time changes, so callers can reschedule
  /// any already-scheduled notifications to the new time.
  VoidCallback? onReminderTimeChanged;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final minutes = prefs.getInt(_prefsKey);
    if (minutes != null) {
      reminderTime.value = TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
    }
  }

  Future<void> setReminderTime(TimeOfDay time) async {
    reminderTime.value = time;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefsKey, time.hour * 60 + time.minute);
    onReminderTimeChanged?.call();
  }
}
