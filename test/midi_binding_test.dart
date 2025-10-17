import 'package:flutter_test/flutter_test.dart';

import 'package:synther_holographic_pro/core/midi_binding.dart';
import 'package:synther_holographic_pro/core/parameter_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MidiBinding', () {
    test('maps cc values into parameter range respecting overrides', () {
      final registry = ParameterRegistry.instance;
      final descriptor = registry.descriptorFor('masterVolume')!;
      const binding = MidiBinding(
        controller: 10,
        parameterId: 'masterVolume',
        minValue: 0.2,
        maxValue: 0.6,
      );

      expect(binding.resolveValue(0, descriptor), closeTo(0.2, 0.0001));
      expect(binding.resolveValue(127, descriptor), closeTo(0.6, 0.0001));

      final midValue = binding.resolveValue(64, descriptor);
      expect(midValue, greaterThan(0.2));
      expect(midValue, lessThan(0.6));
    });

    test('invert flag flips midi response', () {
      final registry = ParameterRegistry.instance;
      final descriptor = registry.descriptorFor('filterResonance')!;
      const binding = MidiBinding(
        controller: 74,
        parameterId: 'filterResonance',
        invert: true,
      );

      final minValue = binding.resolveValue(0, descriptor);
      final maxValue = binding.resolveValue(127, descriptor);

      expect(minValue, closeTo(descriptor.range.max, 0.0001));
      expect(maxValue, closeTo(descriptor.range.min, 0.0001));
    });
  });

  group('MidiBindingManager', () {
    late MidiBindingManager manager;

    setUp(() {
      manager = MidiBindingManager(registry: ParameterRegistry.instance);
      manager.clear();
    });

    test('canonicalises aliases when registering bindings', () {
      manager.registerBinding(
        const MidiBinding(controller: 71, parameterId: 'cutoff'),
      );

      final bindings = manager.bindingsForController(71);
      expect(bindings, hasLength(1));
      expect(bindings.single.parameterId, 'filterCutoff');
    });

    test('processControlChange returns mapped parameters', () {
      manager.registerBinding(
        const MidiBinding(controller: 74, parameterId: 'filterResonance'),
      );

      final updates = manager.processControlChange(74, 100);
      expect(updates, contains('filterResonance'));
      expect(updates['filterResonance'], isNotNull);
    });

    test('removeBinding clears matching entries', () {
      manager.registerBinding(
        const MidiBinding(controller: 10, parameterId: 'masterVolume'),
      );

      final removed = manager.removeBinding(10, 'masterVolume');
      expect(removed, isTrue);
      expect(manager.bindingsForController(10), isEmpty);
    });
  });
}
