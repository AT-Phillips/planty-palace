import 'package:flutter/material.dart';

import '../models/plant.dart';
// import '../services/home_widget_service.dart'; // widget disabled for now
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../utils/care_overdue.dart';
import '../utils/fertilizing_status.dart';
import '../utils/pruning_status.dart';
import '../utils/repotting_status.dart';
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
  PlantSortOption _sortOption = PlantSortOption.urgency;
  bool _overdueOnly = false;

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
    final list = _plants.where((p) {
      if (_query.isNotEmpty &&
          !p.name.toLowerCase().contains(_query) &&
          !p.species.toLowerCase().contains(_query)) {
        return false;
      }
      if (_overdueOnly && !hasAnyOverdueCare(p)) return false;
      return true;
    }).toList();
    sortPlants(list, _sortOption);
    return list;
  }

  Future<void> _load() async {
    try {
      final spaces = await _repository.getGardens();
      final plants = await _repository.getPlants();

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

  Future<void> _markRepotted(Plant plant) async {
    await _repository.markRepotted(plant.id!);
    final updated = plant.copyWith(lastRepotted: DateTime.now().toIso8601String());
    await NotificationService().scheduleRepottingReminder(updated);
    if (!mounted) return;
    _load();
  }

  Future<void> _markPruned(Plant plant) async {
    await _repository.markPruned(plant.id!);
    final updated = plant.copyWith(lastPruned: DateTime.now().toIso8601String());
    await NotificationService().schedulePruningReminder(updated);
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

  Future<void> _handleCareAction(String action, Plant plant) async {
    switch (action) {
      case 'water':
        await _markWatered(plant);
        break;
      case 'fertilize':
        await _markFertilized(plant);
        break;
      case 'repot':
        await _markRepotted(plant);
        break;
      case 'prune':
        await _markPruned(plant);
        break;
    }
  }

  String _sortLabel(PlantSortOption option) {
    switch (option) {
      case PlantSortOption.name:
        return 'Name';
      case PlantSortOption.dateAdded:
        return 'Date added';
      case PlantSortOption.urgency:
        return 'Most urgent';
    }
  }

  Widget _buildFilterBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Overdue only'),
            selected: _overdueOnly,
            onSelected: (value) => setState(() => _overdueOnly = value),
          ),
          const Spacer(),
          PopupMenuButton<PlantSortOption>(
            initialValue: _sortOption,
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder: (context) => PlantSortOption.values
                .map((option) => PopupMenuItem(value: option, child: Text(_sortLabel(option))))
                .toList(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sort, size: 18),
                const SizedBox(width: 4),
                Text(_sortLabel(_sortOption)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCareCard(Plant plant) {
    final scheme = Theme.of(context).colorScheme;
    final spaceName = _spaceNames[plant.gardenId] ?? '';
    final overdue = isOverdue(plant);
    final fertilizingOverdue = isFertilizingOverdue(plant);
    final repottingOverdue = isRepottingOverdue(plant);
    final pruningOverdue = isPruningOverdue(plant);
    final hasFertilizingSchedule = plant.fertilizingIntervalDays != null;
    final hasRepottingSchedule = plant.repottingIntervalDays != null;
    final hasPruningSchedule = plant.pruningIntervalDays != null;

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
            if (hasRepottingSchedule)
              Text(
                repottingStatusText(plant),
                style: repottingOverdue ? TextStyle(color: scheme.error) : null,
              ),
            if (hasPruningSchedule)
              Text(
                pruningStatusText(plant),
                style: pruningOverdue ? TextStyle(color: scheme.error) : null,
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (action) => _handleCareAction(action, plant),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'water', child: Text('Mark Watered')),
            if (hasFertilizingSchedule)
              const PopupMenuItem(value: 'fertilize', child: Text('Mark Fertilized')),
            if (hasRepottingSchedule)
              const PopupMenuItem(value: 'repot', child: Text('Mark Repotted')),
            if (hasPruningSchedule)
              const PopupMenuItem(value: 'prune', child: Text('Mark Pruned')),
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
                _buildFilterBar(),
                Expanded(
                  child: filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.filter_alt_off_outlined,
                          title: 'No matching plants',
                          message: _overdueOnly
                              ? 'Nothing is overdue right now.'
                              : 'Try a different search.',
                        )
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildCareCard(filtered[index]),
                        ),
                ),
              ],
            ),
    );
  }
}
