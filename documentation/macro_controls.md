# Macro Control Workflow

Macro controls let you design performance-ready knobs and sliders that fan out
across multiple parameters. Each macro stores a definition (name, description,
assignments, and default value) plus the current position. The audio engine uses
the shared `ParameterRegistry` metadata to translate macro values into
parameter-safe ranges, so presets, the UI, visualiser metrics, and MIDI bindings
all stay in sync.

## Runtime architecture

- **Definitions** – `MacroDefinition` exposes the macro id, display name,
description, default value, and a list of `MacroAssignment` entries. Each
assignment targets a canonical parameter and specifies the normalised range that
should respond to the macro.
- **Controller** – `MacroController` tracks registered definitions, normalises
incoming values, and resolves them into concrete parameter updates using the
registry’s curves/ranges. The controller also emits snapshot objects for preset
capture and accepts snapshot payloads when loading presets.
- **Audio engine integration** – `AudioEngine` hosts a controller instance,
exposes helpers like `registerMacro`, `setMacroValue`, and `macroDefinitions`,
and pipes resolved updates through the existing parameter setter map so bridge
aliases, the backend, and visualiser metrics update automatically.
- **Preset capture & load** – macros are included in `SynthPreset` snapshots.
Captured presets persist definitions and their current values, and loading a
preset replaces the active macro program before applying parameter deltas.

## Holographic Macro Panel

Open the status HUD and tap **MACROS** to launch the macro control panel:

- **Live sliders** – every registered macro renders as a glassy card with a
  slider, current percentage, and optional description. Moving the slider calls
  `AudioEngine.setMacroValue` so presets, the backend, and bridge metrics update
  immediately.
- **Assignment summaries** – each card lists the targeted parameters with their
  resolved value ranges, making it clear how a macro shapes the sound.
- **Quick actions** – reset all macros to their definition defaults or clear the
  macro program entirely using the footer controls (the reset button calls
  `AudioEngine.resetMacroValues`).

## Creating macros

```dart
await engine.registerMacro(
  MacroDefinition(
    id: 'performance-rise',
    name: 'Performance Rise',
    description: 'Opens the filter while adding drive.',
    assignments: <MacroAssignment>[
      MacroAssignment(parameterId: 'filterCutoff', minNormalized: 0.4, maxNormalized: 1.0),
      MacroAssignment(parameterId: 'distortionDrive', minNormalized: 0.2, maxNormalized: 0.8),
    ],
    defaultValue: 0.25,
  ),
);

await engine.setMacroValue('performance-rise', 0.65);
```

The controller clamps macro values to `0.0–1.0`, denormalises them using the
assigned parameter curves, and emits one update per assignment. If the resolved
value matches the current parameter, the engine skips redundant updates so
listeners are only notified when state changes.

## Preset integration

- **Capture** – `AudioEngine.capturePreset` records the current macro program by
serialising each `MacroSnapshot` into the preset payload.
- **Apply** – `AudioEngine.applyPreset` replaces any active macros with the
preset snapshots, reapplies their values, and reflects the resolved parameters
through the backend, bridge, and UI listeners.
- **Factory data** – curated sounds in `AudioPresetLibrary` can ship with macros.
The built-in “Glow Pad” and “Laser Pluck” presets demonstrate how to couple
macros with expressive performance sweeps.

## Tips for UI & handoff

- Use `engine.macroDefinitions` and `engine.macroValue(id)` to build macro
panels or extend the built-in sheet. The collection is exposed as an
unmodifiable list for direct UI binding.
- When building automation or MIDI workflows, reuse macro ids so presets and
hardware controllers stay aligned.
- Include macro descriptions in docs/tooltips so future contributors understand
the intended movement (e.g. “Brighten”, “Drive & Width”).
