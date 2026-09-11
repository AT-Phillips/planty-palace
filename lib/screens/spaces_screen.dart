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
import '../utils/app_page_route.dart';
import '../utils/care_kind.dart';
import '../utils/care_overdue.dart';
import '../widgets/account_button.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/primitives.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer.dart';
import '../widgets/weather_appbar_chip.dart';
import 'my_plants_screen.dart';
import 'plant_detail_screen.dart';
import 'propagations_screen.dart';
import 'species_detail_screen.dart';

/// The hub: what needs doing today, then a way into everything else.
///
/// This screen used to be three [ExpansionTile]s inside [Card]s with
/// [ListTile] rows - structurally the Flutter settings-page template, which
/// is why no amount of palette work made it read as a designed plant app.
/// It is now built from the app's own primitives, and reorganised around
/// what the screen is actually *for*: a single dominant "today" panel, a
/// glanceable collection summary, then quieter navigation beneath.
class SpacesScreen extends StatefulWidget {
  /// Switches the shell to the Care tab - used by the to-do panel, since the
  /// tasks themselves live on Care.
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
  int _completedToday = 0;

  /// Nothing renders as "empty" until the first load resolves, so switching
  /// to this tab never flashes "no spaces yet" at a user who has plenty.
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    refresh();
  }

  /// Reloads everything - called by MainShell after a plant is added via the
  /// global camera button, since IndexedStack keeps this tab's state alive
  /// rather than rebuilding it on return.
  Future<void> refresh() async {
    await Future.wait([_loadHub(), _loadSideCounts()]);
  }

  /// Spaces, plants, per-Space counts and the to-do list, from one snapshot.
  ///
  /// These were four independent loads that between them refetched the plant
  /// list twice and issued an aggregate count per Space. They are now one
  /// two-query snapshot with the counts derived locally - so the numbers can
  /// never disagree with each other mid-refresh.
  Future<void> _loadHub() async {
    try {
      final snapshot = await _repository.getHubSnapshot();
      final due =
          snapshot.plants.where((p) {
              final d = mostUrgentDueIn(p);
              return d != null && d <= 0;
            }).toList()
            ..sort(
              (a, b) =>
                  (mostUrgentDueIn(a) ?? 0).compareTo(mostUrgentDueIn(b) ?? 0),
            );

      if (!mounted) return;
      setState(() {
        _spaces = snapshot.spaces;
        _plantCounts = snapshot.counts;
        _dueToday = due;
        _loaded = true;
        _error = null;
      });
    } catch (e) {
      debugPrint('Failed to load hub: $e');
      if (!mounted) return;
      // Only surface the failure if there is nothing already on screen -
      // a background refresh that fails should not blank out good content.
      setState(() {
        _loaded = true;
        if (_spaces.isEmpty && _dueToday.isEmpty) _error = '$e';
      });
    }
  }

  /// Counts that are nice to have but must never block or break the hub.
  Future<void> _loadSideCounts() async {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);

    final results = await Future.wait([
      PropagationRepository().getPropagationCount().catchError((_) => 0),
      WishlistRepository().getWishlist().catchError(
        (_) => <WishlistItem>[],
      ),
      _repository.getCareEventCountSince(startOfToday).catchError((_) => 0),
    ]);

    if (!mounted) return;
    setState(() {
      _propagationCount = results[0] as int;
      _wishlist = results[1] as List<WishlistItem>;
      _completedToday = results[2] as int;
    });
  }

  int get _totalPlants =>
      _plantCounts.values.fold(0, (sum, count) => sum + count);

  // --- Navigation -----------------------------------------------------------

  Future<void> _navigateToSpace(Garden space) async {
    await Navigator.push(context, appRoute(MyPlantsScreen(garden: space)));
    if (mounted) refresh();
  }

  Future<void> _navigateToAllPlants() async {
    await Navigator.push(context, appRoute(const MyPlantsScreen()));
    if (mounted) refresh();
  }

  Future<void> _navigateToPropagations() async {
    await Navigator.push(context, appRoute(const PropagationsScreen()));
    if (mounted) refresh();
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
    if (mounted) _loadSideCounts();
  }

  // --- Mutations ------------------------------------------------------------

  Future<void> _markWatered(Plant plant) async {
    // Drop it from the to-do list immediately and bump the done counter, so
    // the tap feels instant rather than waiting on a network round trip.
    setState(() {
      _dueToday.removeWhere((p) => p.id == plant.id);
      _completedToday++;
    });
    try {
      await _repository.markCare(plant.id!, CareKind.water);
      await NotificationService().scheduleWateringReminder(
        CareKind.water.withPerformed(plant, DateTime.now()),
      );
    } catch (e) {
      if (!mounted) return;
      showAppSnack(context, 'Could not save that. Please try again.',
          error: true);
      refresh();
      return;
    }
    if (mounted) _loadHub();
  }

  Future<void> _createSpace() async {
    final name = await showAppPrompt(
      context,
      title: 'New Space',
      hintText: 'e.g. Living Room',
      confirmLabel: 'Create',
    );
    if (name == null) return;
    await _repository.insertGarden(Garden(name: name));
    await _loadHub();
  }

  Future<void> _editSpace(Garden space) async {
    final name = await showAppPrompt(
      context,
      title: 'Rename Space',
      hintText: 'e.g. Living Room',
      initialValue: space.name,
    );
    if (name == null || name == space.name) return;
    await _repository.updateGarden(Garden(id: space.id, name: name));
    await _loadHub();
  }

  Future<void> _deleteSpace(Garden space) async {
    final count = _plantCounts[space.id] ?? 0;
    final confirmed = await showAppConfirm(
      context,
      title: 'Delete Space?',
      message:
          count > 0
              ? 'Its $count plant${count == 1 ? '' : 's'} will move to '
                  '${PlantRepository.defaultGardenName} instead of being deleted.'
              : 'This deletes "${space.name}".',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    // Optimistically hide, then commit after a fixed window - decoupled from
    // the snackbar's close future (which could leave the snackbar stuck and
    // the delete never committing). Undo restores immediately.
    setState(() => _spaces.removeWhere((s) => s.id == space.id));

    var undone = false;
    showAppSnack(
      context,
      '${space.name} deleted',
      onUndo: () {
        undone = true;
        if (mounted) _loadHub();
      },
    );

    await Future.delayed(const Duration(seconds: 4, milliseconds: 250));
    if (undone) return;

    await _repository.deleteGarden(space.id!);
    if (mounted) _loadHub();
  }

  Future<void> _spaceMenu(Garden space) async {
    final isDefault = space.name == PlantRepository.defaultGardenName;
    final action = await showAppMenu<String>(
      context,
      title: space.name,
      options: [
        const AppMenuOption(
          label: 'Rename',
          icon: Icons.edit_outlined,
          value: 'edit',
        ),
        if (!isDefault)
          const AppMenuOption(
            label: 'Delete Space',
            icon: Icons.delete_outline,
            value: 'delete',
            destructive: true,
          ),
      ],
    );
    if (action == 'edit') await _editSpace(space);
    if (action == 'delete') await _deleteSpace(space);
  }

  // --- Sections -------------------------------------------------------------

  /// The dominant panel: what needs care right now.
  ///
  /// Kept deliberately large and editorial. This is the one thing a user
  /// opens the app to find out, so it gets the serif headline, the full
  /// width, and the only saturated surface on the screen.
  Widget _todayPanel() {
    final p = context.palette;
    final has = _dueToday.isNotEmpty;
    final total = _dueToday.length + _completedToday;

    return AppCard(
      color: has ? p.coralSoft : p.card,
      radius: AppRadius.xl,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      margin: const EdgeInsets.fromLTRB(Gap.screen, 6, Gap.screen, 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TODAY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: has ? p.coral : p.inkFaint,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      has
                          ? '${_dueToday.length} plant${_dueToday.length == 1 ? '' : 's'} '
                              'need${_dueToday.length == 1 ? 's' : ''} care'
                          : 'All caught up',
                      style: AppTheme.plantNameStyle(context, size: 25),
                    ),
                    if (!has) ...[
                      const SizedBox(height: 5),
                      Text(
                        _completedToday > 0
                            ? '$_completedToday task${_completedToday == 1 ? '' : 's'} done today. Nice work.'
                            : 'Nothing needs care right now.',
                        style: TextStyle(fontSize: 13.5, color: p.inkSoft),
                      ),
                    ],
                  ],
                ),
              ),
              if (total > 0) ...[
                Gap.md,
                _ProgressDial(
                  done: _completedToday,
                  total: total,
                  color: has ? p.coral : p.mintRing,
                ),
              ] else
                Icon(Icons.spa_outlined, size: 34, color: p.mintRing),
            ],
          ),
          if (has) ...[
            Gap.md,
            for (final plant in _dueToday.take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  flat: true,
                  radius: AppRadius.md,
                  padding: EdgeInsets.zero,
                  child: AppRow(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    leading: PlantThumbnail(
                      plant: plant,
                      size: 42,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    title: plant.name,
                    serifTitle: true,
                    subtitle: _dueLabel(plant),
                    subtitleUrgent: true,
                    onTap: () => _navigateToPlant(plant),
                    trailing: CircleAction(
                      icon: Icons.water_drop_rounded,
                      color: p.coral,
                      filled: true,
                      size: 36,
                      tooltip: 'Water now',
                      onTap: () => _markWatered(plant),
                    ),
                  ),
                ),
              ),
            if (_dueToday.length > 4)
              Padding(
                padding: const EdgeInsets.only(top: 2, bottom: 4),
                child: Text(
                  '+ ${_dueToday.length - 4} more',
                  style: TextStyle(fontSize: 12.5, color: p.inkSoft),
                ),
              ),
            Center(
              child: TextButton(
                onPressed: widget.onGoToCare,
                child: Text(
                  'View all in Care',
                  style: TextStyle(color: p.coral, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _dueLabel(Plant plant) {
    final due = mostUrgentDueIn(plant) ?? 0;
    if (due < 0) return 'Overdue by ${-due} ${-due == 1 ? 'day' : 'days'}';
    return 'Due today';
  }

  /// Three big numbers. The hierarchy contrast a modern layout needs - a
  /// large figure against a tiny uppercase label - and a fast way into the
  /// three collections underneath.
  Widget _statStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 28),
      child: Row(
        children: [
          Expanded(
            child: _StatTile(
              value: _totalPlants,
              label: 'PLANTS',
              onTap: _navigateToAllPlants,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              value: _spaces.length,
              label: 'SPACES',
              onTap: null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatTile(
              value: _propagationCount,
              label: 'PROJECTS',
              onTap: _navigateToPropagations,
            ),
          ),
        ],
      ),
    );
  }

  Widget _spacesSection() {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            'Spaces',
            action: SectionAction(label: 'New', onPressed: _createSpace),
          ),
          if (_spaces.isEmpty)
            AppCard(
              bordered: true,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Text(
                'Create a Space for each area of your home — Living Room, '
                'Backyard, Office — to organise your plants.',
                style: TextStyle(fontSize: 13.5, height: 1.5, color: p.inkSoft),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _spaces.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 62,
                        color: p.hairline,
                      ),
                    _spaceRow(_spaces[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _spaceRow(Garden space) {
    final p = context.palette;
    final count = _plantCounts[space.id] ?? 0;

    return AppRow(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      leading: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: p.fernSoft,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Icon(Icons.grid_view_rounded, size: 17, color: p.fern),
      ),
      title: space.name,
      subtitle: '$count plant${count == 1 ? '' : 's'}',
      onTap: () => _navigateToSpace(space),
      trailing: CircleAction(
        icon: Icons.more_horiz_rounded,
        color: p.inkFaint,
        size: 32,
        tooltip: 'Space options',
        onTap: () => _spaceMenu(space),
      ),
    );
  }

  Widget _wishlistSection() {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            _wishlist.isEmpty ? 'Wishlist' : 'Wishlist · ${_wishlist.length}',
          ),
          if (_wishlist.isEmpty)
            AppCard(
              bordered: true,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Text(
                'Save plants you want from a species page (tap the ♥) and '
                "they'll show up here for later.",
                style: TextStyle(fontSize: 13.5, height: 1.5, color: p.inkSoft),
              ),
            )
          else
            AppCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < _wishlist.length; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 1,
                        indent: 62,
                        color: p.hairline,
                      ),
                    _wishlistRow(_wishlist[i]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _wishlistRow(WishlistItem item) {
    final p = context.palette;
    final hasImage = item.imageUrl != null && item.imageUrl!.isNotEmpty;

    return AppRow(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: SizedBox(
          width: 34,
          height: 34,
          child:
              hasImage
                  ? Image.network(
                    item.imageUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: 120,
                    errorBuilder:
                        (_, __, ___) => _wishlistFallbackIcon(p.fernSoft, p.fern),
                  )
                  : _wishlistFallbackIcon(p.fernSoft, p.fern),
        ),
      ),
      title: item.commonName ?? item.scientificName,
      subtitle: item.scientificName,
      subtitleItalic: true,
      chevron: true,
      onTap: () => _navigateToWishlistItem(item),
    );
  }

  Widget _wishlistFallbackIcon(Color background, Color foreground) {
    return ColoredBox(
      color: background,
      child: Icon(Icons.local_florist_outlined, size: 17, color: foreground),
    );
  }

  Widget _projectsSection() {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SectionHeader('Projects'),
          AppCard(
            padding: EdgeInsets.zero,
            child: AppRow(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              leading: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.fernSoft,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.eco_outlined, size: 17, color: p.fern),
              ),
              title: 'Propagations',
              subtitle:
                  _propagationCount == 0
                      ? 'Start a cutting and track it here'
                      : '$_propagationCount in progress',
              chevron: true,
              onTap: _navigateToPropagations,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(
        title: 'Spaces',
        actions: [WeatherAppBarChip(), AccountButton()],
      ),
      body: RefreshIndicator.adaptive(
        onRefresh: refresh,
        child:
            !_loaded
                ? const SpacesSkeleton()
                : _error != null
                ? AppErrorView(
                  message:
                      'Your plants could not be loaded. Check your connection '
                      'and try again.',
                  onRetry: refresh,
                )
                : ListView(
                  padding: const EdgeInsets.only(top: 6, bottom: 28),
                  children: [
                    AnimatedEntrance(index: 0, child: _todayPanel()),
                    AnimatedEntrance(index: 1, child: _statStrip()),
                    AnimatedEntrance(index: 2, child: _spacesSection()),
                    AnimatedEntrance(index: 3, child: _projectsSection()),
                    AnimatedEntrance(index: 4, child: _wishlistSection()),
                  ],
                ),
      ),
    );
  }
}

/// A big number over a small uppercase label. The type-scale jump between the
/// two is doing the design work here - it is what separates a considered
/// layout from one where everything is the same medium size.
class _StatTile extends StatelessWidget {
  final int value;
  final String label;
  final VoidCallback? onTap;

  const _StatTile({required this.value, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      child: Column(
        children: [
          Text(
            '$value',
            style: AppTheme.plantNameStyle(context, size: 26),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.9,
              color: p.inkFaint,
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact ring showing how much of today's care is done. Gives the panel
/// a sense of progress rather than only a count of what is left.
class _ProgressDial extends StatelessWidget {
  final int done;
  final int total;
  final Color color;

  const _ProgressDial({
    required this.done,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final fraction = total == 0 ? 0.0 : (done / total).clamp(0.0, 1.0);

    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.expand(
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: fraction),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
              builder:
                  (context, value, _) => CircularProgressIndicator(
                    value: value,
                    strokeWidth: 4,
                    strokeCap: StrokeCap.round,
                    backgroundColor: color.withValues(alpha: 0.18),
                    valueColor: AlwaysStoppedAnimation(color),
                  ),
            ),
          ),
          Text(
            '$done/$total',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: p.ink,
            ),
          ),
        ],
      ),
    );
  }
}
