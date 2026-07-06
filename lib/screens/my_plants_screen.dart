import 'package:flutter/material.dart';

import '../models/garden.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../utils/watering_status.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/search_field.dart';
import 'add_edit_plant_screen.dart';
import 'plant_detail_screen.dart';

/// Shows the plants inside a single [Garden].
class MyPlantsScreen extends StatefulWidget {
  final Garden garden;

  const MyPlantsScreen({super.key, required this.garden});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final PlantRepository _repository = PlantRepository();
  final TextEditingController _searchController = TextEditingController();
  List<Plant> _plants = [];
  String _query = '';

  @override
  void initState() {
    super.initState();
    _loadPlants();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Plant> get _filteredPlants {
    if (_query.isEmpty) return _plants;
    return _plants
        .where((p) =>
            p.name.toLowerCase().contains(_query) || p.species.toLowerCase().contains(_query))
        .toList();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await _repository.getPlantsByGarden(widget.garden.id!);
      if (!mounted) return;
      setState(() => _plants = plants);
    } catch (e) {
      debugPrint('Failed to load plants: $e');
    }
  }

  Future<void> _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(gardenId: widget.garden.id!),
      ),
    );
    if (result != null && mounted) {
      _loadPlants();
    }
  }

  Future<void> _navigateToDetail(Plant plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
    );
    if (result == true && mounted) {
      _loadPlants();
    }
  }

  Future<void> _markWatered(Plant plant) async {
    await _repository.markWatered(plant.id!);
    final updated = plant.copyWith(lastWatered: DateTime.now().toIso8601String());
    await NotificationService().scheduleWateringReminder(updated);
    if (!mounted) return;
    _loadPlants();
  }

  Future<void> _deletePlant(Plant plant) async {
    await _repository.deletePlant(plant.id!);
    await NotificationService().cancelReminder(plant.id!);
    if (!mounted) return;
    setState(() => _plants.removeWhere((p) => p.id == plant.id));
  }

  Widget _buildPlantCard(Plant plant) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = isOverdue(plant);

    return Dismissible(
      key: ValueKey(plant.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deletePlant(plant),
      background: Container(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(20),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      child: Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: PlantThumbnail(plant: plant),
          title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${plant.species}\n${wateringStatusText(plant)}',
            style: overdue ? TextStyle(color: scheme.error) : null,
          ),
          isThreeLine: true,
          trailing: IconButton(
            icon: const Icon(Icons.water_drop),
            tooltip: 'Mark as watered',
            onPressed: () => _markWatered(plant),
          ),
          onTap: () => _navigateToDetail(plant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlants;

    return Scaffold(
      appBar: FrostedAppBar(title: widget.garden.name),
      body: _plants.isEmpty
          ? EmptyState(
              icon: Icons.local_florist_outlined,
              title: 'No plants in ${widget.garden.name} yet',
              message: 'Tap the + button to identify and add your first plant here.',
              actionLabel: 'Add a Plant',
              onAction: _navigateToAddPlant,
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search this Space',
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildPlantCard(filtered[index]),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlant,
        child: const Icon(Icons.add),
      ),
    );
  }
}
