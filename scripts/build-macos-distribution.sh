#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
BUILD_DIR="$ROOT_DIR/build/macos/Build/Products/Release"
SOURCE_APP="$BUILD_DIR/memaster.app"
OUTPUT_APP_NAME="${OUTPUT_APP_NAME:-memaster.app}"
OUTPUT_APP="$DIST_DIR/$OUTPUT_APP_NAME"
OUTPUT_DMG="${OUTPUT_APP%.app}.dmg"
SERVICE_SRC="$ROOT_DIR/service"
SERVICE_DST="$OUTPUT_APP/Contents/Resources/service"
RELEASE_ENTITLEMENTS="$ROOT_DIR/macos/Runner/Release.entitlements"
FLUTTER_BIN="${FLUTTER_BIN:-${HOME:-}/flutter/bin/flutter}"
CREATE_DMG="${CREATE_DMG:-1}"
EMBEDDED_PYTHON_VERSION="${EMBEDDED_PYTHON_VERSION:-3.14.3}"

require_cmd() {
  local name="$1"
  if ! command -v "$name" >/dev/null 2>&1; then
    echo "Error: missing required command: $name" >&2
    exit 1
  fi
}

if [[ ! -x "$FLUTTER_BIN" ]]; then
  if command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  else
    echo "Error: flutter is not installed and FLUTTER_BIN is not set." >&2
    exit 1
  fi
fi

require_cmd rsync
require_cmd ditto
require_cmd codesign
require_cmd uv

mkdir -p "$DIST_DIR"

echo "Building release macOS app..."
"$FLUTTER_BIN" build macos

if [[ ! -d "$SOURCE_APP" ]]; then
  echo "Error: expected built app at $SOURCE_APP" >&2
  exit 1
fi

echo "Preparing app bundle at $OUTPUT_APP..."
rm -rf "$OUTPUT_APP"
ditto "$SOURCE_APP" "$OUTPUT_APP"

echo "Embedding local service..."
rm -rf "$SERVICE_DST"
mkdir -p "$SERVICE_DST"
rsync -aL \
  --delete \
  --exclude '.venv/' \
  --exclude '.pytest_cache/' \
  --exclude '__pycache__/' \
  --exclude 'data/' \
  --exclude 'tests/' \
  --exclude '.DS_Store' \
  "$SERVICE_SRC/" "$SERVICE_DST/"

prepare_embedded_runtime() {
  local managed_python
  managed_python="$(uv python find "$EMBEDDED_PYTHON_VERSION" 2>/dev/null || true)"
  if [[ -z "$managed_python" ]]; then
    echo "Installing managed Python $EMBEDDED_PYTHON_VERSION for distribution..."
    uv python install "$EMBEDDED_PYTHON_VERSION"
    managed_python="$(uv python find "$EMBEDDED_PYTHON_VERSION")"
  fi

  if [[ ! -x "$managed_python" ]]; then
    echo "Error: managed Python $EMBEDDED_PYTHON_VERSION not found." >&2
    exit 1
  fi

  local managed_root
  managed_root="$(dirname "$(dirname "$managed_python")")"
  if [[ ! -d "$managed_root" ]]; then
    echo "Error: expected managed Python root at $managed_root" >&2
    exit 1
  fi

  local embedded_runtime="$SERVICE_DST/.venv"
  echo "Embedding managed Python runtime from $managed_root..."
  rm -rf "$embedded_runtime"
  ditto "$managed_root" "$embedded_runtime"

  echo "Installing service dependencies into embedded runtime..."
  (
    cd "$SERVICE_DST"
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
      "$embedded_runtime/bin/python" -m pip install --break-system-packages .
  )
}

prepare_embedded_runtime

cat >"$OUTPUT_APP/Contents/Resources/memaster-release.txt" <<EOF
This bundle contains:
- Flutter desktop app
- Embedded local FastAPI service
- Embedded Python virtual environment under Resources/service/.venv

On first launch the app will:
1. Start the bundled local service
2. Create its writable data directory under Application Support
3. Ask the user to add the first source and trigger the first scan
EOF

echo "Re-signing app bundle after embedding service..."
codesign \
  --force \
  --deep \
  --sign - \
  --entitlements "$RELEASE_ENTITLEMENTS" \
  "$OUTPUT_APP"

echo "Embedded app ready: $OUTPUT_APP"

if [[ "$CREATE_DMG" != "1" ]]; then
  echo "Skipping DMG creation because CREATE_DMG=$CREATE_DMG"
  exit 0
fi

require_cmd hdiutil

echo "Creating DMG at $OUTPUT_DMG..."
rm -f "$OUTPUT_DMG"
hdiutil create \
  -volname "memaster" \
  -srcfolder "$OUTPUT_APP" \
  -ov \
  -format UDZO \
  "$OUTPUT_DMG" >/dev/null

echo "Distribution artifacts:"
echo "- App: $OUTPUT_APP"
echo "- DMG: $OUTPUT_DMG"
