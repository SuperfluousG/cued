#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
mkdir -p "$MAC_ROOT/Sources/CuedCore/Resources"
cp "$REPO_ROOT/tests/fixtures/unicode-rules.json" "$MAC_ROOT/Sources/CuedCore/Resources/unicode-rules.json"
