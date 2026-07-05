import 'package:flutter/material.dart';

import '../services/notification_preferences.dart';
import '../services/theme_controller.dart';
import '../services/weather_preferences.dart';
import '../widgets/frosted_app_bar.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Widget _sectionHeader(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Future<void> _pickReminderTime(BuildContext context) async {
    final current = NotificationPreferences.instance.reminderTime.value;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      await NotificationPreferences.instance.setReminderTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Settings'),
      body: ListView(
        children: [
          _sectionHeader(context, 'Appearance'),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: ThemeController.instance.themeMode,
            builder: (context, mode, _) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      value: ThemeMode.system,
                      groupValue: mode,
                      onChanged: (value) => ThemeController.instance.setThemeMode(value!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      value: ThemeMode.light,
                      groupValue: mode,
                      onChanged: (value) => ThemeController.instance.setThemeMode(value!),
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      value: ThemeMode.dark,
                      groupValue: mode,
                      onChanged: (value) => ThemeController.instance.setThemeMode(value!),
                    ),
                  ],
                ),
              );
            },
          ),
          _sectionHeader(context, 'Notifications'),
          ValueListenableBuilder<TimeOfDay>(
            valueListenable: NotificationPreferences.instance.reminderTime,
            builder: (context, time, _) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Daily reminder time'),
                  subtitle: Text(time.format(context)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _pickReminderTime(context),
                ),
              );
            },
          ),
          _sectionHeader(context, 'Weather'),
          ValueListenableBuilder<bool>(
            valueListenable: WeatherPreferences.instance.enabled,
            builder: (context, enabled, _) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Show local weather'),
                      subtitle: const Text('Displayed at the top of My Spaces'),
                      value: enabled,
                      onChanged: (value) => WeatherPreferences.instance.setEnabled(value),
                    ),
                    if (enabled)
                      ValueListenableBuilder<bool>(
                        valueListenable: WeatherPreferences.instance.useCelsius,
                        builder: (context, celsius, _) {
                          return SwitchListTile(
                            title: const Text('Use Celsius'),
                            subtitle: Text(celsius ? 'e.g. 24°C' : 'e.g. 75°F'),
                            value: celsius,
                            onChanged: (value) => WeatherPreferences.instance.setUseCelsius(value),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
