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
import 'pest_disease_screen.dart';
import 'plant_detail_screen.dart';

/// Shows every plant across every Space, sorted so whatever needs
/// attention soonest surfaces first. Also doubles as the "browse all my
/// plants regardless of Space" view.
class CareScreen extends StatefulWidget {
  const CareScreen({super.key});

  @override
  State<CareScreen> createState() => CareScreenState();
}

class CareScreenState extends State<CareScreen> {
  final PlantRepository _repository = PlantRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Plant> _plants = [];
  Map<String, String> _spaceNames = {};
  String _query = '';
  PlantSortOption _sortOption = PlantSortOption.urgency;
  bool _overdueOnly = false;
  bool _selectionMode = false;
  Set<String> _selectedIds = {};

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

  /// Reloads all plants - called by MainShell after a plant is added via
  /// the global camera button, since IndexedStack keeps this tab's state
  /// alive rather than rebuilding it on return.
  void refresh() => _load();

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

  void _startSelection(Plant plant) {
    setState(() {
      _selectionMode = true;
      _selectedIds = {plant.id!};
    });
  }

  void _toggleSelection(Plant plant) {
    setState(() {
      if (_selectedIds.contains(plant.id)) {
        _selectedIds.remove(plant.id);
        if (_selectedIds.isEmpty) _selectionMode = false;
      } else {
        _selectedIds.add(plant.id!);
      }
    });
  }

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds = {};
    });
  }

  bool get _anySelectedHasFertilizing =>
      _plants.any((p) => _selectedIds.contains(p.id) && p.fertilizingIntervalDays != null);
  bool get _anySelectedHasRepotting =>
      _plants.any((p) => _selectedIds.contains(p.id) && p.repottingIntervalDays != null);
  bool get _anySelectedHasPruning =>
      _plants.any((p) => _selectedIds.contains(p.id) && p.pruningIntervalDays != null);

  Future<void> _bulkAction(String action) async {
    final selected = _plants.where((p) => _selectedIds.contains(p.id)).toList();
    for (final plant in selected) {
      if (action == 'water') {
        await _repository.markWatered(plant.id!);
        await NotificationService().scheduleWateringReminder(
          plant.copyWith(lastWatered: DateTime.now().toIso8601String()),
        );
      } else if (action == 'fertilize' && plant.fertilizingIntervalDays != null) {
        await _repository.markFertilized(plant.id!);
        await NotificationService().scheduleFertilizingReminder(
          plant.copyWith(lastFertilized: DateTime.now().toIso8601String()),
        );
      } else if (action == 'repot' && plant.repottingIntervalDays != null) {
        await _repository.markRepotted(plant.id!);
        await NotificationService().scheduleRepottingReminder(
          plant.copyWith(lastRepotted: DateTime.now().toIso8601String()),
        );
      } else if (action == 'prune' && plant.pruningIntervalDays != null) {
        await _repository.markPruned(plant.id!);
        await NotificationService().schedulePruningReminder(
          plant.copyWith(lastPruned: DateTime.now().toIso8601String()),
        );
      }
    }
    if (!mounted) return;
    _exitSelection();
    _load();
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
    final selected = _selectedIds.contains(plant.id);

    return Card(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: _selectionMode
            ? Checkbox(value: selected, onChanged: (_) => _toggleSelection(plant))
            : PlantThumbnail(plant: plant),
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
        trailing: _selectionMode
            ? null
            : PopupMenuButton<String>(
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
        onTap: () => _selectionMode ? _toggleSelection(plant) : _navigateToDetail(plant),
        onLongPress: _selectionMode ? null : () => _startSelection(plant),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlants;

    return Scaffold(
      appBar: _selectionMode
          ? FrostedAppBar(
              title: '${_selectedIds.length} selected',
              leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitSelection),
              actions: [
                IconButton(
                  icon: const Icon(Icons.water_drop),
                  tooltip: 'Mark Watered',
                  onPressed: () => _bulkAction('water'),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: _bulkAction,
                  itemBuilder: (context) => [
                    if (_anySelectedHasFertilizing)
                      const PopupMenuItem(value: 'fertilize', child: Text('Mark Fertilized')),
                    if (_anySelectedHasRepotting)
                      const PopupMenuItem(value: 'repot', child: Text('Mark Repotted')),
                    if (_anySelectedHasPruning)
                      const PopupMenuItem(value: 'prune', child: Text('Mark Pruned')),
                  ],
                ),
              ],
            )
          : FrostedAppBar(
              title: 'Care',
              actions: [
                IconButton(
                  icon: const Icon(Icons.bug_report_outlined),
                  tooltip: 'Common Problems',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PestDiseaseScreen()),
                  ),
                ),
              ],
            ),
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
