import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../utils/app_page_route.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/settings_sections.dart';
import 'edit_profile_screen.dart';

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

  Widget _profileRow() {
    final scheme = Theme.of(context).colorScheme;
    final isAnonymous = AuthService.instance.isAnonymous;
    final displayName = AuthService.instance.displayName;
    final email = AuthService.instance.email;

    final String subtitle;
    final Color? subtitleColor;
    if (isAnonymous) {
      subtitle = 'Not backed up — tap to save your account';
      subtitleColor = scheme.error;
    } else {
      subtitle = displayName?.isNotEmpty == true ? displayName! : (email ?? '');
      subtitleColor = null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _openEditProfile,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ProfileAvatar(
                  photoUrl: AuthService.instance.photoUrl,
                  size: 44,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Edit Profile',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(color: subtitleColor, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 20,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Account'),
      body: ListView(
        children: [
          if (!AuthService.instance.isAvailable)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off,
                    size: 48,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Account features aren\'t available on this platform',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            _profileRow(),
          const SettingsSections(),
        ],
      ),
    );
  }
}
