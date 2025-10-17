import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/modulation_matrix.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ModulationMatrix', () {
    test('setRoute adds and aggregates modulation data', () {
      final matrix = ModulationMatrix();

      expect(matrix.routeCount, 0);
      expect(matrix.routes, isEmpty);

      final changed = matrix.setRoute(
        const ModulationRoute(source: 'lfo1', destination: 'filterCutoff', amount: 0.5),
      );

      expect(changed, isTrue);
      expect(matrix.routeCount, 1);
      expect(matrix.routes.first.source, 'lfo1');

      final sources = matrix.aggregateDepthBySource();
      final destinations = matrix.aggregateDepthByDestination();

      expect(sources, containsPair('lfo1', closeTo(0.5, 1e-6)));
      expect(destinations, containsPair('filtercutoff', closeTo(0.5, 1e-6)));
    });

    test('setRoute with near-zero amount removes the route', () {
      final matrix = ModulationMatrix();
      matrix.setRoute(
        const ModulationRoute(source: 'lfo1', destination: 'filterCutoff', amount: 0.5),
      );

      final changed = matrix.setRoute(
        const ModulationRoute(source: 'lfo1', destination: 'filterCutoff', amount: 1e-7),
      );

      expect(changed, isTrue);
      expect(matrix.routeCount, 0);
      expect(matrix.routes, isEmpty);
    });

    test('replaceAll syncs incoming routes and reports changes', () {
      final matrix = ModulationMatrix();
      matrix.setRoute(
        const ModulationRoute(source: 'lfo1', destination: 'filterCutoff', amount: 0.5),
      );

      final changed = matrix.replaceAll(const <ModulationRoute>[
        ModulationRoute(source: 'aftertouch', destination: 'lfoDepth', amount: 0.25),
        ModulationRoute(source: 'expression', destination: 'distortionDrive', amount: 0.4),
      ]);

      expect(changed, isTrue);
      expect(matrix.routeCount, 2);
      final sources = matrix.aggregateDepthBySource();
      expect(sources.keys, containsAll(<String>['aftertouch', 'expression']));
    });
  });
}
