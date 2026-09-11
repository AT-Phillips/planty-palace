import 'package:flutter/material.dart';

import '../content/guides_content.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../widgets/account_button.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/primitives.dart';
import '../widgets/section_header.dart';
import '../widgets/weather_appbar_chip.dart';
import 'info_screen.dart';

/// "Guides" tab: a small library of curated, offline plant-care how-tos. Each
/// topic opens in the existing [InfoScreen] (reused for its heading/paragraph
/// rendering). Static content - no network, no cost.
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: const FrostedAppBar(
        title: 'Guides',
        actions: [WeatherAppBarChip(), AccountButton()],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 10, Gap.screen, 28),
        children: [
          // A short editorial lead-in, rather than dropping the reader
          // straight into an undifferentiated list of links.
          Text(
            'Plant-care essentials',
            style: AppTheme.plantNameStyle(context, size: 23),
          ),
          const SizedBox(height: 6),
          Text(
            'Short, practical answers to the things that actually kill '
            'houseplants.',
            style: TextStyle(fontSize: 13.5, height: 1.5, color: p.inkSoft),
          ),
          Gap.lg,
          const SectionHeader('All guides'),
          for (var i = 0; i < guides.length; i++)
            AnimatedEntrance(
              index: i,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  padding: EdgeInsets.zero,
                  onTap:
                      () => Navigator.push(
                        context,
                        appRoute(
                          InfoScreen(
                            title: guides[i].title,
                            qaEntries: guides[i].sections,
                          ),
                        ),
                      ),
                  child: AppRow(
                    padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: p.fernSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(guides[i].icon, size: 20, color: p.fern),
                    ),
                    title: guides[i].title,
                    serifTitle: true,
                    subtitle: guides[i].summary,
                    chevron: true,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
