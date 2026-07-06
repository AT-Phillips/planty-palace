import 'package:flutter/material.dart';

import '../models/plant.dart';
// import '../services/home_widget_service.dart'; // widget disabled for now
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../utils/fertilizing_status.dart';
import '../utils/watering_status.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/search_field.dart';
import 'plant_detail_screen.dart';

/// Shows every plant across every Space, sorted so whatever needs
/// attention soonest surfaces first. Also doubles as the "browse all my
/// plants regardless of Space" view.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => _CareScreenState();
}

class _CareScreenState extends State<CareScreen> {
  final PlantRepository _repository = PlantRepository();
  final TextEditingController _searchController = TextEditingController();

  // MainShell rebuilds each tab fresh on every switch (not an IndexedStack),
  // so this State is recreated every time the user taps this tab. Seeding
  // from the last successful load avoids a flash of the empty state while
  // the new fetch is in flight.
  static List<Plant>? _cachedPlants;
  static Map<String, String>? _cachedSpaceNames;

  List<Plant> _plants = _cachedPlants ?? [];
  Map<String, String> _spaceNames = _cachedSpaceNames ?? {};
  String _query = '';

  @override
  void initState() {
    super.initState();
    _load();
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

  /// The sooner of watering/fertilizing due-in-days (whichever is more
  /// urgent), or null if neither has a schedule set.
  int? _mostUrgentDueIn(Plant plant) {
    final watering = daysUntilDue(plant);
    final fertilizing = daysUntilFertilizeDue(plant);
    if (watering == null) return fertilizing;
    if (fertilizing == null) return watering;
    return watering < fertilizing ? watering : fertilizing;
  }

  Future<void> _load() async {
    try {
      final spaces = await _repository.getGardens();
      final plants = await _repository.getPlants();

      plants.sort((a, b) {
        final aDue = _mostUrgentDueIn(a);
        final bDue = _mostUrgentDueIn(b);
        if (aDue == null && bDue == null) return 0;
        if (aDue == null) return 1;
        if (bDue == null) return -1;
        return aDue.compareTo(bDue);
      });

      final spaceNames = {for (final s in spaces) s.id!: s.name};
      _cachedPlants = plants;
      _cachedSpaceNames = spaceNames;
      if (!mounted) return;
      setState(() {
        _spaceNames = spaceNames;
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
    // HomeWidgetService().refresh(); // widget disabled for now
    if (!mounted) return;
    _load();
  }

  Future<void> _markFertilized(Plant plant) async {
    await _repository.markFertilized(plant.id!);
    final updated = plant.copyWith(lastFertilized: DateTime.now().toIso8601String());
    await NotificationService().scheduleFertilizingReminder(updated);
    // HomeWidgetService().refresh(); // widget disabled for now
    if (!mounted) return;
    _load();
  }

  Future<void> _navigateToDetail(Plant plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
    );
    if (result == true && mounted) {
      _load();
    }
  }

  Widget _buildCareCard(Plant plant) {
    final scheme = Theme.of(context).colorScheme;
    final spaceName = _spaceNames[plant.gardenId] ?? '';
    final overdue = isOverdue(plant);
    final fertilizingOverdue = isFertilizingOverdue(plant);
    final hasFertilizingSchedule = plant.fertilizingIntervalDays != null;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: PlantThumbnail(plant: plant),
        title: Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(spaceName),
            Text(
              wateringStatusText(plant),
              style: overdue ? TextStyle(color: scheme.error) : null,
            ),
            if (hasFertilizingSchedule)
              Text(
                fertilizingStatusText(plant),
                style: fertilizingOverdue ? TextStyle(color: scheme.error) : null,
              ),
          ],
        ),
        trailing: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.water_drop),
              tooltip: 'Mark as watered',
              onPressed: () => _markWatered(plant),
            ),
            if (hasFertilizingSchedule)
              IconButton(
                icon: const Icon(Icons.eco_outlined),
                tooltip: 'Mark as fertilized',
                onPressed: () => _markFertilized(plant),
              ),
          ],
        ),
        onTap: () => _navigateToDetail(plant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlants;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Care'),
      body: _plants.isEmpty
          ? const EmptyState(
              icon: Icons.water_drop_outlined,
              title: 'Nothing to water yet',
              message: 'Once you add plants with a watering schedule, '
                  "they'll show up here when they need attention.",
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: SearchField(
                    controller: _searchController,
                    hintText: 'Search all your plants',
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => _buildCareCard(filtered[index]),
                  ),
                ),
              ],
            ),
    );
  }
}
