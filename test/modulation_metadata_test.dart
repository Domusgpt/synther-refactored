import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/modulation_metadata.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('availableSources exposes curated controller list', () {
    final sources = ModulationRoutingMetadata.availableSources;

    expect(sources, containsAll(<String>['lfo1', 'modWheel', 'expression']));
    expect(sources.first, 'lfo1');
  });

  test('availableDestinations resolve canonical parameter names', () {
    final destinations = ModulationRoutingMetadata.availableDestinations;

    expect(
      destinations,
      containsAll(<String>['filterCutoff', 'lfoDepth', 'distortionDrive']),
    );
    expect(destinations.toSet().length, destinations.length);
  });

  group('category helpers', () {
    test('categoriesForSources returns curated order', () {
      final categories = ModulationRoutingMetadata.categoriesForSources();

      expect(
        categories,
        orderedEquals(<String>[
          'Modulators',
          'Performance',
          'Key Tracking',
          'Utility',
          'Envelopes',
        ]),
      );
    });

    test('categoriesForDestinations returns curated order', () {
      final categories = ModulationRoutingMetadata.categoriesForDestinations();

      expect(
        categories,
        orderedEquals(<String>[
          'Filter',
          'Modulation',
          'Oscillators',
          'Effects',
          'Granular',
          'Output',
        ]),
      );
      expect(categories.toSet().length, categories.length);
    });
  });

  group('ModulationRoutingMetadata search', () {
    test('searchSources matches aliases and descriptions', () {
      final aliasResults = ModulationRoutingMetadata.searchSources('aftertouch');
      expect(
        aliasResults.map((descriptor) => descriptor.id),
        contains('channelAftertouch'),
      );

      final descriptionResults =
          ModulationRoutingMetadata.searchSources('organic drift');
      expect(
        descriptionResults.map((descriptor) => descriptor.id),
        contains('random'),
      );
    });

    test('searchDestinations matches registry aliases and categories', () {
      final aliasResults =
          ModulationRoutingMetadata.searchDestinations('cutoff');
      expect(
        aliasResults.map((descriptor) => descriptor.id),
        contains('filterCutoff'),
      );

      final categoryResults =
          ModulationRoutingMetadata.searchDestinations('granular');
      expect(
        categoryResults.map((descriptor) => descriptor.id),
        containsAll(<String>[
          'granularActive',
          'granularGrainRate',
          'granularGrainDuration',
          'granularPosition',
          'granularPitch',
        ]),
      );
    });

    test('searchSources requires all tokens to match', () {
      final positive =
          ModulationRoutingMetadata.searchSources('mod wheel performance');
      expect(
        positive.map((descriptor) => descriptor.id),
        contains('modWheel'),
      );

      final negative =
          ModulationRoutingMetadata.searchSources('mod wheel filter');
      expect(
        negative.map((descriptor) => descriptor.id),
        isNot(contains('modWheel')),
      );
    });
  });

  group('ModulationRoutingMetadata suggestions', () {
    test('suggestedRoutes returns curated combinations with metadata', () {
      final suggestions = ModulationRoutingMetadata.suggestedRoutes();

      expect(suggestions, isNotEmpty);
      final filterSweep = suggestions.firstWhere(
        (suggestion) =>
            suggestion.sourceId == 'lfo1' &&
            suggestion.destinationId == 'filterCutoff',
      );

      expect(filterSweep.sourceLabel, 'LFO 1');
      expect(filterSweep.destinationLabel, 'Filter Cutoff');
      expect(filterSweep.sourceCategory, 'Modulators');
      expect(filterSweep.destinationCategory, 'Filter');
      expect(filterSweep.description, isNotEmpty);
      expect(filterSweep.defaultAmount, moreOrLessEquals(0.45));
      expect(filterSweep.tags, containsAll(<String>['Filter', 'Movement']));
    });

    test('suggestedRoutes respects category filters when provided', () {
      final filtered = ModulationRoutingMetadata.suggestedRoutes(
        sourceCategory: 'Modulators',
        destinationCategory: 'Filter',
      );

      expect(filtered, isNotEmpty);
      expect(
        filtered.every(
          (suggestion) =>
              suggestion.sourceCategory == 'Modulators' &&
              suggestion.destinationCategory == 'Filter',
        ),
        isTrue,
      );
    });

    test('suggestedRoutes filters by tags and query tokens', () {
      final tagFiltered = ModulationRoutingMetadata.suggestedRoutes(
        requiredTags: <String>['Granular'],
      );

      expect(tagFiltered, isNotEmpty);
      expect(
        tagFiltered.every(
          (suggestion) => suggestion.tags
              .map((tag) => tag.toLowerCase())
              .contains('granular'),
        ),
        isTrue,
      );

      final queryResults = ModulationRoutingMetadata.suggestedRoutes(
        query: 'performance texture',
      );

      expect(queryResults, isNotEmpty);
      expect(
        queryResults.map((suggestion) => suggestion.destinationId),
        contains('wavetablePosition'),
      );
    });

    test('suggestionTags exposes sorted unique labels', () {
      final tags = ModulationRoutingMetadata.suggestionTags();

      expect(tags, containsAll(<String>['Granular', 'Performance', 'Filter']));
      final sorted = tags.toList()
        ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      expect(tags, orderedEquals(sorted));
    });
  });
}
