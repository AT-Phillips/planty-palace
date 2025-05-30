import 'dart:io';

import 'package:flutter/material.dart';

import '../helpers/database_helper.dart';
import '../models/plant.dart';
import '../widgets/camera_capture_area.dart';
import 'add_edit_plant_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  State<MyPlantsScreen> createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Plant> _plants = [];

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await _dbHelper.getPlants();
    if (!mounted) return;
    setState(() => _plants = plants);
  }

  Future<void> _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPlantScreen()),
    );
    if (result == true && mounted) {
      _loadPlants();
    }
  }

  Future<void> _navigateToEditPlant(Plant plant) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddEditPlantScreen(plant: plant)),
    );
    if (result == true && mounted) {
      _loadPlants();
    }
  }

  Future<void> _deleteAllPlants() async {
    await _dbHelper.deleteAllPlants();
    if (!mounted) return;
    _loadPlants();
    _showSnackbar('All plants deleted');
  }

  void _showSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleImagePicked(File image) {
    // For now, just print the image path
    print('Picked image path: ${image.path}');

    // TODO: Optionally navigate to Identify screen or Add/Edit with image
  }

  Widget _buildPlantTile(Plant plant) {
    Widget leadingWidget;

    if (plant.imagePath.isNotEmpty) {
      leadingWidget = Image.asset(
        plant.imagePath,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
      );
    } else {
      leadingWidget = const Icon(Icons.local_florist);
    }

    return ListTile(
      leading: leadingWidget,
      title: Text(plant.name),
      subtitle: Text(plant.species),
      onTap: () => _navigateToEditPlant(plant),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Plants')),
      body: _plants.isEmpty
          ? const Center(child: Text('No plants yet.'))
          : ListView.builder(
              itemCount: _plants.length,
              itemBuilder: (context, index) => _buildPlantTile(_plants[index]),
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _navigateToAddPlant,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'deleteAll',
            onPressed: _deleteAllPlants,
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete_forever),
          ),
          const SizedBox(height: 12),
          CameraCaptureArea(onImagePicked: _handleImagePicked),
        ],
      ),
    );
  }
}
