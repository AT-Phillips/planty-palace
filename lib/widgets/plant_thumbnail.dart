import 'dart:io';

import 'package:flutter/material.dart';

import '../models/plant.dart';
import '../services/photo_storage_service.dart';

/// Shows a plant's photo, resolving it the same way regardless of whether
/// it's already cached locally or just synced in from another device:
/// - If [Plant.imagePath] already points at a file that exists on this
///   device, shows it immediately.
/// - Otherwise, if [Plant.photoUrl] is set (synced from Firestore/Storage
///   but never downloaded here), downloads and caches it first.
/// - Falls back to a plain icon if there's no photo at all, or the download
///   fails - never blocks the rest of the UI on a photo problem.
class PlantThumbnail extends StatefulWidget {
  final Plant plant;
  final double size;
  final BorderRadius borderRadius;

  const PlantThumbnail({
    super.key,
    required this.plant,
    this.size = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<PlantThumbnail> createState() => _PlantThumbnailState();
}

class _PlantThumbnailState extends State<PlantThumbnail> {
  late Future<File?> _resolvedFile;

  @override
  void initState() {
    super.initState();
    _resolvedFile = _resolve();
  }

  Future<File?> _resolve() async {
    final localPath = widget.plant.imagePath;
    if (localPath.isNotEmpty && await File(localPath).exists()) {
      return File(localPath);
    }

    final photoUrl = widget.plant.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return null;

    try {
      return await PhotoStorageService().ensureLocalCopy(widget.plant.id!, photoUrl);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: FutureBuilder<File?>(
          future: _resolvedFile,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                ),
              );
            }
            final file = snapshot.data;
            if (file == null) {
              return const Icon(Icons.local_florist);
            }
            return Image.file(
              file,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
            );
          },
        ),
      ),
    );
  }
}
