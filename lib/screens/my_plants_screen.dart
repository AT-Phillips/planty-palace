// lib/screens/my_plants_screen.dart
import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/plant.dart';
import 'add_plant_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  MyPlantsScreenState createState() => MyPlantsScreenState();
}

class MyPlantsScreenState extends State<MyPlantsScreen> {
  List<Plant> _plants = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await _dbHelper.getPlants();
    if (mounted) {
      setState(() {
        _plants = plants;
      });
    }
  }

  Future<void> _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result == true && mounted) {
      _loadPlants();
    }
  }

  Future<void> _deleteAllPlants() async {
    await _dbHelper.deleteAllPlants();
    if (mounted) {
      _loadPlants();
      _showSnackbar('All plants deleted');
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'add',
            onPressed: _navigateToAddPlant,
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'deleteAll',
            onPressed: _deleteAllPlants,
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete_forever),
          ),
        ],
      ),
      appBar: AppBar(title: const Text('My Plants')),
      body: _plants.isEmpty
          ? const Center(child: Text('No plants yet.'))
          : ListView.builder(
              itemCount: _plants.length,
              itemBuilder: (context, index) {
                final plant = _plants[index];
                return ListTile(
                  leading: plant.imagePath.isNotEmpty
                      ? Image.asset(
                          plant.imagePath,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        )
                      : const Icon(Icons.local_florist),
                  title: Text(plant.name),
                  subtitle: Text(plant.species),
                );
              },
            ),
    );
  }
}