import 'dart:io';

import 'package:flutter/material.dart';

import '../helpers/database_helper.dart';
import '../models/garden.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../utils/watering_status.dart';
import '../widgets/frosted_app_bar.dart';
import 'add_edit_plant_screen.dart';

/// Shows the plants inside a single [Garden].
class MyPlantsScreen extends StatefulWidget {
  final Garden garden;

  const MyPlantsScreen({super.key, required this.garden});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Plant> _plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await _dbHelper.getPlantsByGarden(widget.garden.id!);
    if (!mounted) return;
    setState(() => _plants = plants);
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
    await _dbHelper.markWatered(plant.id!);
    final updated = Plant(
      id: plant.id,
      name: plant.name,
      species: plant.species,
      imagePath: plant.imagePath,
      careInstructions: plant.careInstructions,
      gardenId: plant.gardenId,
      lastWatered: DateTime.now().toIso8601String(),
      wateringIntervalDays: plant.wateringIntervalDays,
    );
    await NotificationService().scheduleWateringReminder(updated);
    if (!mounted) return;
    _loadPlants();
  }

  Future<void> _deletePlant(Plant plant) async {
    await _dbHelper.deletePlant(plant.id!);
    await NotificationService().cancelReminder(plant.id!);
    if (!mounted) return;
    setState(() => _plants.removeWhere((p) => p.id == plant.id));
  }

  Widget _buildPlantCard(Plant plant) {
    final scheme = Theme.of(context).colorScheme;
    Widget leadingWidget;

    if (plant.imagePath.isNotEmpty) {
      leadingWidget = ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(plant.imagePath),
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
        ),
      );
    } else {
      leadingWidget = const Icon(Icons.local_florist);
    }

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
          leading: leadingWidget,
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
          ? const Center(child: Text('No plants yet.'))
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
