import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/plant.dart';

class AddPlantScreen extends StatefulWidget {
  const AddPlantScreen({super.key});

  @override
  State<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends State<AddPlantScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _species = '';
  String _careInstructions = '';
  String _imagePath = '';

  Future<void> _savePlant() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final newPlant = Plant(
        name: _name,
        species: _species,
        imagePath: _imagePath,
        careInstructions: _careInstructions,
      );

      await DatabaseHelper().insertPlant(newPlant);
      Navigator.pop(context, true); // return to previous screen and trigger refresh
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Plant')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.isEmpty ? 'Enter plant name' : null,
                onSaved: (value) => _name = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Species'),
                validator: (value) => value == null || value.isEmpty ? 'Enter species' : null,
                onSaved: (value) => _species = value!,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Care Instructions'),
                maxLines: 3,
                onSaved: (value) => _careInstructions = value ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Image Path (optional)'),
                onSaved: (value) => _imagePath = value ?? '',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _savePlant,
                child: const Text('Save Plant'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
