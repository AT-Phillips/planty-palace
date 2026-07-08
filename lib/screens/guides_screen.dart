import 'package:flutter/material.dart';

import '../content/guides_content.dart';
import '../widgets/account_button.dart';
import '../widgets/frosted_app_bar.dart';
import 'info_screen.dart';

/// "Guides" tab: a small library of curated, offline plant-care how-tos. Each
/// topic opens in the existing InfoScreen (reused for its heading/paragraph
/// rendering). Static content for now - no network, no cost.
class GuidesScreen extends StatelessWidget {
  const GuidesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Guides', actions: [AccountButton()]),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Text(
              'Plant-care essentials',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: scheme.onSurface,
              ),
            ),
          ),
          for (final guide in guides)
            Card(
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: scheme.primaryContainer,
                  foregroundColor: scheme.onPrimaryContainer,
                  child: Icon(guide.icon),
                ),
                title: Text(guide.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(guide.summary),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => InfoScreen(title: guide.title, qaEntries: guide.sections),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
