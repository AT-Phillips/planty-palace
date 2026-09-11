import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/app_links.dart';
import '../content/faq_content.dart';
import '../content/help_content.dart';
import '../content/legal_content.dart';
import '../screens/info_screen.dart';
import '../screens/schedules_screen.dart';
import '../services/theme_controller.dart';
import '../services/weather_service.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import 'app_dialogs.dart';
import 'inset_group.dart';
import 'primitives.dart';
import 'weather_detail_sheet.dart';

/// All former Settings-tab content, as a plain widget (no Scaffold/AppBar of
/// its own) so it can be embedded inline at the bottom of the Account screen
/// instead of living in a separate tab.
///
/// Deliberately three short sections rather than a header per setting, and
/// no accent-color picker - see [ThemeController] for why the brand accent
/// is fixed.
class SettingsSections extends StatelessWidget {
  const SettingsSections({super.key});

  void _showComingSoon(BuildContext context, String feature) {
    showAppSnack(context, '$feature is coming soon.');
  }

  Future<void> _rateApp(BuildContext context) async {
    try {
      final launched = await launchUrl(
        Uri.parse(appStoreReviewUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        showAppSnack(context, "Couldn't open the App Store.", error: true);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, "Couldn't open the App Store.", error: true);
      }
    }
  }

  Future<void> _shareApp() async {
    await Share.share(
      'Check out Thicket, the plant-care app I use: $appStoreUrl',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _AppearanceSection(),
        InsetGroup(
          header: 'General',
          dividerIndent: 56,
          children: [
            InsetRow(
              icon: Icons.notifications_outlined,
              title: 'Schedules',
              onTap:
                  () => Navigator.push(
                    context,
                    appRoute(const SchedulesScreen()),
                  ),
            ),
            InsetRow(
              icon: Icons.wb_sunny_outlined,
              title: 'Weather',
              onTap: () async {
                final weather = await WeatherService().fetchCurrentWeather();
                if (context.mounted) {
                  showWeatherDetailSheet(context, weather: weather);
                }
              },
            ),
            InsetRow(
              icon: Icons.language,
              title: 'Language',
              value: 'English',
              onTap: () => _showComingSoon(context, 'More languages'),
            ),
            InsetRow(
              icon: Icons.workspace_premium_outlined,
              title: 'Manage Subscription',
              value: 'Free plan',
              onTap: () => _showComingSoon(context, 'Subscriptions'),
            ),
          ],
        ),
        InsetGroup(
          header: 'Support',
          dividerIndent: 56,
          children: [
            InsetRow(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap:
                  () => Navigator.push(
                    context,
                    appRoute(
                      const InfoScreen(
                        title: 'Help & Support',
                        body: helpText,
                        showContactButton: true,
                      ),
                    ),
                  ),
            ),
            InsetRow(
              icon: Icons.quiz_outlined,
              title: 'FAQ',
              onTap:
                  () => Navigator.push(
                    context,
                    appRoute(
                      const InfoScreen(title: 'FAQ', qaEntries: faqEntries),
                    ),
                  ),
            ),
            InsetRow(
              icon: Icons.star_outline,
              title: 'Rate Thicket',
              onTap: () => _rateApp(context),
            ),
            InsetRow(
              icon: Icons.share_outlined,
              title: 'Share Thicket',
              onTap: _shareApp,
            ),
          ],
        ),
        InsetGroup(
          header: 'Legal',
          children: [
            InsetRow(
              title: 'Privacy Policy',
              onTap:
                  () => Navigator.push(
                    context,
                    appRoute(
                      const InfoScreen(
                        title: 'Privacy Policy',
                        body: privacyPolicyText,
                      ),
                    ),
                  ),
            ),
            InsetRow(
              title: 'Terms & Conditions',
              onTap:
                  () => Navigator.push(
                    context,
                    appRoute(
                      const InfoScreen(
                        title: 'Terms & Conditions',
                        body: termsAndConditionsText,
                      ),
                    ),
                  ),
            ),
            InsetRow(
              title: 'Billing Terms',
              onTap:
                  () => Navigator.push(
                    context,
                    appRoute(
                      const InfoScreen(
                        title: 'Billing Terms',
                        body: billingTermsText,
                      ),
                    ),
                  ),
            ),
          ],
        ),
        Gap.sm,
      ],
    );
  }
}

/// Theme mode and ground palette.
///
/// The two settings that change how the app looks, presented as what they
/// actually are - a mode switch and a set of named looks - rather than as
/// rows of unlabelled colored dots.
class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return InsetGroup(
      header: 'Appearance',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 15, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Theme',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 10),
              ValueListenableBuilder<ThemeMode>(
                valueListenable: ThemeController.instance.themeMode,
                builder: (context, mode, _) {
                  const modes = [
                    ThemeMode.system,
                    ThemeMode.light,
                    ThemeMode.dark,
                  ];
                  return SegmentedTabs(
                    labels: const ['System', 'Light', 'Dark'],
                    selected: modes.indexOf(mode),
                    onChanged:
                        (i) =>
                            ThemeController.instance.setThemeMode(modes[i]),
                  );
                },
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Background',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: p.ink,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<int>(
                valueListenable:
                    ThemeController.instance.backgroundPaletteIndex,
                builder: (context, selectedIndex, _) {
                  final brightness = Theme.of(context).brightness;
                  final palettes = ThemeController.backgroundPalettes;
                  return Row(
                    children: [
                      for (var i = 0; i < palettes.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(
                          child: _PaletteSwatch(
                            name: palettes[i].name,
                            color: palettes[i].swatchFor(brightness),
                            selected: i == selectedIndex,
                            onTap:
                                () => ThemeController.instance
                                    .setBackgroundPalette(i),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A named background option: the tone itself as a tall rounded tile with its
/// name beneath, instead of a bare 28px dot. Several grounds are near-black
/// or near-white, so the tile always carries a hairline and the selected one
/// gets a fern ring - otherwise the current choice is invisible against the
/// card it sits on.
class _PaletteSwatch extends StatelessWidget {
  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _PaletteSwatch({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            decoration: BoxDecoration(
              color: color,
              borderRadius: AppRadius.smAll,
              border: Border.all(
                color: selected ? p.fern : p.line,
                width: selected ? 2.5 : 1,
              ),
            ),
            child:
                selected
                    ? Center(
                      child: Icon(
                        Icons.check_rounded,
                        size: 18,
                        color: p.fern,
                      ),
                    )
                    : null,
          ),
          const SizedBox(height: 6),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? p.fern : p.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}
