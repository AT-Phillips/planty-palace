import 'package:flutter/material.dart';

import '../services/notification_preferences.dart';
import '../widgets/frosted_app_bar.dart';

/// Reminders/scheduling controls, split out from the former inline
/// "Schedules" block in SettingsSections into their own screen.
class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
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
      appBar: const FrostedAppBar(title: 'Schedules'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ValueListenableBuilder<bool>(
              valueListenable: NotificationPreferences.instance.enabled,
              builder: (context, enabled, _) {
                return Column(
                  children: [
                    SwitchListTile(
                      title: const Text('Reminders'),
                      subtitle: const Text(
                        'Watering, fertilizing, repotting & pruning',
                      ),
                      value: enabled,
                      onChanged:
                          (value) => NotificationPreferences.instance
                              .setEnabled(value),
                    ),
                    if (enabled)
                      ValueListenableBuilder<TimeOfDay>(
                        valueListenable:
                            NotificationPreferences.instance.reminderTime,
                        builder: (context, time, _) {
                          return ListTile(
                            leading: const Icon(Icons.notifications_outlined),
                            title: const Text('Daily reminder time'),
                            subtitle: Text(time.format(context)),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _pickReminderTime(context),
                          );
                        },
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
