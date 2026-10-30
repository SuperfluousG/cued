#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
ARCH="${1:-$(uname -m)}"
APP="$2"
OUTPUT="$3"
case "$ARCH" in arm64|x86_64) ;; *) echo 'Expected arm64 or x86_64' >&2; exit 2 ;; esac
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
NAME="Cued-1.1.0-rc.1-macOS-$ARCH-unnotarized-test"
STAGE="$OUTPUT/$NAME"
if [[ -e "$STAGE" ]]; then echo "Refusing to overwrite existing package: $STAGE" >&2; exit 2; fi
mkdir -p "$STAGE/Skills"
cp -R "$APP" "$STAGE/Cued.app"
cp "$REPO_ROOT/app/sample.cued.json" "$STAGE/sample.cued.json"
cp "$REPO_ROOT/docs/macos/README.md" "$STAGE/README.md"
cp -R "$REPO_ROOT/source/make-cued-deck" "$STAGE/Skills/"
python3 - "$REPO_ROOT/source/make-cued-deck" "$STAGE/Skills/make-cued-deck-claude.zip" <<'PY'
import pathlib, sys, zipfile
source = pathlib.Path(sys.argv[1])
with zipfile.ZipFile(sys.argv[2], 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in sorted(source.rglob('*')):
        if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc':
            archive.write(path, pathlib.Path('make-cued-deck') / path.relative_to(source))
PY
if [[ -d "$REPO_ROOT/openai-marketplace" ]]; then ditto -c -k --sequesterRsrc --keepParent "$REPO_ROOT/openai-marketplace" "$STAGE/Skills/cued-openai-marketplace.zip"; fi
printf '1.1.0-rc.1\nmacOS %s\nUnnotarized test build; no Developer ID signature.\n' "$ARCH" > "$STAGE/VERSION.txt"
git -C "$REPO_ROOT" rev-parse HEAD > "$STAGE/SOURCE-COMMIT.txt"
(
  cd "$STAGE"
  find . -type f ! -name SHA256SUMS.txt -print0 | LC_ALL=C sort -z | xargs -0 shasum -a 256 > SHA256SUMS.txt
)
ditto -c -k --sequesterRsrc --keepParent "$STAGE" "$OUTPUT/$NAME.zip"
shasum -a 256 "$OUTPUT/$NAME.zip" > "$OUTPUT/$NAME.zip.sha256"
printf '%s\n' "$OUTPUT/$NAME.zip"
