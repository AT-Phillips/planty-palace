import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Ensures the given image file lives in permanent app storage, copying it
/// there if it currently points at a transient picker/cache location.
Future<File> ensurePermanentPlantImage(File file) async {
  final appDocDir = await getApplicationDocumentsDirectory();
  final plantImagesDir = Directory(p.join(appDocDir.path, 'plant_images'));

  if (p.isWithin(plantImagesDir.path, file.path)) {
    return file;
  }

  if (!await plantImagesDir.exists()) {
    await plantImagesDir.create(recursive: true);
  }

  final newPath = p.join(
    plantImagesDir.path,
    '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
  );
  return file.copy(newPath);
}
