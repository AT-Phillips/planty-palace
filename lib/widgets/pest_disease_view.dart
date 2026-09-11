import 'dart:async';

import 'package:flutter/material.dart';

import '../services/pest_disease_service.dart';
import 'empty_state.dart';
import 'search_field.dart';
import 'shimmer.dart';
import '../styles/app_theme.dart';
import 'primitives.dart';

/// Search for common pests and diseases (spider mites, powdery mildew, root
/// rot, etc.) with symptoms and treatment info. A bodyless view (no Scaffold)
/// so it can sit inside the Care tab's "Common Problems" section.
class PestDiseaseView extends StatefulWidget {
  const PestDiseaseView({super.key});

  @override
  State<PestDiseaseView> createState() => _PestDiseaseViewState();
}

class _PestDiseaseViewState extends State<PestDiseaseView> {
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
    return Column(
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
              message:
                  'Search common pests and diseases for symptoms and '
                  'how to treat them.',
            ),
          ),
        if (!_searching && _results.isNotEmpty)
          Expanded(
            child: ListView.builder(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              itemCount: _results.length,
              itemBuilder:
                  (context, index) => _PestDiseaseTile(info: _results[index]),
            ),
          ),
      ],
    );
  }
}

class _PestDiseaseTile extends StatelessWidget {
  final PestDiseaseInfo info;

  const _PestDiseaseTile({required this.info});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;

    return AppExpander(
      title: info.commonName,
      subtitle: info.scientificName ?? 'Common houseplant problem',
      leading: ClipRRect(
        borderRadius: AppRadius.smAll,
        child: SizedBox(
          width: 44,
          height: 44,
          child:
              info.imageUrl != null
                  ? Image.network(
                    info.imageUrl!,
                    fit: BoxFit.cover,
                    cacheWidth: 132,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => _fallback(p),
                  )
                  : _fallback(p),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (info.description != null) ...[
                Text(
                  info.description!,
                  style: TextStyle(
                    fontSize: 13.5,
                    height: 1.5,
                    color: p.inkSoft,
                  ),
                ),
                Gap.md,
              ],
              if (info.solution != null) ...[
                // The fix is what a worried plant owner opened this for, so
                // it gets its own tinted panel rather than a bold run-in
                // heading in the middle of the description.
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(13, 12, 13, 13),
                  decoration: BoxDecoration(
                    color: p.fernSoft,
                    borderRadius: AppRadius.mdAll,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.healing_outlined,
                            size: 15,
                            color: p.fern,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'WHAT TO DO',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                              color: p.fern,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 7),
                      Text(
                        info.solution!,
                        style: TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: p.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Gap.md,
              ],
              if (info.hostPlants.isNotEmpty)
                Text(
                  'Commonly affects: ${info.hostPlants.join(", ")}',
                  style: TextStyle(fontSize: 12.5, color: p.inkFaint),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _fallback(Palette p) => ColoredBox(
    color: p.amberSoft,
    child: Icon(Icons.bug_report_outlined, size: 20, color: p.amber),
  );
}
