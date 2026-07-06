import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/plant.dart';
import '../models/propagation.dart';
import '../services/plant_repository.dart';
import '../services/propagation_repository.dart';
import '../utils/permanent_image.dart';

const _methods = ['Water', 'Soil', 'Air Layering', 'Division', 'Other'];

/// Add or edit a Propagation - name, method, start date, notes, an optional
/// link to an existing plant, and an optional photo.
class AddEditPropagationScreen extends StatefulWidget {
  final Propagation? propagation;

  const AddEditPropagationScreen({super.key, this.propagation});

  @override
  State<AddEditPropagationScreen> createState() => _AddEditPropagationScreenState();
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
          final matches = plants.where((p) => p.id == widget.propagation!.parentPlantId);
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

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please give it a name')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final permanentImage = _imageFile == null ? null : await ensurePermanentPlantImage(_imageFile!);
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.propagation == null ? 'Add Propagation' : 'Edit Propagation'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _imageFile != null
                        ? Image.file(_imageFile!, height: 180, width: double.infinity, fit: BoxFit.cover)
                        : Container(
                            height: 180,
                            width: double.infinity,
                            color: scheme.surfaceContainerHighest,
                            child: Icon(Icons.eco_outlined, size: 40, color: scheme.onSurfaceVariant),
                          ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.camera_alt_outlined),
                          label: const Text('Camera'),
                          onPressed: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                          onPressed: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _method,
                    decoration: const InputDecoration(labelText: 'Method'),
                    items: _methods
                        .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => _method = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Started'),
                    subtitle: Text('${_startedAt.year}-${_startedAt.month.toString().padLeft(2, '0')}-${_startedAt.day.toString().padLeft(2, '0')}'),
                    trailing: const Icon(Icons.calendar_today_outlined),
                    onTap: _pickDate,
                  ),
                  const SizedBox(height: 12),
                  if (_loadingPlants)
                    const Center(child: CircularProgressIndicator.adaptive())
                  else
                    DropdownButtonFormField<Plant?>(
                      value: _parentPlant,
                      decoration: const InputDecoration(labelText: 'From plant (optional)'),
                      items: [
                        const DropdownMenuItem(value: null, child: Text('None')),
                        ..._availablePlants.map(
                          (p) => DropdownMenuItem(value: p, child: Text(p.name)),
                        ),
                      ],
                      onChanged: (value) => setState(() => _parentPlant = value),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _notesController,
                    maxLines: null,
                    minLines: 3,
                    decoration: const InputDecoration(hintText: 'Notes (optional)'),
                  ),
                ],
              ),
            ),
          ),
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
              onPressed: _isSaving ? null : _save,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save Propagation'),
            ),
          ),
        ),
      ),
    );
  }
}
