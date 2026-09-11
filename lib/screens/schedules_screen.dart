import 'package:flutter/material.dart';

import '../services/notification_preferences.dart';
import '../styles/app_theme.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/inset_group.dart';
import '../widgets/primitives.dart';

/// Reminders/scheduling controls, split out from the former inline
/// "Schedules" block in SettingsSections into their own screen.
class SchedulesScreen extends StatefulWidget {
  const SchedulesScreen({super.key});

  @override
  State<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends State<SchedulesScreen> {
  Future<void> _pickReminderTime() async {
    final current = NotificationPreferences.instance.reminderTime.value;
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) {
      await NotificationPreferences.instance.setReminderTime(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Schedules'),
      body: ListView(
        padding: const EdgeInsets.only(top: 14, bottom: 28),
        children: [
          ValueListenableBuilder<bool>(
            valueListenable: NotificationPreferences.instance.enabled,
            builder: (context, enabled, _) {
              return InsetGroup(
                header: 'Reminders',
                dividerIndent: 56,
                children: [
                  InsetSwitchRow(
                    icon: Icons.notifications_active_outlined,
                    title: 'Care reminders',
                    subtitle: 'Watering, feeding, repotting & pruning',
                    value: enabled,
                    onChanged:
                        (value) =>
                            NotificationPreferences.instance.setEnabled(value),
                  ),
                  // The time picker is only meaningful while reminders are on,
                  // so it collapses away rather than sitting there inert.
                  if (enabled)
                    ValueListenableBuilder<TimeOfDay>(
                      valueListenable:
                          NotificationPreferences.instance.reminderTime,
                      builder: (context, time, _) {
                        return InsetRow(
                          icon: Icons.schedule_outlined,
                          title: 'Daily reminder time',
                          value: time.format(context),
                          onTap: _pickReminderTime,
                        );
                      },
                    ),
                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.screen + 4, 2, Gap.screen + 4, 0),
            child: Text(
              'Thicket checks once a day at this time and only notifies you '
              'about plants that are actually due. Each plant’s own '
              'schedule is set on its detail screen.',
              style: TextStyle(fontSize: 12.5, height: 1.5, color: p.inkFaint),
            ),
          ),
        ],
      ),
    );
  }
}
