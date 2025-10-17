#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'MSG'
Usage: tool/prepare_android_apk.sh [--debug|--profile|--release]

Ensures the Flutter SDK is available, fetches dependencies, and then builds an
Android APK using the existing build tooling. The resulting APK path is printed
at the end so the file can be uploaded or shared immediately.
MSG
}

MODE="--release"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --help|-h)
      usage
      exit 0
      ;;
    --debug|--profile|--release)
      MODE="$1"
      shift
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SETUP_SCRIPT="$REPO_ROOT/tool/setup_dev_environment.sh"
BUILD_SCRIPT="$REPO_ROOT/tool/build_artifact.sh"
APK_DIR="$REPO_ROOT/build/app/outputs/flutter-apk"

mkdir -p "$APK_DIR"

echo "[prepare_android_apk] Ensuring Flutter toolchain and dependencies..."
"$SETUP_SCRIPT"

echo "[prepare_android_apk] Building Android APK (${MODE#--})..."
"$BUILD_SCRIPT" android-apk "$MODE"

FLAVOUR=${MODE#--}
APK_PATH="$APK_DIR/app-$FLAVOUR.apk"
if [[ ! -f "$APK_PATH" ]]; then
  # Fallback names Flutter sometimes uses (e.g. app.apk for release builds).
  if [[ -f "$APK_DIR/app.apk" ]]; then
    APK_PATH="$APK_DIR/app.apk"
  else
    echo "[prepare_android_apk] Unable to locate the generated APK under $APK_DIR" >&2
    exit 1
  fi
fi

echo "[prepare_android_apk] APK ready: $APK_PATH"
echo "[prepare_android_apk] Transfer this file to a device or upload it to your distribution channel."
