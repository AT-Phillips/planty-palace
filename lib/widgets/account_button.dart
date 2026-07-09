import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../services/auth_service.dart';
import 'profile_avatar.dart';

/// A circular profile avatar shown in the top-right of the main screens.
/// Tapping it opens the Account screen - Account lives here rather than in
/// the bottom navigation bar. Shares [ProfileAvatar] with the Account/Edit
/// Profile screens so a real photo or preset avatar shows up everywhere,
/// not just on the Account screen itself.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ),
        child: ProfileAvatar(photoUrl: AuthService.instance.photoUrl, size: 36),
      ),
    );
  }
}
