import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  void _goToGardensHome(BuildContext context) {
    Navigator.pop(context); // close the drawer
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _push(BuildContext context, Widget screen) {
    Navigator.pop(context); // close the drawer
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  Icon(Icons.local_florist, color: scheme.primary, size: 32),
                  const SizedBox(width: 12),
                  const Text('Planty Palace', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.yard),
              title: const Text('My Gardens'),
              onTap: () => _goToGardensHome(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => _push(context, const SettingsScreen()),
            ),
            ListTile(
              leading: const Icon(Icons.account_circle),
              title: const Text('Account'),
              onTap: () => _push(context, const AccountScreen()),
            ),
          ],
        ),
      ),
    );
  }
}
