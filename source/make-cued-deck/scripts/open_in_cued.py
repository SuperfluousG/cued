#!/usr/bin/env python3
"""Validate a deck, then open it in a local Cued installation when available."""

from __future__ import annotations

import argparse
import os
import shlex
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

    if sys.platform == "darwin":
        values.extend(
            [
                str(Path.home() / "Applications" / "Cued.app"),
                "/Applications/Cued.app",
            ]
        )

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


def launch_command(deck: Path, explicit: str | None) -> list[str] | None:
    if sys.platform == "darwin":
        app = next(
            (
                candidate
                for candidate in app_candidates(explicit)
                if candidate.is_dir() and candidate.suffix.casefold() == ".app"
            ),
            None,
        )
        if app is not None:
            return ["open", "-a", str(app), str(deck)]

        resolved = subprocess.run(
            ["open", "-Ra", "Cued"],
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
            check=False,
        )
        if resolved.returncode == 0:
            return ["open", "-a", "Cued", str(deck)]
        return None

    app = next((candidate for candidate in app_candidates(explicit) if candidate.is_file()), None)
    if app is None:
        return None
    return [str(app), str(deck)]


def main() -> int:
    parser = argparse.ArgumentParser(description="Open a validated deck in Cued.")
    parser.add_argument("deck", type=Path)
    parser.add_argument("--app", help="Explicit path to Cued.exe or Cued.app")
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

    command = launch_command(deck, args.app)
    if command is None:
        print(f"Cued was not found. The validated deck is ready at: {deck}")
        return 2

    if args.dry_run:
        display = subprocess.list2cmdline(command) if os.name == "nt" else shlex.join(command)
        print("READY:", display)
        return 0

    subprocess.Popen(command, close_fds=True)
    print(f"OPENED: {deck}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
