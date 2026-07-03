import 'package:flutter/material.dart';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../helpers/database_helper.dart';
import '../models/plant.dart';
import '../services/notification_service.dart';
import '../services/perenual_service.dart';
import '../services/plant_identifier_service.dart';

const _wateringIntervalOptions = [3, 7, 10, 14, 21, 30];

class AddEditPlantScreen extends StatefulWidget {
  final Plant? plant;
  final int gardenId;

  const AddEditPlantScreen({super.key, this.plant, required this.gardenId});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final PlantIdentifierService _identifierService = PlantIdentifierService();
  final PerenualService _careService = PerenualService();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  bool isLoading = false;
  bool isSaving = false;
  bool isFetchingCareInfo = false;
  bool wateringManuallySet = false;
  List<String> suggestions = [];
  String? selectedName;
  int wateringIntervalDays = 7;
  String careInstructions = '';
  final TextEditingController nicknameController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.plant != null) {
      final plant = widget.plant!;
      selectedName = plant.species;
      nicknameController.text = plant.name;
      wateringIntervalDays = plant.wateringIntervalDays ?? 7;
      careInstructions = plant.careInstructions;
      if (plant.imagePath.isNotEmpty) {
        _identifierService.imageFile = File(plant.imagePath);
      }
    }
  }

  Future<void> _lookupCareInfo(String species) async {
    setState(() => isFetchingCareInfo = true);

    final info = await _careService.lookupCareInfo(species);

    if (!mounted) return;
    setState(() {
      isFetchingCareInfo = false;
      if (info != null) {
        careInstructions = info.careInstructions;
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

  void _toggleOrgan() {
    setState(() {
      _identifierService.toggleOrgan();
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

  /// Ensures the given image file lives in permanent app storage, copying it
  /// there if it currently points at a transient picker/cache location.
  Future<File> _ensurePermanentImage(File file) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final plantImagesDir = Directory(p.join(appDocDir.path, 'plant_images'));

    if (p.isWithin(plantImagesDir.path, file.path)) {
      return file;
    }

    if (!await plantImagesDir.exists()) {
      await plantImagesDir.create(recursive: true);
    }

    final newPath = p.join(
      plantImagesDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
    );
    return file.copy(newPath);
  }

  Future<void> _savePlant() async {
    if (selectedName == null || _identifierService.imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plant and image')),
      );
      return;
    }

    setState(() => isSaving = true);

    try {
      final permanentImage =
          await _ensurePermanentImage(_identifierService.imageFile!);
      final nickname = nicknameController.text.trim();

      final plant = Plant(
        id: widget.plant?.id,
        name: nickname.isEmpty ? selectedName! : nickname,
        species: selectedName!,
        imagePath: permanentImage.path,
        careInstructions: careInstructions,
        gardenId: widget.plant?.gardenId ?? widget.gardenId,
        lastWatered: widget.plant?.lastWatered ?? DateTime.now().toIso8601String(),
        wateringIntervalDays: wateringIntervalDays,
      );

      Plant savedPlant;
      if (widget.plant == null) {
        final id = await _dbHelper.insertPlant(plant);
        await _dbHelper.logCareEvent(id, plant.lastWatered!);
        savedPlant = Plant(
          id: id,
          name: plant.name,
          species: plant.species,
          imagePath: plant.imagePath,
          careInstructions: plant.careInstructions,
          gardenId: plant.gardenId,
          lastWatered: plant.lastWatered,
          wateringIntervalDays: plant.wateringIntervalDays,
        );
      } else {
        await _dbHelper.updatePlant(plant);
        savedPlant = plant;
      }
      await NotificationService().scheduleWateringReminder(savedPlant);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save plant: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final file = _identifierService.imageFile;

    return Scaffold(
      appBar: AppBar(title: Text(widget.plant == null ? 'Add Plant' : 'Edit Plant')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Photo section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: file != null
                        ? Image.file(file, height: 200, width: double.infinity, fit: BoxFit.cover)
                        : Container(
                            height: 200,
                            width: double.infinity,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Center(child: Text('No image selected')),
                          ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                        onPressed: _handleCamera,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                        onPressed: _handleGallery,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.swap_vert),
                        label: Text(_identifierService.organ),
                        onPressed: _toggleOrgan,
                      ),
                    ],
                  ),
                  if (file != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      label: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                      onPressed: _handleRemovePhoto,
                    ),
                ],
              ),
            ),
          ),

          // Identify section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: file == null ? null : _identifyPlant,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                          )
                        : const Text('Identify Plant'),
                  ),
                  if (suggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Select a species:', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...suggestions.map((name) => RadioListTile(
                          title: Text(name),
                          value: name,
                          groupValue: selectedName,
                          onChanged: (value) {
                            setState(() {
                              selectedName = value.toString();
                            });
                            _lookupCareInfo(value.toString());
                          },
                        )),
                  ],
                ],
              ),
            ),
          ),

          // Watering section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: DropdownButtonFormField<int>(
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
            ),
          ),

          // Care info section
          if (isFetchingCareInfo || careInstructions.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: isFetchingCareInfo
                    ? const Row(
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Looking up care info...'),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Care Info', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(careInstructions),
                        ],
                      ),
              ),
            ),

          // Details section
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Nickname (optional)',
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : _savePlant,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Save Plant'),
            ),
          ),
        ],
      ),
    );
  }
}
