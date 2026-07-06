import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/care_log_entry.dart';
import '../models/plant.dart';
import '../models/plant_photo.dart';
import '../services/home_widget_service.dart';
import '../services/notification_service.dart';
import '../services/plant_repository.dart';
import '../utils/fertilizing_status.dart';
import '../utils/permanent_image.dart';
import '../utils/watering_status.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import 'add_edit_plant_screen.dart';

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
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _careHistory = history;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load plant detail: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markWatered() async {
    await _repository.markWatered(_plant.id!);
    final updated = _plant.copyWith(lastWatered: DateTime.now().toIso8601String());
    await NotificationService().scheduleWateringReminder(updated);
    HomeWidgetService().refresh();
    if (!mounted) return;
    setState(() => _plant = updated);
    _load();
  }

  Future<void> _markFertilized() async {
    await _repository.markFertilized(_plant.id!);
    final updated = _plant.copyWith(lastFertilized: DateTime.now().toIso8601String());
    await NotificationService().scheduleFertilizingReminder(updated);
    HomeWidgetService().refresh();
    if (!mounted) return;
    setState(() => _plant = updated);
    _load();
  }

  Future<void> _editPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(plant: _plant, gardenId: _plant.gardenId!),
      ),
    );
    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePlant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete plant?'),
        content: Text('This will remove ${_plant.name} and all of its photos and history.'),
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
      _plant = _plant.copyWith(photoUrl: photo.photoUrl, imagePath: permanentImage.path);
    });
  }

  void _showAddPhotoOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _addTimelinePhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _addTimelinePhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openPhotoOptions(PlantPhoto photo) async {
    final isCover = photo.photoUrl == _plant.photoUrl;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCover)
              ListTile(
                leading: const Icon(Icons.check_circle_outline),
                title: const Text('Set as cover photo'),
                onTap: () => Navigator.pop(context, 'cover'),
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Delete photo'),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
          ],
        ),
      ),
    );

    if (action == 'cover') {
      await _repository.setCoverPhoto(_plant.id!, photo);
      if (!mounted) return;
      setState(() => _plant = _plant.copyWith(photoUrl: photo.photoUrl, imagePath: ''));
    } else if (action == 'delete') {
      await _repository.deletePhoto(_plant.id!, photo);
      if (!mounted) return;
      setState(() {
        _timeline = _timeline.where((p) => p.id != photo.id).toList();
        if (photo.photoUrl == _plant.photoUrl) {
          final newCover = _timeline.isEmpty ? null : _timeline.first;
          _plant = _plant.copyWith(
            photoUrl: newCover?.photoUrl,
            imagePath: '',
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = isOverdue(_plant);
    final fertilizingOverdue = isFertilizingOverdue(_plant);

    return Scaffold(
      appBar: FrostedAppBar(
        title: _plant.name,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editPlant),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deletePlant),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox(
                    height: 240,
                    width: double.infinity,
                    child: PlantThumbnail(
                      plant: _plant,
                      size: double.infinity,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _plant.species,
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        wateringStatusText(_plant),
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: overdue ? scheme.error : scheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _markWatered,
                      icon: const Icon(Icons.water_drop_outlined, size: 18),
                      label: const Text('Watered'),
                    ),
                  ],
                ),
                if (_plant.fertilizingIntervalDays != null)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          fertilizingStatusText(_plant),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: fertilizingOverdue ? scheme.error : scheme.onSurface,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _markFertilized,
                        icon: const Icon(Icons.eco_outlined, size: 18),
                        label: const Text('Fertilized'),
                      ),
                    ],
                  ),
                if (_plant.careInstructions.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text('Care Info', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                  const SizedBox(height: 8),
                  Text(_plant.careInstructions),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Growth Photos', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                    TextButton.icon(
                      onPressed: _showAddPhotoOptions,
                      icon: const Icon(Icons.add),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                if (_timeline.isEmpty)
                  Text('No growth photos yet.', style: TextStyle(color: scheme.onSurfaceVariant))
                else
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _timeline.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final photo = _timeline[index];
                        final isCover = photo.photoUrl == _plant.photoUrl;
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
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 80,
                                    height: 80,
                                    color: scheme.surfaceContainerHighest,
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                              ),
                              if (isCover)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(Icons.star, size: 18, color: scheme.primary),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
                Text('Care History', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                const SizedBox(height: 8),
                if (_careHistory.isEmpty)
                  Text('No care history yet.', style: TextStyle(color: scheme.onSurfaceVariant))
                else
                  for (final entry in _careHistory)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Icon(
                            entry.type == 'fertilizing' ? Icons.eco_outlined : Icons.water_drop_outlined,
                            size: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.type == 'fertilizing' ? 'Fertilized' : 'Watered'} — '
                            '${DateTime.parse(entry.timestamp).toLocal().toString().split('.').first}',
                          ),
                        ],
                      ),
                    ),
              ],
            ),
    );
  }
}
