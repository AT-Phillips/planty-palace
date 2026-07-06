import 'package:flutter/material.dart';

import '../models/propagation.dart';
import '../services/propagation_repository.dart';
import '../utils/relative_time.dart';
import '../widgets/empty_state.dart';
import '../widgets/frosted_app_bar.dart';
import '../widgets/propagation_thumbnail.dart';
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
      });
    } catch (e) {
      debugPrint('Failed to load propagations: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _navigateToAdd() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddEditPropagationScreen()),
    );
    if (result != null && mounted) _load();
  }

  Future<void> _navigateToDetail(Propagation propagation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PropagationDetailScreen(propagation: propagation)),
    );
    if (result == true && mounted) _load();
  }

  Widget _buildCard(Propagation propagation) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: PropagationThumbnail(propagation: propagation),
        title: Text(propagation.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text('${propagation.method} · ${startedAgoText(propagation.startedAt)}'),
        trailing: propagation.isPromoted
            ? Chip(
                label: const Text('Promoted'),
                backgroundColor: scheme.primaryContainer,
                labelStyle: TextStyle(color: scheme.onPrimaryContainer),
              )
            : null,
        onTap: () => _navigateToDetail(propagation),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const FrostedAppBar(title: 'Propagations'),
      body: _loading
          ? const Center(child: CircularProgressIndicator.adaptive())
          : _propagations.isEmpty
              ? EmptyState(
                  icon: Icons.eco_outlined,
                  title: 'No propagations yet',
                  message: 'Track cuttings and divisions here, and promote them '
                      'to full plants once they root.',
                  actionLabel: 'Add a Propagation',
                  onAction: _navigateToAdd,
                )
              : ListView.builder(
                  itemCount: _propagations.length,
                  itemBuilder: (context, index) => _buildCard(_propagations[index]),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAdd,
        child: const Icon(Icons.add),
      ),
    );
  }
}
