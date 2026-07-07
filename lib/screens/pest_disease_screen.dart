import 'dart:async';

import 'package:flutter/material.dart';

import '../services/pest_disease_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/search_field.dart';
import '../widgets/shimmer.dart';

/// Search for common pests and diseases (spider mites, powdery mildew,
/// root rot, etc.) - reference info independent of the user's own
/// collection, mirroring DiscoverScreen's search pattern.
class PestDiseaseScreen extends StatefulWidget {
  const PestDiseaseScreen({super.key});

  @override
  State<PestDiseaseScreen> createState() => _PestDiseaseScreenState();
}

class _PestDiseaseScreenState extends State<PestDiseaseScreen> {
  final PestDiseaseService _service = PestDiseaseService();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<PestDiseaseInfo> _results = [];
  bool _searching = false;
  bool _searched = false;
  String? _error;

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
    if (query.trim().isEmpty) return;

    setState(() {
      _searching = true;
      _error = null;
    });
    try {
      final results = await _service.search(query);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Common Problems'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SearchField(
              controller: _controller,
              hintText: 'Search pests or diseases...',
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
                message: 'Try a different name, like "aphids" or "root rot".',
              ),
            ),
          if (!_searching && _results.isEmpty && !_searched)
            const Expanded(
              child: EmptyState(
                icon: Icons.bug_report_outlined,
                title: 'Identify a problem',
                message: 'Search common pests and diseases for symptoms and '
                    'how to treat them.',
              ),
            ),
          if (!_searching && _results.isNotEmpty)
            Expanded(
              child: ListView.builder(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                itemCount: _results.length,
                itemBuilder: (context, index) {
                  final result = _results[index];
                  return _PestDiseaseTile(info: result);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _PestDiseaseTile extends StatelessWidget {
  final PestDiseaseInfo info;

  const _PestDiseaseTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ExpansionTile(
        leading: info.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  info.imageUrl!,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.bug_report_outlined),
                ),
              )
            : const Icon(Icons.bug_report_outlined),
        title: Text(info.commonName),
        subtitle: info.scientificName != null
            ? Text(info.scientificName!, style: const TextStyle(fontStyle: FontStyle.italic))
            : null,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (info.description != null) ...[
                  Text(info.description!),
                  const SizedBox(height: 12),
                ],
                if (info.solution != null) ...[
                  Text('Solution', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.primary)),
                  const SizedBox(height: 4),
                  Text(info.solution!),
                  const SizedBox(height: 12),
                ],
                if (info.hostPlants.isNotEmpty)
                  Text(
                    'Commonly affects: ${info.hostPlants.join(", ")}',
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
