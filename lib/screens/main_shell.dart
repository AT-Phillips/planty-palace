import 'package:flutter/material.dart';

import '../services/plant_repository.dart';
import '../widgets/main_bottom_nav_bar.dart';
import 'account_screen.dart';
import 'add_edit_plant_screen.dart';
import 'care_screen.dart';
import 'discover_screen.dart';
import 'spaces_screen.dart';

/// Hosts the app's 4 persistent tabs (Spaces, Care, Find, Account - Settings
/// now lives inline at the bottom of Account) plus the camera quick-action.
/// Tabs are rebuilt fresh on every switch (not an IndexedStack) so a plant
/// added via the global camera button shows up immediately regardless of
/// which tab you're on.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    SpacesScreen(),
    CareScreen(),
    DiscoverScreen(),
    AccountScreen(),
  ];

  Future<void> _openCamera() async {
    final defaultSpaceId = await PlantRepository().getOrCreateDefaultGardenId();
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(gardenId: defaultSpaceId),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_selectedIndex],
      bottomNavigationBar: MainBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        onCameraTap: _openCamera,
      ),
    );
  }
}
