#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
APP="$1"
OUTPUT="$2"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
# Use Launch Services to launch the actual application bundle, not swift run.
open -n -W "$APP" --args --smoke-report "$OUTPUT" --fixtures "$REPO_ROOT/tests/fixtures"
python3 - "$OUTPUT/packaged-app-smoke.json" <<'PY'
import json, pathlib, sys
result = json.loads(pathlib.Path(sys.argv[1]).read_text())
print(json.dumps(result, indent=2))
assert result['passed'], 'Packaged app smoke failed'
PY
