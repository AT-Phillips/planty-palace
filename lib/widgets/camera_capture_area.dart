import 'dart:io';
import 'package:flutter/material.dart';
import 'package:planty_palace/helpers/image_picker_helper.dart';
import 'package:planty_palace/styles/app_theme.dart';

class CameraCaptureArea extends StatefulWidget {
  final void Function(File image) onImagePicked;

  const CameraCaptureArea({super.key, required this.onImagePicked});

  @override
  State<CameraCaptureArea> createState() => _CameraCaptureAreaState();
}

class _CameraCaptureAreaState extends State<CameraCaptureArea> {
  File? _imageFile;

  Future<void> _pickImageFromCamera() async {
    final image = await ImagePickerHelper.pickImageFromCamera();
    if (image != null) {
      setState(() => _imageFile = image);
      widget.onImagePicked(image);
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: _pickImageFromCamera,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: double.infinity,
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
        ),
        child: _imageFile == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.camera_alt, size: 40, color: Colors.grey[700]),
                  const SizedBox(height: 8),
                  Text(
                    'Tap to take a photo',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  _imageFile!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                ),
              ),
      ),
    );
  }
}
