import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant.dart';
import '../models/plant_photo.dart';
import '../models/propagation.dart';
import '../services/plant_repository.dart';
import '../services/propagation_repository.dart';
import '../utils/permanent_image.dart';
import '../utils/relative_time.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/propagation_thumbnail.dart';
import 'add_edit_plant_screen.dart';
import 'add_edit_propagation_screen.dart';
import 'plant_detail_screen.dart';

class PropagationDetailScreen extends StatefulWidget {
  final Propagation propagation;

  const PropagationDetailScreen({super.key, required this.propagation});

  @override
  State<PropagationDetailScreen> createState() => _PropagationDetailScreenState();
}

class _PropagationDetailScreenState extends State<PropagationDetailScreen> {
  final PropagationRepository _repository = PropagationRepository();
  late Propagation _propagation;
  List<PlantPhoto> _timeline = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _propagation = widget.propagation;
    _load();
  }

  Future<void> _load() async {
    try {
      final timeline = await _repository.getPhotos(_propagation.id!);
      if (!mounted) return;
      setState(() {
        _timeline = timeline;
        _loading = false;
      });
    } catch (e) {
      debugPrint('Failed to load propagation detail: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editPropagation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditPropagationScreen(propagation: _propagation)),
    );
    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  Future<void> _deletePropagation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete propagation?'),
        content: Text('This will remove ${_propagation.name} and all of its photos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true) return;

    await _repository.deletePropagation(_propagation.id!);
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _viewParentPlant() async {
    final parentId = _propagation.parentPlantId;
    if (parentId == null) return;
    final plants = await PlantRepository().getPlants();
    final matches = plants.where((p) => p.id == parentId);
    if (matches.isEmpty || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: matches.first)),
    );
  }

  Future<void> _viewPromotedPlant() async {
    final plants = await PlantRepository().getPlants();
    final matches = plants.where((p) => p.id == _propagation.promotedPlantId);
    if (matches.isEmpty || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: matches.first)),
    );
  }

  Future<void> _promote() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Promote to a plant?'),
        content: Text(
          '${_propagation.name} will become a new plant you can track watering and care for. '
          'This propagation stays visible, marked as promoted.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Promote')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final gardenId = await PlantRepository().getOrCreateDefaultGardenId();
    if (!mounted) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(
          gardenId: gardenId,
          prefillSpecies: _propagation.parentSpeciesSnapshot ?? _propagation.name,
          prefillImagePath: _propagation.imagePath.isNotEmpty ? _propagation.imagePath : null,
        ),
      ),
    );

    if (result is! Plant || !mounted) return;

    await _repository.markPromoted(_propagation.id!, result.id!);
    if (!mounted) return;
    setState(() => _propagation = _propagation.copyWith(isPromoted: true, promotedPlantId: result.id));

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlantDetailScreen(plant: result)),
    );
  }

  Future<void> _addTimelinePhoto(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;

    final permanentImage = await ensurePermanentPlantImage(File(picked.path));
    final photo = await _repository.addPhoto(_propagation.id!, permanentImage);
    if (!mounted) return;
    setState(() {
      _timeline = [photo, ..._timeline];
      _propagation = _propagation.copyWith(photoUrl: photo.photoUrl, imagePath: permanentImage.path);
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
    final isCover = photo.photoUrl == _propagation.photoUrl;
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
      await _repository.setCoverPhoto(_propagation.id!, photo);
      if (!mounted) return;
      setState(() => _propagation = _propagation.copyWith(photoUrl: photo.photoUrl, imagePath: ''));
    } else if (action == 'delete') {
      await _repository.deletePhoto(_propagation.id!, photo);
      if (!mounted) return;
      setState(() {
        _timeline = _timeline.where((p) => p.id != photo.id).toList();
        if (photo.photoUrl == _propagation.photoUrl) {
          final newCover = _timeline.isEmpty ? null : _timeline.first;
          _propagation = _propagation.copyWith(photoUrl: newCover?.photoUrl, imagePath: '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: FrostedAppBar(
        title: _propagation.name,
        actions: [
          IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _editPropagation),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deletePropagation),
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
                    child: PropagationThumbnail(
                      propagation: _propagation,
                      size: double.infinity,
                      borderRadius: BorderRadius.zero,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '${_propagation.method} · ${startedAgoText(_propagation.startedAt)}',
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                if (_propagation.parentPlantId != null) ...[
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _viewParentPlant,
                    icon: const Icon(Icons.arrow_back, size: 16),
                    label: Text('From ${_propagation.parentSpeciesSnapshot ?? 'a plant in your collection'}'),
                  ),
                ],
                if (_propagation.notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text('Notes', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                  const SizedBox(height: 8),
                  Text(_propagation.notes),
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
                        final isCover = photo.photoUrl == _propagation.photoUrl;
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
                const SizedBox(height: 24),
                if (_propagation.isPromoted)
                  OutlinedButton.icon(
                    onPressed: _viewPromotedPlant,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Promoted — View Plant'),
                  )
                else
                  FilledButton.icon(
                    onPressed: _promote,
                    icon: const Icon(Icons.arrow_upward),
                    label: const Text('Promote to Plant'),
                  ),
              ],
            ),
    );
  }
}
