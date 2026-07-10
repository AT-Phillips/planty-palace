import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/perenual_service.dart';
import '../services/plant_identifier_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/care_kind.dart';
import '../utils/haptics.dart';
import '../utils/permanent_image.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/inset_group.dart';

const _wateringIntervalOptions = [3, 7, 10, 14, 21, 30];
const _fertilizingIntervalOptions = [14, 30, 60, 90];
const _repottingIntervalOptions = [180, 365, 730];
const _pruningIntervalOptions = [30, 60, 90, 180];

class AddEditPlantScreen extends StatefulWidget {
  final Plant? plant;
  final String gardenId;

  /// Pre-fills species/care info without requiring a camera ID pass first -
  /// used when adding a plant found via Discover's catalog search, or
  /// promoting a Propagation.
  final String? prefillSpecies;
  final String? prefillCareInstructions;
  final int? prefillWateringIntervalDays;
  final String? prefillImagePath;

  const AddEditPlantScreen({
    super.key,
    this.plant,
    required this.gardenId,
    this.prefillSpecies,
    this.prefillCareInstructions,
    this.prefillWateringIntervalDays,
    this.prefillImagePath,
  });

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final PlantIdentifierService _identifierService = PlantIdentifierService();
  final PerenualService _careService = PerenualService();
  final PlantRepository _repository = PlantRepository();
  bool isLoading = false;
  bool isSaving = false;
  bool isFetchingCareInfo = false;
  bool wateringManuallySet = false;
  bool careInstructionsManuallySet = false;
  List<PlantSuggestion> suggestions = [];
  String? selectedName;
  String? selectedCommonName;
  int wateringIntervalDays = 7;
  int? fertilizingIntervalDays;
  int? repottingIntervalDays;
  int? pruningIntervalDays;

  // Species reference facts from Perenual, carried through to the saved
  // Plant - see PerenualService.lookupCareInfo. Null until (if) a lookup
  // resolves with data; never overwritten with placeholder text.
  String? speciesDescription;
  String? speciesOrigin;
  String? speciesFamily;
  String? speciesImageUrl;
  bool? poisonousToHumans;
  bool? poisonousToPets;
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController careInstructionsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.plant != null) {
      final plant = widget.plant!;
      selectedName = plant.species;
      nicknameController.text = plant.name;
      wateringIntervalDays = plant.wateringIntervalDays ?? 7;
      fertilizingIntervalDays = plant.fertilizingIntervalDays;
      repottingIntervalDays = plant.repottingIntervalDays;
      pruningIntervalDays = plant.pruningIntervalDays;
      careInstructionsController.text = plant.careInstructions;
      speciesDescription = plant.speciesDescription;
      speciesOrigin = plant.speciesOrigin;
      speciesFamily = plant.speciesFamily;
      speciesImageUrl = plant.speciesImageUrl;
      poisonousToHumans = plant.poisonousToHumans;
      poisonousToPets = plant.poisonousToPets;
      if (plant.imagePath.isNotEmpty) {
        _identifierService.imageFile = File(plant.imagePath);
      }
    } else if (widget.prefillSpecies != null) {
      selectedName = widget.prefillSpecies;
      if (widget.prefillCareInstructions != null) {
        careInstructionsController.text = widget.prefillCareInstructions!;
      }
      if (widget.prefillWateringIntervalDays != null) {
        wateringIntervalDays = widget.prefillWateringIntervalDays!;
        wateringManuallySet = true;
      }
      if (widget.prefillImagePath != null &&
          widget.prefillImagePath!.isNotEmpty) {
        _identifierService.imageFile = File(widget.prefillImagePath!);
      }
    }

    careInstructionsController.addListener(() {
      careInstructionsManuallySet = true;
    });
  }

  @override
  void dispose() {
    nicknameController.dispose();
    careInstructionsController.dispose();
    super.dispose();
  }

  Future<void> _lookupCareInfo(String species) async {
    setState(() => isFetchingCareInfo = true);

    final info = await _careService.lookupCareInfo(species);

    if (!mounted) return;
    setState(() {
      isFetchingCareInfo = false;
      if (info != null) {
        if (!careInstructionsManuallySet) {
          careInstructionsController.text = info.careInstructions;
          // Setting .text above triggers the listener; undo the
          // manually-set flag since this was an automatic fill-in.
          careInstructionsManuallySet = false;
        }
        if (!wateringManuallySet && info.wateringIntervalDays != null) {
          wateringIntervalDays = info.wateringIntervalDays!;
        }
        speciesDescription = info.description;
        speciesOrigin = info.origin;
        speciesFamily = info.family;
        speciesImageUrl = info.imageUrl;
        poisonousToHumans = info.poisonousToHumans;
        poisonousToPets = info.poisonousToPets;
      }
    });
  }

  Future<void> _handleCamera() async {
    await _identifierService.pickImageFromCamera();
    if (!mounted) return;
    setState(() {
      selectedName = null;
      suggestions = [];
    });
  }

  Future<void> _handleGallery() async {
    await _identifierService.pickImageFromGallery();
    if (!mounted) return;
    setState(() {
      selectedName = null;
      suggestions = [];
    });
  }

  Future<void> _handleRemovePhoto() async {
    await _identifierService.clearImage();
    if (!mounted) return;
    setState(() {
      selectedName = null;
      suggestions = [];
    });
  }

  /// Single tap-target for the photo: an action sheet to take, choose, or
  /// remove the plant photo (replacing the two always-on tonal buttons).
  Future<void> _changePhoto() async {
    final hasPhoto = _identifierService.imageFile != null;
    final action = await showAppActionSheet<String>(
      context,
      title: 'Plant photo',
      message: 'Used to identify the plant and as its cover photo.',
      actions: [
        const AppSheetAction(
          icon: Icons.camera_alt_outlined,
          label: 'Take Photo',
          value: 'camera',
        ),
        const AppSheetAction(
          icon: Icons.photo_library_outlined,
          label: 'Choose from Library',
          value: 'gallery',
        ),
        if (hasPhoto)
          const AppSheetAction(
            icon: Icons.delete_outline,
            label: 'Remove Photo',
            value: 'remove',
            destructive: true,
          ),
      ],
    );
    switch (action) {
      case 'camera':
        await _handleCamera();
        break;
      case 'gallery':
        await _handleGallery();
        break;
      case 'remove':
        await _handleRemovePhoto();
        break;
    }
  }

  void _setOrgan(String organ) {
    setState(() {
      _identifierService.organ = organ;
      selectedName = null;
      suggestions = [];
    });
  }

  Future<void> _identifyPlant() async {
    Haptics.selection();
    setState(() {
      isLoading = true;
      selectedName = null;
      suggestions = [];
    });

    try {
      suggestions = await _identifierService.identifyPlant();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _selectSuggestion(PlantSuggestion suggestion) {
    Haptics.selection();
    setState(() {
      selectedName = suggestion.scientificName;
      selectedCommonName = suggestion.commonName;
    });
    _lookupCareInfo(suggestion.scientificName);
  }

  Future<void> _savePlant() async {
    if (selectedName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a photo and identify your plant first'),
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final pickedImage = _identifierService.imageFile;
      final permanentImage =
          pickedImage == null
              ? null
              : await ensurePermanentPlantImage(pickedImage);
      final nickname = nicknameController.text.trim();

      final plant = Plant(
        id: widget.plant?.id,
        name: nickname.isEmpty ? selectedName! : nickname,
        species: selectedName!,
        imagePath: permanentImage?.path ?? widget.plant?.imagePath ?? '',
        photoUrl: widget.plant?.photoUrl,
        careInstructions: careInstructionsController.text,
        gardenId: widget.plant?.gardenId ?? widget.gardenId,
        createdAt: widget.plant?.createdAt ?? DateTime.now().toIso8601String(),
        lastWatered:
            widget.plant?.lastWatered ?? DateTime.now().toIso8601String(),
        wateringIntervalDays: wateringIntervalDays,
        lastFertilized:
            widget.plant?.lastFertilized ??
            (fertilizingIntervalDays != null
                ? DateTime.now().toIso8601String()
                : null),
        fertilizingIntervalDays: fertilizingIntervalDays,
        lastRepotted:
            widget.plant?.lastRepotted ??
            (repottingIntervalDays != null
                ? DateTime.now().toIso8601String()
                : null),
        repottingIntervalDays: repottingIntervalDays,
        lastPruned:
            widget.plant?.lastPruned ??
            (pruningIntervalDays != null
                ? DateTime.now().toIso8601String()
                : null),
        pruningIntervalDays: pruningIntervalDays,
        speciesDescription: speciesDescription,
        speciesOrigin: speciesOrigin,
        speciesFamily: speciesFamily,
        speciesImageUrl: speciesImageUrl,
        poisonousToHumans: poisonousToHumans,
        poisonousToPets: poisonousToPets,
      );

      Plant savedPlant;
      if (widget.plant == null) {
        final id = await _repository.insertPlant(plant);
        await _repository.logCareEvent(id, plant.lastWatered!);
        savedPlant = plant.copyWith(id: id);
      } else {
        await _repository.updatePlant(plant);
        savedPlant = plant;
      }
      await NotificationService().scheduleWateringReminder(savedPlant);
      await NotificationService().scheduleFertilizingReminder(savedPlant);
      await NotificationService().scheduleRepottingReminder(savedPlant);
      await NotificationService().schedulePruningReminder(savedPlant);

      // A freshly picked photo becomes the first (or newest) growth-timeline
      // entry after the plant document exists (upload is keyed by the doc
      // ID) - a failure here shouldn't block the save, since the plant is
      // already fully usable locally without cross-device photo sync.
      if (permanentImage != null) {
        try {
          await _repository.addPhoto(savedPlant.id!, permanentImage);
        } catch (_) {
          // Photo sync can be retried later; not a blocking failure.
        }
      }

      if (!mounted) return;
      Haptics.medium();
      Navigator.pop(context, savedPlant);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save plant: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  /// Human interval label for a schedule row / picker (e.g. "Every 7 days",
  /// "Every 3 months", "Yearly", or "Off" when unscheduled).
  String _intervalLabel(int? days) {
    if (days == null) return 'Off';
    if (days == 365) return 'Yearly';
    if (days == 730) return 'Every 2 years';
    if (days >= 60 && days % 30 == 0) return 'Every ${days ~/ 30} months';
    return 'Every $days day${days == 1 ? '' : 's'}';
  }

  /// A wheel picker for a schedule interval. Returns a single-element record
  /// holding the chosen value on "Done" (which may be null = "Off" when
  /// [allowNone]), or null if the sheet was dismissed without confirming - so
  /// a legitimate null selection is distinguishable from a cancel.
  Future<(int?,)?> _pickIntervalSheet({
    required String title,
    required List<int> options,
    required int? current,
    required bool allowNone,
  }) {
    final items = <int?>[if (allowNone) null, ...options];
    var startIndex = items.indexOf(current);
    if (startIndex < 0) startIndex = 0;
    var tempIndex = startIndex;

    return showAppSheet<(int?,)>(
      context,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              SizedBox(
                height: 190,
                child: CupertinoPicker(
                  scrollController: FixedExtentScrollController(
                    initialItem: startIndex,
                  ),
                  itemExtent: 38,
                  onSelectedItemChanged: (i) {
                    Haptics.selection();
                    tempIndex = i;
                  },
                  children: [
                    for (final it in items)
                      Center(
                        child: Text(
                          _intervalLabel(it),
                          style: TextStyle(
                            fontSize: 18,
                            color: scheme.onSurface,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed:
                        () => Navigator.of(context).pop((items[tempIndex],)),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.fernColor(context),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Done'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---- section builders ----

  Widget _photoHeader() {
    final scheme = Theme.of(context).colorScheme;
    final file = _identifierService.imageFile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: _changePhoto,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 190,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (file != null)
                  Image.file(file, fit: BoxFit.cover)
                else
                  Container(
                    color: scheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 34,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Add a photo',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                if (file != null)
                  Positioned(
                    left: 12,
                    bottom: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 11,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.autorenew, size: 14, color: Colors.white),
                          SizedBox(width: 5),
                          Text(
                            'Change photo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The identified-species confirmation card, shown once a suggestion is
  /// selected (or when editing/prefilling an existing plant).
  Widget _identifiedCard() {
    final scheme = Theme.of(context).colorScheme;
    final fern = AppTheme.fernColor(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: fern.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(color: fern, shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selectedName!,
                    style: AppTheme.plantNameStyle(context, size: 16),
                  ),
                  if (selectedCommonName != null)
                    Text(
                      selectedCommonName!,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (isFetchingCareInfo)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator.adaptive(strokeWidth: 2),
              ),
          ],
        ),
      ),
    );
  }

  /// The identify flow: organ toggle + Identify button + suggestion list.
  /// Only shown when there's a photo to identify and nothing selected yet.
  Widget _identifySection() {
    final scheme = Theme.of(context).colorScheme;
    final file = _identifierService.imageFile;
    if (file == null || selectedName != null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(
              "WHAT'S IN THE PHOTO?",
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'leaf',
                label: Text('Leaf'),
                icon: Icon(Icons.eco_outlined),
              ),
              ButtonSegment(
                value: 'flower',
                label: Text('Flower'),
                icon: Icon(Icons.local_florist_outlined),
              ),
            ],
            selected: {_identifierService.organ},
            onSelectionChanged: (selection) => _setOrgan(selection.first),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: isLoading ? null : _identifyPlant,
            icon:
                isLoading
                    ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                    : const Icon(Icons.travel_explore),
            label: Text(isLoading ? 'Identifying...' : 'Identify Plant'),
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.fernColor(context),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Select the closest match',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...suggestions.map(_buildSuggestionRow),
          ],
        ],
      ),
    );
  }

  Widget _confidenceBadge(double score) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (score * 100).round();
    final Color color;
    if (score >= 0.5) {
      color = AppTheme.fernColor(context);
    } else if (score >= 0.2) {
      color = AppTheme.careSoon(context);
    } else {
      color = scheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$percent%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildSuggestionRow(PlantSuggestion suggestion) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _selectSuggestion(suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        suggestion.scientificName,
                        style: const TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (suggestion.commonName != null)
                        Text(
                          suggestion.commonName!,
                          style: TextStyle(
                            color: scheme.onSurfaceVariant,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _confidenceBadge(suggestion.score),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _scheduleRow(
    CareKind kind,
    int? current,
    List<int> options, {
    required bool allowNone,
    required ValueChanged<int?> onPicked,
  }) {
    return InsetRow(
      icon: kind.icon,
      title: kind.label,
      value: _intervalLabel(current),
      onTap: () async {
        Haptics.selection();
        final result = await _pickIntervalSheet(
          title: '${kind.label} every',
          options: options,
          current: current,
          allowNone: allowNone,
        );
        if (result != null) onPicked(result.$1);
      },
    );
  }

  Widget _scheduleGroup() {
    return InsetGroup(
      header: 'Schedule',
      dividerIndent: 56,
      children: [
        _scheduleRow(
          CareKind.water,
          wateringIntervalDays,
          _wateringIntervalOptions,
          allowNone: false,
          onPicked:
              (v) => setState(() {
                wateringIntervalDays = v!;
                wateringManuallySet = true;
              }),
        ),
        _scheduleRow(
          CareKind.feed,
          fertilizingIntervalDays,
          _fertilizingIntervalOptions,
          allowNone: true,
          onPicked: (v) => setState(() => fertilizingIntervalDays = v),
        ),
        _scheduleRow(
          CareKind.repot,
          repottingIntervalDays,
          _repottingIntervalOptions,
          allowNone: true,
          onPicked: (v) => setState(() => repottingIntervalDays = v),
        ),
        _scheduleRow(
          CareKind.prune,
          pruningIntervalDays,
          _pruningIntervalOptions,
          allowNone: true,
          onPicked: (v) => setState(() => pruningIntervalDays = v),
        ),
      ],
    );
  }

  Widget _careNotesGroup() {
    return InsetGroup(
      header: 'Care notes',
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          child: TextField(
            controller: careInstructionsController,
            maxLines: null,
            minLines: 3,
            decoration: const InputDecoration(
              border: InputBorder.none,
              isCollapsed: true,
              hintText: 'Add your own care notes, or wait for a suggestion...',
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsGroup() {
    return InsetGroup(
      header: 'Details',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: TextField(
            controller: nicknameController,
            decoration: const InputDecoration(
              border: InputBorder.none,
              icon: Icon(Icons.badge_outlined, size: 20),
              hintText: 'Nickname (optional)',
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedAppBar(
        title: widget.plant == null ? 'New Plant' : 'Edit Plant',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child:
                isSaving
                    ? const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator.adaptive(
                            strokeWidth: 2,
                          ),
                        ),
                      ),
                    )
                    : TextButton(
                      onPressed: _savePlant,
                      child: Text(
                        'Save',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: AppTheme.fernColor(context),
                        ),
                      ),
                    ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _photoHeader(),
          if (selectedName != null) _identifiedCard() else _identifySection(),
          _scheduleGroup(),
          _careNotesGroup(),
          _detailsGroup(),
        ],
      ),
    );
  }
}
