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
  String? _sourceCategoryFilter;
  String? _destinationCategoryFilter;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final engine = Provider.of<AudioEngine>(context, listen: false);
    final sources = engine.modulationSourceDescriptors;
    final destinations = engine.modulationDestinationDescriptors;
    if (_selectedSource != null &&
        sources.every((descriptor) => descriptor.id != _selectedSource)) {
      _selectedSource = _resolveInitialSourceId(sources);
    } else {
      _selectedSource ??= _resolveInitialSourceId(sources);
    }
    if (_selectedDestination != null &&
        destinations
            .every((descriptor) => descriptor.id != _selectedDestination)) {
      _selectedDestination = _resolveInitialDestinationId(destinations);
    } else {
      _selectedDestination ??=
          _resolveInitialDestinationId(destinations);
    }
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
    final sourceDescriptor =
        ModulationRoutingMetadata.descriptorForSource(route.source);
    final destinationDescriptor =
        ModulationRoutingMetadata.descriptorForDestination(route.destination);

    final tooltipSegments = <String>[];
    if (sourceDescriptor != null && sourceDescriptor.description.isNotEmpty) {
      tooltipSegments.add(
        '${sourceDescriptor.label}: ${sourceDescriptor.description}',
      );
    }
    if (destinationDescriptor != null &&
        destinationDescriptor.description.isNotEmpty) {
      tooltipSegments.add(
        '${destinationDescriptor.label}: ${destinationDescriptor.description}',
      );
    }
    final tooltip = tooltipSegments.isEmpty ? null : tooltipSegments.join('
');

    final titleText = Text(
      '${ModulationRoutingMetadata.labelForSource(route.source)} → '
      '${ModulationRoutingMetadata.labelForDestination(route.destination)}',
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

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
                child: tooltip == null
                    ? titleText
                    : Tooltip(
                        message: tooltip,
                        waitDuration: const Duration(milliseconds: 600),
                        child: titleText,
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
          if (sourceDescriptor != null || destinationDescriptor != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (sourceDescriptor != null)
                    _buildCategoryChip(
                      icon: Icons.settings_input_component,
                      label:
                          'Source · ${sourceDescriptor.category.isEmpty ? 'General' : sourceDescriptor.category}',
                      colorScheme: colorScheme,
                    ),
                  if (destinationDescriptor != null)
                    _buildCategoryChip(
                      icon: Icons.ads_click,
                      label:
                          'Destination · ${destinationDescriptor.category.isEmpty ? 'General' : destinationDescriptor.category}',
                      colorScheme: colorScheme,
                    ),
                ],
              ),
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

  Widget _buildCategoryChip({
    required IconData icon,
    required String label,
    required ColorScheme colorScheme,
  }) {
    return Chip(
      backgroundColor: const Color(0xFF1A1D39),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      avatar: Icon(icon, size: 14, color: colorScheme.primary),
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 11),
      ),
    );
  }

  Widget _buildAddRouteCard({
    required AudioEngine engine,
    required ColorScheme colorScheme,
    required List<ModulationSourceDescriptor> sourceDescriptors,
    required List<ModulationDestinationDescriptor> destinationDescriptors,
  }) {
    final selectedSourceDescriptor = _selectedSource == null
        ? null
        : ModulationRoutingMetadata.descriptorForSource(_selectedSource!);
    final selectedDestinationDescriptor = _selectedDestination == null
        ? null
        : ModulationRoutingMetadata.descriptorForDestination(
            _selectedDestination!,
          );
    final sourceCategories =
        ModulationRoutingMetadata.categoriesForSources(sourceDescriptors);
    final destinationCategories =
        ModulationRoutingMetadata.categoriesForDestinations(
      destinationDescriptors,
    );
    final suggestions = ModulationRoutingMetadata.suggestedRoutes(
      sourceCategory: _sourceCategoryFilter,
      destinationCategory: _destinationCategoryFilter,
    );

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
          if (sourceCategories.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildCategoryFilters(
                label: 'Focus sources',
                categories: sourceCategories,
                activeCategory: _sourceCategoryFilter,
                onCategorySelected: (category) {
                  setState(() {
                    final toggled =
                        _sourceCategoryFilter == category ? null : category;
                    _sourceCategoryFilter = toggled;
                    if (toggled != null) {
                      final descriptor = _selectedSource == null
                          ? null
                          : ModulationRoutingMetadata
                              .descriptorForSource(_selectedSource!);
                      if (descriptor == null ||
                          descriptor.category != toggled) {
                        _selectedSource =
                            _firstSourceIdForCategory(sourceDescriptors, toggled);
                      }
                    } else {
                      if (_selectedSource == null &&
                          sourceDescriptors.isNotEmpty) {
                        _selectedSource = sourceDescriptors.first.id;
                      }
                    }
                  });
                },
              ),
            ),
          if (destinationCategories.length > 1)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildCategoryFilters(
                label: 'Focus destinations',
                categories: destinationCategories,
                activeCategory: _destinationCategoryFilter,
                onCategorySelected: (category) {
                  setState(() {
                    final toggled =
                        _destinationCategoryFilter == category ? null : category;
                    _destinationCategoryFilter = toggled;
                    if (toggled != null) {
                      final descriptor = _selectedDestination == null
                          ? null
                          : ModulationRoutingMetadata.descriptorForDestination(
                              _selectedDestination!,
                            );
                      if (descriptor == null ||
                          descriptor.category != toggled) {
                        _selectedDestination = _firstDestinationIdForCategory(
                          destinationDescriptors,
                          toggled,
                        );
                      }
                    } else {
                      if (_selectedDestination == null &&
                          destinationDescriptors.isNotEmpty) {
                        _selectedDestination = destinationDescriptors.first.id;
                      }
                    }
                  });
                },
              ),
            ),
          if (suggestions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildSuggestionSection(
                context,
                suggestions: suggestions,
                colorScheme: colorScheme,
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _SourceAutocompleteField(
                  descriptors: sourceDescriptors,
                  selectedId: _selectedSource,
                  categoryFilter: _sourceCategoryFilter,
                  onSelected: (value) => setState(() => _selectedSource = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DestinationAutocompleteField(
                  descriptors: destinationDescriptors,
                  selectedId: _selectedDestination,
                  categoryFilter: _destinationCategoryFilter,
                  onSelected: (value) =>
                      setState(() => _selectedDestination = value),
                ),
              ),
            ],
          ),
          if (selectedSourceDescriptor != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _SelectionInsight(
                title: 'Source',
                category: selectedSourceDescriptor.category,
                description: selectedSourceDescriptor.description,
              ),
            ),
          if (selectedDestinationDescriptor != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _SelectionInsight(
                title: 'Destination',
                category: selectedDestinationDescriptor.category,
                description: selectedDestinationDescriptor.description,
              ),
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
                            const SnackBar(
                              content: Text('All modulation routes cleared.'),
                            ),
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

  String? _resolveInitialSourceId(
    List<ModulationSourceDescriptor> descriptors,
  ) {
    if (descriptors.isEmpty) {
      return null;
    }
    final filter = _sourceCategoryFilter;
    if (filter == null) {
      return descriptors.first.id;
    }
    return _firstSourceIdForCategory(descriptors, filter) ?? descriptors.first.id;
  }

  String? _resolveInitialDestinationId(
    List<ModulationDestinationDescriptor> descriptors,
  ) {
    if (descriptors.isEmpty) {
      return null;
    }
    final filter = _destinationCategoryFilter;
    if (filter == null) {
      return descriptors.first.id;
    }
    return _firstDestinationIdForCategory(descriptors, filter) ??
        descriptors.first.id;
  }

  String? _firstSourceIdForCategory(
    List<ModulationSourceDescriptor> descriptors,
    String category,
  ) {
    for (final descriptor in descriptors) {
      if (descriptor.category == category) {
        return descriptor.id;
      }
    }
    return null;
  }

  String? _firstDestinationIdForCategory(
    List<ModulationDestinationDescriptor> descriptors,
    String category,
  ) {
    for (final descriptor in descriptors) {
      if (descriptor.category == category) {
        return descriptor.id;
      }
    }
    return null;
  }

  Widget _buildSuggestionSection(
    BuildContext context, {
    required List<ModulationRouteSuggestion> suggestions,
    required ColorScheme colorScheme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick suggestions',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.2,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: suggestions.map((suggestion) {
            final label =
                '${suggestion.sourceLabel} → ${suggestion.destinationLabel}';
            final chip = ActionChip(
              backgroundColor: const Color(0xFF1A1D39),
              avatar: Icon(
                Icons.auto_awesome,
                color: colorScheme.primary,
                size: 18,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              label: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onPressed: () => _applySuggestion(suggestion),
            );

            if (suggestion.description.isEmpty) {
              return chip;
            }

            return Tooltip(
              message: suggestion.description,
              waitDuration: const Duration(milliseconds: 400),
              child: chip,
            );
          }).toList(growable: false),
        ),
      ],
    );
  }

  void _applySuggestion(ModulationRouteSuggestion suggestion) {
    setState(() {
      _selectedSource = suggestion.sourceId;
      _selectedDestination = suggestion.destinationId;
      _pendingAmount = suggestion.defaultAmount.clamp(-1.0, 1.0).toDouble();

      if (suggestion.sourceCategory.isNotEmpty) {
        _sourceCategoryFilter = suggestion.sourceCategory;
      }
      if (suggestion.destinationCategory.isNotEmpty) {
        _destinationCategoryFilter = suggestion.destinationCategory;
      }
    });

    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            '${suggestion.sourceLabel} primed → ${suggestion.destinationLabel} '
            'at ${suggestion.defaultAmount.toStringAsFixed(2)}',
          ),
        ),
      );
  }

  Widget _buildCategoryFilters({
    required String label,
    required List<String> categories,
    required String? activeCategory,
    required ValueChanged<String> onCategorySelected,
  }) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.white70,
                letterSpacing: 1.4,
              ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map(
                (category) => ChoiceChip(
                  label: Text(category),
                  selected: activeCategory == category,
                  labelStyle: TextStyle(
                    color:
                        activeCategory == category ? Colors.black : Colors.white,
                  ),
                  selectedColor: Theme.of(context).colorScheme.secondary,
                  backgroundColor: const Color(0xFF1A1D39),
                  onSelected: (_) => onCategorySelected(category),
                ),
              )
              .toList(),
        ),
      ],
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

class _DescriptorOption {
  const _DescriptorOption({
    required this.id,
    required this.label,
    required this.category,
    required this.description,
  });

  final String id;
  final String label;
  final String category;
  final String description;
}

class _SourceAutocompleteField extends StatelessWidget {
  const _SourceAutocompleteField({
    required this.descriptors,
    required this.selectedId,
    required this.onSelected,
    required this.categoryFilter,
  });

  final List<ModulationSourceDescriptor> descriptors;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? categoryFilter;

  @override
  Widget build(BuildContext context) {
    final allowedIds = descriptors.map((descriptor) => descriptor.id).toSet();
    return _DescriptorAutocompleteField(
      labelText: 'Source',
      leadingIcon: Icons.settings_input_component,
      selectedId: selectedId,
      labelResolver: ModulationRoutingMetadata.labelForSource,
      optionsBuilder: (query) =>
          ModulationRoutingMetadata.searchSources(query)
              .where((descriptor) => allowedIds.contains(descriptor.id))
              .where(
                (descriptor) =>
                    categoryFilter == null ||
                    descriptor.category == categoryFilter,
              )
              .map(
                (descriptor) => _DescriptorOption(
                  id: descriptor.id,
                  label: descriptor.label,
                  category: descriptor.category,
                  description: descriptor.description,
                ),
              ),
      onSelected: onSelected,
    );
  }
}

class _DestinationAutocompleteField extends StatelessWidget {
  const _DestinationAutocompleteField({
    required this.descriptors,
    required this.selectedId,
    required this.onSelected,
    required this.categoryFilter,
  });

  final List<ModulationDestinationDescriptor> descriptors;
  final String? selectedId;
  final ValueChanged<String?> onSelected;
  final String? categoryFilter;

  @override
  Widget build(BuildContext context) {
    final allowedIds = descriptors.map((descriptor) => descriptor.id).toSet();
    return _DescriptorAutocompleteField(
      labelText: 'Destination',
      leadingIcon: Icons.ads_click,
      selectedId: selectedId,
      labelResolver: ModulationRoutingMetadata.labelForDestination,
      optionsBuilder: (query) =>
          ModulationRoutingMetadata.searchDestinations(query)
              .where((descriptor) => allowedIds.contains(descriptor.id))
              .where(
                (descriptor) =>
                    categoryFilter == null ||
                    descriptor.category == categoryFilter,
              )
              .map(
                (descriptor) => _DescriptorOption(
                  id: descriptor.id,
                  label: descriptor.label,
                  category: descriptor.category,
                  description: descriptor.description,
                ),
              ),
      onSelected: onSelected,
    );
  }
}

class _DescriptorAutocompleteField extends StatefulWidget {
  const _DescriptorAutocompleteField({
    required this.labelText,
    required this.leadingIcon,
    required this.selectedId,
    required this.optionsBuilder,
    required this.onSelected,
    this.labelResolver,
  });

  final String labelText;
  final IconData leadingIcon;
  final String? selectedId;
  final Iterable<_DescriptorOption> Function(String query) optionsBuilder;
  final ValueChanged<String?> onSelected;
  final String Function(String id)? labelResolver;

  @override
  State<_DescriptorAutocompleteField> createState() =>
      _DescriptorAutocompleteFieldState();
}

class _DescriptorAutocompleteFieldState
    extends State<_DescriptorAutocompleteField> {
  TextEditingController? _controller;

  @override
  void didUpdateWidget(covariant _DescriptorAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedId != widget.selectedId) {
      _syncControllerWithSelection();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Autocomplete<_DescriptorOption>(
      displayStringForOption: (option) => option.label,
      optionsBuilder: (textEditingValue) {
        final results =
            widget.optionsBuilder(textEditingValue.text).toList(growable: false);
        return results.length > 20 ? results.take(20) : results;
      },
      onSelected: (option) {
        widget.onSelected(option.id);
        _setControllerText(option.label);
      },
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        _controller = textEditingController;
        _scheduleSync();

        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          style: const TextStyle(color: Colors.white),
          cursorColor: Colors.white,
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: const TextStyle(color: Colors.white70),
            prefixIcon: Icon(widget.leadingIcon, color: Colors.white54, size: 18),
            suffixIcon: widget.selectedId == null
                ? const Icon(Icons.search, color: Colors.white54, size: 18)
                : IconButton(
                    tooltip:
                        'Clear ${widget.labelText.toLowerCase()} selection',
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      widget.onSelected(null);
                      textEditingController.clear();
                      focusNode.requestFocus();
                    },
                  ),
            filled: true,
            fillColor: const Color(0xFF111327),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Theme.of(context).colorScheme.secondary),
            ),
          ),
          onEditingComplete: onFieldSubmitted,
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        final entries = options.toList(growable: false);
        if (entries.isEmpty) {
          return Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              color: const Color(0xFF111327),
              borderRadius: BorderRadius.circular(12),
              child: const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'No matches found',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ),
          );
        }

        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 6,
            color: const Color(0xFF111327),
            borderRadius: BorderRadius.circular(12),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 260, minWidth: 260),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: entries.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  color: Colors.white10,
                ),
                itemBuilder: (context, index) {
                  final option = entries[index];
                  return ListTile(
                    leading: Icon(
                      widget.leadingIcon,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    title: Text(
                      option.label,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: option.description.isEmpty
                        ? null
                        : Text(
                            option.description,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                    trailing: Text(
                      option.category,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  void _scheduleSync() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _syncControllerWithSelection();
    });
  }

  void _syncControllerWithSelection() {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    final label = widget.selectedId == null
        ? ''
        : (widget.labelResolver?.call(widget.selectedId!) ?? widget.selectedId!);
    if (controller.text == label) {
      return;
    }
    controller
      ..text = label
      ..selection = TextSelection.collapsed(offset: label.length);
  }

  void _setControllerText(String value) {
    final controller = _controller;
    if (controller == null) {
      return;
    }
    controller
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
  }
}

class _SelectionInsight extends StatelessWidget {
  const _SelectionInsight({
    required this.title,
    required this.category,
    required this.description,
  });

  final String title;
  final String category;
  final String description;

  @override
  Widget build(BuildContext context) {
    if (category.isEmpty && description.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.info_outline, size: 14, color: Colors.white54),
            const SizedBox(width: 6),
            Text(
              category.isEmpty ? title : '$title · $category',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
        if (description.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              description,
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
      ],
    );
  }
}
