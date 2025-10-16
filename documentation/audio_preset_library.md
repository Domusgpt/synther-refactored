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

All presets in the factory library ship with sensible glide and pitch bend
defaults so patches feel playable immediately while remaining easy to tweak or
override in custom sounds.

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
