import 'package:flutter/material.dart';

import '../models/garden.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../utils/watering_status.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import 'add_edit_plant_screen.dart';

/// Shows the plants inside a single [Garden].
class MyPlantsScreen extends StatefulWidget {
  final Garden garden;

  const MyPlantsScreen({super.key, required this.garden});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final PlantRepository _repository = PlantRepository();
  List<Plant> _plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
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
    if (result == true && mounted) {
      _loadPlants();
    }
  }

  Future<void> _navigateToEditPlant(Plant plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(
          plant: plant,
          gardenId: widget.garden.id!,
        ),
      ),
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
          onTap: () => _navigateToEditPlant(plant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
          : ListView.builder(
              itemCount: _plants.length,
              itemBuilder: (context, index) => _buildPlantCard(_plants[index]),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlant,
        child: const Icon(Icons.add),
      ),
    );
  }
}
