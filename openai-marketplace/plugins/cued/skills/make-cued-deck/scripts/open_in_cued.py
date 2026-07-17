#!/usr/bin/env python3
"""Validate a deck, then open it in a local Cued installation when available."""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
from pathlib import Path

from validate_cued import validate_file


def app_candidates(explicit: str | None) -> list[Path]:
    values: list[str] = []
    if explicit:
        values.append(explicit)
    if os.environ.get("CUED_APP"):
        values.append(os.environ["CUED_APP"])

    located = shutil.which("Cued.exe") or shutil.which("Cued")
    if located:
        values.append(located)

    local = os.environ.get("LOCALAPPDATA")
    program_files = os.environ.get("ProgramFiles")
    user_profile = os.environ.get("USERPROFILE")
    if user_profile:
        values.append(str(Path(user_profile) / "Cued" / "Cued.exe"))
    if local:
        values.extend(
            [
                str(Path(local) / "Programs" / "Cued" / "Cued.exe"),
                str(Path(local) / "Cued" / "Cued.exe"),
            ]
        )
    if program_files:
        values.append(str(Path(program_files) / "Cued" / "Cued.exe"))

    values.append(str(Path.cwd() / "Cued.exe"))

    seen: set[str] = set()
    candidates: list[Path] = []
    for value in values:
        candidate = Path(value).expanduser().resolve()
        key = str(candidate).casefold()
        if key not in seen:
            seen.add(key)
            candidates.append(candidate)
    return candidates


def main() -> int:
    parser = argparse.ArgumentParser(description="Open a validated deck in Cued.")
    parser.add_argument("deck", type=Path)
    parser.add_argument("--app", help="Explicit path to Cued.exe")
    parser.add_argument("--dry-run", action="store_true", help="Validate and print the launch command")
    args = parser.parse_args()

    deck = args.deck.expanduser().resolve()
    errors, warnings, _ = validate_file(deck)
    for warning in warnings:
        print(f"WARNING: {warning}")
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return 1

    app = next((candidate for candidate in app_candidates(args.app) if candidate.is_file()), None)
    if app is None:
        print(f"Cued was not found. The validated deck is ready at: {deck}")
        return 2

    command = [str(app), str(deck)]
    if args.dry_run:
        print("READY:", subprocess.list2cmdline(command))
        return 0

    subprocess.Popen(command, close_fds=True)
    print(f"OPENED: {deck}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
