# Flutter & Dart Development Environment

This guide walks through installing the tooling required to work on Synther
Refactored. The project is a standard Flutter application, so the instructions
mirror Flutter’s recommended workflow with a few project specific notes.

## 1. Install Flutter (bundles Dart)

1. Download the Flutter SDK for your platform from the
   [official installation page](https://docs.flutter.dev/get-started/install).
2. Extract the archive and add the `flutter/bin` directory to your `PATH`.
3. Run `flutter doctor` to download additional components and check that your
   environment is ready.

> **Note:** Flutter ships with its own copy of the Dart SDK. Installing Flutter
> is sufficient unless you specifically want a standalone Dart installation for
> other projects.

## 2. Verify Your Environment

After Flutter is installed and on the `PATH`, run:

```bash
flutter --version
flutter doctor
```

Resolve any issues highlighted by `flutter doctor`, such as missing Android
Studio, Xcode, or command line tools.

## 3. Fetch Project Dependencies

From the repository root, execute the helper script included in this project:

```bash
./tool/setup_dev_environment.sh
```

The script ensures that both `flutter` and `dart` are available, prints
diagnostic information, and runs `flutter pub get` to download dependencies.
It also enables Flutter web and desktop targets by default so you can run the
app in a browser or as a native desktop executable. Set
`ENABLE_FLUTTER_WEB=0` and/or `ENABLE_FLUTTER_DESKTOP=0` before invoking the
script if you prefer to skip those steps.

If you prefer manual steps, run:

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
