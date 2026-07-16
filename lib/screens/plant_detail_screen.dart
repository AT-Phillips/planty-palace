import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/care_log_entry.dart';
import '../models/journal_entry.dart';
import '../models/plant.dart';
import '../models/plant_photo.dart';
// import '../services/home_widget_service.dart'; // widget disabled for now
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/care_kind.dart';
import '../utils/haptics.dart';
import '../utils/permanent_image.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/care_action_sheet.dart';
import '../widgets/care_ring_tile.dart';
import '../widgets/pulse_glow.dart';
import '../widgets/plant_thumbnail.dart';
import 'add_edit_plant_screen.dart';
import '../utils/app_page_route.dart';

IconData _careIconFor(String type) {
  switch (type) {
    case 'fertilizing':
      return Icons.eco_outlined;
    case 'repotting':
      return Icons.yard_outlined;
    case 'pruning':
      return Icons.content_cut;
    default:
      return Icons.water_drop_outlined;
  }
}

String _careLabelFor(String type) {
  switch (type) {
    case 'fertilizing':
      return 'Fertilized';
    case 'repotting':
      return 'Repotted';
    case 'pruning':
      return 'Pruned';
    default:
      return 'Watered';
  }
}

class PlantDetailScreen extends StatefulWidget {
  final Plant plant;

  const PlantDetailScreen({super.key, required this.plant});

  @override
  State<PlantDetailScreen> createState() => _PlantDetailScreenState();
}

class _PlantDetailScreenState extends State<PlantDetailScreen> {
  final PlantRepository _repository = PlantRepository();
  late Plant _plant;
  List<PlantPhoto> _timeline = [];
  List<CareLogEntry> _careHistory = [];
  List<JournalEntry> _journal = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _plant = widget.plant;
    _load();
  }

  Future<void> _load() async {
    try {
      final timeline = await _repository.getPhotos(_plant.id!);
      final history = await _repository.getCareHistory(_plant.id!);
      final journal = await _repository.getJournalEntries(_plant.id!);
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _careHistory = history;
        _journal = journal;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load plant detail: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markWatered() async {
    await _repository.markWatered(_plant.id!);
    final updated = _plant.copyWith(
      lastWatered: DateTime.now().toIso8601String(),
    );
    await NotificationService().scheduleWateringReminder(updated);
    // HomeWidgetService().refresh(); // widget disabled for now
    if (!mounted) return;
    setState(() => _plant = updated);
    _load();
  }

  Future<void> _markFertilized() async {
    await _repository.markFertilized(_plant.id!);
    final updated = _plant.copyWith(
      lastFertilized: DateTime.now().toIso8601String(),
    );
    await NotificationService().scheduleFertilizingReminder(updated);
    // HomeWidgetService().refresh(); // widget disabled for now
    if (!mounted) return;
    setState(() => _plant = updated);
    _load();
  }

  Future<void> _markRepotted() async {
    await _repository.markRepotted(_plant.id!);
    final updated = _plant.copyWith(
      lastRepotted: DateTime.now().toIso8601String(),
    );
    await NotificationService().scheduleRepottingReminder(updated);
    if (!mounted) return;
    setState(() => _plant = updated);
    _load();
  }

  Future<void> _markPruned() async {
    await _repository.markPruned(_plant.id!);
    final updated = _plant.copyWith(
      lastPruned: DateTime.now().toIso8601String(),
    );
    await NotificationService().schedulePruningReminder(updated);
    if (!mounted) return;
    setState(() => _plant = updated);
    _load();
  }

  /// Dispatches to the right mark-* method for a [CareKind] and shows a brief
  /// confirmation. The underlying methods already persist, reschedule the
  /// reminder, and refresh state.
  Future<void> _logCareForKind(CareKind kind) async {
    switch (kind) {
      case CareKind.water:
        await _markWatered();
        break;
      case CareKind.feed:
        await _markFertilized();
        break;
      case CareKind.repot:
        await _markRepotted();
        break;
      case CareKind.prune:
        await _markPruned();
        break;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text('${_plant.name} ${kind.pastTense.toLowerCase()}'),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  /// Opens the slide-to-confirm care sheet for [kind]; logs the action or
  /// jumps to the schedule editor based on the user's choice.
  Future<void> _openCareSheet(CareKind kind) async {
    final result = await showCareActionSheet(
      context,
      plant: _plant,
      kind: kind,
    );
    if (!mounted || result == null) return;
    if (result == CareSheetResult.editSchedule) {
      await _editPlant();
    } else {
      await _logCareForKind(kind);
    }
  }

  /// The prominent one-tap watering action - a fast path for the most
  /// frequent care task, with a haptic + snackbar so it never reads as a
  /// silent tap (the deliberate slide-to-confirm path lives in the sheet).
  Future<void> _quickWater() async {
    Haptics.medium();
    await _logCareForKind(CareKind.water);
  }

  Future<void> _addJournalEntry() async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add journal entry'),
            content: TextField(
              controller: controller,
              autofocus: true,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'What did you notice?',
              ),
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
    if (text == null || text.isEmpty) return;

    final entry = await _repository.addJournalEntry(_plant.id!, text);
    if (!mounted) return;
    setState(() => _journal = [entry, ..._journal]);
  }

  Future<void> _deleteJournalEntry(JournalEntry entry) async {
    await _repository.deleteJournalEntry(_plant.id!, entry.id);
    if (!mounted) return;
    setState(() => _journal = _journal.where((e) => e.id != entry.id).toList());
  }

  Future<void> _editPlant() async {
    final result = await Navigator.push(
      context,
      appRoute(AddEditPlantScreen(plant: _plant, gardenId: _plant.gardenId!)),
    );
    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePlant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete plant?'),
            content: Text(
              'This will remove ${_plant.name} and all of its photos and history.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );
    if (confirmed != true) return;

    await _repository.deletePlant(_plant.id!);
    await NotificationService().cancelReminder(_plant.id!);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _addTimelinePhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final permanentImage = await ensurePermanentPlantImage(File(picked.path));
    final photo = await _repository.addPhoto(_plant.id!, permanentImage);
    if (!mounted) return;
    setState(() {
      _timeline = [photo, ..._timeline];
      _plant = _plant.copyWith(
        photoUrl: photo.photoUrl,
        imagePath: permanentImage.path,
      );
    });
  }

  Future<void> _showAddPhotoOptions() async {
    final source = await showAppActionSheet<ImageSource>(
      context,
      title: 'Add a growth photo',
      actions: const [
        AppSheetAction(
          icon: Icons.camera_alt_outlined,
          label: 'Camera',
          value: ImageSource.camera,
        ),
        AppSheetAction(
          icon: Icons.photo_library_outlined,
          label: 'Gallery',
          value: ImageSource.gallery,
        ),
      ],
    );
    if (source != null) await _addTimelinePhoto(source);
  }

  Future<void> _openPhotoOptions(PlantPhoto photo) async {
    final isCover = photo.photoUrl == _plant.photoUrl;
    final action = await showAppActionSheet<String>(
      context,
      actions: [
        if (!isCover)
          const AppSheetAction(
            icon: Icons.check_circle_outline,
            label: 'Set as cover photo',
            value: 'cover',
          ),
        const AppSheetAction(
          icon: Icons.delete_outline,
          label: 'Delete photo',
          value: 'delete',
          destructive: true,
        ),
      ],
    );

    if (action == 'cover') {
      await _repository.setCoverPhoto(_plant.id!, photo);
      if (!mounted) return;
      setState(
        () => _plant = _plant.copyWith(photoUrl: photo.photoUrl, imagePath: ''),
      );
    } else if (action == 'delete') {
      await _repository.deletePhoto(_plant.id!, photo);
      if (!mounted) return;
      setState(() {
        _timeline = _timeline.where((p) => p.id != photo.id).toList();
        if (photo.photoUrl == _plant.photoUrl) {
          final newCover = _timeline.isEmpty ? null : _timeline.first;
          _plant = _plant.copyWith(photoUrl: newCover?.photoUrl, imagePath: '');
        }
      });
    }
  }

  /// Species reference facts sourced from Perenual at add-time (see
  /// PerenualService.lookupCareInfo / AddEditPlantScreen) - distinct from
  /// the user's own "Care Info" notes above. Nullable-safe throughout: only
  /// ever shows a fact Perenual actually returned for this species, and the
  /// whole section is omitted if none of them are present (e.g. plants
  /// added before this existed, or species Perenual has no data for).
  List<Widget> _buildSpeciesFactsSection(ColorScheme scheme) {
    final hasToxicityInfo =
        _plant.poisonousToHumans != null || _plant.poisonousToPets != null;
    final isToxic =
        _plant.poisonousToHumans == true || _plant.poisonousToPets == true;
    final hasAnyFact =
        _plant.speciesDescription != null ||
        _plant.speciesFamily != null ||
        _plant.speciesOrigin != null ||
        hasToxicityInfo;

    if (!hasAnyFact) return const [];

    return [
      const SizedBox(height: 20),
      Text(
        'About This Species',
        style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary),
      ),
      const SizedBox(height: 8),
      if (_plant.speciesDescription != null) ...[
        Text(_plant.speciesDescription!),
        const SizedBox(height: 8),
      ],
      if (_plant.speciesFamily != null)
        Text(
          'Family: ${_plant.speciesFamily}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      if (_plant.speciesOrigin != null)
        Text(
          'Origin: ${_plant.speciesOrigin}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      if (hasToxicityInfo) ...[
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
              isToxic
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
              size: 18,
              color: isToxic ? scheme.error : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                isToxic
                    ? 'May be toxic${_plant.poisonousToPets == true ? ' to pets' : ''}'
                        '${_plant.poisonousToHumans == true && _plant.poisonousToPets == true ? ' and' : ''}'
                        '${_plant.poisonousToHumans == true ? ' humans' : ''} if ingested'
                    : 'Not known to be toxic to humans or pets',
                style: TextStyle(
                  color: isToxic ? scheme.error : scheme.onSurfaceVariant,
                  fontWeight: isToxic ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ],
    ];
  }

  /// Days-ago label for a nullable ISO timestamp, matching the compact
  /// style used elsewhere (e.g. the Journal feed) - null if unparseable.
  String? _daysAgoLabel(String? iso) {
    if (iso == null) return null;
    final date = DateTime.tryParse(iso);
    if (date == null) return null;
    final days = DateTime.now().difference(date).inDays;
    if (days <= 0) return 'Today';
    return '${days}d ago';
  }

  static const _monthAbbr = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// A compact, friendly local timestamp like "Jul 10 · 2:03 PM" - replaces
  /// the raw `DateTime.toString()` the care history and journal used to show.
  String _friendlyDateTime(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    final hour12 = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final minute = d.minute.toString().padLeft(2, '0');
    final ampm = d.hour < 12 ? 'AM' : 'PM';
    return '${_monthAbbr[d.month - 1]} ${d.day} · $hour12:$minute $ampm';
  }

  /// The plant's scheduled care kinds, in a stable display order.
  List<CareKind> get _scheduledKinds =>
      CareKind.values.where((k) => k.isScheduled(_plant)).toList();

  /// A 2-column grid of care ring tiles, one per scheduled kind.
  Widget _careGrid() {
    final kinds = _scheduledKinds;
    final rows = <Widget>[];
    for (var i = 0; i < kinds.length; i += 2) {
      final left = kinds[i];
      final right = i + 1 < kinds.length ? kinds[i + 1] : null;
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CareRingTile(
                kind: left,
                plant: _plant,
                index: i,
                onTap: () => _openCareSheet(left),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child:
                  right == null
                      ? const SizedBox()
                      : CareRingTile(
                        kind: right,
                        plant: _plant,
                        index: i + 1,
                        onTap: () => _openCareSheet(right),
                      ),
            ),
          ],
        ),
      );
      if (i + 2 < kinds.length) rows.add(const SizedBox(height: 10));
    }
    return Column(children: rows);
  }

  /// Compact "About this plant" stat row - Water interval, last watered,
  /// species family, and toxicity, each only shown when the underlying
  /// field actually has data (never a fabricated placeholder). Returns an
  /// empty widget if none of the four have anything to show.
  Widget _buildStatRow(ColorScheme scheme) {
    final lastWatered = _daysAgoLabel(_plant.lastWatered);
    final hasToxicityInfo =
        _plant.poisonousToHumans != null || _plant.poisonousToPets != null;
    final isToxic =
        _plant.poisonousToHumans == true || _plant.poisonousToPets == true;

    final stats = <Widget>[
      if (_plant.wateringIntervalDays != null)
        _StatItem(
          label: 'Water',
          value: 'Every ${_plant.wateringIntervalDays}d',
        ),
      if (lastWatered != null) _StatItem(label: 'Last', value: lastWatered),
      if (_plant.speciesFamily != null)
        _StatItem(label: 'Family', value: _plant.speciesFamily!),
      if (hasToxicityInfo)
        _StatItem(
          label: 'Pets',
          value: isToxic ? 'Toxic' : 'Safe',
          color: isToxic ? scheme.error : null,
        ),
    ];
    if (stats.isEmpty) return const SizedBox.shrink();

    return Row(children: [for (final stat in stats) Expanded(child: stat)]);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final waterOverdue = CareKind.water.overdue(_plant);

    final topInset = MediaQuery.of(context).padding.top;

    return Scaffold(
      body:
          _loading
              ? const Center(child: CircularProgressIndicator.adaptive())
              : Stack(
                children: [
                  ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Immersive full-bleed hero (runs under the status bar)
                      // with a bottom scrim so the overlapping sheet and the
                      // floating controls stay legible over any photo.
                      SizedBox(
                        height: 300,
                        width: double.infinity,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            PlantThumbnail(
                              plant: _plant,
                              size: double.infinity,
                              borderRadius: BorderRadius.zero,
                              heroTag: 'plant_${_plant.id}',
                            ),
                            const DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black26],
                                  stops: [0.6, 1.0],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Overlapping rounded sheet with a grab handle - the
                      // signature "content sheet rises over the photo" look.
                      Transform.translate(
                        offset: const Offset(0, -26),
                        child: Container(
                          decoration: BoxDecoration(
                            color: scheme.surface,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(26),
                            ),
                          ),
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Container(
                                  width: 34,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: scheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _plant.name,
                                style: AppTheme.plantNameStyle(context, size: 24),
                              ),
                        const SizedBox(height: 2),
                        Text(
                          _plant.species,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildStatRow(scheme),
                        if (_scheduledKinds.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Care',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _careGrid(),
                          if (_plant.wateringIntervalDays != null) ...[
                            const SizedBox(height: 12),
                            PulseGlow(
                              active: waterOverdue,
                              color: AppTheme.careOverdue(context),
                              borderRadius: BorderRadius.circular(16),
                              child: SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: _quickWater,
                                  icon: const Icon(Icons.water_drop),
                                  label: Text(
                                    waterOverdue
                                        ? 'Water now'
                                        : 'Mark as watered',
                                  ),
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    backgroundColor:
                                        waterOverdue
                                            ? AppTheme.careOverdue(context)
                                            : AppTheme.fernColor(context),
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                        if (_plant.careInstructions.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          Text(
                            'Care Info',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_plant.careInstructions),
                        ],
                        ..._buildSpeciesFactsSection(scheme),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Growth Photos',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _showAddPhotoOptions,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        if (_timeline.isEmpty)
                          Text(
                            'No growth photos yet.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          )
                        else
                          SizedBox(
                            height: 90,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: _timeline.length,
                              separatorBuilder:
                                  (_, __) => const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final photo = _timeline[index];
                                final isCover =
                                    photo.photoUrl == _plant.photoUrl;
                                return GestureDetector(
                                  onTap: () => _openPhotoOptions(photo),
                                  child: Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          photo.photoUrl,
                                          width: 80,
                                          height: 80,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (_, __, ___) => Container(
                                                width: 80,
                                                height: 80,
                                                color:
                                                    scheme
                                                        .surfaceContainerHighest,
                                                child: const Icon(
                                                  Icons.broken_image,
                                                ),
                                              ),
                                        ),
                                      ),
                                      if (isCover)
                                        Positioned(
                                          top: 4,
                                          right: 4,
                                          child: Icon(
                                            Icons.star,
                                            size: 18,
                                            color: scheme.primary,
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        const SizedBox(height: 20),
                        Text(
                          'Care History',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (_careHistory.isEmpty)
                          Text(
                            'No care history yet.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          )
                        else
                          for (final entry in _careHistory)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              child: Row(
                                children: [
                                  Icon(
                                    _careIconFor(entry.type),
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_careLabelFor(entry.type)} · ${_friendlyDateTime(entry.timestamp)}',
                                  ),
                                ],
                              ),
                            ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Journal',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: scheme.primary,
                              ),
                            ),
                            TextButton.icon(
                              onPressed: _addJournalEntry,
                              icon: const Icon(Icons.add),
                              label: const Text('Add'),
                            ),
                          ],
                        ),
                        if (_journal.isEmpty)
                          Text(
                            'No journal entries yet.',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          )
                        else
                          for (final entry in _journal)
                            Dismissible(
                              key: ValueKey(entry.id),
                              direction: DismissDirection.endToStart,
                              onDismissed: (_) => _deleteJournalEntry(entry),
                              background: Container(
                                color: scheme.errorContainer,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                ),
                                child: Icon(
                                  Icons.delete,
                                  color: scheme.onErrorContainer,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _friendlyDateTime(entry.createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(entry.text),
                                  ],
                                ),
                              ),
                            ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                    top: topInset + 6,
                    left: 8,
                    child: _CircleIconButton(
                      icon: Icons.arrow_back_ios_new,
                      onPressed: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                  Positioned(
                    top: topInset + 6,
                    right: 8,
                    child: Row(
                      children: [
                        _CircleIconButton(
                          icon: Icons.edit_outlined,
                          onPressed: _editPlant,
                        ),
                        const SizedBox(width: 8),
                        _CircleIconButton(
                          icon: Icons.delete_outline,
                          onPressed: _deletePlant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
    );
  }
}

/// A translucent, circular icon button that floats over the immersive hero
/// photo (back, edit, delete) - blurred glass so it stays legible on any image.
class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _CircleIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.28),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}

/// One cell of the plant-detail stat row - a small label over a value,
/// evenly distributed across the row by the caller's [Expanded].
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _StatItem({required this.label, required this.value, this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: color ?? scheme.onSurface,
          ),
        ),
      ],
    );
  }
}
