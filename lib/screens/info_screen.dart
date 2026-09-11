import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/app_links.dart';
import '../styles/app_theme.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/primitives.dart';

/// Generic static-content screen, reused for Help & Support, FAQ, Privacy
/// Policy, Terms & Conditions, Billing Terms, and every Guide - instead of
/// several near-duplicate screens.
///
/// Long-form reading is the one place in the app where measure and leading
/// matter more than chrome, so this sets a comfortable line height and a
/// serif question heading rather than reusing the dense body defaults.
class InfoScreen extends StatelessWidget {
  final String title;
  final String? body;
  final List<(String, String)>? qaEntries;
  final bool showContactButton;

  const InfoScreen({
    super.key,
    required this.title,
    this.body,
    this.qaEntries,
    this.showContactButton = false,
  });

  Future<void> _contactSupport(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent('Thicket Support')}',
    );
    // launchUrl throws when no mail client is configured; without this the
    // button simply appeared to do nothing.
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        showAppSnack(context, 'No email app is set up on this device.',
            error: true);
      }
    } catch (_) {
      if (context.mounted) {
        showAppSnack(context, 'Could not open your email app.', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bodyStyle = TextStyle(fontSize: 14.5, height: 1.62, color: p.inkSoft);

    return Scaffold(
      appBar: FrostedAppBar(title: title),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 12, Gap.screen, 40),
        children: [
          if (body != null) Text(body!, style: bodyStyle),
          if (qaEntries != null)
            for (final (question, answer) in qaEntries!)
              Padding(
                padding: const EdgeInsets.only(bottom: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: AppTheme.plantNameStyle(context, size: 18),
                    ),
                    const SizedBox(height: 7),
                    Text(answer, style: bodyStyle),
                  ],
                ),
              ),
          if (showContactButton) ...[
            Gap.sm,
            OutlinedButton.icon(
              onPressed: () => _contactSupport(context),
              icon: const Icon(Icons.email_outlined, size: 18),
              label: const Text('Contact us'),
            ),
          ],
        ],
      ),
    );
  }
}
