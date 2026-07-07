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
/// Uses an IndexedStack so each tab's state (scroll position, the persistent
/// weather card, in-flight loads) is preserved across switches instead of
/// flashing/reloading. A plant added via the global camera button is
/// reflected by explicitly refreshing the Spaces and Care tabs afterward.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final _spacesKey = GlobalKey<SpacesScreenState>();
  final _careKey = GlobalKey<CareScreenState>();

  late final List<Widget> _tabs = [
    SpacesScreen(key: _spacesKey),
    CareScreen(key: _careKey),
    const DiscoverScreen(),
    const AccountScreen(),
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
    _spacesKey.currentState?.refresh();
    _careKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: MainBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        onCameraTap: _openCamera,
      ),
    );
  }
}
