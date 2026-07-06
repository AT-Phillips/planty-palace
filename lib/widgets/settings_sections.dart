import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/app_links.dart';
import '../content/faq_content.dart';
import '../content/help_content.dart';
import '../content/legal_content.dart';
import '../screens/info_screen.dart';
import '../screens/location_picker_screen.dart';
import '../services/location_preferences.dart';
import '../services/notification_preferences.dart';
import '../services/theme_controller.dart';
import '../services/unit_preferences.dart';
import '../services/weather_preferences.dart';

/// All former Settings-tab content, extracted into a plain widget (no
/// Scaffold/AppBar of its own) so it can be embedded inline at the bottom of
/// the Account tab instead of living in a separate tab. Deliberately kept to
/// exactly two sections (General, Support) with single-line controls where
/// possible, rather than a section header per setting.
class SettingsSections extends StatelessWidget {
  const SettingsSections({super.key});

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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature is coming soon.')),
    );
  }

  Future<void> _rateApp(BuildContext context) async {
    final uri = Uri.parse(appStoreReviewUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Couldn't open the App Store.")),
      );
    }
  }

  Future<void> _shareApp() async {
    await Share.share('Check out Thicket, the plant-care app I use: $appStoreUrl');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _sectionHeader(context, 'General'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.instance.themeMode,
                builder: (context, mode, _) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Theme'),
                        const SizedBox(height: 8),
                        SegmentedButton<ThemeMode>(
                          segments: const [
                            ButtonSegment(value: ThemeMode.system, label: Text('System')),
                            ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                            ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
                          ],
                          selected: {mode},
                          onSelectionChanged: (selection) =>
                              ThemeController.instance.setThemeMode(selection.first),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Accent color'),
                            const Spacer(),
                            ValueListenableBuilder<int>(
                              valueListenable: ThemeController.instance.accentColorIndex,
                              builder: (context, selectedIndex, _) {
                                return Row(
                                  children: [
                                    for (var i = 0; i < ThemeController.accentColors.length; i++)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: GestureDetector(
                                          onTap: () => ThemeController.instance.setAccentColor(i),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: ThemeController.accentColors[i],
                                              shape: BoxShape.circle,
                                              border: i == selectedIndex
                                                  ? Border.all(
                                                      color: Theme.of(context).colorScheme.onSurface,
                                                      width: 2,
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<bool>(
                valueListenable: NotificationPreferences.instance.enabled,
                builder: (context, enabled, _) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Schedules',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('Reminders'),
                        subtitle: const Text('Watering, fertilizing, repotting & pruning'),
                        value: enabled,
                        onChanged: (value) => NotificationPreferences.instance.setEnabled(value),
                      ),
                      if (enabled)
                        ValueListenableBuilder<TimeOfDay>(
                          valueListenable: NotificationPreferences.instance.reminderTime,
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
              const Divider(height: 1),
              ValueListenableBuilder<bool>(
                valueListenable: UnitPreferences.instance.useMetric,
                builder: (context, useMetric, _) {
                  return ListTile(
                    leading: const Icon(Icons.straighten_outlined),
                    title: const Text('Unit System'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          useMetric ? 'Metric' : 'Imperial',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    onTap: () => UnitPreferences.instance.setUseMetric(!useMetric),
                  );
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<bool>(
                valueListenable: LocationPreferences.instance.useGps,
                builder: (context, useGps, _) {
                  return ValueListenableBuilder<String?>(
                    valueListenable: LocationPreferences.instance.manualLabel,
                    builder: (context, manualLabel, _) {
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined),
                        title: Text(
                          useGps ? 'Using device location' : (manualLabel ?? 'Manual location'),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LocationPickerScreen()),
                        ),
                      );
                    },
                  );
                },
              ),
              const Divider(height: 1),
              ValueListenableBuilder<bool>(
                valueListenable: WeatherPreferences.instance.enabled,
                builder: (context, enabled, _) {
                  return SwitchListTile(
                    secondary: const Icon(Icons.wb_sunny_outlined),
                    title: const Text('Show local weather'),
                    subtitle: const Text('Displayed at the top of My Spaces'),
                    value: enabled,
                    onChanged: (value) => WeatherPreferences.instance.setEnabled(value),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: const Text('Language'),
                trailing: const Text('English'),
                onTap: () => _showComingSoon(context, 'More languages'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.workspace_premium_outlined),
                title: const Text('Manage Subscription'),
                subtitle: const Text('Free plan — upgrade options coming soon'),
                onTap: () => _showComingSoon(context, 'Subscriptions'),
              ),
            ],
          ),
        ),
        _sectionHeader(context, 'Support'),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoScreen(
                      title: 'Help & Support',
                      body: helpText,
                      showContactButton: true,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.quiz_outlined),
                title: const Text('FAQ'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoScreen(title: 'FAQ', qaEntries: faqEntries),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.star_outline),
                title: const Text('Rate Thicket'),
                onTap: () => _rateApp(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.share_outlined),
                title: const Text('Share Thicket'),
                onTap: _shareApp,
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Privacy Policy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoScreen(
                      title: 'Privacy Policy',
                      body: privacyPolicyText,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Terms & Conditions'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoScreen(
                      title: 'Terms & Conditions',
                      body: termsAndConditionsText,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                title: const Text('Billing Terms'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const InfoScreen(
                      title: 'Billing Terms',
                      body: billingTermsText,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
