import 'dart:async';

import 'package:flutter/material.dart';

import '../services/perenual_service.dart';
import '../services/wikimedia_image_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/search_field.dart';
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
    try {
      final detail = await _service.fetchSpeciesDetail(summary.id);
      if (!mounted || detail == null) return;

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
            species: detail,
            fallbackImageUrl: fallbackImage?.url,
            fallbackImageAttribution: fallbackImage?.attribution,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingSpeciesId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Find'),
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
          if (!_searching && _results.isEmpty && !_searched)
            const Expanded(
              child: EmptyState(
                icon: Icons.travel_explore_outlined,
                title: 'Discover any plant',
                message: 'Search thousands of species for care info and facts - '
                    'whether or not it\'s already in your collection.',
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

  bool get _hasPerenualThumb =>
      widget.summary.thumbnailUrl != null && widget.summary.thumbnailUrl!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    if (!_hasPerenualThumb) _fetchFallback();
  }

  Future<void> _fetchFallback() async {
    final image = await WikimediaImageService().fetchImage(widget.summary.scientificName);
    if (!mounted) return;
    setState(() => _fallbackUrl = image?.url);
  }

  @override
  Widget build(BuildContext context) {
    final url = _hasPerenualThumb ? widget.summary.thumbnailUrl : _fallbackUrl;
    if (url == null) return const Icon(Icons.local_florist);

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        url,
        width: 44,
        height: 44,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => const Icon(Icons.local_florist),
      ),
    );
  }
}
