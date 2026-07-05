import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../utils/watering_status.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';

/// Shows every plant across every Space, sorted so whatever needs
/// attention soonest surfaces first.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  final PlantRepository _repository = PlantRepository();
  List<Plant> _plants = [];
  Map<String, String> _spaceNames = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final spaces = await _repository.getGardens();
      final plants = await _repository.getPlants();

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
    } catch (e) {
      debugPrint('Failed to load Care data: $e');
    }
  }

  Future<void> _markWatered(Plant plant) async {
    await _repository.markWatered(plant.id!);
    final updated = plant.copyWith(lastWatered: DateTime.now().toIso8601String());
    await NotificationService().scheduleWateringReminder(updated);
    if (!mounted) return;
    _load();
  }

  Widget _buildCareCard(Plant plant) {
    final scheme = Theme.of(context).colorScheme;
    final spaceName = _spaceNames[plant.gardenId] ?? '';
    final overdue = isOverdue(plant);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: PlantThumbnail(plant: plant),
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
