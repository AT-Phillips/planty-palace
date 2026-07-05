import 'dart:io';

import 'package:flutter/material.dart';

import '../helpers/database_helper.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../utils/watering_status.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';

/// Shows every plant across every Space, sorted so whatever needs
/// attention soonest surfaces first.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Plant> _plants = [];
  Map<int, String> _spaceNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final spaces = await _dbHelper.getGardens();
    final plants = await _dbHelper.getPlants();

    plants.sort((a, b) {
      final aDue = daysUntilDue(a);
      final bDue = daysUntilDue(b);
      if (aDue == null && bDue == null) return 0;
      if (aDue == null) return 1;
      if (bDue == null) return -1;
      return aDue.compareTo(bDue);
    });

    if (!mounted) return;
    setState(() {
      _spaceNames = {for (final s in spaces) s.id!: s.name};
      _plants = plants;
    });
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
    _load();
  }

  Widget _buildCareCard(Plant plant) {
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

    final spaceName = _spaceNames[plant.gardenId] ?? '';
    final overdue = isOverdue(plant);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: leadingWidget,
        title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
          '$spaceName\n${wateringStatusText(plant)}',
          style: overdue ? TextStyle(color: scheme.error) : null,
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.water_drop),
          tooltip: 'Mark as watered',
          onPressed: () => _markWatered(plant),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Care'),
      body: _plants.isEmpty
          ? const EmptyState(
              icon: Icons.water_drop_outlined,
              title: 'Nothing to water yet',
              message: 'Once you add plants with a watering schedule, '
                  "they'll show up here when they need attention.",
            )
          : ListView.builder(
              itemCount: _plants.length,
              itemBuilder: (context, index) => _buildCareCard(_plants[index]),
            ),
    );
  }
}
