import 'package:flutter/material.dart';

import '../helpers/database_helper.dart';
import '../models/garden.dart';
import '../widgets/frosted_sliver_app_bar.dart';
import 'my_plants_screen.dart';

class SpacesScreen extends StatefulWidget {
  const SpacesScreen({super.key});

  @override
  State<SpacesScreen> createState() => _SpacesScreenState();
}

class _SpacesScreenState extends State<SpacesScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Garden> _spaces = [];
  Map<int, int> _plantCounts = {};

  @override
  void initState() {
    super.initState();
    _loadSpaces();
  }

  Future<void> _loadSpaces() async {
    final spaces = await _dbHelper.getGardens();
    final counts = <int, int>{};
    for (final space in spaces) {
      counts[space.id!] = await _dbHelper.getPlantCountForGarden(space.id!);
    }
    if (!mounted) return;
    setState(() {
      _spaces = spaces;
      _plantCounts = counts;
    });
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
      await _dbHelper.insertGarden(Garden(name: name));
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
      extendBodyBehindAppBar: true,
      body: CustomScrollView(
        slivers: [
          const FrostedSliverAppBar(title: 'My Spaces'),
          if (_spaces.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: Text('No spaces yet.')),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildSpaceCard(_spaces[index]),
                childCount: _spaces.length,
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
