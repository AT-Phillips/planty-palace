import 'dart:io';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../helpers/plantnet_helper.dart';

class IdentifyPlantScreen extends StatefulWidget {
  const IdentifyPlantScreen({super.key});

  @override
  State<IdentifyPlantScreen> createState() => _IdentifyPlantScreenState();
}

class _IdentifyPlantScreenState extends State<IdentifyPlantScreen> {
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedImages = [];
  bool _isLoading = false;
  Map<String, dynamic>? _results;

  Future<void> _pickImage() async {
    if (_selectedImages.length >= 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Maximum 5 photos allowed')),
      );
      return;
    }
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImages.add(File(pickedFile.path));
      });
    }
  }

  Future<void> _identifyPlant() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _results = null;
    });

    final response = await PlantNetHelper.identifyPlant(images: _selectedImages);

    setState(() {
      _isLoading = false;
      _results = response;
    });
  }

  Widget _buildResults() {
    if (_results == null) return SizedBox.shrink();

    // Simplified example: display raw JSON string prettified
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(8),
        child: Text(
          JsonEncoder.withIndent('  ').convert(_results),
          style: TextStyle(fontFamily: 'monospace'),
        ),
      ),
    );
  }

  Widget _buildImagePreviews() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _selectedImages
          .map((file) => Stack(
                alignment: Alignment.topRight,
                children: [
                  Image.file(file, width: 80, height: 80, fit: BoxFit.cover),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedImages.remove(file);
                      });
                    },
                    child: CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.red,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  )
                ],
              ))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Identify Plant'),
      ),
      body: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            _buildImagePreviews(),
            SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: Icon(Icons.camera_alt),
                  label: Text('Add Photo'),
                ),
                SizedBox(width: 10),
                if (_selectedImages.length < 5)
                  ElevatedButton(
                    onPressed: _pickImage,
                    child: Text('Add More Photos?'),
                  ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _identifyPlant,
              child: _isLoading ? CircularProgressIndicator(color: Colors.white) : Text('Identify Plant'),
            ),
            SizedBox(height: 20),
            Expanded(child: _buildResults()),
          ],
        ),
      ),
    );
  }
}
