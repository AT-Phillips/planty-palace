import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant.dart';
import '../models/propagation.dart';
import '../services/plant_repository.dart';
import '../services/propagation_repository.dart';
import '../styles/app_theme.dart';
import '../utils/haptics.dart';
import '../utils/permanent_image.dart';
import '../widgets/app_bottom_sheet.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/inset_group.dart';

const _methods = ['Water', 'Soil', 'Air Layering', 'Division', 'Other'];

/// Add or edit a Propagation - name, method, start date, notes, an optional
/// link to an existing plant, and an optional photo.
class AddEditPropagationScreen extends StatefulWidget {
  final Propagation? propagation;

  const AddEditPropagationScreen({super.key, this.propagation});

  @override
  State<AddEditPropagationScreen> createState() =>
      _AddEditPropagationScreenState();
}

class _AddEditPropagationScreenState extends State<AddEditPropagationScreen> {
  final PropagationRepository _repository = PropagationRepository();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  String _method = _methods.first;
  DateTime _startedAt = DateTime.now();
  List<Plant> _availablePlants = [];
  Plant? _parentPlant;
  File? _imageFile;
  bool _loadingPlants = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final propagation = widget.propagation;
    if (propagation != null) {
      _nameController.text = propagation.name;
      _method = propagation.method;
      _startedAt = DateTime.parse(propagation.startedAt);
      _notesController.text = propagation.notes;
      if (propagation.imagePath.isNotEmpty) {
        _imageFile = File(propagation.imagePath);
      }
    }
    _loadPlants();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadPlants() async {
    try {
      final plants = await PlantRepository().getPlants();
      if (!mounted) return;
      setState(() {
        _availablePlants = plants;
        if (widget.propagation?.parentPlantId != null) {
          final matches = plants.where(
            (p) => p.id == widget.propagation!.parentPlantId,
          );
          _parentPlant = matches.isEmpty ? null : matches.first;
        }
        _loadingPlants = false;
      });
    } catch (e) {
      debugPrint('Failed to load plants for propagation parent picker: $e');
      if (mounted) setState(() => _loadingPlants = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 5)),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _startedAt = picked);
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await ImagePicker().pickImage(source: source);
    if (picked == null) return;
    setState(() => _imageFile = File(picked.path));
  }

  Future<void> _changePhoto() async {
    final hasPhoto = _imageFile != null;
    final action = await showAppActionSheet<String>(
      context,
      title: 'Propagation photo',
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
        await _pickImage(ImageSource.camera);
        break;
      case 'gallery':
        await _pickImage(ImageSource.gallery);
        break;
      case 'remove':
        setState(() => _imageFile = null);
        break;
    }
  }

  Future<void> _pickMethod() async {
    final result = await showAppActionSheet<String>(
      context,
      title: 'Method',
      actions: [
        for (final m in _methods)
          AppSheetAction(icon: Icons.eco_outlined, label: m, value: m),
      ],
    );
    if (result != null) setState(() => _method = result);
  }

  Future<void> _pickParentPlant() async {
    final result = await showAppActionSheet<Object?>(
      context,
      title: 'From plant',
      actions: [
        const AppSheetAction(icon: Icons.close, label: 'None', value: _none),
        for (final p in _availablePlants)
          AppSheetAction(
            icon: Icons.local_florist_outlined,
            label: p.name,
            value: p,
          ),
      ],
    );
    if (result == _none) {
      setState(() => _parentPlant = null);
    } else if (result is Plant) {
      setState(() => _parentPlant = result);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please give it a name')));
      return;
    }

    setState(() => _isSaving = true);

    try {
      final permanentImage =
          _imageFile == null
              ? null
              : await ensurePermanentPlantImage(_imageFile!);
      final propagation = Propagation(
        id: widget.propagation?.id,
        name: name,
        method: _method,
        startedAt: _startedAt.toIso8601String(),
        notes: _notesController.text.trim(),
        parentPlantId: _parentPlant?.id,
        parentSpeciesSnapshot: _parentPlant?.species,
        photoUrl: widget.propagation?.photoUrl,
        imagePath: permanentImage?.path ?? widget.propagation?.imagePath ?? '',
      );

      String id;
      if (widget.propagation == null) {
        id = await _repository.insertPropagation(propagation);
      } else {
        id = widget.propagation!.id!;
        await _repository.updatePropagation(propagation);
      }

      if (permanentImage != null) {
        try {
          await _repository.addPhoto(id, permanentImage);
        } catch (_) {
          // Photo sync can be retried later; not a blocking failure.
        }
      }

      if (!mounted) return;
      Haptics.medium();
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _dateLabel(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Widget _photoHeader() {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: GestureDetector(
        onTap: _changePhoto,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 170,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (_imageFile != null)
                  Image.file(_imageFile!, fit: BoxFit.cover)
                else
                  Container(
                    color: scheme.surfaceContainerHighest,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 32,
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
                if (_imageFile != null)
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedAppBar(
        title:
            widget.propagation == null ? 'New Propagation' : 'Edit Propagation',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child:
                _isSaving
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
                      onPressed: _save,
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
          InsetGroup(
            header: 'Details',
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    icon: Icon(Icons.badge_outlined, size: 20),
                    hintText: 'Name',
                  ),
                ),
              ),
            ],
          ),
          InsetGroup(
            header: 'Schedule',
            dividerIndent: 56,
            children: [
              InsetRow(
                icon: Icons.eco_outlined,
                title: 'Method',
                value: _method,
                onTap: () {
                  Haptics.selection();
                  _pickMethod();
                },
              ),
              InsetRow(
                icon: Icons.calendar_today_outlined,
                title: 'Started',
                value: _dateLabel(_startedAt),
                onTap: _pickDate,
              ),
              InsetRow(
                icon: Icons.local_florist_outlined,
                title: 'From plant',
                value: _loadingPlants ? '…' : (_parentPlant?.name ?? 'None'),
                onTap:
                    _loadingPlants
                        ? null
                        : () {
                          Haptics.selection();
                          _pickParentPlant();
                        },
              ),
            ],
          ),
          InsetGroup(
            header: 'Notes',
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                child: TextField(
                  controller: _notesController,
                  maxLines: null,
                  minLines: 3,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    isCollapsed: true,
                    hintText: 'Notes (optional)',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Sentinel distinguishing "user picked None" from "sheet dismissed" in
/// [_pickParentPlant], since both would otherwise be indistinguishable nulls.
const Object _none = Object();
