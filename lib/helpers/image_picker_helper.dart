// lib/helpers/image_picker_helper.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';

class ImagePickerHelper {
  static Future<File?> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera); // or .gallery

    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
}
