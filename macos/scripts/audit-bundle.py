#!/usr/bin/env python3
"""Reject developer paths and build-only material in a distributable Cued app."""
import argparse
import json
from pathlib import Path
import sys


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("app", type=Path)
    parser.add_argument("--source-root", type=Path, required=True)
    args = parser.parse_args()
    executable = args.app / "Contents/MacOS/Cued"
    binary = executable.read_bytes()
    forbidden = {
        "runner-home-path": b"/Users/runner",
        "source-checkout-path": str(args.source_root.resolve()).encode(),
        "SwiftPM-derived-source": b"DerivedSources",
        "SwiftPM-build-path": b"/macos/.build/",
        "generated-resource-accessor": b"resource_bundle_accessor.swift",
    }
    path_hits = [name for name, value in forbidden.items() if value in binary]
    debug_suffixes = {".o", ".dSYM", ".swiftmodule", ".swiftdoc", ".swiftsourceinfo", ".pdb"}
    debug_files = [
        str(path.relative_to(args.app)) for path in args.app.rglob("*")
        if path.suffix in debug_suffixes or path.name == ".build"
    ]
    result = {
        "kind": "macOS-distribution-hygiene",
        "passed": not path_hits and not debug_files,
        "forbiddenPathHits": path_hits,
        "debugFileHits": debug_files,
    }
    print(json.dumps(result, indent=2))
    return 0 if result["passed"] else 1


if __name__ == "__main__":
    sys.exit(main())
