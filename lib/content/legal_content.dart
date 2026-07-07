// Placeholder legal text - not legal advice. Review and replace before a
// wide public release; App Store Connect submission separately requires a
// hosted (not just in-app) privacy policy URL.

import 'app_links.dart';

const String privacyPolicyText = '''
Last updated: July 2026

Thicket ("the app") is a plant-care tracking app. We built Thicket to respect your privacy: we collect as little as possible, we never sell your data, and we never track you across other apps or websites.

Our commitments to you:
- We do NOT use your microphone. Thicket has no audio features and never requests microphone access.
- We use your camera ONLY when you actively choose to take a photo of a plant — to identify it or add it to your collection. The camera is never accessed in the background or for any other purpose.
- We do NOT track you across other apps or websites, show you ads, or use advertising cookies. There are no third-party advertising or ad-analytics trackers in Thicket.
- Your data is protected both in transit and at rest using industry-standard encryption (HTTPS and Google Firebase security).

What we collect:
- Photos of your plants that you choose to add.
- Plant and care data you enter (names, species, watering and other care schedules, notes).
- Your email address, only if you choose to create an account with an email and password. Anonymous use requires no email.
- Approximate location, only if you enable weather or search for a city, used solely to show local weather relevant to your plants' care.

How it's used:
- Your plant and account data is stored securely via Firebase (Google Cloud) and used only to sync your data across your own devices.
- Plant photos and search terms may be sent to third-party plant services (PlantNet, Perenual) solely to identify plants and retrieve care guidance — never for advertising.
- We never sell your data to anyone.

Your choices and controls:
- You can delete any plant, space, or your entire account and its data at any time from within the app.
- You can disable location and weather features at any time in Settings.
- You can revoke camera, photo, or location access at any time in your device's system settings; the app keeps working without them, apart from the specific feature that needs them.

Contact: $supportEmail
''';

const String termsAndConditionsText = '''
Last updated: 2026

By using Thicket, you agree to the following:

- The app is provided "as is," without warranty of any kind. Plant care guidance is provided for general informational purposes only and should not be relied on as the sole basis for the health of valuable or rare plants.
- You are responsible for the accuracy of the plant and care data you enter.
- You must not use the app for any unlawful purpose or attempt to disrupt its normal operation.
- We may update these terms from time to time; continued use of the app after changes constitutes acceptance of the new terms.

Contact: $supportEmail
''';

const String billingTermsText = '''
Last updated: 2026

Thicket is currently free to use. There is no paid subscription or in-app purchase at this time.

If paid features are introduced in the future, this page will be updated with full billing terms (pricing, renewal, cancellation, and refund policy) before any charges apply, and you will be asked to explicitly agree before being charged.

Contact: $supportEmail
''';
