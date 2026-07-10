import 'package:flutter/material.dart';

import '../services/wishlist_repository.dart';

/// Heart toggle that saves/removes a species from the user's wishlist. Owns
/// its own saved state so it can drop into stateless screens (e.g. the app
/// bar of SpeciesDetailScreen). Reflects the current state on first build and
/// updates optimistically on tap.
class WishlistButton extends StatefulWidget {
  final String scientificName;
  final String? commonName;
  final String? imageUrl;

  const WishlistButton({
    super.key,
    required this.scientificName,
    this.commonName,
    this.imageUrl,
  });

  @override
  State<WishlistButton> createState() => _WishlistButtonState();
}

class _WishlistButtonState extends State<WishlistButton> {
  final WishlistRepository _repository = WishlistRepository();
  bool _saved = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    try {
      final saved = await _repository.isSaved(widget.scientificName);
      if (mounted) setState(() => _saved = saved);
    } catch (e) {
      debugPrint('Failed to read wishlist state: $e');
    }
  }

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final nowSaved = await _repository.toggle(
        scientificName: widget.scientificName,
        commonName: widget.commonName,
        imageUrl: widget.imageUrl,
      );
      if (!mounted) return;
      setState(() => _saved = nowSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            nowSaved ? 'Added to your wishlist' : 'Removed from your wishlist',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Failed to update wishlist: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Couldn't update your wishlist.")),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: _busy ? null : _toggle,
      tooltip: _saved ? 'Remove from wishlist' : 'Save to wishlist',
      icon: Icon(
        _saved ? Icons.favorite : Icons.favorite_border,
        color: _saved ? scheme.primary : null,
      ),
    );
  }
}
