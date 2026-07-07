import 'package:flutter/material.dart';

import '../services/perenual_service.dart';
import '../services/plant_repository.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/shimmer.dart';
import 'add_edit_plant_screen.dart';

/// Read-only reference view for a species from Perenual's catalog - shown
/// whether or not the plant is already in the user's collection. Works
/// purely as a lookup, with an optional "Add to My Plants" action.
class SpeciesDetailScreen extends StatelessWidget {
  final PerenualSpeciesDetail species;

  /// Shown only when Perenual had no image for this species - sourced from
  /// Wikimedia Commons (see [WikimediaImageService]), which requires visible
  /// attribution as a condition of the image's license.
  final String? fallbackImageUrl;
  final String? fallbackImageAttribution;

  /// True when full care details couldn't be loaded (Perenual free-tier
  /// lock, or a network failure) and this screen is showing only the basics
  /// from the search result - surfaces a gentle note instead of looking like
  /// the species simply has no care info.
  final bool detailUnavailable;

  /// Matches the search-result thumbnail's Hero tag so the photo animates
  /// smoothly from the list into this screen.
  final Object? heroTag;

  const SpeciesDetailScreen({
    super.key,
    required this.species,
    this.fallbackImageUrl,
    this.fallbackImageAttribution,
    this.detailUnavailable = false,
    this.heroTag,
  });

  Future<void> _addToMyPlants(BuildContext context) async {
    final gardenId = await PlantRepository().getOrCreateDefaultGardenId();
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddEditPlantScreen(
          gardenId: gardenId,
          prefillSpecies: species.scientificName,
          prefillCareInstructions:
              species.careInstructions.isEmpty ? null : species.careInstructions,
          prefillWateringIntervalDays: species.wateringIntervalDays,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasFacts = species.description != null ||
        species.origin != null ||
        species.family != null ||
        species.poisonousToHumans != null ||
        species.poisonousToPets != null;
    final speciesImageUrl =
        (species.imageUrl != null && species.imageUrl!.isNotEmpty) ? species.imageUrl : null;
    final displayImageUrl = speciesImageUrl ?? fallbackImageUrl;
    final usingFallbackImage = speciesImageUrl == null && fallbackImageUrl != null;

    return Scaffold(
      appBar: FrostedAppBar(title: species.commonName ?? species.scientificName),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (displayImageUrl != null) ...[
            _HeroImage(
              tag: heroTag,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  displayImageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  cacheWidth: 1080,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) return child;
                    return const ShimmerLoading(
                      child: SkeletonBox(
                        height: 220,
                        borderRadius: BorderRadius.all(Radius.circular(20)),
                      ),
                    );
                  },
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            if (usingFallbackImage && fallbackImageAttribution != null) ...[
              const SizedBox(height: 4),
              Text(
                'Photo: $fallbackImageAttribution',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
              ),
            ],
          ],
          const SizedBox(height: 16),
          Text(
            species.scientificName,
            style: const TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w700, fontSize: 18),
          ),
          if (species.commonName != null)
            Text(species.commonName!, style: TextStyle(color: scheme.onSurfaceVariant)),
          if (detailUnavailable) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 20, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Detailed care info isn't available for this species yet. "
                      'You can still add it and set your own care schedule.',
                      style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (species.careInstructions.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Care Info', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
            const SizedBox(height: 8),
            Text(species.careInstructions),
          ],
          if (hasFacts) ...[
            const SizedBox(height: 20),
            Text('Facts', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
            const SizedBox(height: 8),
            if (species.description != null) ...[
              Text(species.description!),
              const SizedBox(height: 8),
            ],
            if (species.family != null) Text('Family: ${species.family}'),
            if (species.origin != null) Text('Origin: ${species.origin}'),
            if (species.poisonousToHumans != null)
              Text('Toxic to humans: ${species.poisonousToHumans! ? 'Yes' : 'No'}'),
            if (species.poisonousToPets != null)
              Text('Toxic to pets: ${species.poisonousToPets! ? 'Yes' : 'No'}'),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _addToMyPlants(context),
            icon: const Icon(Icons.add),
            label: const Text('Add to My Plants'),
          ),
        ],
      ),
    );
  }
}

/// Wraps the detail photo in a [Hero] when a tag is provided (so it animates
/// from the search-result thumbnail), or returns it unchanged otherwise.
class _HeroImage extends StatelessWidget {
  final Object? tag;
  final Widget child;

  const _HeroImage({required this.tag, required this.child});

  @override
  Widget build(BuildContext context) {
    if (tag == null) return child;
    return Hero(tag: tag!, child: child);
  }
}
