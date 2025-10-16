# MIDI Integration Guide

The refactored synth now includes a pure Dart MIDI routing layer that connects
hardware controllers to the audio engine without native plugins. This guide
describes the moving pieces and shows how to extend them for custom rigs.

## Overview

- [`MidiRouter`](../lib/core/midi_router.dart) decodes raw MIDI bytes, filters
  by channel, and forwards note, controller, and pitch bend data through typed
  callbacks.
- The `AudioEngine` exposes a `midiRouter` getter that wires these callbacks to
  `noteOn`, `noteOff`, registry-aware parameter setters, and the new pitch wheel
  handling logic.
- Parameter ranges, aliases, and curves are sourced from the
  [`ParameterRegistry`](../lib/core/parameter_registry.dart) so MIDI controllers
  automatically honour the same clamping behaviour as presets and the UI.

## Default Controller Mappings

The engine registers a handful of useful CC bindings when the router is created:

| Controller | Target Parameter    | Notes                                              |
|------------|---------------------|----------------------------------------------------|
| 74         | `filterCutoff`      | Exponential mapping from 20 Hz to 20 kHz.          |
| 71         | `filterResonance`   | Linear response across the 0–1 resonance range.    |
| 1          | `lfoDepth`          | Matches the mod wheel on most keyboards.           |

You can inspect or modify these mappings at runtime:

```dart
final router = engine.midiRouter;
router.clearBindings();
router.bindControllerToParameter(controller: 73, parameter: 'attackTime');
router.bindControllerToParameter(controller: 72, parameter: 'releaseTime');
```

## Custom Parameter Ranges

If a controller should operate over a restricted range, provide overrides when
binding:

```dart
router.bindControllerToParameter(
  controller: 10,
  parameter: 'masterVolume',
  minValue: 0.2,
  maxValue: 0.8,
);
```

The router will interpolate within the supplied window while still applying the
parameter’s configured curve (linear, exponential, or logarithmic).

## Pitch Bend Handling

Pitch wheel data is normalised to the `[-1, 1]` range and forwarded to the
engine, which multiplies it by the current `pitchBendRange` parameter before
calling `AudioBackend.setPitchBend`. Visualiser metrics and the parameter bridge
expose both the normalised wheel position and the semitone offset so UI layers
stay in sync.

## Listening on a Specific Channel

By default the router listens to all MIDI channels. Limit it to a specific one
when working with multi-timbral setups:

```dart
router.listenToChannel(1); // respond to channel 2 (0-based indexing)
```

Passing `null` restores omni mode.

## Testing & Extensibility

Unit tests in `test/midi_router_test.dart` cover note dispatch, CC range
mappings, and pitch bend normalisation. Because everything runs in pure Dart, it
is straightforward to extend the router with additional message types (e.g.
aftertouch or NRPN) without touching platform code.
