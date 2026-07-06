import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../content/app_links.dart';
import '../widgets/frosted_app_bar.dart';

/// Generic static-content screen, reused for Help & Support, FAQ, Privacy
/// Policy, Terms & Conditions, and Billing Terms instead of five
/// near-duplicate screens.
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

  Future<void> _contactSupport() async {
    final uri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=${Uri.encodeComponent('Thicket Support')}',
    );
    await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedAppBar(title: title),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (body != null)
            Text(body!, style: Theme.of(context).textTheme.bodyMedium),
          if (qaEntries != null)
            for (final (question, answer) in qaEntries!)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Text(answer, style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
          if (showContactButton) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _contactSupport,
              icon: const Icon(Icons.email_outlined),
              label: const Text('Contact us'),
            ),
          ],
        ],
      ),
    );
  }
}
