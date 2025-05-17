import 'package:flutter/material.dart';
import 'dart:io';

import '../services/plant_identifier_service.dart';

class AddEditPlantScreen extends StatefulWidget {
  const AddEditPlantScreen({super.key});

  @override
  State<AddEditPlantScreen> createState() => _AddEditPlantScreenState();
}

class _AddEditPlantScreenState extends State<AddEditPlantScreen> {
  final PlantIdentifierService _identifierService = PlantIdentifierService();
  bool isLoading = false;
  List<String> suggestions = [];
  String? selectedName;
  final TextEditingController nicknameController = TextEditingController();

  Future<void> _handleCamera() async {
    await _identifierService.pickImageFromCamera();
    setState(() {});
  }

  Future<void> _handleGallery() async {
    await _identifierService.pickImageFromGallery();
    setState(() {});
  }

  void _toggleOrgan() {
    setState(() {
      _identifierService.toggleOrgan();
    });
  }

  Future<void> _identifyPlant() async {
    setState(() {
      isLoading = true;
      selectedName = null;
      suggestions = [];
    });

    try {
      suggestions = await _identifierService.identifyPlant();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _savePlant() {
    if (selectedName == null || _identifierService.imageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a plant and image')),
      );
      return;
    }

    final nickname = nicknameController.text.trim();
    final path = _identifierService.imageFile!.path;

    // Example: Replace with real database save later
    debugPrint('Saving plant:');
    debugPrint('Scientific Name: $selectedName');
    debugPrint('Nickname: $nickname');
    debugPrint('Image Path: $path');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Plant saved (mocked)!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final file = _identifierService.imageFile;

    return Scaffold(
      appBar: AppBar(title: const Text('Add / Edit Plant')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (file != null)
              Image.file(file, height: 200)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Text('No image selected')),
              ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: _handleCamera,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  onPressed: _handleGallery,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.swap_vert),
                  label: Text(_identifierService.organ),
                  onPressed: _toggleOrgan,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _identifyPlant,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Identify Plant'),
            ),
            const SizedBox(height: 16),
            if (suggestions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Select a species:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...suggestions.map((name) => RadioListTile(
                        title: Text(name),
                        value: name,
                        groupValue: selectedName,
                        onChanged: (value) {
                          setState(() {
                            selectedName = value.toString();
                          });
                        },
                      )),
                ],
              ),
            const SizedBox(height: 16),
            TextField(
              controller: nicknameController,
              decoration: const InputDecoration(
                labelText: 'Nickname (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _savePlant,
              icon: const Icon(Icons.save),
              label: const Text('Save Plant'),
            ),
          ],
        ),
      ),
    );
  }
}
