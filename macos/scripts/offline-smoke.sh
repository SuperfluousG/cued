#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
APP="$1"
OUTPUT="$2"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
# Process-scoped test restriction only; no system network/security settings change.
# Launch the packaged executable directly so it inherits the network deny policy.
POLICY='(version 1) (allow default) (deny network*)'
printf '%s\n' "$POLICY" > "$OUTPUT/process-sandbox-policy.sb"
/usr/bin/sandbox-exec -p "$POLICY" "$APP/Contents/MacOS/Cued" \
  --smoke-report "$OUTPUT" --fixtures "$REPO_ROOT/tests/fixtures" 2>&1 | tee "$OUTPUT/offline-launch.log"
python3 - "$OUTPUT/packaged-app-smoke.json" <<'PY'
import json, pathlib, sys
result = json.loads(pathlib.Path(sys.argv[1]).read_text())
assert result['passed'], 'Network-denied packaged app smoke failed'
print('PASS: packaged app launch, load, playback and local settings under deny network* policy')
PY
