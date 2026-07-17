#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
MAC_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
DIST="$MAC_ROOT/dist"
APP="$DIST/Cued.app"
CONTENTS="$APP/Contents"
RESOURCES="$CONTENTS/Resources"

rm -rf "$DIST"
mkdir -p "$CONTENTS/MacOS" "$RESOURCES"

cd "$MAC_ROOT"
swift build -c release --arch arm64
BIN_PATH="$(swift build -c release --arch arm64 --show-bin-path)"
cp "$BIN_PATH/Cued" "$CONTENTS/MacOS/Cued"
cp "$MAC_ROOT/Config/Info.plist" "$CONTENTS/Info.plist"

RESOURCE_BUNDLE="$(find "$BIN_PATH" -maxdepth 1 -type d -name '*.bundle' -print -quit)"
if [[ -z "$RESOURCE_BUNDLE" ]]; then
    echo "Swift resource bundle was not produced." >&2
    exit 1
fi
cp -R "$RESOURCE_BUNDLE" "$RESOURCES/"

mkdir -p "$RESOURCES/CuedSupport"
cp -R "$REPO_ROOT/source/make-cued-deck" "$RESOURCES/CuedSupport/make-cued-deck"
cp "$REPO_ROOT/packages/make-cued-deck-claude.zip" "$RESOURCES/CuedSupport/make-cued-deck-claude.zip"

ICON_PNG="$DIST/cued-icon-1024.png"
ICONSET="$DIST/Cued.iconset"
swift "$SCRIPT_DIR/render-icon.swift" "$MAC_ROOT/Resources/cued-icon.svg" "$ICON_PNG"
mkdir -p "$ICONSET"
for size in 16 32 128 256 512; do
    sips -z "$size" "$size" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}.png" >/dev/null
    double=$((size * 2))
    sips -z "$double" "$double" "$ICON_PNG" --out "$ICONSET/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$ICONSET" -o "$RESOURCES/Cued.icns"

plutil -lint "$CONTENTS/Info.plist"
codesign --force --deep --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
file "$CONTENTS/MacOS/Cued" | tee "$DIST/binary.txt"
if ! grep -q "arm64" "$DIST/binary.txt"; then
    echo "Cued is not an Apple Silicon executable." >&2
    exit 1
fi

ditto -c -k --sequesterRsrc --keepParent "$APP" "$DIST/Cued-macOS-1.0.0-inspection.zip"
shasum -a 256 "$DIST/Cued-macOS-1.0.0-inspection.zip" > "$DIST/SHA256SUMS.txt"
echo "Built $APP"

