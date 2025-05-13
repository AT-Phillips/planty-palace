import 'package:flutter/material.dart';
import '../helpers/database_helper.dart';
import '../models/plant.dart';

class MyPlantsScreen extends StatefulWidget {
  const MyPlantsScreen({super.key});

  @override
  _MyPlantsScreenState createState() => _MyPlantsScreenState();
}

class _MyPlantsScreenState extends State<MyPlantsScreen> {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
