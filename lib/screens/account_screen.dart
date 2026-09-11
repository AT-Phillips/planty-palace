import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/primitives.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/settings_sections.dart';
import 'edit_profile_screen.dart';

/// The account hub: who you are signed in as, then every app setting.
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  Future<void> _openEditProfile() async {
    await Navigator.push(context, appRoute(const EditProfileScreen()));
    if (mounted) setState(() {});
  }

  /// The identity card.
  ///
  /// An anonymous account is the important case: the user's whole collection
  /// lives only on this device and is lost with it. That gets a coral
  /// treatment and explicit copy rather than a grey subtitle, because it is
  /// a real risk rather than a preference.
  Widget _profileCard() {
    final p = context.palette;
    final isAnonymous = AuthService.instance.isAnonymous;
    final displayName = AuthService.instance.displayName;
    final email = AuthService.instance.email;

    final name =
        displayName?.isNotEmpty == true
            ? displayName!
            : (isAnonymous ? 'Guest' : (email ?? 'Your account'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 14, Gap.screen, 22),
      child: AppCard(
        radius: AppRadius.xl,
        padding: const EdgeInsets.fromLTRB(16, 16, 14, 16),
        onTap: _openEditProfile,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  photoUrl: AuthService.instance.photoUrl,
                  size: 54,
                ),
                Gap.md,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.plantNameStyle(context, size: 20),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAnonymous
                            ? 'Signed in as a guest'
                            : (email ?? 'Signed in'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 13, color: p.inkSoft),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: p.inkFaint,
                ),
              ],
            ),
            if (isAnonymous) ...[
              Gap.md,
              Container(
                padding: const EdgeInsets.fromLTRB(13, 11, 13, 11),
                decoration: BoxDecoration(
                  color: p.coralSoft,
                  borderRadius: AppRadius.mdAll,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      size: 17,
                      color: p.coral,
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Your plants are only on this device. Add an email '
                        'to keep them if you lose or replace it.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.4,
                          color: p.ink,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Account'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          if (!AuthService.instance.isAvailable)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.screen, 20, Gap.screen, 8),
              child: AppCard(
                bordered: true,
                child: Row(
                  children: [
                    Icon(Icons.cloud_off_rounded, size: 22, color: p.inkFaint),
                    Gap.md,
                    Expanded(
                      child: Text(
                        'Account features are not available on this platform.',
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.4,
                          color: p.inkSoft,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            _profileCard(),
          const SettingsSections(),
        ],
      ),
    );
  }
}
