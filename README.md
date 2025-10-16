# Synther Refactored

A lightweight Flutter shell that keeps the Synther project compiling while the
larger audio and visualizer stacks are rewritten. The goal of this revision is
to provide a clean starting point with a focused UI that runs everywhere out of
the box.

## What's Included

- Minimal `MaterialApp` entry point (`lib/main.dart`).
- Vaporwave-inspired dashboard stub with responsive layout and animated level
  meter (`lib/ui/vaporwave_dashboard.dart`).
- Dark theme defaults so the app looks polished even without the legacy
  holographic design system.

## What's Not Included (Yet)

All previous integrations (audio engines, AI preset generators, premium flows,
WebGL visualizer, microphone bridge, etc.) were removed because they were
broken or depended on code that no longer exists. They can be rebuilt on top of
this shell as discrete, testable modules.

## Getting Started

```bash
flutter pub get
flutter analyze
flutter test
flutter run
```

The repository now uses only the default Flutter SDK dependencies, so the
commands above should succeed on a clean machine.

## Next Steps

- Reintroduce audio backends with clear platform boundaries.
- Rebuild the visualizer as a standalone package before embedding it.
- Add integration tests as new features land.
- Update documentation alongside each subsystem as it returns.
