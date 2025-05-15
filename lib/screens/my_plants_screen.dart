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

  @override
  void initState() {
    super.initState();
    _loadPlants();
  }

  Future<void> _loadPlants() async {
    final plants = await DatabaseHelper().getPlants();
    setState(() {
      _plants = plants;
    });
  }

  Future<void> _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result == true) {
      _loadPlants();
    }
  }

  Future<void> _deleteAllPlants() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Plants?'),
        content: const Text('This will delete all plant data permanently.'),
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

    if (confirm == true) {
      await DatabaseHelper().deleteAllPlants();
      _loadPlants(); // Refresh UI after deletion
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlant,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(
        title: const Text('My Plants'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteAllPlants,
          ),
        ],
      ),
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
