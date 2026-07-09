import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../services/perenual_service.dart';
import '../services/species_cache_service.dart';
import '../services/wikimedia_image_service.dart';
import '../widgets/account_button.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/search_field.dart';
import '../widgets/shimmer.dart';
import '../widgets/weather_appbar_chip.dart';
import 'species_detail_screen.dart';

// Real taxonomic/common group words, not attribute filters (e.g. not "Low
// light" or "Pet-safe") - Perenual's search is a plain text match against
// species names, so a query has to actually be a name-ish term to return
// anything.
const _categoryChips = ['Succulent', 'Fern', 'Cactus', 'Orchid', 'Palm', 'Ivy'];

// A curated, well-covered starting set - not real usage/trending data (this
// app doesn't track that), so framed honestly as "Popular houseplants".
const _popularSpeciesNames = [
  'Monstera deliciosa',
  'Epipremnum aureum',
  'Sansevieria trifasciata',
  'Ficus lyrata',
  'Zamioculcas zamiifolia',
  'Pilea peperomioides',
];

const _plantFacts = [
  "Monstera deliciosa's iconic leaf holes let light reach its lower leaves in a dense rainforest canopy.",
  'Pothos is one of the few houseplants that tolerates low light for long stretches, though it grows fastest in bright, indirect light.',
  'Snake plants release oxygen at night as well as during the day, unlike most plants.',
  "A ZZ plant's thick rhizomes store water, letting it comfortably go weeks between waterings.",
  'Air plants absorb water and nutrients through their leaves rather than through roots.',
  'Most houseplant root rot comes from overwatering, not underwatering - soggy soil suffocates roots of oxygen.',
  'Rotating a plant a quarter turn every week or two helps it grow evenly instead of leaning toward the light.',
  'Many succulents evolved thick, water-storing leaves as a drought adaptation, not because they dislike water entirely.',
];

/// Live, as-you-type search across Perenual's species catalog - a reference
/// lookup independent of the user's own collection (no photo/camera
/// involved), with an "Add to My Plants" action from the result detail.
class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final PerenualService _service = PerenualService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<PerenualSpeciesSummary> _results = [];
  bool _searching = false;
  bool _searched = false;
  String? _error;

  /// Guards against duplicate detail-screen pushes from rapid/repeated taps,
  /// and doubles as which row shows a loading indicator while its fetch is
  /// in flight.
  int? _openingSpeciesId;

  List<RecentSpecies> _recent = [];
  List<PerenualSpeciesSummary> _popular = [];
  late final String _fact = _plantFacts[Random().nextInt(_plantFacts.length)];

  @override
  void initState() {
    super.initState();
    _loadRecent();
    _loadPopular();
  }

  Future<void> _loadRecent() async {
    final recent = await SpeciesCacheService.instance.getRecent();
    if (mounted) setState(() => _recent = recent);
  }

  /// Resolves the curated "Popular houseplants" names to real Perenual
  /// results (for a thumbnail + working tap-through) - one cached search per
  /// name, run in parallel. A name that fails to resolve is just omitted
  /// rather than shown broken.
  Future<void> _loadPopular() async {
    final results = await Future.wait(
      _popularSpeciesNames.map((name) async {
        try {
          final matches = await _service.searchSpecies(name);
          return matches.isEmpty ? null : matches.first;
        } catch (_) {
          return null;
        }
      }),
    );
    if (!mounted) return;
    setState(() => _popular = results.whereType<PerenualSpeciesSummary>().toList());
  }

  void _searchCategory(String label) {
    _controller.text = label;
    _search(label);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () => _search(query));
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _results = [];
        _searched = false;
      });
      return;
    }

    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await _service.searchSpecies(query);
      if (!mounted) return;
      // Dedupe by id so no two rows share a species Hero tag (and to drop
      // any duplicate results Perenual occasionally returns).
      final seen = <int>{};
      results.retainWhere((r) => seen.add(r.id));
      setState(() {
        _results = results;
        _searching = false;
        _searched = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searching = false;
        _searched = true;
        _error = e.toString();
      });
    }
  }

  Future<void> _openSpecies(PerenualSpeciesSummary summary) async {
    if (_openingSpeciesId != null) return;
    setState(() => _openingSpeciesId = summary.id);
    try {
      var detail = await _service.fetchSpeciesDetail(summary.id);
      var detailUnavailable = false;

      if (detail != null) {
        unawaited(SpeciesCacheService.instance.recordViewed(summary, detail));
        unawaited(_loadRecent());
      } else {
        // Perenual's free tier locks full details for many species (esp.
        // cultivars), and the network can fail - fall back to a previously-
        // viewed copy, or to a minimal record built from the search result,
        // so tapping a result always opens something rather than dead-ending.
        detail = await SpeciesCacheService.instance.getCachedDetail(summary.id);
        if (detail == null) {
          detail = PerenualSpeciesDetail(
            scientificName: summary.scientificName,
            commonName: summary.commonName,
            imageUrl: summary.thumbnailUrl,
            wateringIntervalDays: null,
            careInstructions: '',
          );
          detailUnavailable = true;
        }
      }

      WikimediaImage? fallbackImage;
      final imageUrl = detail.imageUrl;
      if (imageUrl == null || imageUrl.isEmpty) {
        fallbackImage = await WikimediaImageService().fetchImage(detail.scientificName);
      }
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpeciesDetailScreen(
            species: detail!,
            fallbackImageUrl: fallbackImage?.url,
            fallbackImageAttribution: fallbackImage?.attribution,
            detailUnavailable: detailUnavailable,
            heroTag: 'species_${summary.id}',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingSpeciesId = null);
    }
  }

  /// What Find shows before any search is active - previously just a
  /// centered icon+message with a lot of unused space. Now genuinely
  /// browsable: recently viewed species (if any), a plant fact, real
  /// category shortcuts, and a curated (not usage-tracked - this app has no
  /// such data) starting set of well-known species. All shown together
  /// rather than recent-viewed replacing the rest, since viewing one plant
  /// shouldn't erase the browsing entry points.
  Widget _buildExplore(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (_recent.isNotEmpty) ...[
          Text('Recently viewed', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recent.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final entry = _recent[index];
                return SizedBox(
                  width: 96,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openSpecies(entry.summary),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: _SpeciesThumbnail(
                              key: ValueKey('recent_${entry.summary.id}'),
                              summary: entry.summary,
                              heroTag: 'species_${entry.summary.id}',
                              size: 96,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          entry.summary.commonName ?? entry.summary.scientificName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        Card(
          color: scheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome, size: 20, color: scheme.onPrimaryContainer),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _fact,
                    style: TextStyle(color: scheme.onPrimaryContainer, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text('Browse a category', style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final label in _categoryChips)
              ActionChip(label: Text(label), onPressed: () => _searchCategory(label)),
          ],
        ),
        if (_popular.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text('Popular houseplants', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          SizedBox(
            height: 132,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _popular.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final species = _popular[index];
                return SizedBox(
                  width: 96,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openSpecies(species),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: 96,
                            height: 96,
                            child: _SpeciesThumbnail(
                              key: ValueKey('popular_${species.id}'),
                              summary: species,
                              heroTag: 'species_${species.id}',
                              size: 96,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          species.commonName ?? species.scientificName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(
        title: 'Find',
        actions: [WeatherAppBarChip(), AccountButton()],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchField(
              controller: _controller,
              hintText: 'Search any plant species...',
              onChanged: _onChanged,
            ),
          ),
          if (_searching) const Expanded(child: SearchSkeletonList()),
          if (!_searching && _searched && _results.isEmpty && _error != null)
            Expanded(
              child: EmptyState(
                icon: Icons.error_outline,
                title: 'Search unavailable',
                message: _error!,
              ),
            ),
          if (!_searching && _searched && _results.isEmpty && _error == null)
            const Expanded(
              child: EmptyState(
                icon: Icons.search_off,
                title: 'No matches found',
                message: 'Try a different name or spelling.',
              ),
            ),
          if (!_searching && _results.isEmpty && !_searched)
            Expanded(child: _buildExplore(context)),
          if (!_searching && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final isOpening = _openingSpeciesId == result.id;
                  return ListTile(
                    leading: _SpeciesThumbnail(
                      key: ValueKey(result.id),
                      summary: result,
                      heroTag: 'species_${result.id}',
                    ),
                    title: Text(
                      result.scientificName,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle: result.commonName != null ? Text(result.commonName!) : null,
                    trailing: isOpening
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator.adaptive(strokeWidth: 2),
                          )
                        : null,
                    onTap: () => _openSpecies(result),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// List-row thumbnail for a search result: Perenual's image when present,
/// otherwise a lazily-fetched Wikimedia Commons fallback (mirrors the
/// detail screen's fallback), otherwise a generic icon.
class _SpeciesThumbnail extends StatefulWidget {
  final PerenualSpeciesSummary summary;
  final Object? heroTag;
  final double size;

  const _SpeciesThumbnail({
    super.key,
    required this.summary,
    this.heroTag,
    this.size = 44,
  });

  @override
  State<_SpeciesThumbnail> createState() => _SpeciesThumbnailState();
}

class _SpeciesThumbnailState extends State<_SpeciesThumbnail> {
  String? _fallbackUrl;
  bool _fallbackRequested = false;

  // Perenual's listed thumbnail URL sometimes 404s/expires even when
  // present - only trust it until it actually fails to load, then fall
  // back to Wikimedia the same as when it was missing outright.
  bool _perenualFailed = false;

  bool get _hasPerenualThumb =>
      widget.summary.thumbnailUrl != null && widget.summary.thumbnailUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasPerenualThumb) _fetchFallback();
  }

  Future<void> _fetchFallback() async {
    if (_fallbackRequested) return;
    _fallbackRequested = true;
    final image = await WikimediaImageService().fetchImage(widget.summary.scientificName);
    if (!mounted) return;
    setState(() => _fallbackUrl = image?.url);
  }

  void _onPerenualImageFailed() {
    if (_perenualFailed) return;
    _perenualFailed = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _fetchFallback();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usingPerenual = _hasPerenualThumb && !_perenualFailed;
    final url = usingPerenual ? widget.summary.thumbnailUrl : _fallbackUrl;
    if (url == null) return const Icon(Icons.local_florist);

    Widget image = ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: widget.size,
        height: widget.size,
        fit: BoxFit.cover,
        // Decode at roughly the on-screen size (at up to ~3x density)
        // instead of full resolution - much faster to load and lighter on
        // memory for a list of thumbnails.
        cacheWidth: (widget.size * 3).round(),
        errorBuilder: (_, __, ___) {
          if (usingPerenual) _onPerenualImageFailed();
          return const Icon(Icons.local_florist);
        },
      ),
    );

    if (widget.heroTag != null) {
      image = Hero(tag: widget.heroTag!, child: image);
    }
    return image;
  }
}
