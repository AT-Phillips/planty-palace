// lib/screens/test_plantnet_screen.dart

import 'dart:io';
import 'package:flutter/material.dart';
import '../helpers/plantnet_helper.dart';
import 'dart:convert';

class TestPlantNetScreen extends StatefulWidget {
  const TestPlantNetScreen({super.key});

  @override
  State<TestPlantNetScreen> createState() => _TestPlantNetScreenState();
}

class _TestPlantNetScreenState extends State<TestPlantNetScreen> {
  Map<String, dynamic>? _result;
  bool _loading = false;
  String? _error;

  final List<String> _imagePaths = [
    r'C:\Users\atomp\Downloads\plant1.jpg',
    r'C:\Users\atomp\Downloads\plant2.jpg',
    r'C:\Users\atomp\Downloads\plant3.jpg',
  ];

  Future<void> _testIdentify() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final images = _imagePaths.map((p) => File(p)).where((file) => file.existsSync()).toList();

      if (images.length != _imagePaths.length) {
        throw Exception("One or more image files do not exist.");
      }

      final data = await PlantNetHelper.identifyPlant(images: images, organ: 'leaf');

      if (data == null) {
        setState(() {
          _error = 'No data returned from PlantNet.';
        });
      } else {
        setState(() {
          _result = data;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Widget _buildResult() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!, style: const TextStyle(color: Colors.red)));
    }
    if (_result == null) {
      return const Center(child: Text('Press the button to test PlantNet identification.'));
    }

    final prettyJson = const JsonEncoder.withIndent('  ').convert(_result);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: SelectableText(prettyJson),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test PlantNet Identify'),
      ),
      body: _buildResult(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _testIdentify,
        icon: const Icon(Icons.search),
        label: const Text('Identify Plants'),
      ),
    );
  }
}
