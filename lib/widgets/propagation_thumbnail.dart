import 'dart:io';

import 'package:flutter/material.dart';

import '../models/propagation.dart';
import '../services/photo_storage_service.dart';

/// Shows a propagation's photo - mirrors [PlantThumbnail]'s resolution logic
/// exactly (local-first, download-fallback via PhotoStorageService).
class PropagationThumbnail extends StatefulWidget {
  final Propagation propagation;
  final double size;
  final BorderRadius borderRadius;

  const PropagationThumbnail({
    super.key,
    required this.propagation,
    this.size = 50,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  State<PropagationThumbnail> createState() => _PropagationThumbnailState();
}

class _PropagationThumbnailState extends State<PropagationThumbnail> {
  late Future<File?> _resolvedFile;

  @override
  void initState() {
    super.initState();
    _resolvedFile = _resolve();
  }

  Future<File?> _resolve() async {
    final localPath = widget.propagation.imagePath;
    if (localPath.isNotEmpty && await File(localPath).exists()) {
      return File(localPath);
    }

    final photoUrl = widget.propagation.photoUrl;
    if (photoUrl == null || photoUrl.isEmpty) return null;

    try {
      return await PhotoStorageService().ensureLocalCopy(widget.propagation.id!, photoUrl);
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
              return const Icon(Icons.eco_outlined);
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
