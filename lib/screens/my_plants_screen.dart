import 'dart:ui';

import 'package:flutter/material.dart';

import '../models/garden.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../utils/care_kind.dart';
import '../utils/care_overdue.dart';
import '../utils/watering_status.dart' show isOverdue;
import '../widgets/animated_entrance.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/primitives.dart';
import '../widgets/pulse_glow.dart';
import '../widgets/search_field.dart';
import '../widgets/shimmer.dart';
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

  bool _loaded = false;
  String? _error;

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
          if (_spaceFilterId != null && p.gardenId != _spaceFilterId) {
            return false;
          }
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
      setState(() {
        _plants = plants;
        _loaded = true;
        _error = null;
      });
    } catch (e) {
      debugPrint('Failed to load plants: $e');
      if (!mounted) return;
      setState(() {
        _loaded = true;
        if (_plants.isEmpty) _error = '$e';
      });
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
    if (result != null && mounted) _loadPlants();
  }

  Future<void> _navigateToDetail(Plant plant) async {
    final result = await Navigator.push(
      context,
      appRoute(PlantDetailScreen(plant: plant)),
    );
    if (result == true && mounted) _loadPlants();
  }

  /// Waters in place - the tile updates from memory rather than triggering a
  /// full collection refetch on every tap of the drop badge.
  Future<void> _markWatered(Plant plant) async {
    final updated = CareKind.water.withPerformed(plant, DateTime.now());
    setState(() {
      final index = _plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) _plants[index] = updated;
    });
    try {
      await _repository.markCare(plant.id!, CareKind.water);
      await NotificationService().scheduleWateringReminder(updated);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Could not save that. Please try again.',
          error: true);
      _loadPlants();
    }
  }

  Future<void> _deletePlant(Plant plant) async {
    // Optimistically hide, then commit after a fixed window - decoupled from
    // the snackbar's close future (which could leave the snackbar stuck and
    // the delete never committing). Undo restores immediately.
    setState(() => _plants.removeWhere((p) => p.id == plant.id));

    var undone = false;
    showAppSnack(
      context,
      '${plant.name} deleted',
      onUndo: () {
        undone = true;
        if (mounted) _loadPlants();
      },
    );

    await Future.delayed(const Duration(seconds: 4, milliseconds: 250));
    if (undone) return;

    await _repository.deletePlant(plant.id!);
    await NotificationService().cancelReminder(plant.id!);
    if (mounted) _loadPlants();
  }

  String _sortLabel(PlantSortOption option) => switch (option) {
    PlantSortOption.name => 'Name',
    PlantSortOption.dateAdded => 'Date added',
    PlantSortOption.urgency => 'Most urgent',
  };

  IconData _sortIcon(PlantSortOption option) => switch (option) {
    PlantSortOption.name => Icons.sort_by_alpha_rounded,
    PlantSortOption.dateAdded => Icons.schedule_rounded,
    PlantSortOption.urgency => Icons.priority_high_rounded,
  };

  Future<void> _openSortMenu() async {
    final option = await showAppMenu<PlantSortOption>(
      context,
      title: 'Sort by',
      options: [
        for (final option in PlantSortOption.values)
          AppMenuOption(
            label: _sortLabel(option),
            icon: _sortIcon(option),
            value: option,
            selected: option == _sortOption,
          ),
      ],
    );
    if (option != null) setState(() => _sortOption = option);
  }

  Future<void> _openSpaceMenu() async {
    final selection = await showAppMenu<String>(
      context,
      title: 'Filter by Space',
      options: [
        AppMenuOption(
          label: 'All spaces',
          icon: Icons.apps_rounded,
          value: '',
          selected: _spaceFilterId == null,
        ),
        for (final g in _gardens)
          AppMenuOption(
            label: g.name,
            icon: Icons.grid_view_rounded,
            value: g.id!,
            selected: g.id == _spaceFilterId,
          ),
      ],
    );
    if (selection == null) return;
    setState(() => _spaceFilterId = selection.isEmpty ? null : selection);
  }

  String get _spaceFilterLabel {
    if (_spaceFilterId == null) return 'All spaces';
    return _gardens
        .firstWhere(
          (g) => g.id == _spaceFilterId,
          orElse: () => Garden(name: 'Space'),
        )
        .name;
  }

  Widget _buildFilterBar() {
    return FilterBar(
      children: [
        FilterPill(
          label: 'Overdue',
          icon: Icons.priority_high_rounded,
          selected: _overdueOnly,
          urgent: true,
          onTap: () => setState(() => _overdueOnly = !_overdueOnly),
        ),
        if (_isAllMode)
          InlineButton(
            label: _spaceFilterLabel,
            icon: Icons.grid_view_rounded,
            onTap: _openSpaceMenu,
          ),
        InlineButton(
          label: _sortLabel(_sortOption),
          icon: Icons.swap_vert_rounded,
          onTap: _openSortMenu,
        ),
      ],
    );
  }

  /// Photo-first gallery tile: a square photo with a tap-to-water drop badge
  /// overlaid in its corner, name + species below.
  ///
  /// The badge is a frosted disc when on schedule and a solid pulsing coral
  /// when overdue - so urgency is legible from across the grid without a
  /// second glance, while a healthy plant stays quiet. Detailed
  /// watering/fertilizing/repotting/pruning status lives on Care, so this
  /// stays a clean browsing tile.
  Widget _buildPlantCard(Plant plant) {
    final p = context.palette;
    final overdue = isOverdue(plant);

    return Dismissible(
      key: ValueKey(plant.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deletePlant(plant),
      background: Container(
        decoration: BoxDecoration(
          color: p.coral,
          borderRadius: AppRadius.lgAll,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _navigateToDetail(plant),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PlantThumbnail(
                    plant: plant,
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppRadius.lg),
                    ),
                    heroTag: 'plant_${plant.id}',
                  ),
                  Positioned(
                    top: 9,
                    right: 9,
                    child: PulseGlow(
                      active: overdue,
                      color: p.coral,
                      child: _WaterBadge(
                        overdue: overdue,
                        onTap: () => _markWatered(plant),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    plant.name,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme.plantNameStyle(context, size: 15),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    plant.species,
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      color: p.inkFaint,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.garden?.name ?? 'All Plants';

    return Scaffold(
      appBar: FrostedAppBar(title: title),
      body: _buildBody(title),
      floatingActionButton: FloatingActionPill(
        label: 'Add plant',
        onPressed: _navigateToAddPlant,
      ),
    );
  }

  Widget _buildBody(String title) {
    if (!_loaded) return const PlantGridSkeleton();
    if (_error != null) {
      return AppErrorView(
        message:
            'Your plants could not be loaded. Check your connection and try '
            'again.',
        onRetry: _loadPlants,
      );
    }
    if (_plants.isEmpty) {
      return EmptyState(
        icon: Icons.local_florist_outlined,
        title: _isAllMode ? 'No plants yet' : 'No plants in $title yet',
        message: 'Add your first plant to start tracking its care.',
        actionLabel: 'Add a Plant',
        onAction: _navigateToAddPlant,
      );
    }

    final filtered = _filteredPlants;

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        await _loadPlants();
        if (_isAllMode) await _loadGardens();
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Gap.screen, 10, Gap.screen, 10),
            child: SearchField(
              controller: _searchController,
              hintText: _isAllMode ? 'Search all plants' : 'Search this Space',
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
                      padding: const EdgeInsets.fromLTRB(
                        Gap.screen,
                        0,
                        Gap.screen,
                        96,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 14,
                            crossAxisSpacing: 14,
                            childAspectRatio: 0.76,
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
    );
  }
}

/// The tap-to-water badge on a grid tile.
///
/// On schedule it is a genuinely frosted disc - a blur of whatever photo sits
/// behind it - rather than a flat translucent white circle, so it stays
/// legible over both a bright leaf and a dark pot. Overdue, it goes solid
/// coral and the surrounding [PulseGlow] animates.
class _WaterBadge extends StatelessWidget {
  final bool overdue;
  final VoidCallback onTap;

  const _WaterBadge({required this.overdue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color:
                  overdue ? p.coral : Colors.black.withValues(alpha: 0.22),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: overdue ? 0.0 : 0.45),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
