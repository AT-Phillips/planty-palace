import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/plant.dart';
import 'add_plant_screen.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  _MyPlantsScreenState createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
  List<Plant> _plants = []; // Store the list of plants

  @override
  void initState() {
    super.initState();
    _loadPlants(); // Load plants when the screen initializes
  }

  Future<void> _loadPlants() async {
    final plants = await DatabaseHelper().getPlants(); // Fetch plants from DB
    setState(() {
      _plants = plants; // Update the state with the plants
    });
  }

  Future<void> _navigateToAddPlant() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddPlantScreen()),
    );
    if (result == true) {
      _loadPlants(); // Refresh plant list after adding new plant
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPlant,
        child: const Icon(Icons.add),
      ),
      appBar: AppBar(title: const Text('My Plants')),
      body:
          _plants.isEmpty
              ? const Center(
                child: Text('No plants yet.'),
              ) // Display when no plants are available
              : ListView.builder(
                itemCount: _plants.length,
                itemBuilder: (context, index) {
                  final plant = _plants[index]; // Get each plant
                  return ListTile(
                    leading:
                        plant.imagePath.isNotEmpty
                            ? Image.asset(
                              plant.imagePath,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            )
                            : const Icon(Icons.local_florist),
                    title: Text(plant.name), // Plant name
                    subtitle: Text(plant.species), // Plant species
                  );
                },
              ),
    );
  }
}