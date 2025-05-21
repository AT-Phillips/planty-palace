import 'dart:io';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'screens/my_plants_screen.dart';
import 'screens/identify_plant_screen.dart';
import 'styles/app_theme.dart';  // Import your theme here

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
      theme: AppTheme.lightTheme,  // Use your custom theme here
      home: const MainContainer(),
      routes: {
        '/identify': (context) => const IdentifyPlantScreen(),
        '/myplants': (context) => const MyPlantsScreen(),
      },
    );
  }
}

class MainContainer extends StatefulWidget {
  const MainContainer({super.key});

  @override
  State<MainContainer> createState() => _MainContainerState();
}

class _MainContainerState extends State<MainContainer> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    MyPlantsScreen(),
    IdentifyPlantScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.local_florist),
            label: 'My Plants',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Identify',
          ),
        ],
      ),
    );
  }
}
