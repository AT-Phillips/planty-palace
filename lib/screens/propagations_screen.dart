import 'package:flutter/material.dart';

import '../models/propagation.dart';
import '../services/propagation_repository.dart';
import '../styles/app_theme.dart';
import '../utils/app_page_route.dart';
import '../utils/relative_time.dart';
import '../widgets/animated_entrance.dart';
import '../widgets/app_dialogs.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/primitives.dart';
import '../widgets/propagation_thumbnail.dart';
import '../widgets/shimmer.dart';
import 'add_edit_propagation_screen.dart';
import 'propagation_detail_screen.dart';

/// Lists every propagation (cuttings, divisions, etc.) - separate from full
/// Plants, with a path to promote a successful one into a real Plant.
class PropagationsScreen extends StatefulWidget {
  const PropagationsScreen({super.key});

  @override
  State<PropagationsScreen> createState() => _PropagationsScreenState();
}

class _PropagationsScreenState extends State<PropagationsScreen> {
  final PropagationRepository _repository = PropagationRepository();
  List<Propagation> _propagations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final propagations = await _repository.getPropagations();
      if (!mounted) return;
      setState(() {
        _propagations = propagations;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      debugPrint('Failed to load propagations: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_propagations.isEmpty) _error = '$e';
      });
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      appRoute(const AddEditPropagationScreen()),
    );
    if (result != null && mounted) _load();
  }

  Future<void> _navigateToDetail(Propagation propagation) async {
    final result = await Navigator.push(
      context,
      appRoute(PropagationDetailScreen(propagation: propagation)),
    );
    if (result == true && mounted) _load();
  }

  Widget _buildCard(Propagation propagation) {
    final p = context.palette;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: EdgeInsets.zero,
        onTap: () => _navigateToDetail(propagation),
        child: AppRow(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          leading: PropagationThumbnail(propagation: propagation),
          title: propagation.name,
          serifTitle: true,
          subtitle:
              '${propagation.method} · ${startedAgoText(propagation.startedAt)}',
          trailing:
              propagation.isPromoted
                  ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: p.fernSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Promoted',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: p.fern,
                      ),
                    ),
                  )
                  : Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: p.inkFaint,
                  ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // As on My Plants: the empty state has its own call to action, so the
    // floating pill stands down rather than duplicating it.
    final showFloatingAction =
        _loading || _error != null || _propagations.isNotEmpty;

    return Scaffold(
      appBar: const FrostedAppBar(title: 'Propagations'),
      body: _buildBody(),
      floatingActionButton:
          showFloatingAction
              ? FloatingActionPill(
                label: 'New cutting',
                onPressed: _navigateToAdd,
              )
              : null,
    );
  }

  Widget _buildBody() {
    if (_loading) return const CareListSkeleton(rows: 5);
    if (_error != null) {
      return AppErrorView(
        message:
            'Your propagations could not be loaded. Check your connection '
            'and try again.',
        onRetry: _load,
      );
    }
    if (_propagations.isEmpty) {
      return EmptyState(
        icon: Icons.eco_outlined,
        title: 'No propagations yet',
        message:
            'Track cuttings and divisions here, and promote them to full '
            'plants once they root.',
        actionLabel: 'Add a Propagation',
        onAction: _navigateToAdd,
      );
    }

    return RefreshIndicator.adaptive(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(Gap.screen, 12, Gap.screen, 96),
        itemCount: _propagations.length,
        itemBuilder:
            (context, index) => AnimatedEntrance(
              index: index,
              child: _buildCard(_propagations[index]),
            ),
      ),
    );
  }
}
