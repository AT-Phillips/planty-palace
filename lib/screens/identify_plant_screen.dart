import 'dart:io';

import 'package:flutter/material.dart';
import 'package:planty_palace/styles/app_theme.dart';
import 'package:planty_palace/widgets/organ_toggle.dart';
import 'package:planty_palace/widgets/identify_button.dart';
import 'package:planty_palace/widgets/camera_capture_area.dart';

class IdentifyPlantScreen extends StatefulWidget {
  const IdentifyPlantScreen({Key? key}) : super(key: key);

  @override
  State<IdentifyPlantScreen> createState() => _IdentifyPlantScreenState();
}

class _IdentifyPlantScreenState extends State<IdentifyPlantScreen> {
  String _selectedOrgan = 'leaf';
  bool _showResultPreview = false;
  File? _pickedImage;

  void _onOrganChanged(String organ) {
    setState(() {
      _selectedOrgan = organ;
    });
  }

  void _onIdentifyPressed() {
    if (_pickedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please take a photo first.')),
      );
      return;
    }

    setState(() {
      _showResultPreview = true;
    });

    // TODO: Call Pl@ntNet service using _pickedImage and _selectedOrgan
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Identify Plant'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CameraCaptureArea(
              onImagePicked: (File image) {
                setState(() {
                  _pickedImage = image;
                  _showResultPreview = false;
                });
              },
            ),
            const SizedBox(height: 20),
            OrganToggle(
              selectedOrgan: _selectedOrgan,
              onChanged: _onOrganChanged,
            ),
            const SizedBox(height: 20),
            IdentifyButton(onPressed: _onIdentifyPressed),
            const SizedBox(height: 30),
            AnimatedOpacity(
              opacity: _showResultPreview ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: _showResultPreview
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Text(
                        'Result preview will show up here...',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
