import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/audio_engine.dart';
import '../core/modulation_matrix.dart';
import '../core/modulation_metadata.dart';

class ModulationMatrixPanel extends StatefulWidget {
  const ModulationMatrixPanel({super.key});

  @override
  State<ModulationMatrixPanel> createState() => _ModulationMatrixPanelState();
}

class _ModulationMatrixPanelState extends State<ModulationMatrixPanel> {
  String? _selectedSource;
  String? _selectedDestination;
  double _pendingAmount = 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = Provider.of<AudioEngine>(context, listen: false);
    final sources = engine.modulationSourceDescriptors;
    final destinations = engine.modulationDestinationDescriptors;
    _selectedSource ??= sources.isNotEmpty ? sources.first.id : null;
    _selectedDestination ??=
        destinations.isNotEmpty ? destinations.first.id : null;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FractionallySizedBox(
      heightFactor: 0.85,
      child: SafeArea(
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF090B1F).withOpacity(0.95),
                const Color(0xFF040511).withOpacity(0.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF00FFFF).withOpacity(0.3),
              width: 1.5,
            ),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0xAA00FFFF),
                blurRadius: 24,
                spreadRadius: -12,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Consumer<AudioEngine>(
            builder: (context, engine, _) {
              final routes = engine.modulationRoutes;
              final sourceDescriptors = engine.modulationSourceDescriptors;
              final destinationDescriptors =
                  engine.modulationDestinationDescriptors;
              final sourceIds =
                  sourceDescriptors.map((descriptor) => descriptor.id).toList();
              final destinationIds = destinationDescriptors
                  .map((descriptor) => descriptor.id)
                  .toList();
              final depthBySource = engine.modulationDepthBySource;
              final depthByDestination = engine.modulationDepthByDestination;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Modulation Matrix',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    color: colorScheme.primary,
                                    letterSpacing: 1.2,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              routes.isEmpty
                                  ? 'Create modulation routes to bring the holographic engine alive.'
                                  : '${routes.length} active route${routes.length == 1 ? '' : 's'} syncing across the engine, presets and visualiser.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Close modulation matrix',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (depthBySource.isNotEmpty || depthByDestination.isNotEmpty)
                    _ModulationSummary(
                      sourceTotals: depthBySource,
                      destinationTotals: depthByDestination,
                    ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: routes.isEmpty
                        ? _buildEmptyState(colorScheme)
                        : ListView.separated(
                            padding: EdgeInsets.zero,
                            itemCount: routes.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final route = routes[index];
                              return _buildRouteCard(context, engine, route);
                            },
                          ),
                  ),
                  const SizedBox(height: 16),
                  _buildAddRouteCard(
                    engine: engine,
                    colorScheme: colorScheme,
                    sourceDescriptors: sourceDescriptors,
                    destinationDescriptors: destinationDescriptors,
                    sourceIds: sourceIds,
                    destinationIds: destinationIds,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, color: colorScheme.primary.withOpacity(0.7), size: 40),
          const SizedBox(height: 16),
          const Text(
            'No modulation routes yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.1,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Patch LFOs, performance controllers or envelopes into destinations
for evolving textures.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteCard(
    BuildContext context,
    AudioEngine engine,
    ModulationRoute route,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111327).withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${ModulationRoutingMetadata.labelForSource(route.source)} → '
                  '${ModulationRoutingMetadata.labelForDestination(route.destination)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Remove route',
                icon: const Icon(Icons.delete_outline, color: Colors.white70),
                onPressed: () {
                  engine.removeModulationRoute(route.source, route.destination);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Modulation route removed.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text(
                '-1',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                    inactiveTrackColor: Colors.white24,
                  ),
                  child: Slider(
                    min: -1,
                    max: 1,
                    divisions: 200,
                    value: route.amount.clamp(-1, 1).toDouble(),
                    label: route.amount.toStringAsFixed(2),
                    onChanged: (value) {
                      engine.setModulationRoute(
                        route.copyWith(amount: value),
                      );
                    },
                  ),
                ),
              ),
              const Text(
                '+1',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddRouteCard({
    required AudioEngine engine,
    required ColorScheme colorScheme,
    required List<ModulationSourceDescriptor> sourceDescriptors,
    required List<ModulationDestinationDescriptor> destinationDescriptors,
    required List<String> sourceIds,
    required List<String> destinationIds,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF141731).withOpacity(0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Create Route',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: colorScheme.secondary,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: sourceIds.contains(_selectedSource) ? _selectedSource : null,
                  items: sourceDescriptors
                      .map(
                        (descriptor) => DropdownMenuItem<String>(
                          value: descriptor.id,
                          child: _DropdownLabel(
                            title: descriptor.label,
                            subtitle: descriptor.description,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedSource = value),
                  decoration: const InputDecoration(
                    labelText: 'Source',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF111327),
                  style: const TextStyle(color: Colors.white),
                  isDense: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: destinationIds.contains(_selectedDestination)
                      ? _selectedDestination
                      : null,
                  items: destinationDescriptors
                      .map(
                        (descriptor) => DropdownMenuItem<String>(
                          value: descriptor.id,
                          child: _DropdownLabel(
                            title: descriptor.label,
                            subtitle: descriptor.description,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _selectedDestination = value),
                  decoration: const InputDecoration(
                    labelText: 'Destination',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  dropdownColor: const Color(0xFF111327),
                  style: const TextStyle(color: Colors.white),
                  isDense: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text(
                'Amount',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 4,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                  ),
                  child: Slider(
                    min: -1,
                    max: 1,
                    divisions: 200,
                    value: _pendingAmount,
                    label: _pendingAmount.toStringAsFixed(2),
                    onChanged: (value) => setState(() => _pendingAmount = value),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.add),
                  onPressed: () => _onAddRoute(engine),
                  label: const Text('Add route'),
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: engine.modulationRoutes.isEmpty
                    ? null
                    : () {
                        final cleared = engine.clearModulationRoutes();
                        if (cleared) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('All modulation routes cleared.')),
                          );
                        }
                      },
                child: const Text('Clear all'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onAddRoute(AudioEngine engine) {
    final source = _selectedSource;
    final destination = _selectedDestination;
    if (source == null || destination == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a source and destination first.')),
      );
      return;
    }

    final route = ModulationRoute(
      source: source,
      destination: destination,
      amount: _pendingAmount,
    );

    final changed = engine.setModulationRoute(route);
    if (!changed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Route already exists with this amount.')),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${ModulationRoutingMetadata.labelForSource(source)} now modulates '
          '${ModulationRoutingMetadata.labelForDestination(destination)}',
        ),
      ),
    );
  }
}

class _ModulationSummary extends StatelessWidget {
  const _ModulationSummary({
    required this.sourceTotals,
    required this.destinationTotals,
  });

  final Map<String, double> sourceTotals;
  final Map<String, double> destinationTotals;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (sourceTotals.isNotEmpty)
          _buildChipGroup(
            context,
            label: 'Source activity',
            entries: sourceTotals,
            labelFormatter: ModulationRoutingMetadata.labelForSource,
          ),
        if (destinationTotals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: _buildChipGroup(
              context,
              label: 'Destination depth',
              entries: destinationTotals,
              labelFormatter: ModulationRoutingMetadata.labelForDestination,
            ),
          ),
      ],
    );
  }

  Widget _buildChipGroup(
    BuildContext context, {
    required String label,
    required Map<String, double> entries,
    required String Function(String) labelFormatter,
  }) {
    final sortedEntries = entries.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.5,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: sortedEntries
              .map(
                (entry) => Chip(
                  backgroundColor: const Color(0xFF1A1D39),
                  label: Text(
                    '${labelFormatter(entry.key)} ${entry.value.toStringAsFixed(2)}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _DropdownLabel extends StatelessWidget {
  const _DropdownLabel({
    required this.title,
    this.subtitle,
  });

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: const TextStyle(color: Colors.white)),
        if (subtitle != null && subtitle!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              subtitle!,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ),
      ],
    );
  }
}
