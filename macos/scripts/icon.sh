#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
DESTINATION="$1"
WORK="$2"
mkdir -p "$WORK/Cued.iconset"
# Retain the exact existing Cued artwork. The Windows ICO contains PNG frames.
python3 - "$REPO_ROOT/development/icon/cued.ico" "$WORK/original.png" <<'PY'
import pathlib, struct, sys
data = pathlib.Path(sys.argv[1]).read_bytes()
count = struct.unpack_from('<H', data, 4)[0]
entries = [struct.unpack_from('<BBBBHHII', data, 6 + i * 16) for i in range(count)]
largest = max(entries, key=lambda item: (item[0] or 256) * (item[1] or 256))
size, offset = largest[-2:]
png = data[offset:offset + size]
assert png.startswith(b'\x89PNG\r\n\x1a\n')
pathlib.Path(sys.argv[2]).write_bytes(png)
PY
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" "$WORK/original.png" --out "$WORK/Cued.iconset/icon_${size}x${size}.png" >/dev/null
  doubled=$((size * 2))
  sips -z "$doubled" "$doubled" "$WORK/original.png" --out "$WORK/Cued.iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$WORK/Cued.iconset" -o "$DESTINATION"
