#!/usr/bin/env bash
set -euo pipefail

# Downloads and extracts the Flutter SDK into a local tooling directory.
# Respects FLUTTER_CHANNEL (defaults to stable), FLUTTER_VERSION (optional), and
# FLUTTER_INSTALL_DIR (defaults to ".tooling/flutter").

CHANNEL="${FLUTTER_CHANNEL:-stable}"
REQUESTED_VERSION="${FLUTTER_VERSION:-}"
INSTALL_DIR="${FLUTTER_INSTALL_DIR:-$(pwd)/.tooling/flutter}"

if ! command -v curl >/dev/null 2>&1; then
  echo "curl is required to download Flutter. Please install curl and retry." >&2
  exit 1
fi

if ! command -v tar >/dev/null 2>&1; then
  echo "tar is required to extract the Flutter archive. Please install tar and retry." >&2
  exit 1
fi

SYSTEM=$(uname -s | tr '[:upper:]' '[:lower:]')
case "$SYSTEM" in
  linux*) PLATFORM="linux" ;;
  darwin*) PLATFORM="macos" ;;
  msys*|mingw*|cygwin*) PLATFORM="windows" ;;
  *)
    echo "Unsupported platform: $SYSTEM" >&2
    exit 1
    ;;
esac

if [[ "$PLATFORM" == "windows" ]] && ! command -v unzip >/dev/null 2>&1; then
  echo "unzip is required to extract the Flutter archive on Windows." >&2
  exit 1
fi

METADATA_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_${PLATFORM}.json"
TMP_JSON=$(mktemp)
TMP_ARCHIVE=$(mktemp)
cleanup() {
  rm -f "$TMP_JSON" "$TMP_ARCHIVE"
}
trap cleanup EXIT

curl -sSL "$METADATA_URL" -o "$TMP_JSON"

ARCHIVE_PATH=$(CHANNEL="$CHANNEL" REQUESTED_VERSION="$REQUESTED_VERSION" TMP_JSON="$TMP_JSON" python3 - <<'PY'
import json
import os
import sys

channel = os.environ["CHANNEL"]
requested_version = os.environ["REQUESTED_VERSION"]
with open(os.environ["TMP_JSON"]) as fh:
    meta = json.load(fh)

releases = meta["releases"]
if requested_version:
    release = next((r for r in releases if r["version"] == requested_version), None)
    if release is None:
        sys.stderr.write(f"Unable to find Flutter version {requested_version} for this platform.\n")
        sys.exit(1)
else:
    current = meta["current_release"].get(channel)
    if not current:
        sys.stderr.write(f"Channel '{channel}' is not available for this platform.\n")
        sys.exit(1)
    release = next((r for r in releases if r["hash"] == current), None)
    if release is None:
        sys.stderr.write(f"Unable to resolve release for channel '{channel}'.\n")
        sys.exit(1)

print(release["archive"])
PY
)

DOWNLOAD_URL="https://storage.googleapis.com/flutter_infra_release/releases/${ARCHIVE_PATH}"

echo "Downloading Flutter SDK from ${DOWNLOAD_URL}" >&2
curl -# -SL "$DOWNLOAD_URL" -o "$TMP_ARCHIVE"

rm -rf "$INSTALL_DIR"
mkdir -p "$(dirname "$INSTALL_DIR")"

if [[ "$PLATFORM" == "windows" ]]; then
  unzip -q "$TMP_ARCHIVE" -d "$(dirname "$INSTALL_DIR")"
else
  tar xf "$TMP_ARCHIVE" -C "$(dirname "$INSTALL_DIR")"
fi

EXTRACTED_DIR="$(dirname "$INSTALL_DIR")/flutter"
if [[ "$EXTRACTED_DIR" != "$INSTALL_DIR" ]]; then
  rm -rf "$INSTALL_DIR"
  mv "$EXTRACTED_DIR" "$INSTALL_DIR"
fi

echo "Flutter SDK installed to $INSTALL_DIR"
