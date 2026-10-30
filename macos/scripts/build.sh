#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
ARCH="${1:-$(uname -m)}"
case "$ARCH" in arm64|x86_64) ;; *) echo 'Expected arm64 or x86_64' >&2; exit 2 ;; esac
OUTPUT="${2:-$MAC_ROOT/out/$ARCH}"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
bash "$MAC_ROOT/scripts/prepare.sh"
export MACOSX_DEPLOYMENT_TARGET=13.0
swift build --package-path "$MAC_ROOT" --configuration release --arch "$ARCH"
BIN="$(swift build --package-path "$MAC_ROOT" --configuration release --arch "$ARCH" --show-bin-path)"
APP="$OUTPUT/Cued.app"
if [[ -e "$APP" ]]; then echo "Refusing to overwrite an existing bundle: $APP" >&2; exit 2; fi
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN/Cued" "$APP/Contents/MacOS/Cued"
cp "$MAC_ROOT/Config/Info.plist" "$APP/Contents/Info.plist"
cp "$REPO_ROOT/app/sample.cued.json" "$APP/Contents/Resources/sample.cued.json"
RESOURCE_BUNDLE="$(find "$BIN" -maxdepth 1 -name '*CuedCore*.bundle' -print -quit)"
if [[ -z "$RESOURCE_BUNDLE" ]]; then echo 'SwiftPM validation resource bundle missing' >&2; exit 1; fi
cp -R "$RESOURCE_BUNDLE" "$APP/Contents/Resources/"
bash "$MAC_ROOT/scripts/icon.sh" "$APP/Contents/Resources/Cued.icns" "$OUTPUT/icon-build"
chmod +x "$APP/Contents/MacOS/Cued"
plutil -lint "$APP/Contents/Info.plist"
# Ad-hoc signing permits native local testing. It is NOT Developer ID signing
# or notarization and does not establish normal downloaded-app distribution.
codesign --force --sign - "$APP"
codesign --verify --deep --strict --verbose=2 "$APP"
lipo -archs "$APP/Contents/MacOS/Cued" | tee "$OUTPUT/architectures.txt"
file "$APP/Contents/MacOS/Cued" | tee "$OUTPUT/executable-file.txt"
test "$(lipo -archs "$APP/Contents/MacOS/Cued")" = "$ARCH"
otool -l "$APP/Contents/MacOS/Cued" > "$OUTPUT/load-commands.txt"
printf '%s\n' "$APP"
