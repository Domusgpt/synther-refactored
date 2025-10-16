# Handoff Status

This document captures the latest synthesiser updates, outstanding follow-up
work, and tooling recommendations so the next engineer can pick up where this
iteration ended.

## Latest Changes

- Added a reusable modulation matrix (`lib/core/modulation_matrix.dart`) and
  integrated it with `AudioEngine`, presets, and the parameter bridge so
  modulation routes (e.g. LFO → filter cutoff) persist across
  captures, loads, and visualiser updates.
- Extended the preset library and `SynthPreset` model to store
  modulation routes alongside canonical parameters, seeded the factory presets
  with expressive default routings, and documented the JSON shapes accepted by
  `AudioEngine.loadPreset`.
- Expanded the regression suite (`test/audio_engine_test.dart` and
  `test/modulation_matrix_test.dart`) to cover modulation matrix behaviour,
  visualiser metrics, preset capture/application, and alias-aware parsing of
  modulation payloads.
- Updated documentation (README and preset guide) with modulation-matrix
  guidance, new metrics, and entry points for engineers exploring the system.
- Added four assignable macro controllers to the parameter registry, audio
  engine, and backend metrics so presets can expose performance macros with
  alias-aware bridge syncing and visualiser support.

## Outstanding Opportunities

- **UI controls:** The Flutter UI does not yet surface a dedicated modulation
  routing editor. Wire up controls that publish bridge updates using the
  `modMatrix.*` keys so performers can add/remove routes interactively.
- **Macro surfaces:** Surface the new macro controllers in the UI (knobs, pads,
  or MIDI learn) so performers can tweak them live and author automation clips
  without hand-editing JSON.
- **Automation sources:** Only a few shorthand source names (e.g. `lfo1`,
  `expression`, `aftertouch`) are validated. Consider enumerating known sources
  or surfacing metadata so the UI can present available modulators.
- **Preset migrations:** Existing saved presets created before the modulation
  matrix feature won’t include routes. If you introduce migrations, ensure the
  loader gracefully upgrades older JSON blobs.
- **Audio backend parity:** The pure Dart backend records modulation analytics
  for the visualiser but does not drive a real DSP graph. Native backends should
  mirror the `ModulationMatrixCodec` contract when implemented.

## Tooling & Environment Notes

- The container environment currently lacks the Flutter/Dart SDK, so commands
  like `flutter test` or `dart test` cannot be executed here. Install Flutter
  (3.19+) locally to run the full test suite.
- Add `melos` or `very_good_cli` if you plan to manage multiple packages or run
  lint/test pipelines from a single command.
- Consider installing `dart fix --apply` and `flutter analyze` hooks in CI to
  keep the growing codebase tidy, especially now that modulation routing adds
  richer JSON surface areas.
- For authoring presets or modulation tables, tools like [Open Stage Control](https://openstagecontrol.ammd.net/)
  or the `ctrlr` panel editor can speed up MIDI/controller exploration before
  encoding routes into JSON.

## Quick Start for the Next Engineer

1. Install Flutter (`flutter doctor`) and run `tool/setup_dev_environment.sh`
   to pull dependencies and enable web/desktop targets if needed.
2. Execute `flutter test` locally to exercise the expanded regression suite.
3. Explore the modulation matrix by calling `AudioEngine.setModulationRoute` in
   integration tests or the debug console and inspect the visualiser metrics via
   `AudioEngine.getVisualizerData()`.
4. Extend the UI or preset authoring tools to write to
   `ModulationMatrixCodec.encodeBridgeKey(source, destination)` so audio, UI, and
   visualiser layers stay synchronised.

