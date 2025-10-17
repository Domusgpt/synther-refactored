# Audio Preset Library

The refactored audio stack ships with a pure Dart preset library that keeps the
synth engine, UI controls, and visualiser bridge in sync. This document outlines
how presets are modelled and how to work with them in code.

## Preset Concepts

### `SynthPreset`

Presets are represented by the immutable [`SynthPreset`](../lib/core/synth_preset.dart)
class. A preset contains:

- Metadata describing the preset (`id`, `name`, `description`, `category`, etc.)
- A map of canonical parameter values keyed by parameter name
- Optional modulation/auxiliary values stored alongside the core parameters
- An ordered list of modulation matrix routes describing controller-to-parameter
  assignments

The metadata is modelled by `SynthPresetMetadata` and includes helpers to
serialise to/from JSON so presets can be stored on disk or shipped with the app.

### Categories

`synth_preset.dart` defines `SynthPresetCategory` to keep presets organised. The
built-in categories cover common use cases (factory, ambient, bass, keys,
performance, experimental, user). Additional categories can be added if your UI
needs more granular filtering.

## Built-in Factory Presets

[`AudioPresetLibrary`](../lib/core/audio_preset_library.dart) lazily registers a
handful of factory presets the first time it is accessed. Each preset captures a
signature sound (pad, pluck, bass, keys) with tuned ADSR, filter, and effect
parameters. The library exposes helper methods to:

- Register or upsert new presets (useful for user saved sounds)
- Query presets by id or by category
- Export all presets as JSON for persistence or telemetry

The factory presets are deliberately deterministic so automated tests can rely
on them.

### Modulation-aware presets

The library now captures low-frequency oscillator (LFO) settings alongside the
core filter and envelope parameters. Each factory preset specifies an
`lfoRate` (in Hertz) and an `lfoDepth` (0–1 intensity) so patches can ship with
subtle motion out of the box. When you register additional presets, include
these keys to have the UI, parameter bridge, and visualiser react to the
modulation depth in exactly the same way.

### Modulation matrix routes

In addition to the scalar parameters above, presets can persist full modulation
matrices. Each [`ModulationRoute`](../lib/core/modulation_matrix.dart) captures a
`source` controller (LFOs, expression pedals, aftertouch, etc.), a destination
parameter, and a bipolar `amount`. The preset library stores these routes in
order so the `AudioEngine` can reapply them, push updates through the
`ParameterBridge`, and expose aggregated metrics such as
`modulationRouteCount`, `modSource.*`, and `modDestination.*` to the visualiser.

When serialising presets to JSON, include a `modulationRoutes` array with
objects shaped like `{ "source": "lfo1", "destination": "filterCutoff",
"amount": 0.6 }`. For more compact representations you can also provide a
`modulationMatrix` map using `source->destination` keys; the engine accepts both
formats (and nested maps like `{ "expression": { "distortionDrive": -0.3 } }`).

### Oscillator and effects sculpting

Factory presets also opt into the expanded oscillator and effects metadata. In
addition to classic ADSR and filter controls, presets can describe:

- `oscillatorBlend` – crossfades between the primary and secondary oscillators
  for quickly shifting a tone from fundamental-heavy to harmonic-rich.
- `oscillatorDetune` – offsets the secondary oscillator ±12 semitones to add
  shimmer or grit.
- `oscillatorSpread` – introduces unison-style width that the visualiser can
  mirror via the new ensemble metrics.
- `distortionDrive` – pushes the backend’s virtual waveshaper for more bite.
- `chorusRate`/`chorusDepth` – emulate ensemble motion with alias-aware bridge
  keys like `chorusSpeed` or `chorusMix`.

Including these parameters keeps presets future-proof: the parameter registry
automatically canonicalises aliases, clamps the ranges, and emits matching
visualiser targets so both the UI and holographic shader can showcase the extra
movement.

### Granular and sample shaping

The shared registry now covers grain playback, wavetable motion, and microphone
input gain so sample-based sounds stay consistent across the engine and UI:

- `granularActive` – toggles grain playback (aliases like `granularEnabled`
  and `granularOn` are mirrored automatically).
- `granularGrainRate` / `granularGrainDuration` – control grain density and
  length with exponential curves for musical sweeps.
- `granularPosition`, `granularPitch`, and the variation controls (`position`
  / `pitch` / `duration`) – sculpt motion-heavy textures while keeping the
  visualiser in sync via dedicated variance metrics.
- `granularPan` / `granularPanVariation` and `granularWindowType` – manage
  stereo spread and window shapes with discrete, clamped values.
- `wavetablePosition` – sweep through wavetable indices with aliases like
  `tablePosition` or `wavetableIndex`.
- `microphoneVolume` – surface live-input gain under aliases such as
  `micVolume` or `inputGain`.

Whether presets use canonical keys or shorthand aliases, the registry keeps the
data tidy so the `AudioEngine`, bridge and visualiser all agree on the final
values.

### Performance controls

The registry now tracks performance-oriented parameters alongside the tonal
shaping controls:

- `glideTime` – sets the portamento time (with aliases like `portamento` or
  `glide`) so legato passages sweep smoothly between notes. The backend exposes
  a `portamentoProgress` visualiser metric that mirrors the glide motion.
- `pitchBendRange` – captures the pitch wheel range in semitones and bridges it
  to aliases such as `pitchBend` or `pitchWheelRange`. Captured presets and the
  UI both see the exact same range metadata, keeping expressive bends in sync
  across the app.
- `modWheel` – represents the modulation wheel amount (aliases like
  `modulationWheel` or `modWheelAmount`) and drives the new
  `performanceEnergy` visualiser metric alongside aftertouch and expression.
- `channelAftertouch` – tracks channel pressure data, mirroring aliases such as
  `aftertouch` or `channelPressure` and enabling the UI to reflect finger
  pressure changes in real time.
- `expression` – models expression pedal depth (aliases `expressionPedal` or
  `expressionAmount`) with sensible defaults that keep factory presets loud
  while allowing performers to taper levels.
- `sustainPedal` – exposes the hold/damper pedal state (aliases `sustain` or
  `holdPedal`) and feeds the derived `sustainActive` visualiser flag so shader
  and UI elements know when pedal sustain is engaged.

All presets in the factory library ship with sensible glide and pitch bend
defaults so patches feel playable immediately while remaining easy to tweak or
override in custom sounds. The new performance controllers round this out with
expressive mod wheel, aftertouch, expression pedal, and sustain pedal values so
factory sounds translate directly to live contexts and automation workflows.

### Macro control surfaces

Presets can now bundle macro definitions that sweep multiple parameters in one
gesture. Each [`MacroDefinition`](../lib/core/macro_controls.dart) stores an id,
display name, description, default value, and a set of
[`MacroAssignment`](../lib/core/macro_controls.dart) entries. Assignments
declare which canonical parameter should respond to the macro and the minimum /
maximum normalised range to apply when the macro sits at 0 or 1.

Capturing a preset records the active macro program as an array of
`MacroSnapshot` structures (definition + current value). Loading a preset
replaces the engine’s active macros with those snapshots, reapplies the resolved
parameter values, and notifies listeners if anything changed.

The factory library demonstrates the approach:

- **Glow Pad → “Brightness”** – opens the filter and lifts resonance for airy
  swells.
- **Laser Pluck → “Drive & Width”** – links distortion drive with chorus depth
  so a single macro thickens the lead while adding grit.

Because the engine resolves macros through the shared `ParameterRegistry`,
alias strings and response curves stay consistent across presets, the UI, MIDI
bindings, and the visualiser. UI panels can read
`AudioEngine.macroDefinitions` and `AudioEngine.macroValue(id)` to render macro
knobs, and the snapshot payloads serialise cleanly to JSON for automation or
LLM-assisted preset generation.

### Arpeggiator and phrase programming

The shared registry also coordinates a programmable arpeggiator so presets can
ship with musical phrase data instead of relying on ad-hoc UI state:

- `arpeggiatorEnabled` – toggles the arp on/off (aliases `arpEnabled` or
  `arpeggiatorActive`) and mirrors into the backend for visualiser metrics like
  `arpeggiatorGateOpen`.
- `arpeggiatorRate` – controls the step rate in Hz with an exponential curve so
  slow pulses and brisk runs share a single musical control, including aliases
  such as `arpRate` or `arpeggiatorSpeed`.
- `arpeggiatorGate` – sets the note length per step (aliases `arpGate`), keeping
  values between 0.05 and 1.0 for natural phrasing.
- `arpeggiatorOctaves` – expands the phrase across up to four octaves (aliases
  `arpOctaves`/`arpeggiatorRange`).
- `arpeggiatorMode` / `arpeggiatorPattern` – pick playback directions (`up`,
  `down`, `upDown`, `random`, `chord`) and musical spreads (`asPlayed`,
  `majorTriad`, `minorTriad`, `octaves`, `fifths`) using either numeric indices
  or readable strings.
- `arpeggiatorSwing` – applies shuffle to alternating steps (aliases `arpSwing`
  or `swingAmount`).
- `arpeggiatorLatch` – latches the current chord even after all keys are
  released (aliases `arpLatch` / `arpeggiatorHold`).
- `arpeggiatorTempoSync` – toggles BPM-synchronised playback (aliases
  `arpSync` / `arpeggiatorSync`). When enabled, the backend derives the effective
  step rate from `transportTempo` and the selected division.
- `arpeggiatorDivision` – note division used when tempo sync is active (aliases
  `arpDivision` / `arpeggiatorRateDivision`). Supported values include
  `whole`, `half`, `quarter`, `eighth`, `eighthTriplet`, `sixteenth`,
  `sixteenthTriplet`, and `thirtySecond`.

Factory presets now include curated arpeggiator settings so pads shimmer, plucks
repeat with tempo-synced gates, and keys can launch evolving sequences straight
from preset recall. When registering custom sounds, provide any subset of the
above keys (or their aliases) to keep the audio engine, bridge, and backend in
lockstep.

### Tempo and transport metadata

Presets also carry lightweight transport information so tempo-synchronised
parameters can load with predictable defaults:

- `transportTempo` – BPM value (`tempo` / `bpm`).
- `transportRunning` – indicates whether playback is active (`transportPlay` /
  `transportActive`).
- `transportTimeSignatureNumerator` / `transportTimeSignatureDenominator` –
  expose the current time signature (`tsNumerator` / `tsDenominator`).

Transport parameters can now be adjusted from the holographic interface’s
transport panel (status HUD → **TRANSPORT**), making it easy to audition preset
tempo changes while keeping the saved metadata in sync.

## Working with Presets in `AudioEngine`

The [`AudioEngine`](../lib/core/audio_engine.dart) exposes high-level helpers to
capture, apply, and load presets:

- `capturePreset()` – snapshots the current engine state (including alias values
  for the parameter bridge and the active polyphony limit) and optionally
  persists it to the library.
- `applyPreset()` – applies a strongly typed `SynthPreset`, updates the backend
  and bridge, and marks it as the active preset.
- `loadPreset()` – parses loosely structured maps (e.g. JSON produced by LLMs)
  using a forgiving alias system and loads the resulting parameter set.
- `loadPresetById()` – pulls a preset from the library by identifier and applies
  it.

Every preset application updates the shared `ParameterBridge`, so the UI and
visualiser stay in sync without extra plumbing.

## Parameter Registry

Parameter alias handling and range metadata now live in the
[`ParameterRegistry`](../lib/core/parameter_registry.dart). The registry provides
canonical names, clamps incoming values to sane limits, and mirrors updates to
bridge aliases like `volume` or `polyphony`. Both the audio engine and preset
library rely on the registry to keep user-supplied data tidy, so new presets or
LLM-generated maps automatically benefit from the shared metadata. The registry
also exposes modulation descriptors (`lfoRate`, `lfoDepth`) so alias-aware
imports can light up the new motion controls without additional wiring.

## Importing External Presets

`AudioEngine.loadPreset` accepts permissive `Map<String, dynamic>` structures. It
supports:

- Nested maps like `{ "filter": { "cutoff": 2000 } }`
- Snake-case, kebab-case, dotted paths, and common aliases (e.g. `res`, `volume`)
- Values provided as `num` or numeric strings

This makes it trivial to consume presets generated by AI tools or imported from
legacy data formats.

## Testing Hooks

Unit tests can instantiate the `AudioPresetLibrary` and `AudioEngine` with the
pure Dart `BasicAudioBackend`, as demonstrated in
[`test/audio_engine_test.dart`](../test/audio_engine_test.dart). The tests cover
capturing presets, applying typed presets, parsing nested maps, and loading
factory presets by id, ensuring the new functionality remains stable.

---

For additional integrations (e.g. persisting user presets), hook into the
`AudioPresetLibrary.register`/`upsertPreset` APIs and serialise the
`SynthPreset.toJson()` payloads as needed.

## Related Guides

- [Performance Setlists](performance_setlists.md) – shows how curated run sheets
  wrap existing presets and drive the engine/HUD during live shows.
