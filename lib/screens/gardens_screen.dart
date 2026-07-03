import 'package:flutter/material.dart';

import '../helpers/database_helper.dart';
import '../models/garden.dart';
import '../widgets/app_drawer.dart';
import '../widgets/frosted_sliver_app_bar.dart';
import 'my_plants_screen.dart';

class GardensScreen extends StatefulWidget {
  const GardensScreen({super.key});

  @override
  State<GardensScreen> createState() => _GardensScreenState();
}

class _GardensScreenState extends State<GardensScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Garden> _gardens = [];
  Map<int, int> _plantCounts = {};

  @override
  void initState() {
    super.initState();
    _loadGardens();
  }

  Future<void> _loadGardens() async {
    final gardens = await _dbHelper.getGardens();
    final counts = <int, int>{};
    for (final garden in gardens) {
      counts[garden.id!] = await _dbHelper.getPlantCountForGarden(garden.id!);
    }
    if (!mounted) return;
    setState(() {
      _gardens = gardens;
      _plantCounts = counts;
    });
  }

  Future<void> _navigateToGarden(Garden garden) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => MyPlantsScreen(garden: garden)),
    );
    if (mounted) _loadGardens();
  }

  Future<void> _createGarden() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Garden'),
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
      await _dbHelper.insertGarden(Garden(name: name));
      _loadGardens();
    }
  }

  Widget _buildGardenCard(Garden garden) {
    final scheme = Theme.of(context).colorScheme;
    final count = _plantCounts[garden.id] ?? 0;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: scheme.primaryContainer,
          foregroundColor: scheme.onPrimaryContainer,
          child: const Icon(Icons.yard),
        ),
        title: Text(garden.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('$count plant${count == 1 ? '' : 's'}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => _navigateToGarden(garden),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      drawer: const AppDrawer(),
      body: CustomScrollView(
        slivers: [
          const FrostedSliverAppBar(title: 'My Gardens'),
          if (_gardens.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No gardens yet.')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildGardenCard(_gardens[index]),
                childCount: _gardens.length,
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createGarden,
        child: const Icon(Icons.add),
      ),
    );
  }
}
