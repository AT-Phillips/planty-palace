import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/plantnet_helper.dart';

class TestPlantNetScreen extends StatefulWidget {
  const TestPlantNetScreen({super.key});

  @override
  State<TestPlantNetScreen> createState() => _TestPlantNetScreenState();
}

class _TestPlantNetScreenState extends State<TestPlantNetScreen> {
  String? _responseJson;
  bool _isLoading = false;

  // Replace these with your actual local image file paths
  final List<String> testImagePaths = [
    'C:/Users/YourUserName/Pictures/plant1.jpg',
    'C:/Users/YourUserName/Pictures/plant2.jpg',
    'C:/Users/YourUserName/Pictures/plant3.jpg',
  ];

  Future<void> _testIdentifyPlant() async {
    setState(() {
      _isLoading = true;
      _responseJson = null;
    });

    try {
      // Convert paths to File objects
      final files = testImagePaths.map((path) => File(path)).toList();

      final result = await PlantNetHelper.identifyPlant(images: files);

      setState(() {
        _responseJson = result != null ? result.toString() : 'No result or error';
      });
    } catch (e) {
      setState(() {
        _responseJson = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Test PlantNet API')),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testIdentifyPlant,
              child: Text(_isLoading ? 'Loading...' : 'Run PlantNet Identify'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  _responseJson ?? 'Press the button to test',
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
