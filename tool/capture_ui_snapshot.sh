#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SNAPSHOT_DIR="$PROJECT_ROOT/build/ui_snapshots"
TEST_FILE="test/ui_snapshotter_test.dart"

if ! command -v flutter >/dev/null 2>&1; then
  if [[ -x "$PROJECT_ROOT/.tooling/flutter/bin/flutter" ]]; then
    export PATH="$PROJECT_ROOT/.tooling/flutter/bin:$PATH"
  fi
fi

if ! command -v flutter >/dev/null 2>&1; then
  echo "error: Flutter SDK not found. Run tool/setup_dev_environment.sh first." >&2
  exit 1
fi

mkdir -p "$SNAPSHOT_DIR"

echo "Capturing widget snapshot via flutter test (output: $SNAPSHOT_DIR)"
FLUTTER_BIN="$(command -v flutter)"

"$FLUTTER_BIN" test \
  --update-goldens \
  --dart-define=SNAPSHOT_OUTPUT_DIR="$SNAPSHOT_DIR" \
  "$PROJECT_ROOT/$TEST_FILE"

echo "Snapshot capture complete. Inspect assets under $SNAPSHOT_DIR"
