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

    setState(() => _searching = true);
    final results = await _service.searchSpecies(query);
    if (!mounted) return;
    setState(() {
      _results = results;
      _searching = false;
      _searched = true;
    });
  }

  Future<void> _openSpecies(PerenualSpeciesSummary summary) async {
    final detail = await _service.fetchSpeciesDetail(summary.id);
    if (!mounted || detail == null) return;

    WikimediaImage? fallbackImage;
    if (detail.imageUrl == null) {
      fallbackImage = await WikimediaImageService().fetchImage(detail.scientificName);
    }
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SpeciesDetailScreen(
          species: detail,
          fallbackImageUrl: fallbackImage?.url,
          fallbackImageAttribution: fallbackImage?.attribution,
        ),
      ),
    );
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
          if (!_searching && _searched && _results.isEmpty)
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
                  return ListTile(
                    leading: result.thumbnailUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              result.thumbnailUrl!,
                              width: 44,
                              height: 44,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.local_florist),
                            ),
                          )
                        : const Icon(Icons.local_florist),
                    title: Text(
                      result.scientificName,
                      style: const TextStyle(fontStyle: FontStyle.italic),
                    ),
                    subtitle: result.commonName != null ? Text(result.commonName!) : null,
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
