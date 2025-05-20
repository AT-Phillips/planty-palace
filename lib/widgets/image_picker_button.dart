// lib/widgets/image_picker_button.dart

import 'dart:io';

import 'package:flutter/material.dart';
import '../helpers/image_picker_helper.dart';

class ImagePickerButton extends StatelessWidget {
  final void Function(File pickedImage) onImagePicked;

  const ImagePickerButton({super.key, required this.onImagePicked});

  void _showPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () async {
                Navigator.of(context).pop();
                final image = await ImagePickerHelper.pickImageFromCamera();
                if (image != null) onImagePicked(image);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final image = await ImagePickerHelper.pickImageFromGallery();
                if (image != null) onImagePicked(image);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () => _showPicker(context),
      tooltip: 'Pick Image',
      child: const Icon(Icons.add_a_photo),
    );
  }
}
