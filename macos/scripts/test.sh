#!/bin/bash
set -euo pipefail
MAC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$MAC_ROOT/.." && pwd)"
OUTPUT="${1:-$MAC_ROOT/out/evidence}"
mkdir -p "$OUTPUT"
OUTPUT="$(cd "$OUTPUT" && pwd)"
bash "$MAC_ROOT/scripts/prepare.sh"
export CUED_FIXTURES="$REPO_ROOT/tests/fixtures"
export CUED_FIXTURE_REPORT="$OUTPUT/mac-fixture-results.json"
{
  sw_vers
  uname -m
  xcodebuild -version
  xcrun --sdk macosx --show-sdk-version
  swift --version
} > "$OUTPUT/build-environment.txt"
swift test --package-path "$MAC_ROOT" 2>&1 | tee "$OUTPUT/swift-tests.log"
