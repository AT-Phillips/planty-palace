import 'package:flutter/material.dart';

import '../services/plant_repository.dart';
import '../widgets/main_bottom_nav_bar.dart';
import 'add_edit_plant_screen.dart';
import 'care_screen.dart';
import 'discover_screen.dart';
import 'guides_screen.dart';
import 'spaces_screen.dart';

/// Hosts the app's 4 persistent tabs (Spaces, Care, Find, Guides) plus the
/// central camera quick-action. Account isn't a tab - it's reached via the
/// profile avatar in the top-right of each screen (see AccountButton). Uses
/// an IndexedStack so each tab's state (scroll position, the persistent
/// weather card, in-flight loads) is preserved across switches instead of
/// flashing. A plant added via the global camera button is reflected by
/// explicitly refreshing the Spaces and Care tabs afterward (Guides is
/// static reference content, so it needs no refresh).
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
    SpacesScreen(key: _spacesKey, onGoToCare: () => setState(() => _selectedIndex = 1)),
    CareScreen(key: _careKey),
    const DiscoverScreen(),
    const GuidesScreen(),
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

  void _onTabTap(int index) {
    setState(() => _selectedIndex = index);
    // Spaces can go stale from actions taken on other tabs that don't know
    // to call back into it directly (e.g. saving a species to the wishlist
    // from Discover) - IndexedStack keeps it mounted rather than rebuilding
    // it, so nothing else would trigger a reload. Refreshing on every switch
    // to this tab is simpler and more robust than instrumenting every call
    // site that might affect it.
    if (index == 0) _spacesKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _tabs),
      bottomNavigationBar: MainBottomNavBar(
        selectedIndex: _selectedIndex,
        onTap: _onTabTap,
        onCameraTap: _openCamera,
      ),
    );
  }
}
