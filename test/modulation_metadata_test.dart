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

    expect(destinations, containsAll(<String>['filterCutoff', 'lfoDepth', 'distortionDrive']));
    expect(destinations.toSet().length, destinations.length);
  });
}
