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
}
