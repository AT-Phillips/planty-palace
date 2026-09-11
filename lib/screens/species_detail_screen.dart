import 'package:flutter/material.dart';

import '../services/perenual_service.dart';
import '../services/plant_repository.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/plant_thumbnail.dart';
import '../widgets/primitives.dart';
import '../widgets/section_header.dart';
import '../widgets/shimmer.dart';
import '../widgets/wishlist_button.dart';
import 'add_edit_plant_screen.dart';

/// Read-only reference view for a species from Perenual's catalog - shown
/// whether or not the plant is already in the user's collection. Works purely
/// as a lookup, with an "Add to My Plants" action pinned to the bottom.
class SpeciesDetailScreen extends StatelessWidget {
  final PerenualSpeciesDetail species;

  /// Shown only when Perenual had no image for this species - sourced from
  /// Wikimedia Commons (see [WikimediaImageService]), which requires visible
  /// attribution as a condition of the image's license.
  final String? fallbackImageUrl;
  final String? fallbackImageAttribution;

  /// True when full care details couldn't be loaded (Perenual free-tier lock,
  /// or a network failure) and this screen is showing only the basics from
  /// the search result - surfaces a gentle note instead of looking like the
  /// species simply has no care info.
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
      appRoute(
        AddEditPlantScreen(
          gardenId: gardenId,
          prefillSpecies: species.scientificName,
          prefillCareInstructions:
              species.careInstructions.isEmpty
                  ? null
                  : species.careInstructions,
          prefillWateringIntervalDays: species.wateringIntervalDays,
        ),
      ),
    );
  }

  bool get _isToxic =>
      species.poisonousToHumans == true || species.poisonousToPets == true;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    final speciesImageUrl =
        (species.imageUrl != null && species.imageUrl!.isNotEmpty)
            ? species.imageUrl
            : null;
    final displayImageUrl = speciesImageUrl ?? fallbackImageUrl;
    final usingFallbackImage =
        speciesImageUrl == null && fallbackImageUrl != null;

    return Scaffold(
      // The name lives in the content as a large serif heading, so the bar
      // itself carries only the back affordance and the wishlist action.
      // Previously it repeated the common name verbatim, one line above the
      // heading that already said it.
      appBar: FrostedAppBar(
        title: '',
        actions: [
          WishlistButton(
            scientificName: species.scientificName,
            commonName: species.commonName,
            imageUrl: displayImageUrl,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 0, Gap.screen, 28),
        children: [
          _photo(context, displayImageUrl),
          if (usingFallbackImage && fallbackImageAttribution != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Photo: $fallbackImageAttribution',
                style: TextStyle(fontSize: 11, color: p.inkFaint),
              ),
            ),
          Gap.lg,
          Text(
            species.commonName ?? species.scientificName,
            style: AppTheme.plantNameStyle(context, size: 26),
          ),
          if (species.commonName != null) ...[
            const SizedBox(height: 3),
            Text(
              species.scientificName,
              style: TextStyle(
                fontStyle: FontStyle.italic,
                fontSize: 14,
                color: p.inkSoft,
              ),
            ),
          ],
          if (_isToxic) ...[
            Gap.md,
            _ToxicityBanner(
              humans: species.poisonousToHumans == true,
              pets: species.poisonousToPets == true,
            ),
          ],
          if (detailUnavailable) ...[
            Gap.md,
            AppCard(
              bordered: true,
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 18, color: p.inkFaint),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Detailed care info isn't available for this species "
                      'yet. You can still add it and set your own schedule.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: p.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (species.wateringIntervalDays != null) ...[
            Gap.lg,
            const SectionHeader('Suggested schedule'),
            AppCard(
              padding: EdgeInsets.zero,
              child: AppRow(
                padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: p.fernSoft,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    Icons.water_drop_outlined,
                    size: 17,
                    color: p.fern,
                  ),
                ),
                title: 'Water',
                subtitle: 'Roughly every ${species.wateringIntervalDays} days',
              ),
            ),
          ],
          if (species.careInstructions.isNotEmpty) ...[
            Gap.lg,
            const SectionHeader('Care info'),
            Text(
              species.careInstructions,
              style: TextStyle(fontSize: 14.5, height: 1.6, color: p.inkSoft),
            ),
          ],
          ..._facts(context),
        ],
      ),
      // Pinned rather than sitting at the end of the scroll: on a species
      // with a long description the add action was below the fold, which is
      // the one thing this screen exists to let you do.
      bottomNavigationBar: _addBar(context),
    );
  }

  Widget _photo(BuildContext context, String? url) {
    final placeholder = BotanicalPlaceholder(seed: species.scientificName.hashCode);

    Widget image = ClipRRect(
      borderRadius: AppRadius.xlAll,
      child: SizedBox(
        height: 230,
        width: double.infinity,
        // The botanical gradient sits underneath whatever happens with the
        // network, so a species with no artwork (or a failed load) still
        // reads as a designed screen rather than a blank slot.
        child: Stack(
          fit: StackFit.expand,
          children: [
            placeholder,
            if (url != null)
              Image.network(
                url,
                fit: BoxFit.cover,
                cacheWidth: 1080,
                frameBuilder: (context, child, frame, wasSync) {
                  if (wasSync || frame != null) return child;
                  return const ShimmerLoading(
                    child: SkeletonBox(height: 230),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );

    if (heroTag != null) image = Hero(tag: heroTag!, child: image);
    return image;
  }

  /// Family, origin and description, as labelled rows rather than a run of
  /// "Key: value" sentences.
  List<Widget> _facts(BuildContext context) {
    final p = context.palette;
    final rows = <(String, String)>[
      if (species.family != null) ('Family', species.family!),
      if (species.origin != null) ('Origin', species.origin!),
      if (species.poisonousToPets != null)
        ('Pets', species.poisonousToPets! ? 'Toxic' : 'Safe'),
      if (species.poisonousToHumans != null)
        ('Humans', species.poisonousToHumans! ? 'Toxic' : 'Safe'),
    ];
    if (rows.isEmpty && species.description == null) return const [];

    return [
      Gap.lg,
      const SectionHeader('Facts'),
      if (species.description != null) ...[
        Text(
          species.description!,
          style: TextStyle(fontSize: 14.5, height: 1.6, color: p.inkSoft),
        ),
        if (rows.isNotEmpty) Gap.md,
      ],
      if (rows.isNotEmpty)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: p.hairline),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          rows[i].$1,
                          style: TextStyle(fontSize: 13.5, color: p.inkSoft),
                        ),
                      ),
                      Text(
                        rows[i].$2,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color:
                              rows[i].$2 == 'Toxic' ? p.amber : p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
    ];
  }

  Widget _addBar(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(Gap.screen, 12, Gap.screen, 12),
      decoration: BoxDecoration(
        color: p.ground,
        border: Border(top: BorderSide(color: p.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: () => _addToMyPlants(context),
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Add to My Plants'),
            // Shape only - color and label typography come from the theme.
            style: FilledButton.styleFrom(
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(vertical: 15),
            ),
          ),
        ),
      ),
    );
  }
}

/// A toxicity warning, in amber rather than the destructive red.
///
/// Toxicity is a caution a pet or child owner needs to see before adding a
/// plant, not an error - so it uses the amber "due soon / take note" signal,
/// keeping red reserved for destructive actions. Previously it was a line of
/// body text reading "Toxic to pets: Yes", easy to scroll straight past.
class _ToxicityBanner extends StatelessWidget {
  final bool humans;
  final bool pets;

  const _ToxicityBanner({required this.humans, required this.pets});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final who =
        humans && pets
            ? 'people and pets'
            : (pets ? 'pets' : 'people');

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 12),
      decoration: BoxDecoration(
        color: p.amberSoft,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, size: 19, color: p.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Toxic if eaten by $who. Keep it out of reach.',
              style: TextStyle(fontSize: 13, height: 1.4, color: p.ink),
            ),
          ),
        ],
      ),
    );
  }
}
