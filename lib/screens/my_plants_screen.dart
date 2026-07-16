import 'package:flutter/material.dart';

import '../models/garden.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../utils/care_overdue.dart';
import '../utils/watering_status.dart' show isOverdue;
import '../widgets/animated_entrance.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/pulse_glow.dart';
import '../widgets/search_field.dart';
import 'add_edit_plant_screen.dart';
import 'plant_detail_screen.dart';

/// Shows the plants inside a single [Garden] - or, when [garden] is null,
/// every plant across all spaces (the "All Plants" view), with an extra
/// filter-by-space control. The single-garden and all-plants modes share all
/// of the search/sort/filter/delete logic.
class MyPlantsScreen extends StatefulWidget {
  final Garden? garden;

  const MyPlantsScreen({super.key, this.garden});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final PlantRepository _repository = PlantRepository();
  final TextEditingController _searchController = TextEditingController();
  List<Plant> _plants = [];
  List<Garden> _gardens = []; // for the space filter in all-plants mode
  String _query = '';
  PlantSortOption _sortOption = PlantSortOption.name;
  bool _overdueOnly = false;
  String? _spaceFilterId; // null = all spaces (all-plants mode only)

  bool get _isAllMode => widget.garden == null;

  @override
  void initState() {
    super.initState();
    _loadPlants();
    if (_isAllMode) _loadGardens();
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
    final list =
        _plants.where((p) {
          if (_query.isNotEmpty &&
              !p.name.toLowerCase().contains(_query) &&
              !p.species.toLowerCase().contains(_query)) {
            return false;
          }
          if (_overdueOnly && !hasAnyOverdueCare(p)) return false;
          if (_spaceFilterId != null && p.gardenId != _spaceFilterId)
            return false;
          return true;
        }).toList();
    sortPlants(list, _sortOption);
    return list;
  }

  Future<void> _loadPlants() async {
    try {
      final plants =
          _isAllMode
              ? await _repository.getPlants()
              : await _repository.getPlantsByGarden(widget.garden!.id!);
      if (!mounted) return;
      setState(() => _plants = plants);
    } catch (e) {
      debugPrint('Failed to load plants: $e');
    }
  }

  Future<void> _loadGardens() async {
    try {
      final gardens = await _repository.getGardens();
      if (!mounted) return;
      setState(() => _gardens = gardens);
    } catch (e) {
      debugPrint('Failed to load gardens: $e');
    }
  }

  Future<void> _navigateToAddPlant() async {
    final gardenId =
        widget.garden?.id ?? await _repository.getOrCreateDefaultGardenId();
    if (!mounted) return;
    final result = await Navigator.push(
      context,
      appRoute(AddEditPlantScreen(gardenId: gardenId)),
    );
    if (result != null && mounted) {
      _loadPlants();
    }
  }

  Future<void> _navigateToDetail(Plant plant) async {
    final result = await Navigator.push(
      context,
      appRoute(PlantDetailScreen(plant: plant)),
    );
    if (result == true && mounted) {
      _loadPlants();
    }
  }

  Future<void> _markWatered(Plant plant) async {
    await _repository.markWatered(plant.id!);
    final updated = plant.copyWith(
      lastWatered: DateTime.now().toIso8601String(),
    );
    await NotificationService().scheduleWateringReminder(updated);
    if (!mounted) return;
    _loadPlants();
  }

  Future<void> _deletePlant(Plant plant) async {
    // Optimistically hide, then commit after a fixed window - decoupled from
    // the snackbar's close future (which could leave the snackbar stuck and
    // the delete never committing). Undo restores immediately.
    setState(() => _plants.removeWhere((p) => p.id == plant.id));

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    var undone = false;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${plant.name} deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undone = true;
            if (mounted) _loadPlants();
          },
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 4, milliseconds: 250));
    if (undone) return;

    await _repository.deletePlant(plant.id!);
    await NotificationService().cancelReminder(plant.id!);
    if (mounted) _loadPlants();
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

  Widget _buildSpaceFilter() {
    final scheme = Theme.of(context).colorScheme;
    final label =
        _spaceFilterId == null
            ? 'All spaces'
            : _gardens
                .firstWhere(
                  (g) => g.id == _spaceFilterId,
                  orElse: () => Garden(name: 'Space'),
                )
                .name;
    return PopupMenuButton<String?>(
      initialValue: _spaceFilterId,
      onSelected: (id) => setState(() => _spaceFilterId = id),
      itemBuilder:
          (context) => [
            const PopupMenuItem<String?>(
              value: null,
              child: Text('All spaces'),
            ),
            for (final g in _gardens)
              PopupMenuItem<String?>(value: g.id, child: Text(g.name)),
          ],
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.arrow_drop_down, size: 18),
        ],
      ),
    );
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
          if (_isAllMode) ...[_buildSpaceFilter(), const SizedBox(width: 12)],
          PopupMenuButton<PlantSortOption>(
            initialValue: _sortOption,
            onSelected: (option) => setState(() => _sortOption = option),
            itemBuilder:
                (context) =>
                    PlantSortOption.values
                        .map(
                          (option) => PopupMenuItem(
                            value: option,
                            child: Text(_sortLabel(option)),
                          ),
                        )
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

  /// Photo-first gallery tile: a square-ish photo with a small tap-to-water
  /// drop badge overlaid in its corner (filled fern when on schedule, coral
  /// when overdue), name + species below. Detailed watering/fertilizing/
  /// repotting/pruning status lives on Care, the dedicated action screen, so
  /// this stays a clean browsing tile.
  Widget _buildPlantCard(Plant plant) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = isOverdue(plant);
    final badgeColor =
        overdue ? AppTheme.careOverdue(context) : AppTheme.fernColor(context);

    return Dismissible(
      key: ValueKey(plant.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deletePlant(plant),
      background: Container(
        decoration: BoxDecoration(
          color: scheme.errorContainer,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Icon(Icons.delete, color: scheme.onErrorContainer),
      ),
      child: Material(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _navigateToDetail(plant),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlantThumbnail(
                      plant: plant,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.zero,
                      heroTag: 'plant_${plant.id}',
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: PulseGlow(
                        active: overdue,
                        color: badgeColor,
                        child: Material(
                          color: badgeColor,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => _markWatered(plant),
                            child: const Padding(
                              padding: EdgeInsets.all(6),
                              child: Icon(
                                Icons.water_drop,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plant.name,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.plantNameStyle(context, size: 14.5),
                    ),
                    Text(
                      plant.species,
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        fontSize: 10.5,
                        color: scheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredPlants;
    final title = widget.garden?.name ?? 'All Plants';

    return Scaffold(
      appBar: FrostedAppBar(title: title),
      body:
          _plants.isEmpty
              ? EmptyState(
                icon: Icons.local_florist_outlined,
                title: _isAllMode ? 'No plants yet' : 'No plants in $title yet',
                message:
                    'Tap the + button to identify and add your first plant.',
                actionLabel: 'Add a Plant',
                onAction: _navigateToAddPlant,
              )
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SearchField(
                      controller: _searchController,
                      hintText:
                          _isAllMode
                              ? 'Search all plants'
                              : 'Search this Space',
                    ),
                  ),
                  _buildFilterBar(),
                  Expanded(
                    child:
                        filtered.isEmpty
                            ? EmptyState(
                              icon: Icons.filter_alt_off_outlined,
                              title: 'No matching plants',
                              message:
                                  _overdueOnly
                                      ? 'Nothing is overdue right now.'
                                      : 'Try a different search or filter.',
                            )
                            : GridView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    mainAxisSpacing: 12,
                                    crossAxisSpacing: 12,
                                    childAspectRatio: 0.78,
                                  ),
                              itemCount: filtered.length,
                              itemBuilder:
                                  (context, index) => AnimatedEntrance(
                                    index: index,
                                    child: _buildPlantCard(filtered[index]),
                                  ),
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
