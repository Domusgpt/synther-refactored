# Handoff Status

This document captures the latest synthesiser updates, outstanding follow-up
work, and tooling recommendations so the next engineer can pick up where this
iteration ended.

## Latest Changes

- Introduced tempo/transport state (`lib/core/tempo_transport.dart`) to the
  engine, registry, and backend so BPM, play state, and time signature metadata
  synchronise across the bridge, presets, and visualiser metrics.
- Added arpeggiator tempo-sync controls (boolean + note division) with backend
  rate conversion, division parsing, preset capture/load support, and
  alias-aware parameter coercion.
- Refreshed the factory preset library with tempo metadata, sync-aware
  arpeggiator defaults, and documented transport controls so presets now round
  trip BPM/clock information.
- Expanded regression coverage (`test/audio_engine_test.dart`,
  `test/basic_audio_backend_test.dart`, `test/parameter_registry_test.dart`)
  for transport setters, tempo-synchronised arpeggiator behaviour, and registry
  alias handling.
- Added a tempo transport control panel to the holographic UI so BPM, play
  state, and time signature can be tweaked live from the status HUD.

## Outstanding Opportunities

- **UI enhancements:** Extend the modulation panel with preset browsing, route
  search, and quick actions (e.g. duplicate, reorder) to streamline complex
  patch design.
- **Automation sources:** Only a few shorthand source names (e.g. `lfo1`,
  `expression`, `aftertouch`) are validated. Consider enumerating known sources
  or surfacing metadata so the UI can present available modulators.
- **Preset migrations:** Existing saved presets created before the modulation
  matrix feature won’t include routes. If you introduce migrations, ensure the
  loader gracefully upgrades older JSON blobs.
- **Audio backend parity:** The pure Dart backend records modulation analytics
  for the visualiser but does not drive a real DSP graph. Native backends should
  mirror the `ModulationMatrixCodec` contract when implemented.
- **External clocking:** Wire the tempo transport to MIDI clock/Ableton Link so
  tempo-synced presets follow host applications or hardware sequencers.
- **Transport automation:** Build automation lanes or sequencing tools for
  BPM/time-signature changes now that the core UI controls exist.
- **MIDI capture:** The arpeggiator and performance controllers would benefit
  from MIDI clock/transport capture tooling for live sequencing once external
  sync is available.

## Tooling & Environment Notes

- The container environment currently lacks the Flutter/Dart SDK, so commands
  like `flutter test` or `dart test` cannot be executed here. Run
  `tool/setup_dev_environment.sh` to download a local SDK (or install Flutter
  3.19+ globally) before executing the full test suite.
- Use `tool/install_flutter_sdk.sh` if you want to prefetch/update the Flutter
  archive without running diagnostics.
- Add `melos` or `very_good_cli` if you plan to manage multiple packages or run
  lint/test pipelines from a single command.
- Consider installing `dart fix --apply` and `flutter analyze` hooks in CI to
  keep the growing codebase tidy, especially now that modulation routing adds
  richer JSON surface areas.
- For authoring presets or modulation tables, tools like [Open Stage Control](https://openstagecontrol.ammd.net/)
  or the `ctrlr` panel editor can speed up MIDI/controller exploration before
  encoding routes into JSON.
- Install a lightweight BPM tap tool or MIDI clock generator (e.g. `mididings`
  or Ableton Link) when developing the arpeggiator so rate/gate behaviour can be
  verified against external clocks.

## Quick Start for the Next Engineer

1. Run `tool/setup_dev_environment.sh` to download/activate Flutter, pull
   dependencies, and enable web/desktop targets if needed.
2. Execute `flutter test` locally to exercise the expanded regression suite.
3. Explore the modulation matrix by calling `AudioEngine.setModulationRoute` in
   integration tests or the debug console and inspect the visualiser metrics via
   `AudioEngine.getVisualizerData()`.
4. Extend the UI or preset authoring tools to write to
   `ModulationMatrixCodec.encodeBridgeKey(source, destination)` so audio, UI, and
   visualiser layers stay synchronised.

