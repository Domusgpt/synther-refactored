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
  final Set<String> _activeSuggestionTags = <String>{};
  ModulationRouteSuggestion? _primedSuggestion;
  String _suggestionQuery = '';
  late final TextEditingController _suggestionSearchController;

  @override
  void initState() {
    super.initState();
    _suggestionSearchController = TextEditingController();
  }

  @override
  void dispose() {
    _suggestionSearchController.dispose();
    super.dispose();
  }

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
      requiredTags:
          _activeSuggestionTags.isEmpty ? null : _activeSuggestionTags,
      query: _suggestionQuery.isEmpty ? null : _suggestionQuery,
    );
    final primedSuggestion = _primedSuggestion;
    ModulationRouteSuggestion? previewSuggestion;
    if (primedSuggestion != null) {
      final nonNullPrimed = primedSuggestion;
      previewSuggestion = suggestions.firstWhere(
        (candidate) => _areSuggestionsEquivalent(candidate, nonNullPrimed),
        orElse: () => nonNullPrimed,
      );
    }
    final isPreviewVisible = previewSuggestion != null &&
        suggestions.any(
          (candidate) =>
              _areSuggestionsEquivalent(candidate, previewSuggestion),
        );
    if (_suggestionSearchController.text != _suggestionQuery) {
      _suggestionSearchController.value = TextEditingValue(
        text: _suggestionQuery,
        selection: TextSelection.collapsed(offset: _suggestionQuery.length),
      );
    }
    final suggestionTags = ModulationRoutingMetadata.suggestionTags();
    final favouriteSuggestions = engine.favouriteModulationRouteSuggestions;
    final recentSuggestions = engine.recentModulationRouteSuggestions;
    final bundles = engine.modulationSuggestionBundles;
    final favouriteIds = engine.favouriteModulationSuggestionIds.toSet();
    final showSuggestionSection = suggestions.isNotEmpty ||
        suggestionTags.isNotEmpty ||
        favouriteSuggestions.isNotEmpty ||
        recentSuggestions.isNotEmpty ||
        bundles.isNotEmpty ||
        _suggestionQuery.isNotEmpty ||
        _activeSuggestionTags.isNotEmpty;

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
                    _primedSuggestion = null;
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
                    _primedSuggestion = null;
                  });
                },
              ),
            ),
          if (showSuggestionSection)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _buildSuggestionSection(
                context,
                engine: engine,
                suggestions: suggestions,
                favouriteSuggestions: favouriteSuggestions,
                recentSuggestions: recentSuggestions,
                bundles: bundles,
                favouriteIds: favouriteIds,
                colorScheme: colorScheme,
                availableTags: suggestionTags,
                activeTags: _activeSuggestionTags,
                query: _suggestionQuery,
                primedSuggestion:
                    isPreviewVisible ? previewSuggestion : null,
                onQueryChanged: (value) {
                  setState(() {
                    _suggestionQuery = value;
                    _primedSuggestion = null;
                  });
                },
                onTagToggled: (tag) {
                  setState(() {
                    final normalised = tag.toLowerCase();
                    final hasTag = _activeSuggestionTags.any(
                      (active) => active.toLowerCase() == normalised,
                    );
                    if (hasTag) {
                      _activeSuggestionTags.removeWhere(
                        (active) => active.toLowerCase() == normalised,
                      );
                    } else {
                      _activeSuggestionTags.add(tag);
                    }
                    _primedSuggestion = null;
                  });
                },
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
                  onSelected: (value) => setState(() {
                    _selectedSource = value;
                    _primedSuggestion = null;
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DestinationAutocompleteField(
                  descriptors: destinationDescriptors,
                  selectedId: _selectedDestination,
                  categoryFilter: _destinationCategoryFilter,
                  onSelected: (value) => setState(() {
                    _selectedDestination = value;
                    _primedSuggestion = null;
                  }),
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
          final previewIsFavourite = previewSuggestion != null &&
              engine.isSuggestionFavourite(previewSuggestion.id);
          if (isPreviewVisible && previewSuggestion != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _SuggestionPreviewCard(
                suggestion: previewSuggestion,
                colorScheme: colorScheme,
                isFavourite: previewIsFavourite,
                onFavouriteToggle: () {
                  final suggestion = previewSuggestion;
                  if (suggestion != null) {
                    _toggleFavouriteSuggestion(engine, suggestion);
                  }
                },
                onResetAmount: () {
                  setState(() {
                    _pendingAmount = previewSuggestion.defaultAmount
                        .clamp(-1.0, 1.0)
                        .toDouble();
                  });
                  final messenger = ScaffoldMessenger.of(context);
                  messenger
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      SnackBar(
                        content: Text(
                          'Amount reset to '
                          '${previewSuggestion.defaultAmount.toStringAsFixed(2)} '
                          'for ${previewSuggestion.sourceLabel} → '
                          '${previewSuggestion.destinationLabel}.',
                        ),
                      ),
                    );
                },
                onClear: () {
                  setState(() {
                    _primedSuggestion = null;
                  });
                },
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

    final primed = _primedSuggestion;
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

    setState(() {
      _primedSuggestion = null;
    });

    if (primed != null) {
      engine.registerSuggestionUsage(primed.id);
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
    required AudioEngine engine,
    required List<ModulationRouteSuggestion> suggestions,
    required List<ModulationRouteSuggestion> favouriteSuggestions,
    required List<ModulationRouteSuggestion> recentSuggestions,
    required List<ModulationSuggestionBundle> bundles,
    required Set<String> favouriteIds,
    required ColorScheme colorScheme,
    required List<String> availableTags,
    required Set<String> activeTags,
    required String query,
    required ModulationRouteSuggestion? primedSuggestion,
    required ValueChanged<String> onQueryChanged,
    required ValueChanged<String> onTagToggled,
  }) {
    final hasActiveFilters = query.isNotEmpty || activeTags.isNotEmpty;
    final queryTokens = query.trim().isEmpty
        ? const <String>[]
        : query
            .toLowerCase()
            .split(RegExp(r'\s+'))
            .where((token) => token.isNotEmpty)
            .toList(growable: false);
    final activeTagSet = activeTags
        .map((tag) => tag.toLowerCase())
        .toSet(growable: false);
    final usageSummaries = engine.suggestionUsageSummaries;
    final trendingTags = engine
        .topModulationSuggestionTags(limit: 6)
        .where((tag) =>
            availableTags.any((available) =>
                available.toLowerCase() == tag.toLowerCase()))
        .toList(growable: false);

    bool matchesFilters(ModulationRouteSuggestion suggestion) {
      if (activeTagSet.isNotEmpty) {
        final suggestionTags = suggestion.tags
            .map((tag) => tag.toLowerCase())
            .toSet(growable: false);
        final matchesTags =
            activeTagSet.every((tag) => suggestionTags.contains(tag));
        if (!matchesTags) {
          return false;
        }
      }

      if (queryTokens.isEmpty) {
        return true;
      }

      final haystacks = <String>{
        suggestion.sourceId,
        suggestion.sourceLabel,
        suggestion.sourceCategory,
        suggestion.destinationId,
        suggestion.destinationLabel,
        suggestion.destinationCategory,
        suggestion.description,
        ...suggestion.tags,
      }.map((value) => value.toLowerCase()).toList(growable: false);

      for (final token in queryTokens) {
        if (!haystacks.any((value) => value.contains(token))) {
          return false;
        }
      }
      return true;
    }

    final filteredFavourites = favouriteSuggestions
        .where(matchesFilters)
        .toList(growable: false);

    final filteredRecents = recentSuggestions
        .where(
          (suggestion) =>
              matchesFilters(suggestion) &&
              !favouriteIds.contains(suggestion.id),
        )
        .toList(growable: false);

    final filteredUsageSummaries = usageSummaries
        .where((summary) => matchesFilters(summary.suggestion))
        .toList(growable: false);

    final bundleCache = <String, List<ModulationRouteSuggestion>>{};
    List<ModulationRouteSuggestion> bundleRoutes(
      ModulationSuggestionBundle bundle,
    ) {
      return bundleCache.putIfAbsent(
        bundle.id,
        () => engine.bundleSuggestions(bundle.id),
      );
    }

    bool bundleMatches(ModulationSuggestionBundle bundle) {
      if (activeTagSet.isNotEmpty) {
        final bundleTagSet = bundle.focusTags
            .map((tag) => tag.toLowerCase())
            .toSet(growable: false);
        if (!activeTagSet.every(bundleTagSet.contains)) {
          final routeTags = bundleRoutes(bundle)
              .expand((suggestion) => suggestion.tags)
              .map((tag) => tag.toLowerCase())
              .toSet(growable: false);
          if (!activeTagSet.every(routeTags.contains)) {
            return false;
          }
        }
      }

      if (queryTokens.isEmpty) {
        return true;
      }

      final haystacks = <String>{
        bundle.title,
        bundle.description,
        ...bundle.focusTags,
      }.map((value) => value.toLowerCase()).toList(growable: false);

      bool matchesToken(String token) {
        if (haystacks.any((value) => value.contains(token))) {
          return true;
        }
        final routeHaystacks = bundleRoutes(bundle)
            .expand(
              (suggestion) => <String>[
                suggestion.sourceLabel,
                suggestion.destinationLabel,
                suggestion.description,
                ...suggestion.tags,
              ],
            )
            .map((value) => value.toLowerCase());
        return routeHaystacks.any((value) => value.contains(token));
      }

      for (final token in queryTokens) {
        if (!matchesToken(token)) {
          return false;
        }
      }
      return true;
    }

    final filteredBundles = bundles
        .where(bundleMatches)
        .toList(growable: false);

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
        TextField(
          controller: _suggestionSearchController,
          onChanged: onQueryChanged,
          style: const TextStyle(color: Colors.white, fontSize: 12),
          cursorColor: colorScheme.primary,
          decoration: InputDecoration(
            hintText:
                'Search suggestions (e.g. "granular", "performance", "filter")',
            hintStyle: const TextStyle(color: Colors.white54, fontSize: 12),
            prefixIcon:
                const Icon(Icons.search, size: 18, color: Colors.white54),
            suffixIcon: query.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    color: Colors.white54,
                    tooltip: 'Clear search',
                    onPressed: () {
                      _suggestionSearchController.clear();
                      onQueryChanged('');
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: const Color(0xFF0F1126),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white24),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary),
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (trendingTags.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.local_fire_department,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Popular tags',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 1.1,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: trendingTags.map((tag) {
                  final isActive = activeTags.any(
                    (active) => active.toLowerCase() == tag.toLowerCase(),
                  );
                  return ActionChip(
                    avatar: Icon(
                      Icons.tag,
                      size: 16,
                      color: isActive
                          ? colorScheme.primary
                          : Colors.white54,
                    ),
                    label: Text(
                      tag,
                      style: TextStyle(
                        color: isActive ? colorScheme.primary : Colors.white,
                        fontSize: 11,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w500,
                      ),
                    ),
                    backgroundColor: isActive
                        ? colorScheme.primary.withOpacity(0.18)
                        : const Color(0xFF151834),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    onPressed: () => onTagToggled(tag),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isActive
                            ? colorScheme.primary
                            : Colors.white24,
                      ),
                    ),
                  );
                }).toList(growable: false),
              ),
              const SizedBox(height: 12),
            ],
          ),
        if (availableTags.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: availableTags.map((tag) {
              final isActive = activeTags.any(
                (active) => active.toLowerCase() == tag.toLowerCase(),
              );
              return FilterChip(
                selected: isActive,
                onSelected: (_) => onTagToggled(tag),
                showCheckmark: false,
                label: Text(
                  tag,
                  style: TextStyle(
                    color: isActive ? Colors.black : Colors.white,
                    fontSize: 11,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
                selectedColor: colorScheme.primary,
                backgroundColor: const Color(0xFF1A1D39),
                side: BorderSide(
                  color: isActive
                      ? colorScheme.primary
                      : Colors.white24,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              );
            }).toList(growable: false),
          ),
        if (availableTags.isNotEmpty) const SizedBox(height: 8),
        if (filteredUsageSummaries.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Trending picks',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _resetSuggestionInsights(engine),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset insights'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredUsageSummaries.map((summary) {
              final suggestion = summary.suggestion;
              final isPrimed = primedSuggestion != null &&
                  _areSuggestionsEquivalent(suggestion, primedSuggestion);
              final isFavourite = favouriteIds.contains(suggestion.id);
              return _buildSuggestionChip(
                suggestion: suggestion,
                colorScheme: colorScheme,
                leadingIcon: Icons.local_fire_department,
                isPrimed: isPrimed,
                isFavourite: isFavourite,
                usageCount: summary.usageCount,
                highlightUsage: true,
                onPressed: () => _primeSuggestion(suggestion),
                onFavouriteToggle: () =>
                    _toggleFavouriteSuggestion(engine, suggestion),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        if (filteredFavourites.isNotEmpty) ...[
          Text(
            'Favourites',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredFavourites.map((suggestion) {
              final isPrimed = primedSuggestion != null &&
                  _areSuggestionsEquivalent(suggestion, primedSuggestion);
              return _buildSuggestionChip(
                suggestion: suggestion,
                colorScheme: colorScheme,
                leadingIcon: Icons.star,
                isPrimed: isPrimed,
                isFavourite: true,
                onPressed: () => _primeSuggestion(suggestion),
                onFavouriteToggle: () =>
                    _toggleFavouriteSuggestion(engine, suggestion),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        if (filteredRecents.isNotEmpty) ...[
          Row(
            children: [
              Text(
                'Recently used',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white70,
                      letterSpacing: 1.1,
                    ),
              ),
              const Spacer(),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: () => _clearRecentSuggestions(engine),
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear history'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: filteredRecents.map((suggestion) {
              final isPrimed = primedSuggestion != null &&
                  _areSuggestionsEquivalent(suggestion, primedSuggestion);
              final isFavourite = engine.isSuggestionFavourite(suggestion.id);
              return _buildSuggestionChip(
                suggestion: suggestion,
                colorScheme: colorScheme,
                leadingIcon: Icons.history,
                isPrimed: isPrimed,
                isFavourite: isFavourite,
                usageCount: usageSummaries
                    .firstWhere(
                      (summary) => summary.id == suggestion.id,
                      orElse: () => ModulationSuggestionUsage(
                        suggestion: suggestion,
                        usageCount: 1,
                        lastUsedOrder: 0,
                      ),
                    )
                    .usageCount,
                onPressed: () => _primeSuggestion(suggestion),
                onFavouriteToggle: () =>
                    _toggleFavouriteSuggestion(engine, suggestion),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        if (filteredBundles.isNotEmpty) ...[
          Text(
            'Workflow bundles',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white70,
                  letterSpacing: 1.1,
                ),
          ),
          const SizedBox(height: 6),
          Column(
            children: filteredBundles.map((bundle) {
              final routes = bundleRoutes(bundle);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SuggestionBundleCard(
                  bundle: bundle,
                  colorScheme: colorScheme,
                  suggestions: routes,
                  onPreview: () => _previewBundle(engine, bundle),
                  onApply: () => _applyBundle(engine, bundle),
                ),
              );
            }).toList(growable: false),
          ),
          const SizedBox(height: 12),
        ],
        if (suggestions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((suggestion) {
              final isPrimed = primedSuggestion != null &&
                  _areSuggestionsEquivalent(suggestion, primedSuggestion);
              final isFavourite = favouriteIds.contains(suggestion.id);
              return _buildSuggestionChip(
                suggestion: suggestion,
                colorScheme: colorScheme,
                leadingIcon: Icons.auto_awesome,
                isPrimed: isPrimed,
                isFavourite: isFavourite,
                usageCount: usageSummaries
                    .firstWhere(
                      (summary) => summary.id == suggestion.id,
                      orElse: () => ModulationSuggestionUsage(
                        suggestion: suggestion,
                        usageCount: 0,
                        lastUsedOrder: 0,
                      ),
                    )
                    .usageCount,
                onPressed: () => _primeSuggestion(suggestion),
                onFavouriteToggle: () =>
                    _toggleFavouriteSuggestion(engine, suggestion),
              );
            }).toList(growable: false),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Text(
              hasActiveFilters
                  ? 'No suggestions match the current filters yet.'
                  : 'No curated routes available for this context.',
              style: const TextStyle(color: Colors.white60, fontSize: 12),
            ),
          ),
      ],
    );
  }

  void _primeSuggestion(
    ModulationRouteSuggestion suggestion, {
    bool showFeedback = true,
  }) {
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
      _primedSuggestion = suggestion;
    });

    if (showFeedback) {
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
  }

  void _toggleFavouriteSuggestion(
    AudioEngine engine,
    ModulationRouteSuggestion suggestion,
  ) {
    final willFavourite = !engine.isSuggestionFavourite(suggestion.id);
    final changed = engine.toggleFavouriteSuggestion(suggestion.id);
    if (!changed) {
      return;
    }

    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    final label =
        '${suggestion.sourceLabel} → ${suggestion.destinationLabel}';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            willFavourite
                ? 'Saved $label to favourites.'
                : 'Removed $label from favourites.',
          ),
        ),
      );
  }

  void _clearRecentSuggestions(AudioEngine engine) {
    final changed = engine.clearRecentModulationSuggestions();
    if (!changed) {
      return;
    }

    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Cleared recent suggestion history.'),
        ),
      );
  }

  void _resetSuggestionInsights(AudioEngine engine) {
    final changed = engine.resetSuggestionUsageMetrics();
    if (!changed) {
      return;
    }

    setState(() {});
    final messenger = ScaffoldMessenger.of(context);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Reset suggestion usage insights.'),
        ),
      );
  }

  void _previewBundle(
    AudioEngine engine,
    ModulationSuggestionBundle bundle,
  ) {
    final routes = engine.bundleSuggestions(bundle.id);
    if (routes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No curated routes available for ${bundle.title} yet.',
          ),
        ),
      );
      return;
    }

    final first = routes.first;
    _primeSuggestion(first, showFeedback: false);

    final remaining = routes.length - 1;
    final messenger = ScaffoldMessenger.of(context);
    final summary = remaining > 0
        ? '${bundle.title}: primed ${first.sourceLabel} → ${first.destinationLabel} '
            '(+$remaining more routes ready).'
        : '${bundle.title}: primed ${first.sourceLabel} → ${first.destinationLabel}.';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(summary)),
      );
  }

  void _applyBundle(
    AudioEngine engine,
    ModulationSuggestionBundle bundle,
  ) {
    final planned = engine.bundleSuggestions(bundle.id);
    if (planned.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No curated routes available for ${bundle.title} yet.',
          ),
        ),
      );
      return;
    }

    final applied = engine.applyModulationSuggestionBundle(bundle.id);
    if (applied.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${bundle.title}: all routes already active. Usage history updated.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _primedSuggestion = null;
    });

    final messenger = ScaffoldMessenger.of(context);
    final summary = applied.length == 1
        ? '${applied.first.sourceLabel} → ${applied.first.destinationLabel} applied.'
        : '${applied.length} bundle routes applied.';
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('${bundle.title}: $summary')),
      );
  }

  Widget _buildSuggestionChip({
    required ModulationRouteSuggestion suggestion,
    required ColorScheme colorScheme,
    required IconData leadingIcon,
    required bool isPrimed,
    required bool isFavourite,
    required VoidCallback onPressed,
    required VoidCallback onFavouriteToggle,
    int? usageCount,
    bool highlightUsage = false,
  }) {
    final tooltipParts = <String>[];
    if (suggestion.description.isNotEmpty) {
      tooltipParts.add(suggestion.description);
    }
    if (suggestion.tags.isNotEmpty) {
      tooltipParts.add('Tags: ${suggestion.tags.join(', ')}');
    }
    if (usageCount != null && usageCount > 0) {
      final usageLabel = usageCount == 1 ? 'time' : 'times';
      tooltipParts.add('Used $usageCount $usageLabel recently.');
    }
    final tooltipMessage = tooltipParts.join('\n');
    final normalisedUsage = usageCount != null && usageCount > 0 ? usageCount : null;

    return _SuggestionChip(
      suggestion: suggestion,
      colorScheme: colorScheme,
      leadingIcon: leadingIcon,
      isPrimed: isPrimed,
      isFavourite: isFavourite,
      onPressed: onPressed,
      onFavouriteToggle: onFavouriteToggle,
      tooltipMessage: tooltipMessage,
      usageCount: normalisedUsage,
      highlightUsage: highlightUsage,
    );
  }

  bool _areSuggestionsEquivalent(
    ModulationRouteSuggestion a,
    ModulationRouteSuggestion b,
  ) {
    return a.sourceId == b.sourceId &&
        a.destinationId == b.destinationId &&
        (a.defaultAmount - b.defaultAmount).abs() < 1e-6;
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

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({
    required this.suggestion,
    required this.colorScheme,
    required this.leadingIcon,
    required this.isPrimed,
    required this.isFavourite,
    required this.onPressed,
    required this.onFavouriteToggle,
    this.tooltipMessage = '',
    this.usageCount,
    this.highlightUsage = false,
  });

  final ModulationRouteSuggestion suggestion;
  final ColorScheme colorScheme;
  final IconData leadingIcon;
  final bool isPrimed;
  final bool isFavourite;
  final VoidCallback onPressed;
  final VoidCallback onFavouriteToggle;
  final String tooltipMessage;
  final int? usageCount;
  final bool highlightUsage;

  @override
  Widget build(BuildContext context) {
    Widget buildLabel() {
      final label = Text(
        '${suggestion.sourceLabel} → ${suggestion.destinationLabel}',
        style: TextStyle(
          color: isPrimed ? colorScheme.primary : Colors.white,
          fontSize: 12,
          fontWeight: isPrimed ? FontWeight.w600 : FontWeight.w500,
        ),
        overflow: TextOverflow.ellipsis,
      );

      if (usageCount == null) {
        return label;
      }

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: label),
          const SizedBox(width: 6),
          _UsageBadge(
            count: usageCount!,
            colorScheme: colorScheme,
            highlight: highlightUsage,
            isPrimed: isPrimed,
          ),
        ],
      );
    }

    final chip = RawChip(
      label: buildLabel(),
      avatar: Icon(
        leadingIcon,
        color: isPrimed ? colorScheme.primary : Colors.white70,
        size: 18,
      ),
      onPressed: onPressed,
      selected: isPrimed,
      selectedColor: colorScheme.primary.withOpacity(0.18),
      backgroundColor:
          isPrimed ? colorScheme.primary.withOpacity(0.18) : const Color(0xFF1A1D39),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isPrimed ? colorScheme.primary : Colors.white24,
        ),
      ),
      deleteIcon: Icon(
        isFavourite ? Icons.star : Icons.star_border,
        color: isFavourite ? colorScheme.primary : Colors.white54,
        size: 18,
      ),
      deleteIconTooltipMessage:
          isFavourite ? 'Remove from favourites' : 'Add to favourites',
      onDeleted: onFavouriteToggle,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );

    if (tooltipMessage.isEmpty) {
      return chip;
    }

    return Tooltip(
      message: tooltipMessage,
      waitDuration: const Duration(milliseconds: 400),
      child: chip,
    );
  }
}

class _UsageBadge extends StatelessWidget {
  const _UsageBadge({
    required this.count,
    required this.colorScheme,
    required this.highlight,
    required this.isPrimed,
  });

  final int count;
  final ColorScheme colorScheme;
  final bool highlight;
  final bool isPrimed;

  @override
  Widget build(BuildContext context) {
    final display = count > 999 ? '999+' : count.toString();
    final baseColor = highlight ? colorScheme.primary : Colors.white70;
    final background = highlight
        ? colorScheme.primary.withOpacity(isPrimed ? 0.35 : 0.2)
        : const Color(0x331A214B);

    return Container(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: highlight ? colorScheme.primary : Colors.white24,
          width: highlight ? 1.2 : 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Text(
        display,
        style: TextStyle(
          color: baseColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _SuggestionBundleCard extends StatelessWidget {
  const _SuggestionBundleCard({
    required this.bundle,
    required this.colorScheme,
    required this.suggestions,
    required this.onPreview,
    required this.onApply,
  });

  final ModulationSuggestionBundle bundle;
  final ColorScheme colorScheme;
  final List<ModulationRouteSuggestion> suggestions;
  final VoidCallback onPreview;
  final VoidCallback onApply;

  @override
  Widget build(BuildContext context) {
    final hasSuggestions = suggestions.isNotEmpty;
    final summaries = suggestions
        .take(3)
        .map(
          (suggestion) =>
              '${suggestion.sourceLabel} → ${suggestion.destinationLabel}',
        )
        .toList(growable: false);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F1126),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.secondary.withOpacity(0.25)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  bundle.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: colorScheme.secondary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${suggestions.length} routes',
                  style: TextStyle(
                    color: colorScheme.secondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            bundle.description,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              height: 1.3,
            ),
          ),
          if (bundle.focusTags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: bundle.focusTags
                  .map(
                    (tag) => Chip(
                      backgroundColor: const Color(0xFF1A1D39),
                      label: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (summaries.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...summaries.map(
              (summary) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Icon(Icons.bolt, size: 14, color: colorScheme.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        summary,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: hasSuggestions ? onPreview : null,
                icon: const Icon(Icons.visibility_outlined, size: 18),
                label: const Text('Preview'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  onPressed: hasSuggestions ? onApply : null,
                  icon: const Icon(Icons.auto_fix_high),
                  label: const Text('Apply bundle'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SuggestionPreviewCard extends StatelessWidget {
  const _SuggestionPreviewCard({
    required this.suggestion,
    required this.colorScheme,
    required this.isFavourite,
    required this.onFavouriteToggle,
    required this.onResetAmount,
    required this.onClear,
  });

  final ModulationRouteSuggestion suggestion;
  final ColorScheme colorScheme;
  final bool isFavourite;
  final VoidCallback onFavouriteToggle;
  final VoidCallback onResetAmount;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF10122A).withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withOpacity(0.35)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      colorScheme.primary.withOpacity(0.5),
                      colorScheme.primary.withOpacity(0.1),
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(8),
                child: const Icon(
                  Icons.auto_fix_high,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Suggestion primed',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: colorScheme.primary,
                            letterSpacing: 1.1,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${suggestion.sourceLabel} → ${suggestion.destinationLabel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${suggestion.sourceCategory} → ${suggestion.destinationCategory}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isFavourite
                    ? 'Remove from favourites'
                    : 'Add to favourites',
                onPressed: onFavouriteToggle,
                icon: Icon(
                  isFavourite ? Icons.star : Icons.star_border,
                  color:
                      isFavourite ? colorScheme.primary : Colors.white54,
                  size: 18,
                ),
              ),
              IconButton(
                tooltip: 'Dismiss suggestion preview',
                onPressed: onClear,
                icon: const Icon(Icons.close, color: Colors.white54, size: 18),
              ),
            ],
          ),
          if (suggestion.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              suggestion.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.tune, color: colorScheme.primary, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommended amount ${suggestion.defaultAmount.toStringAsFixed(2)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
              TextButton.icon(
                onPressed: onResetAmount,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reset amount'),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),
            ],
          ),
          if (suggestion.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: suggestion.tags
                  .map(
                    (tag) => Chip(
                      backgroundColor: const Color(0xFF1A1D39),
                      label: Text(
                        tag,
                        style: const TextStyle(color: Colors.white, fontSize: 11),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
        ],
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
