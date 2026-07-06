import 'package:flutter/material.dart';
import 'dart:io';

import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/perenual_service.dart';
import '../services/plant_identifier_service.dart';
import '../services/plant_repository.dart';
import '../utils/permanent_image.dart';

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
  int wateringIntervalDays = 7;
  int? fertilizingIntervalDays;
  int? repottingIntervalDays;
  int? pruningIntervalDays;
  final TextEditingController nicknameController = TextEditingController();
  final TextEditingController careInstructionsController = TextEditingController();

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
      if (widget.prefillImagePath != null && widget.prefillImagePath!.isNotEmpty) {
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

  void _setOrgan(String organ) {
    setState(() {
      _identifierService.organ = organ;
      selectedName = null;
      suggestions = [];
    });
  }

  Future<void> _identifyPlant() async {
    setState(() {
      isLoading = true;
      selectedName = null;
      suggestions = [];
    });

    try {
      suggestions = await _identifierService.identifyPlant();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }

    if (!mounted) return;
    setState(() => isLoading = false);
  }

  void _selectSuggestion(PlantSuggestion suggestion) {
    setState(() => selectedName = suggestion.scientificName);
    _lookupCareInfo(suggestion.scientificName);
  }

  Future<void> _savePlant() async {
    if (selectedName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plant')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final pickedImage = _identifierService.imageFile;
      final permanentImage =
          pickedImage == null ? null : await ensurePermanentPlantImage(pickedImage);
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
        lastWatered: widget.plant?.lastWatered ?? DateTime.now().toIso8601String(),
        wateringIntervalDays: wateringIntervalDays,
        lastFertilized: widget.plant?.lastFertilized ??
            (fertilizingIntervalDays != null ? DateTime.now().toIso8601String() : null),
        fertilizingIntervalDays: fertilizingIntervalDays,
        lastRepotted: widget.plant?.lastRepotted ??
            (repottingIntervalDays != null ? DateTime.now().toIso8601String() : null),
        repottingIntervalDays: repottingIntervalDays,
        lastPruned: widget.plant?.lastPruned ??
            (pruningIntervalDays != null ? DateTime.now().toIso8601String() : null),
        pruningIntervalDays: pruningIntervalDays,
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

  Widget _sectionHeader(IconData icon, String label) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      ],
    );
  }

  Widget _buildPhotoSection() {
    final scheme = Theme.of(context).colorScheme;
    final file = _identifierService.imageFile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: file != null
                      ? Image.file(
                          file,
                          height: 220,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 220,
                          width: double.infinity,
                          color: scheme.surfaceContainerHighest,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.local_florist_outlined,
                                    size: 40, color: scheme.onSurfaceVariant),
                                const SizedBox(height: 8),
                                Text(
                                  'No photo yet',
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
                if (file != null)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 20),
                        tooltip: 'Remove photo',
                        onPressed: _handleRemovePhoto,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Camera'),
                    onPressed: _handleCamera,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Gallery'),
                    onPressed: _handleGallery,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "What's in the photo?",
                style: TextStyle(fontWeight: FontWeight.w600, color: scheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: SegmentedButton<String>(
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _confidenceBadge(double score) {
    final scheme = Theme.of(context).colorScheme;
    final percent = (score * 100).round();
    final Color color;
    if (score >= 0.5) {
      color = Colors.green;
    } else if (score >= 0.2) {
      color = Colors.orange;
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
        style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }

  Widget _buildSuggestionCard(PlantSuggestion suggestion) {
    final scheme = Theme.of(context).colorScheme;
    final isSelected = selectedName == suggestion.scientificName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isSelected ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _selectSuggestion(suggestion),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? scheme.primary : scheme.outline,
                ),
                const SizedBox(width: 12),
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
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
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

  Widget _buildIdentifySection() {
    final file = _identifierService.imageFile;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.search, 'Identify'),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: file == null ? null : _identifyPlant,
              icon: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.travel_explore),
              label: Text(isLoading ? 'Identifying...' : 'Identify Plant'),
            ),
            if (suggestions.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Select the closest match:',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...suggestions.map(_buildSuggestionCard),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWateringSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.water_drop_outlined, 'Watering'),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              value: wateringIntervalDays,
              decoration: const InputDecoration(labelText: 'Water every'),
              items: _wateringIntervalOptions
                  .map((days) => DropdownMenuItem(
                        value: days,
                        child: Text('$days days'),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    wateringIntervalDays = value;
                    wateringManuallySet = true;
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFertilizingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.eco_outlined, 'Fertilizing'),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: fertilizingIntervalDays,
              decoration: const InputDecoration(labelText: 'Fertilize every'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No schedule')),
                ..._fertilizingIntervalOptions.map(
                  (days) => DropdownMenuItem(value: days, child: Text('$days days')),
                ),
              ],
              onChanged: (value) {
                setState(() => fertilizingIntervalDays = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRepottingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.yard_outlined, 'Repotting'),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: repottingIntervalDays,
              decoration: const InputDecoration(labelText: 'Repot every'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No schedule')),
                ..._repottingIntervalOptions.map(
                  (days) => DropdownMenuItem(value: days, child: Text('$days days')),
                ),
              ],
              onChanged: (value) {
                setState(() => repottingIntervalDays = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPruningSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.content_cut, 'Pruning'),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: pruningIntervalDays,
              decoration: const InputDecoration(labelText: 'Prune every'),
              items: [
                const DropdownMenuItem(value: null, child: Text('No schedule')),
                ..._pruningIntervalOptions.map(
                  (days) => DropdownMenuItem(value: days, child: Text('$days days')),
                ),
              ],
              onChanged: (value) {
                setState(() => pruningIntervalDays = value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCareInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _sectionHeader(Icons.spa_outlined, 'Care Info'),
                if (isFetchingCareInfo) ...[
                  const SizedBox(width: 12),
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: careInstructionsController,
              maxLines: null,
              minLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add your own care notes, or wait for a suggestion...',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionHeader(Icons.label_outline, 'Details'),
            const SizedBox(height: 12),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(widget.plant == null ? 'Add Plant' : 'Edit Plant')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          _buildPhotoSection(),
          const SizedBox(height: 12),
          _buildIdentifySection(),
          const SizedBox(height: 12),
          _buildWateringSection(),
          const SizedBox(height: 12),
          _buildFertilizingSection(),
          const SizedBox(height: 12),
          _buildRepottingSection(),
          const SizedBox(height: 12),
          _buildPruningSection(),
          const SizedBox(height: 12),
          _buildCareInfoSection(),
          const SizedBox(height: 12),
          _buildDetailsSection(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: BoxDecoration(
            color: scheme.surface,
            border: Border(top: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : _savePlant,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Plant'),
            ),
          ),
        ),
      ),
    );
  }
}
