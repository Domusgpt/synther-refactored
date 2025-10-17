# MIDI Binding Workflow

The holographic synth now exposes a reusable MIDI binding layer so external
controllers can drive parameters without touching UI widgets directly. Bindings
are registry-aware which means they inherit parameter ranges, alias handling,
and response curves defined in `ParameterRegistry`.

## Core Types

| Type | Description |
| ---- | ----------- |
| `MidiBinding` | Immutable descriptor that maps a MIDI control change number to a synthesiser parameter with optional min/max overrides and inversion. |
| `MidiBindingManager` | Maintains bindings grouped by controller number, resolves aliases via the registry, and produces canonical parameter updates from incoming MIDI values. |
| `AudioEngine.handleMidiControlChange` | Convenience entry point that forwards CC messages through the binding manager, applies the resulting parameter updates, and notifies listeners when values change. |

## Registering Bindings

```dart
final bindings = MidiBindingManager.instance;
bindings.registerBinding(
  const MidiBinding(
    controller: 74,
    parameterId: 'cutoff', // alias resolved to filterCutoff automatically
    minValue: 200.0,       // optional window within the canonical range
    maxValue: 12000.0,
  ),
);
```

Call `removeBinding`, `clear`, or `registerBinding(..., replace: true)` to keep
assignments in sync with evolving controller layouts.

## Applying Control Change Data

Forward CC values to the audio engine so the binding manager can translate them
into parameter updates using the shared registry metadata:

```dart
Future<void> onControlChange(int controller, int value) async {
  final handled = await engine.handleMidiControlChange(controller, value);
  if (!handled) {
    // Fallback behaviour for unbound controllers.
  }
}
```

When bindings are present the engine will clamp values to the configured range,
update the pure Dart backend, emit bridge aliases, and refresh the active preset
snapshot for downstream consumers.

## Persisting Bindings

`MidiBindingManager` supports JSON serialisation so controller layouts can ship
with presets or live performance kits:

```dart
// Save bindings to disk
final payload = MidiBindingManager.instance.toJson();

// Restore bindings later
MidiBindingManager.instance.loadFromJson(payload, replace: true);
```

Each entry stores `controller`, `parameterId`, and optional `minValue`,
`maxValue`, and `invert` fields. The manager will resolve parameter aliases on
load so legacy payloads remain compatible with registry updates.

## Future Extensions

- NRPN/14-bit CC support for higher resolution controllers.
- Per-binding response curves or smoothing for stepped encoders.
- UI editor that reuses the holographic panels to remap controllers visually.
- MIDI learn mode that listens for the next CC message and registers it on the
  selected parameter automatically.
