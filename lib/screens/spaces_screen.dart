import 'package:flutter/material.dart';

import '../models/garden.dart';
import '../models/plant.dart';
import '../models/wishlist_item.dart';
import '../services/notification_service.dart';
import '../services/perenual_service.dart';
import '../services/plant_repository.dart';
import '../services/propagation_repository.dart';
import '../services/wishlist_repository.dart';
import '../styles/app_theme.dart';
import '../utils/care_overdue.dart';
import '../widgets/account_button.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/weather_appbar_chip.dart';
import 'my_plants_screen.dart';
import 'plant_detail_screen.dart';
import 'propagations_screen.dart';
import 'species_detail_screen.dart';
import '../utils/app_page_route.dart';

class SpacesScreen extends StatefulWidget {
  /// Switches the shell to the Care tab - used by the "To-Do today" section,
  /// since the tasks themselves live on Care.
  final VoidCallback? onGoToCare;

  const SpacesScreen({super.key, this.onGoToCare});

  @override
  State<SpacesScreen> createState() => SpacesScreenState();
}

class SpacesScreenState extends State<SpacesScreen> {
  final PlantRepository _repository = PlantRepository();

  List<Garden> _spaces = [];
  Map<String, int> _plantCounts = {};
  List<Plant> _dueToday = [];
  List<WishlistItem> _wishlist = [];
  int _propagationCount = 0;

  // Flash guard: don't render "empty" copy until the first spaces load has
  // completed, so switching to this tab never flickers "no spaces yet".
  bool _spacesLoaded = false;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Reloads everything - called by MainShell after a plant is added via the
  /// global camera button, since IndexedStack keeps this tab's state alive
  /// rather than rebuilding it on return.
  void refresh() {
    _loadSpaces();
    _loadPropagationCount();
    _loadDueTasks();
    _loadWishlist();
  }

  Future<void> _loadDueTasks() async {
    try {
      final plants = await _repository.getPlants();
      // "Needs care today" = any schedule due today or overdue (due-in <= 0),
      // most urgent first.
      final due =
          plants.where((p) {
              final d = mostUrgentDueIn(p);
              return d != null && d <= 0;
            }).toList()
            ..sort(
              (a, b) =>
                  (mostUrgentDueIn(a) ?? 0).compareTo(mostUrgentDueIn(b) ?? 0),
            );
      if (!mounted) return;
      setState(() => _dueToday = due);
    } catch (e) {
      debugPrint('Failed to load due tasks: $e');
    }
  }

  Future<void> _loadSpaces() async {
    try {
      final spaces = await _repository.getGardens();
      final counts = <String, int>{};
      for (final space in spaces) {
        counts[space.id!] = await _repository.getPlantCountForGarden(space.id!);
      }
      if (!mounted) return;
      setState(() {
        _spaces = spaces;
        _plantCounts = counts;
        _spacesLoaded = true;
      });
    } catch (e) {
      debugPrint('Failed to load Spaces: $e');
      if (mounted) setState(() => _spacesLoaded = true);
    }
  }

  Future<void> _loadPropagationCount() async {
    try {
      final count = await PropagationRepository().getPropagationCount();
      if (!mounted) return;
      setState(() => _propagationCount = count);
    } catch (e) {
      debugPrint('Failed to load propagation count: $e');
    }
  }

  Future<void> _loadWishlist() async {
    try {
      final items = await WishlistRepository().getWishlist();
      if (!mounted) return;
      setState(() => _wishlist = items);
    } catch (e) {
      debugPrint('Failed to load wishlist: $e');
    }
  }

  Future<void> _navigateToSpace(Garden space) async {
    await Navigator.push(context, appRoute(MyPlantsScreen(garden: space)));
    if (mounted) _loadSpaces();
  }

  Future<void> _navigateToPropagations() async {
    await Navigator.push(context, appRoute(const PropagationsScreen()));
    if (mounted) _loadPropagationCount();
  }

  Future<void> _navigateToPlant(Plant plant) async {
    await Navigator.push(context, appRoute(PlantDetailScreen(plant: plant)));
    if (mounted) refresh();
  }

  Future<void> _navigateToWishlistItem(WishlistItem item) async {
    // Reconstruct a minimal species detail from the saved fields - enough to
    // show the photo, names, and an "Add to My Plants" action.
    await Navigator.push(
      context,
      appRoute(
        SpeciesDetailScreen(
          species: PerenualSpeciesDetail(
            scientificName: item.scientificName,
            commonName: item.commonName,
            imageUrl: item.imageUrl,
            wateringIntervalDays: null,
            careInstructions: '',
          ),
        ),
      ),
    );
    if (mounted) _loadWishlist();
  }

  Future<void> _createSpace() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('New Space'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Living Room'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Create'),
              ),
            ],
          ),
    );

    if (name != null && name.isNotEmpty) {
      await _repository.insertGarden(Garden(name: name));
      _loadSpaces();
    }
  }

  Future<void> _editSpace(Garden space) async {
    final controller = TextEditingController(text: space.name);
    final name = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Rename Space'),
            content: TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(hintText: 'e.g. Living Room'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, controller.text.trim()),
                child: const Text('Save'),
              ),
            ],
          ),
    );

    if (name != null && name.isNotEmpty && name != space.name) {
      await _repository.updateGarden(Garden(id: space.id, name: name));
      _loadSpaces();
    }
  }

  Future<void> _deleteSpace(Garden space) async {
    final count = _plantCounts[space.id] ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Space?'),
            content: Text(
              count > 0
                  ? 'This deletes "${space.name}". Its $count plant${count == 1 ? '' : 's'} '
                      'will move to ${PlantRepository.defaultGardenName} instead of being deleted.'
                  : 'This deletes "${space.name}".',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed != true || !mounted) return;

    // Optimistically hide, then commit after a fixed window - decoupled from
    // the snackbar's close future (which could leave the snackbar stuck and
    // the delete never committing). Undo restores immediately.
    setState(() => _spaces.removeWhere((s) => s.id == space.id));

    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    var undone = false;
    messenger.showSnackBar(
      SnackBar(
        content: Text('${space.name} deleted'),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            undone = true;
            if (mounted) _loadSpaces();
          },
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 4, milliseconds: 250));
    if (undone) return;

    await _repository.deleteGarden(space.id!);
    if (mounted) _loadSpaces();
  }

  int get _totalPlants =>
      _plantCounts.values.fold(0, (sum, count) => sum + count);

  // --- Section builders -----------------------------------------------------

  /// A collapsible hub section styled as a rounded card, consistent with the
  /// rest of the app.
  Widget _section({
    required String title,
    required String subtitle,
    required List<Widget> children,
    bool initiallyExpanded = false,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        initiallyExpanded: initiallyExpanded,
        shape: const Border(),
        collapsedShape: const Border(),
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        children: children,
      ),
    );
  }

  Future<void> _markWatered(Plant plant) async {
    await _repository.markWatered(plant.id!);
    final updated = plant.copyWith(
      lastWatered: DateTime.now().toIso8601String(),
    );
    await NotificationService().scheduleWateringReminder(updated);
    _loadDueTasks();
  }

  String _dueLabel(Plant plant) {
    final due = mostUrgentDueIn(plant) ?? 0;
    if (due < 0) return 'Overdue by ${-due} ${-due == 1 ? 'day' : 'days'}';
    return 'Due today';
  }

  /// Deliberately NOT one more collapsible `_section` alongside
  /// Projects/Spaces/Wishlist - this is the single most important thing on
  /// the screen, so it stays always-expanded, in its own elevated card, with
  /// a strong error-toned treatment when something actually needs attention.
  Widget _todoCard() {
    final scheme = Theme.of(context).colorScheme;
    final has = _dueToday.isNotEmpty;
    final urgent = AppTheme.urgentColor(context);

    return Card(
      color: has ? urgent.withValues(alpha: 0.15) : scheme.surfaceContainerHigh,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (has)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${_dueToday.length} ${_dueToday.length == 1 ? 'PLANT NEEDS' : 'PLANTS NEED'} CARE',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                    color: urgent,
                  ),
                ),
              ),
            Row(
              children: [
                Icon(
                  has
                      ? Icons.priority_high_rounded
                      : Icons.check_circle_outline,
                  color: has ? urgent : scheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    has
                        ? '${_dueToday.length == 1 ? _dueToday.first.name : '${_dueToday.length} plants'} '
                            '${_dueToday.length == 1 ? 'is' : 'are'} overdue'
                        : "You're all caught up",
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
              ],
            ),
            if (!has)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  'Nothing needs care today.',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
              )
            else ...[
              const SizedBox(height: 4),
              for (final plant in _dueToday)
                Card(
                  color: scheme.surface,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: ListTile(
                    leading: PlantThumbnail(
                      plant: plant,
                      size: 40,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    title: Text(
                      plant.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      _dueLabel(plant),
                      style: TextStyle(color: urgent),
                    ),
                    trailing: IconButton(
                      onPressed: () => _markWatered(plant),
                      tooltip: 'Water now',
                      icon: Icon(Icons.water_drop, color: urgent),
                      style: IconButton.styleFrom(
                        backgroundColor: urgent.withValues(alpha: 0.15),
                        shape: const CircleBorder(),
                      ),
                    ),
                    onTap: () => _navigateToPlant(plant),
                  ),
                ),
              TextButton(
                onPressed: widget.onGoToCare,
                child: const Text('View all in Care'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _projectsSection() {
    return _section(
      title: 'Projects',
      subtitle:
          '$_propagationCount ${_propagationCount == 1 ? 'propagation' : 'propagations'}',
      children: [
        ListTile(
          leading: const Icon(Icons.eco_outlined),
          title: const Text('Propagations'),
          subtitle: Text('$_propagationCount in progress'),
          trailing: const Icon(Icons.chevron_right),
          onTap: _navigateToPropagations,
        ),
      ],
    );
  }

  Widget _spacesSection() {
    return _section(
      title: 'Spaces',
      // Shown immediately (starts at 0/0, like Projects/Wishlist) rather than
      // gated on _spacesLoaded - that guard is only for the empty-state
      // prompt below, not this count line, so it doesn't flash in late.
      subtitle:
          '$_totalPlants ${_totalPlants == 1 ? 'plant' : 'plants'} · '
          '${_spaces.length} ${_spaces.length == 1 ? 'space' : 'spaces'}',
      children: [
        for (final space in _spaces) _buildSpaceRow(space),
        if (_spacesLoaded && _spaces.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Create a Space for each area of your home — Living Room, Backyard, '
              'Office — to organize your plants.',
            ),
          ),
        ListTile(
          leading: const Icon(Icons.add),
          title: const Text('New Space'),
          onTap: _createSpace,
        ),
      ],
    );
  }

  Widget _buildSpaceRow(Garden space) {
    final scheme = Theme.of(context).colorScheme;
    final count = _plantCounts[space.id] ?? 0;
    final isDefault = space.name == PlantRepository.defaultGardenName;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      title: Text(
        space.name,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text('$count plant${count == 1 ? '' : 's'}'),
      trailing: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert),
        onSelected: (action) {
          if (action == 'edit') _editSpace(space);
          if (action == 'delete') _deleteSpace(space);
        },
        itemBuilder:
            (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Rename')),
              if (!isDefault)
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
      ),
      onTap: () => _navigateToSpace(space),
    );
  }

  Widget _wishlistSection() {
    return _section(
      title: 'Wishlist',
      subtitle:
          _wishlist.isEmpty ? 'Plants you want' : '${_wishlist.length} saved',
      children: [
        if (_wishlist.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(
              'Save plants you want from a species page (tap the ♥) and they\'ll '
              'show up here for later.',
            ),
          )
        else
          for (final item in _wishlist) _buildWishlistRow(item),
      ],
    );
  }

  Widget _buildWishlistRow(WishlistItem item) {
    final scheme = Theme.of(context).colorScheme;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: scheme.surfaceContainerHighest,
        foregroundColor: scheme.onSurfaceVariant,
        backgroundImage: hasImage ? NetworkImage(item.imageUrl!) : null,
        child: hasImage ? null : const Icon(Icons.local_florist_outlined),
      ),
      title: Text(
        item.commonName ?? item.scientificName,
        style: const TextStyle(fontWeight: FontWeight.w600),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        item.scientificName,
        style: const TextStyle(fontStyle: FontStyle.italic),
        overflow: TextOverflow.ellipsis,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _navigateToWishlistItem(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedAppBar(
        title: 'Spaces',
        actions: const [WeatherAppBarChip(), AccountButton()],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: () async => refresh(),
        child: ListView(
          padding: const EdgeInsets.only(top: 4, bottom: 24),
          children: [
            AnimatedEntrance(index: 0, child: _todoCard()),
            AnimatedEntrance(index: 1, child: _projectsSection()),
            AnimatedEntrance(index: 2, child: _spacesSection()),
            AnimatedEntrance(index: 3, child: _wishlistSection()),
          ],
        ),
      ),
    );
  }
}
