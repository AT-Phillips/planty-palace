import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/app_links.dart';
import '../content/faq_content.dart';
import '../content/help_content.dart';
import '../content/legal_content.dart';
import '../screens/info_screen.dart';
import '../screens/schedules_screen.dart';
import '../screens/weather_settings_screen.dart';
import '../services/theme_controller.dart';

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
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('Background'),
                            const Spacer(),
                            ValueListenableBuilder<int>(
                              valueListenable: ThemeController.instance.backgroundPaletteIndex,
                              builder: (context, selectedIndex, _) {
                                final scheme = Theme.of(context).colorScheme;
                                return Row(
                                  children: [
                                    for (var i = 0;
                                        i < ThemeController.backgroundPalettes.length;
                                        i++)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: GestureDetector(
                                          onTap: () =>
                                              ThemeController.instance.setBackgroundPalette(i),
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: ThemeController.backgroundPalettes[i].swatch,
                                              shape: BoxShape.circle,
                                              // Always outline: several palettes are near-black
                                              // and would vanish against a dark card otherwise.
                                              border: Border.all(
                                                color: i == selectedIndex
                                                    ? scheme.onSurface
                                                    : scheme.outlineVariant,
                                                width: i == selectedIndex ? 2 : 1,
                                              ),
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
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Schedules'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SchedulesScreen()),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.wb_sunny_outlined),
                title: const Text('Weather'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const WeatherSettingsScreen()),
                ),
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
