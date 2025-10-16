#!/usr/bin/env bash
set -euo pipefail

# Ensures Flutter/Dart tooling is available and fetches project dependencies.

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEFAULT_FLUTTER_HOME="$REPO_ROOT/.tooling/flutter"
LOCAL_FLUTTER_HOME="${FLUTTER_INSTALL_DIR:-$DEFAULT_FLUTTER_HOME}"
LOCAL_FLUTTER_BIN="$LOCAL_FLUTTER_HOME/bin"
INSTALL_SCRIPT="$REPO_ROOT/tool/install_flutter_sdk.sh"

ensure_flutter_on_path() {
  if command -v flutter >/dev/null 2>&1; then
    return
  fi

  if [[ -x "$LOCAL_FLUTTER_BIN/flutter" ]]; then
    export PATH="$LOCAL_FLUTTER_BIN:$PATH"
    return
  fi

  echo "Flutter SDK not found. Downloading to $LOCAL_FLUTTER_HOME..." >&2
  FLUTTER_INSTALL_DIR="$LOCAL_FLUTTER_HOME" "$INSTALL_SCRIPT"
  export PATH="$LOCAL_FLUTTER_BIN:$PATH"
}

ensure_dart_on_path() {
  if command -v dart >/dev/null 2>&1; then
    return
  fi

  if [[ -x "$LOCAL_FLUTTER_BIN/dart" ]]; then
    export PATH="$LOCAL_FLUTTER_BIN:$PATH"
    return
  fi

  echo "Dart SDK not found and Flutter download failed to provide it." >&2
  exit 1
}

ensure_flutter_on_path
ensure_dart_on_path

flutter --version
flutter doctor

# Optionally enable additional platforms. Controlled by environment variables so
# CI or developers can opt out by exporting the value to 0.
if [[ "${ENABLE_FLUTTER_WEB:-1}" == "1" ]]; then
  flutter config --enable-web
fi

if [[ "${ENABLE_FLUTTER_DESKTOP:-1}" == "1" ]]; then
  flutter config --enable-windows-desktop || true
  flutter config --enable-macos-desktop || true
  flutter config --enable-linux-desktop || true
fi

flutter pub get

dart --version

echo "\nFlutter and Dart dependencies fetched successfully."
