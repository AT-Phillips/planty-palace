import 'package:flutter/material.dart';

import '../models/garden.dart';
import '../services/plant_repository.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/weather_card.dart';
import 'my_plants_screen.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> {
  final PlantRepository _repository = PlantRepository();

  // MainShell rebuilds each tab fresh on every switch (not an IndexedStack),
  // so this State is recreated every time the user taps this tab. Seeding
  // from the last successful load avoids a flash of the empty state while
  // the new fetch is in flight.
  static List<Garden>? _cachedSpaces;
  static Map<String, int>? _cachedPlantCounts;

  List<Garden> _spaces = _cachedSpaces ?? [];
  Map<String, int> _plantCounts = _cachedPlantCounts ?? {};

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    try {
      final spaces = await _repository.getGardens();
      final counts = <String, int>{};
      for (final space in spaces) {
        counts[space.id!] = await _repository.getPlantCountForGarden(space.id!);
      }
      _cachedSpaces = spaces;
      _cachedPlantCounts = counts;
      if (!mounted) return;
      setState(() {
        _spaces = spaces;
        _plantCounts = counts;
      });
    } catch (e) {
      debugPrint('Failed to load Spaces: $e');
    }
  }

  Future<void> _navigateToSpace(Garden space) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyPlantsScreen(garden: space)),
    );
    if (mounted) _loadSpaces();
  }

  Future<void> _createSpace() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Space'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'e.g. Living Room'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      await _repository.insertGarden(Garden(name: name));
      _loadSpaces();
    }
  }

  Widget _buildSpaceCard(Garden space) {
    final scheme = Theme.of(context).colorScheme;
    final count = _plantCounts[space.id] ?? 0;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.home_outlined),
        ),
        title: Text(space.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$count plant${count == 1 ? '' : 's'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToSpace(space),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'My Spaces'),
      body: Column(
        children: [
          const WeatherCard(),
          Expanded(
            child: _spaces.isEmpty
                ? EmptyState(
                    icon: Icons.home_outlined,
                    title: 'No Spaces yet',
                    message: 'Create a Space for each area of your home — '
                        'Living Room, Backyard, Office — to organize your plants.',
                    actionLabel: 'Create a Space',
                    onAction: _createSpace,
                  )
                : ListView.builder(
                    itemCount: _spaces.length,
                    itemBuilder: (context, index) => _buildSpaceCard(_spaces[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createSpace,
        child: const Icon(Icons.add),
      ),
    );
  }
}
