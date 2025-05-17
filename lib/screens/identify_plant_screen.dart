import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';

import '../helpers/plantnet_helper.dart';
import '../widgets/image_picker_button.dart';  // Import the new widget

class IdentifyPlantScreen extends StatefulWidget {
  const IdentifyPlantScreen({super.key});

  @override
  State<IdentifyPlantScreen> createState() => _IdentifyPlantScreenState();
}

class _IdentifyPlantScreenState extends State<IdentifyPlantScreen> {
  File? _pickedImage;
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  void _onImagePicked(File? image) {
    if (image != null) {
      setState(() {
        _pickedImage = image;
        _results = null;
      });
    }
  }

  Future<void> _identifyPlant() async {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select or take a photo first')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    final response = await PlantNetHelper.identifyPlant(images: [_pickedImage!]);

    setState(() {
      _isLoading = false;
      _results = response;
    });
  }

  Widget _buildImagePreview() {
    if (_pickedImage == null) return const SizedBox.shrink();

    return Stack(
      alignment: Alignment.topRight,
      children: [
        Image.file(_pickedImage!, width: 120, height: 120, fit: BoxFit.cover),
        GestureDetector(
          onTap: () {
            setState(() {
              _pickedImage = null;
              _results = null;
            });
          },
          child: const CircleAvatar(
            radius: 14,
            backgroundColor: Colors.red,
            child: Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildResults() {
    if (_results == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Text(
          JsonEncoder.withIndent('  ').convert(_results),
          style: const TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Identify Plant')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            ImagePickerButton(onImagePicked: _onImagePicked),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _identifyPlant,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Identify Plant'),
            ),
            const SizedBox(height: 20),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }
}
