import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/plant.dart';

class AddEditPlantScreen extends StatefulWidget {
  final Plant? plant;

  const AddEditPlantScreen({super.key, this.plant}); // use super.key

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  late TextEditingController _nameController;
  late TextEditingController _speciesController;
  late TextEditingController _careInstructionsController;
  late TextEditingController _imagePathController;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.plant?.name ?? '');
    _speciesController = TextEditingController(text: widget.plant?.species ?? '');
    _careInstructionsController = TextEditingController(text: widget.plant?.careInstructions ?? '');
    _imagePathController = TextEditingController(text: widget.plant?.imagePath ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _speciesController.dispose();
    _careInstructionsController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  Future<void> _savePlant() async {
    if (!_formKey.currentState!.validate()) return;

    final newPlant = Plant(
      id: widget.plant?.id,
      name: _nameController.text.trim(),
      species: _speciesController.text.trim(),
      careInstructions: _careInstructionsController.text.trim(),
      imagePath: _imagePathController.text.trim(),
    );

    try {
      if (widget.plant == null) {
        await _dbHelper.insertPlant(newPlant);
        if (kDebugMode) print('Plant added: ${newPlant.name}');
      } else {
        await _dbHelper.updatePlant(newPlant);
        if (kDebugMode) print('Plant updated: ${newPlant.name}');
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (kDebugMode) print('Error saving plant: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error saving plant')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.plant != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Plant' : 'Add Plant'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Plant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Please enter a plant name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _speciesController,
                decoration: const InputDecoration(
                  labelText: 'Species',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _careInstructionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Care Instructions',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imagePathController,
                decoration: const InputDecoration(
                  labelText: 'Image Asset Path',
                  border: OutlineInputBorder(),
                  hintText: 'e.g. assets/images/lavender.png',
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _savePlant,
                child: Text(isEditing ? 'Save Changes' : 'Add Plant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
