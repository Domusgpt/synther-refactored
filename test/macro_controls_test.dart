import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/macro_controls.dart';
import 'package:synther_holographic_pro/core/parameter_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MacroAssignment', () {
    test('resolve maps normalized values using parameter ranges', () {
      final registry = ParameterRegistry.instance;
      final assignment = MacroAssignment(
        parameterId: 'filterCutoff',
        minNormalized: 0.25,
        maxNormalized: 0.75,
      );

      final resolved = assignment.resolve(registry, 0.5);
      final descriptor = registry.descriptorFor('filterCutoff')!;
      final expected = descriptor.range.denormalize(0.5);

      expect(resolved, closeTo(expected, 0.0001));
    });
  });

  group('MacroController', () {
    test('setValue returns resolved parameter updates', () {
      final controller = MacroController();
      controller.register(
        MacroDefinition(
          id: 'macro',
          name: 'Macro',
          assignments: <MacroAssignment>[
            MacroAssignment(
              parameterId: 'oscillatorBlend',
              minNormalized: 0.0,
              maxNormalized: 1.0,
            ),
            MacroAssignment(
              parameterId: 'chorusDepth',
              minNormalized: 0.2,
              maxNormalized: 0.6,
            ),
          ],
        ),
      );

      final updates = controller.setValue('macro', 0.75);

      expect(updates.containsKey('oscillatorBlend'), isTrue);
      expect(updates.containsKey('chorusDepth'), isTrue);
      expect(controller.valueFor('macro'), closeTo(0.75, 0.0001));
    });

    test('replaceWithSnapshots clears existing macros before loading new ones', () {
      final controller = MacroController();
      controller.register(
        MacroDefinition(
          id: 'legacy',
          name: 'Legacy',
          assignments: <MacroAssignment>[
            MacroAssignment(parameterId: 'masterVolume'),
          ],
        ),
      );

      final updates = controller.replaceWithSnapshots(<MacroSnapshot>[
        MacroSnapshot(
          definition: MacroDefinition(
            id: 'new',
            name: 'New Macro',
            assignments: <MacroAssignment>[
              MacroAssignment(parameterId: 'filterResonance'),
            ],
            defaultValue: 0.4,
          ),
          value: 0.8,
        ),
      ]);

      expect(controller.definitions.map((macro) => macro.id), ['new']);
      expect(controller.valueFor('new'), closeTo(0.8, 0.0001));
      expect(updates.containsKey('filterResonance'), isTrue);
    });
  });
}
