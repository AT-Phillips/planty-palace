import 'package:flutter/material.dart';
import 'screens/my_plants_screen.dart';

void main() {
  runApp(PlantyPalaceApp());
}

class PlantyPalaceApp extends StatelessWidget {
  // Use 'super' to pass the 'key' parameter directly to the parent class
  const PlantyPalaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planty Palace',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyPlantsScreen(),
    );
  }
}
