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

  /// Override [size] independently per axis - e.g. a wide, short
  /// photo-forward card image. Both default to [size], so every existing
  /// square usage is unaffected.
  final double? width;
  final double? height;

  final BorderRadius borderRadius;

  /// When set, the thumbnail is wrapped in a [Hero] with this tag so the
  /// photo animates smoothly between a list and the plant's detail screen.
  /// The source and destination must use the same tag.
  final Object? heroTag;

  const PlantThumbnail({
    super.key,
    required this.plant,
    this.size = 50,
    this.width,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.heroTag,
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
      return await PhotoStorageService().ensureLocalCopy(
        widget.plant.id!,
        photoUrl,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.width ?? widget.size;
    final h = widget.height ?? widget.size;

    final content = ClipRRect(
      borderRadius: widget.borderRadius,
      child: SizedBox(
        width: w,
        height: h,
        child: FutureBuilder<File?>(
          future: _resolvedFile,
          builder: (context, snapshot) {
            // A lush botanical gradient always sits underneath - so a plant
            // with no photo (or one still resolving) reads as an intentional,
            // designed tile rather than an empty square with a lone icon.
            final placeholder = _PlantPlaceholder(seed: _seed);

            if (snapshot.connectionState != ConnectionState.done) {
              return placeholder;
            }
            final file = snapshot.data;
            if (file == null) return placeholder;

            // Photo fades in over the gradient once resolved.
            return Stack(
              fit: StackFit.expand,
              children: [
                placeholder,
                Image.file(
                  file,
                  fit: BoxFit.cover,
                  frameBuilder: (_, child, frame, wasSync) {
                    if (wasSync) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                  errorBuilder: (_, __, ___) => placeholder,
                ),
              ],
            );
          },
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(tag: widget.heroTag!, child: content);
    }
    return content;
  }

  /// A stable per-plant seed so each plant keeps the same placeholder gradient
  /// variant across rebuilds (rather than flickering between them).
  int get _seed => (widget.plant.id ?? widget.plant.name).hashCode;
}

/// The no-photo backdrop: one of a few hand-tuned botanical green gradients
/// (mirroring the visual-direction mockup's leaf tiles) with a faint leaf mark,
/// chosen deterministically from [seed] so every plant gets a consistent but
/// varied lush fill instead of a flat empty square.
class _PlantPlaceholder extends StatelessWidget {
  final int seed;

  const _PlantPlaceholder({required this.seed});

  static const List<List<Color>> _palettes = [
    [Color(0xFF4F9E6F), Color(0xFF21503A)],
    [Color(0xFF6BA86A), Color(0xFF2F5F3A)],
    [Color(0xFF8BBF7A), Color(0xFF46703F)],
    [Color(0xFF3F8F77), Color(0xFF1C4A45)],
    [Color(0xFF5AA07C), Color(0xFF244C3B)],
  ];

  static const List<Alignment> _centers = [
    Alignment(-0.4, -0.7),
    Alignment(0.4, -0.6),
    Alignment(-0.2, -0.5),
    Alignment(0.2, -0.8),
    Alignment(0.0, -0.6),
  ];

  @override
  Widget build(BuildContext context) {
    final i = seed.abs() % _palettes.length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final minSide = constraints.biggest.shortestSide;
        final iconSize = (minSide * 0.4).clamp(14.0, 88.0);
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: _centers[i],
              radius: 1.15,
              colors: _palettes[i],
            ),
          ),
          child: Center(
            child: Icon(
              Icons.eco,
              size: iconSize,
              color: Colors.white.withValues(alpha: 0.22),
            ),
          ),
        );
      },
    );
  }
}
