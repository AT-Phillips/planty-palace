import 'package:flutter/material.dart';

import '../screens/account_screen.dart';

/// A circular profile avatar shown in the top-right of the main screens.
/// Tapping it opens the Account screen - Account lives here rather than in
/// the bottom navigation bar.
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AccountScreen()),
        ),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: scheme.surfaceContainerHighest,
          child: Icon(Icons.person_outline, size: 20, color: scheme.onSurfaceVariant),
        ),
      ),
    );
  }
}
