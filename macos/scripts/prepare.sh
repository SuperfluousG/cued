#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
test -s "$REPO_ROOT/tests/fixtures/unicode-rules.json"
