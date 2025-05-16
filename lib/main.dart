import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'screens/my_plants_screen.dart';
import 'screens/identify_plant_screen.dart';  // existing screen
import 'screens/test_plantnet_screen.dart';   // new test screen

void main() {
  // Initialize FFI database for desktop platforms
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }

  runApp(const PlantyPalaceApp());
}

class PlantyPalaceApp extends StatelessWidget {
  const PlantyPalaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planty Palace',
      theme: ThemeData(
        primarySwatch: Colors.green,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const TestPlantNetScreen(),  // <-- temporary test home screen
      routes: {
        '/identify': (context) => const IdentifyPlantScreen(),
        '/myplants': (context) => const MyPlantsScreen(), // keep route for MyPlantsScreen
      },
    );
  }
}
