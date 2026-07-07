import 'dart:async';

import 'package:flutter/material.dart';

import '../services/perenual_service.dart';
import '../services/species_cache_service.dart';
import '../services/wikimedia_image_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/search_field.dart';
import 'pest_disease_screen.dart';
import 'species_detail_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    final recent = await SpeciesCacheService.instance.getRecent();
    if (mounted) setState(() => _recent = recent);
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
    var usedOfflineCache = false;
    try {
      var detail = await _service.fetchSpeciesDetail(summary.id);
      if (detail != null) {
        unawaited(SpeciesCacheService.instance.recordViewed(summary, detail));
        unawaited(_loadRecent());
      } else {
        // Live fetch reported "no data" rather than throwing - still worth
        // trying whatever was viewed before, same as an outright failure.
        detail = await SpeciesCacheService.instance.getCachedDetail(summary.id);
        usedOfflineCache = detail != null;
      }
      if (!mounted || detail == null) return;

      WikimediaImage? fallbackImage;
      final imageUrl = detail.imageUrl;
      if (!usedOfflineCache && (imageUrl == null || imageUrl.isEmpty)) {
        fallbackImage = await WikimediaImageService().fetchImage(detail.scientificName);
      }
      if (!mounted) return;

      if (usedOfflineCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Showing a previously-saved copy (offline or unavailable).')),
        );
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpeciesDetailScreen(
            species: detail!,
            fallbackImageUrl: fallbackImage?.url,
            fallbackImageAttribution: fallbackImage?.attribution,
          ),
        ),
      );
    } catch (_) {
      final cached = await SpeciesCacheService.instance.getCachedDetail(summary.id);
      if (!mounted) return;
      if (cached != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Showing a previously-saved copy (offline or unavailable).')),
        );
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SpeciesDetailScreen(species: cached)),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't load this plant's details. Try again.")),
        );
      }
    } finally {
      if (mounted) setState(() => _openingSpeciesId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: FrostedAppBar(
        title: 'Find',
        actions: [
          IconButton(
            icon: const Icon(Icons.bug_report_outlined),
            tooltip: 'Common Problems',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PestDiseaseScreen()),
            ),
          ),
        ],
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
          if (_searching) const Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator.adaptive(),
          ),
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
          if (!_searching && _results.isEmpty && !_searched && _recent.isEmpty)
            const Expanded(
              child: EmptyState(
                icon: Icons.travel_explore_outlined,
                title: 'Discover any plant',
                message: 'Search thousands of species for care info and facts - '
                    'whether or not it\'s already in your collection.',
              ),
            ),
          if (!_searching && _results.isEmpty && !_searched && _recent.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8),
                itemCount: _recent.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                      child: Text(
                        'Recently viewed',
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    );
                  }
                  final entry = _recent[index - 1];
                  return ListTile(
                    leading: _SpeciesThumbnail(
                      key: ValueKey('recent_${entry.summary.id}'),
                      summary: entry.summary,
                    ),
                    title: Text(
                      entry.summary.scientificName,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle:
                        entry.summary.commonName != null ? Text(entry.summary.commonName!) : null,
                    onTap: () => _openSpecies(entry.summary),
                  );
                },
              ),
            ),
          if (!_searching && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  final isOpening = _openingSpeciesId == result.id;
                  return ListTile(
                    leading: _SpeciesThumbnail(key: ValueKey(result.id), summary: result),
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

  const _SpeciesThumbnail({super.key, required this.summary});

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

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          if (usingPerenual) _onPerenualImageFailed();
          return const Icon(Icons.local_florist);
        },
      ),
    );
  }
}
