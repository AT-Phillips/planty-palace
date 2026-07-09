import 'package:flutter/material.dart';

import '../models/plant.dart';
// import '../services/home_widget_service.dart'; // widget disabled for now
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/care_overdue.dart';
import '../utils/fertilizing_status.dart';
import '../utils/pruning_status.dart';
import '../utils/repotting_status.dart';
import '../utils/watering_status.dart';
import '../widgets/account_button.dart';
import '../widgets/care_ring.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/pest_disease_view.dart';
import '../widgets/search_field.dart';
import '../widgets/weather_appbar_chip.dart';
import 'plant_detail_screen.dart';

/// The single most urgent care line for a plant - whichever of
/// watering/fertilizing/repotting/pruning is soonest due, matching the
/// ordering [PlantSortOption.urgency] already sorts by. Returns null if the
/// plant has no schedules at all.
({String text, bool overdue})? _primaryCareStatus(Plant plant) {
  final candidates = <(int, String, bool)>[
    if (daysUntilDue(plant) != null)
      (daysUntilDue(plant)!, wateringStatusText(plant), isOverdue(plant)),
    if (daysUntilFertilizeDue(plant) != null)
      (daysUntilFertilizeDue(plant)!, fertilizingStatusText(plant), isFertilizingOverdue(plant)),
    if (daysUntilRepotDue(plant) != null)
      (daysUntilRepotDue(plant)!, repottingStatusText(plant), isRepottingOverdue(plant)),
    if (daysUntilPruneDue(plant) != null)
      (daysUntilPruneDue(plant)!, pruningStatusText(plant), isPruningOverdue(plant)),
  ];
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.$1.compareTo(b.$1));
  final (_, text, overdue) = candidates.first;
  return (text: text, overdue: overdue);
}

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
  String _query = '';
  PlantSortOption _sortOption = PlantSortOption.urgency;
  bool _overdueOnly = false;
  bool _selectionMode = false;
  Set<String> _selectedIds = {};

  /// 0 = My Plants, 1 = Common Problems (pest/disease reference).
  int _careSection = 0;

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
      final plants = await _repository.getPlants();
      if (!mounted) return;
      setState(() => _plants = plants);
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

  Future<void> _navigateToDetail(Plant plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: plant)),
    );
    if (result == true && mounted) {
      _load();
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
    final selected = _selectedIds.contains(plant.id);
    final status = _primaryCareStatus(plant);
    final overdue = status?.overdue ?? false;
    final canWater = plant.wateringIntervalDays != null;

    final card = Card(
      color: selected ? scheme.primaryContainer.withValues(alpha: 0.4) : null,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.radius),
        onTap: () => _selectionMode ? _toggleSelection(plant) : _navigateToDetail(plant),
        onLongPress: _selectionMode ? null : () => _startSelection(plant),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              _selectionMode
                  ? Checkbox(value: selected, onChanged: (_) => _toggleSelection(plant))
                  : CareRing(plant: plant, heroTag: 'plant_${plant.id}'),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plant.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(
                      status?.text ?? 'No care schedule set',
                      style: overdue
                          ? TextStyle(
                              color: AppTheme.urgentColor(context),
                              fontWeight: FontWeight.w600,
                            )
                          : TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (!_selectionMode && canWater)
                IconButton(
                  onPressed: () => _markWatered(plant),
                  tooltip: 'Mark as watered',
                  icon: Icon(
                    Icons.water_drop,
                    color: overdue ? AppTheme.urgentColor(context) : scheme.outlineVariant,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        overdue ? AppTheme.urgentColor(context).withValues(alpha: 0.15) : null,
                    shape: const CircleBorder(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    // Swipe right to mark watered - a quick, tactile alternative to the ⋯
    // menu. Disabled in selection mode and for plants with no watering
    // schedule. confirmDismiss performs the action and returns false so the
    // card stays put rather than being removed.
    if (_selectionMode || plant.wateringIntervalDays == null) return card;
    return Dismissible(
      key: ValueKey('care_${plant.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _markWatered(plant);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF3FA34D),
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop, color: Colors.white),
            SizedBox(width: 8),
            Text('Watered', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
      child: card,
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
          : const FrostedAppBar(
              title: 'Care',
              actions: [WeatherAppBarChip(), AccountButton()],
            ),
      body: Column(
        children: [
          if (!_selectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<int>(
                segments: const [
                  ButtonSegment(value: 0, label: Text('My Plants'), icon: Icon(Icons.eco_outlined)),
                  ButtonSegment(
                    value: 1,
                    label: Text('Diagnose'),
                    icon: Icon(Icons.bug_report_outlined),
                  ),
                ],
                selected: {_careSection},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _careSection = s.first),
              ),
            ),
          Expanded(
            child: _careSection == 1
                ? const PestDiseaseView()
                : _buildPlantsSection(filtered),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantsSection(List<Plant> filtered) {
    if (_plants.isEmpty) {
      return const EmptyState(
        icon: Icons.water_drop_outlined,
        title: 'Nothing to water yet',
        message: 'Once you add plants with a watering schedule, '
            "they'll show up here when they need attention.",
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
    );
  }
}
