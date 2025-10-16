# Flutter & Dart Development Environment

This guide walks through installing the tooling required to work on Synther
Refactored. The project is a standard Flutter application, so the instructions
mirror Flutter’s recommended workflow with a few project specific notes.

## 1. Bootstrap Flutter & Dart with the helper script

Run the repository’s bootstrap script from the project root:

```bash
./tool/setup_dev_environment.sh
```

The script will:

- Download the latest stable Flutter SDK (and bundled Dart SDK) into
  `.tooling/flutter` if one is not already available.
- Add the downloaded SDK to the `PATH` for the duration of the script so its
  commands can run immediately.
- Run `flutter doctor` to diagnose missing dependencies.
- Fetch project packages with `flutter pub get` and enable web/desktop targets
  by default.

The script relies on standard command-line utilities (`curl`, `tar`, and
`python3` – plus `unzip` on Windows). Install them via your system package
manager if they are not already present.

Set `FLUTTER_CHANNEL`, `FLUTTER_VERSION`, or `FLUTTER_INSTALL_DIR` to customise
which release is fetched and where it lives. If you already have a global
Flutter installation on your `PATH`, the script uses it as-is without fetching a
local copy. Add `.tooling/flutter/bin` to your shell profile if you want the
downloaded SDK available after the script exits.

Need the SDK without running diagnostics? Invoke
`./tool/install_flutter_sdk.sh` directly to fetch and unpack the archive.

> **Note:** Flutter ships with its own copy of the Dart SDK, so installing or
> downloading Flutter is sufficient unless you explicitly need a standalone Dart
> install for other projects.

## 2. Verify Your Environment

After the script completes (or if you installed Flutter manually), run:

```bash
flutter --version
flutter doctor
```

Resolve any issues highlighted by `flutter doctor`, such as missing Android
Studio, Xcode, or command line tools.

## 3. Fetch Project Dependencies

If you prefer manual steps instead of the helper script, run:

```bash
flutter pub get
```

## 4. Recommended Tooling

- **VS Code** with the Flutter extension or **Android Studio/IntelliJ** with the
  Flutter and Dart plugins for debugging, hot reload, and code completion.
- **Android SDK & emulators** for Android builds. Install via Android Studio.
- **Xcode** (macOS only) for building and testing on iOS.
- **Chrome** or another supported browser when targeting Flutter Web.

## 5. Useful Commands

```bash
flutter run            # Launch the application on a chosen device
flutter analyze        # Static analysis using flutter_lints configuration
flutter test           # Run widget and unit tests
dart format lib test   # Format the Dart source code
tool/build_artifact.sh web   # Example scripted build (see distribution guide)
```

## 6. Troubleshooting Checklist

- **Flutter command not found** – Double check that the `flutter/bin` directory is
  exported in your shell profile (`.bashrc`, `.zshrc`, etc.).
- **Android licences not accepted** – Run `flutter doctor --android-licenses`.
- **CocoaPods errors on macOS** – Install CocoaPods using `sudo gem install
  cocoapods` and re-run `pod install` in the `ios` directory if necessary.
- **Web builds not enabled** – Re-run `./tool/setup_dev_environment.sh` or
  manually execute `flutter config --enable-web` and restart your IDE.

## 7. Building for Players & Performers

Once your environment is healthy, consult the
[Distribution & Playability Guide](distribution_guide.md) for platform-specific
commands that produce Android APKs, desktop builds, or static web bundles that
can be hosted online.

By following these steps you will have the complete toolchain required to work
on the Flutter and Dart portions of the project.
