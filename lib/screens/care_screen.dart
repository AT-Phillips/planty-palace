import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../utils/care_kind.dart';
import '../utils/care_overdue.dart';
import '../utils/fertilizing_status.dart';
import '../utils/pruning_status.dart';
import '../utils/repotting_status.dart';
import '../utils/watering_status.dart';
import '../widgets/account_button.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/care_ring.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/pest_disease_view.dart';
import '../widgets/primitives.dart';
import '../widgets/search_field.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer.dart';
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
      (
        daysUntilFertilizeDue(plant)!,
        fertilizingStatusText(plant),
        isFertilizingOverdue(plant),
      ),
    if (daysUntilRepotDue(plant) != null)
      (
        daysUntilRepotDue(plant)!,
        repottingStatusText(plant),
        isRepottingOverdue(plant),
      ),
    if (daysUntilPruneDue(plant) != null)
      (
        daysUntilPruneDue(plant)!,
        pruningStatusText(plant),
        isPruningOverdue(plant),
      ),
  ];
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => a.$1.compareTo(b.$1));
  final (_, text, overdue) = candidates.first;
  return (text: text, overdue: overdue);
}

/// Shows every plant across every Space, sorted so whatever needs attention
/// soonest surfaces first. Also doubles as the "browse all my plants
/// regardless of Space" view.
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

  bool _loaded = false;
  String? _error;

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

  /// Reloads all plants - called by MainShell after a plant is added via the
  /// global camera button, since IndexedStack keeps this tab's state alive
  /// rather than rebuilding it on return.
  void refresh() => _load();

  List<Plant> get _filteredPlants {
    final list =
        _plants.where((p) {
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
      setState(() {
        _plants = plants;
        _loaded = true;
        _error = null;
      });
    } catch (e) {
      debugPrint('Failed to load Care data: $e');
      if (!mounted) return;
      setState(() {
        _loaded = true;
        if (_plants.isEmpty) _error = '$e';
      });
    }
  }

  /// Applies a care action and updates just that plant in place.
  ///
  /// Previously every tap refetched the whole plant list, so watering one
  /// plant cost a full collection read and a visible list rebuild. The row
  /// now updates from the value already in memory.
  Future<void> _markCare(Plant plant, CareKind kind) async {
    final updated = kind.withPerformed(plant, DateTime.now());
    setState(() {
      final index = _plants.indexWhere((p) => p.id == plant.id);
      if (index != -1) _plants[index] = updated;
    });

    try {
      await _repository.markCare(plant.id!, kind);
      await _scheduleReminder(updated, kind);
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Could not save that. Please try again.',
          error: true);
      _load();
    }
  }

  Future<void> _scheduleReminder(Plant plant, CareKind kind) {
    final notifications = NotificationService();
    return switch (kind) {
      CareKind.water => notifications.scheduleWateringReminder(plant),
      CareKind.feed => notifications.scheduleFertilizingReminder(plant),
      CareKind.repot => notifications.scheduleRepottingReminder(plant),
      CareKind.prune => notifications.schedulePruningReminder(plant),
    };
  }

  Future<void> _navigateToDetail(Plant plant) async {
    final result = await Navigator.push(
      context,
      appRoute(PlantDetailScreen(plant: plant)),
    );
    if (result == true && mounted) _load();
  }

  // --- Selection ------------------------------------------------------------

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

  /// Which care kinds at least one selected plant actually has scheduled -
  /// so the bulk menu never offers an action that would be a no-op.
  List<CareKind> get _applicableBulkKinds => [
    for (final kind in CareKind.values)
      if (_plants.any(
        (p) => _selectedIds.contains(p.id) && kind.isScheduled(p),
      ))
        kind,
  ];

  /// Applies a care kind to every selected plant that has it scheduled.
  ///
  /// The whole selection is written in one batch rather than a pair of
  /// round trips per plant, so marking twenty plants watered is a single
  /// commit instead of forty sequential writes.
  Future<void> _bulkAction(CareKind kind) async {
    final targets =
        _plants
            .where((p) => _selectedIds.contains(p.id) && kind.isScheduled(p))
            .toList();
    if (targets.isEmpty) return;

    _exitSelection();
    final now = DateTime.now();
    setState(() {
      for (final plant in targets) {
        final index = _plants.indexWhere((p) => p.id == plant.id);
        if (index != -1) _plants[index] = kind.withPerformed(plant, now);
      }
    });

    try {
      await _repository.markCareBulk(targets.map((p) => p.id!), kind);
      for (final plant in targets) {
        await _scheduleReminder(kind.withPerformed(plant, now), kind);
      }
      if (!mounted) return;
      showAppSnack(
        context,
        '${targets.length} plant${targets.length == 1 ? '' : 's'} marked '
        '${kind.pastTense.toLowerCase()}',
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Could not save those changes.', error: true);
      _load();
    }
  }

  Future<void> _openBulkMenu() async {
    final kinds = _applicableBulkKinds;
    if (kinds.isEmpty) return;
    final kind = await showAppMenu<CareKind>(
      context,
      title: '${_selectedIds.length} selected',
      options: [
        for (final k in kinds)
          AppMenuOption(label: 'Mark ${k.pastTense}', icon: k.icon, value: k),
      ],
    );
    if (kind != null) await _bulkAction(kind);
  }

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

  // --- Rows -----------------------------------------------------------------

  Widget _careCard(Plant plant) {
    final p = context.palette;
    final selected = _selectedIds.contains(plant.id);
    final status = _primaryCareStatus(plant);
    final overdue = status?.overdue ?? false;
    final canWater = plant.wateringIntervalDays != null;

    final card = AppCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.zero,
      color: selected ? p.fernSoft : null,
      onTap:
          () =>
              _selectionMode ? _toggleSelection(plant) : _navigateToDetail(plant),
      onLongPress: _selectionMode ? null : () => _startSelection(plant),
      child: AppRow(
        padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
        leading:
            _selectionMode
                ? _SelectionDot(selected: selected)
                : CareRing(plant: plant, heroTag: 'plant_${plant.id}'),
        title: plant.name,
        serifTitle: true,
        subtitle: status?.text ?? 'No care schedule set',
        subtitleUrgent: overdue,
        trailing:
            !_selectionMode && canWater
                ? CircleAction(
                  icon: Icons.water_drop_rounded,
                  color: overdue ? p.coral : p.fern,
                  filled: overdue,
                  tooltip: 'Mark as watered',
                  onTap: () => _markCare(plant, CareKind.water),
                )
                : null,
      ),
    );

    // Swipe right to mark watered - a quick, tactile alternative to the
    // trailing button. Disabled in selection mode and for plants with no
    // watering schedule. confirmDismiss performs the action and returns
    // false so the card stays put rather than being removed.
    if (_selectionMode || !canWater) return card;
    return Dismissible(
      key: ValueKey('care_${plant.id}'),
      direction: DismissDirection.startToEnd,
      confirmDismiss: (_) async {
        await _markCare(plant, CareKind.water);
        return false;
      },
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: p.fern,
          borderRadius: AppRadius.lgAll,
        ),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.water_drop_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Watered',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      child: card,
    );
  }

  // --- Build ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _selectionMode ? _selectionAppBar() : _defaultAppBar(),
      body: Column(
        children: [
          if (!_selectionMode)
            Padding(
              padding: const EdgeInsets.fromLTRB(Gap.screen, 10, Gap.screen, 4),
              child: SegmentedTabs(
                labels: const ['My Plants', 'Diagnose'],
                icons: const [
                  Icons.eco_outlined,
                  Icons.healing_outlined,
                ],
                selected: _careSection,
                onChanged: (i) => setState(() => _careSection = i),
              ),
            ),
          Expanded(
            child:
                _careSection == 1
                    ? const PestDiseaseView()
                    : _buildPlantsSection(),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _defaultAppBar() => const FrostedAppBar(
    title: 'Care',
    actions: [WeatherAppBarChip(), AccountButton()],
  );

  PreferredSizeWidget _selectionAppBar() {
    final p = context.palette;
    return FrostedAppBar(
      title: '${_selectedIds.length} selected',
      leading: IconButton(
        icon: const Icon(Icons.close_rounded),
        onPressed: _exitSelection,
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.water_drop_rounded, color: p.fern),
          tooltip: 'Mark watered',
          onPressed: () => _bulkAction(CareKind.water),
        ),
        IconButton(
          icon: const Icon(Icons.more_horiz_rounded),
          tooltip: 'More actions',
          onPressed: _openBulkMenu,
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildPlantsSection() {
    if (!_loaded) return const CareListSkeleton();
    if (_error != null) {
      return AppErrorView(
        message:
            'Your plants could not be loaded. Check your connection and try '
            'again.',
        onRetry: _load,
      );
    }
    if (_plants.isEmpty) {
      return const EmptyState(
        icon: Icons.water_drop_outlined,
        title: 'Nothing to water yet',
        message:
            'Once you add plants with a watering schedule, '
            "they'll show up here when they need attention.",
      );
    }

    final filtered = _filteredPlants;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Gap.screen, 10, Gap.screen, 10),
          child: SearchField(
            controller: _searchController,
            hintText: 'Search all your plants',
          ),
        ),
        FilterBar(
          children: [
            FilterPill(
              label: 'Overdue only',
              icon: Icons.priority_high_rounded,
              selected: _overdueOnly,
              urgent: true,
              onTap: () => setState(() => _overdueOnly = !_overdueOnly),
            ),
            InlineButton(
              label: _sortLabel(_sortOption),
              icon: Icons.swap_vert_rounded,
              onTap: _openSortMenu,
            ),
          ],
        ),
        Expanded(
          child:
              filtered.isEmpty
                  ? EmptyState(
                    icon: Icons.filter_alt_off_outlined,
                    title: 'No matching plants',
                    message:
                        _overdueOnly
                            ? 'Nothing is overdue right now.'
                            : 'Try a different search.',
                  )
                  : _careList(filtered),
        ),
      ],
    );
  }

  /// When sorted by urgency (the default), the list is grouped into Overdue /
  /// Today / Upcoming rather than run together as one uninterrupted column -
  /// so "what actually needs doing" is legible without reading every row.
  /// Any other sort order is shown flat, because the grouping would then
  /// fight the order the user explicitly asked for.
  Widget _careList(List<Plant> plants) {
    if (_sortOption != PlantSortOption.urgency) {
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 16),
        itemCount: plants.length,
        itemBuilder:
            (context, index) => AnimatedEntrance(
              index: index,
              child: _careCard(plants[index]),
            ),
      );
    }

    final overdue = <Plant>[];
    final today = <Plant>[];
    final upcoming = <Plant>[];
    for (final plant in plants) {
      final due = mostUrgentDueIn(plant);
      if (due == null) {
        upcoming.add(plant);
      } else if (due < 0) {
        overdue.add(plant);
      } else if (due == 0) {
        today.add(plant);
      } else {
        upcoming.add(plant);
      }
    }

    final rows = <Widget>[];
    void addGroup(String label, List<Plant> group) {
      if (group.isEmpty) return;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: rows.isEmpty ? 0 : 14, bottom: 4),
          child: SectionHeader('$label · ${group.length}'),
        ),
      );
      rows.addAll(group.map(_careCard));
    }

    addGroup('Overdue', overdue);
    addGroup('Today', today);
    addGroup('Upcoming', upcoming);

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 16),
      itemCount: rows.length,
      itemBuilder:
          (context, index) =>
              AnimatedEntrance(index: index, child: rows[index]),
    );
  }
}

/// The selection-mode marker. Replaces Material's [Checkbox], whose 48dp tap
/// target and square-with-tick shape sat awkwardly where a 48px circular care
/// ring otherwise sits - this keeps the row's geometry identical between
/// modes so nothing jumps when selection starts.
class _SelectionDot extends StatelessWidget {
  final bool selected;

  const _SelectionDot({required this.selected});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: selected ? p.fern : Colors.transparent,
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? p.fern : p.line,
          width: 2,
        ),
      ),
      child:
          selected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 24)
              : null,
    );
  }
}
