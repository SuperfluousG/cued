#!/usr/bin/env python3
"""Validate a Cued schema-version 2 deck without third-party packages."""

from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path
from typing import Any, Iterable


ID_PATTERN = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
WORD_PATTERN = re.compile(r"[A-Za-z0-9]+(?:['-][A-Za-z0-9]+)*")


def word_count(value: str) -> int:
    return len(WORD_PATTERN.findall(value))


def extra_keys(value: dict[str, Any], allowed: Iterable[str]) -> list[str]:
    allowed_set = set(allowed)
    return sorted(key for key in value if key not in allowed_set)


def validate_data(data: Any) -> tuple[list[str], list[str]]:
    errors: list[str] = []
    warnings: list[str] = []

    if not isinstance(data, dict):
        return ["root: expected an object"], warnings

    extras = extra_keys(data, ("schemaVersion", "title", "cards"))
    if extras:
        errors.append(f"root: unsupported properties: {', '.join(extras)}")

    if data.get("schemaVersion") != 2:
        errors.append("schemaVersion: expected 2")

    title = data.get("title")
    if not isinstance(title, str) or not title.strip():
        errors.append("title: expected a non-empty string")
    elif len(title) > 120:
        errors.append("title: maximum length is 120 characters")

    cards = data.get("cards")
    if not isinstance(cards, list) or not cards:
        errors.append("cards: expected at least one card")
        return errors, warnings

    seen_ids: set[str] = set()
    for card_index, card in enumerate(cards, start=1):
        card_path = f"cards[{card_index}]"
        if not isinstance(card, dict):
            errors.append(f"{card_path}: expected an object")
            continue

        extras = extra_keys(card, ("id", "title", "blocks"))
        if extras:
            errors.append(f"{card_path}: unsupported properties: {', '.join(extras)}")

        card_id = card.get("id")
        if not isinstance(card_id, str) or not ID_PATTERN.fullmatch(card_id):
            errors.append(f"{card_path}.id: expected a unique kebab-case identifier")
        elif card_id in seen_ids:
            errors.append(f"{card_path}.id: duplicate identifier '{card_id}'")
        else:
            seen_ids.add(card_id)

        card_title = card.get("title")
        if not isinstance(card_title, str) or not card_title.strip():
            errors.append(f"{card_path}.title: expected a non-empty string")
        elif word_count(card_title) > 6:
            errors.append(f"{card_path}.title: maximum is 6 words")

        blocks = card.get("blocks")
        if not isinstance(blocks, list) or len(blocks) != 3:
            errors.append(f"{card_path}.blocks: expected exactly 3 blocks")
            continue

        total_words = 0
        for block_index, block in enumerate(blocks, start=1):
            block_path = f"{card_path}.blocks[{block_index}]"
            if not isinstance(block, dict):
                errors.append(f"{block_path}: expected an object")
                continue

            extras = extra_keys(block, ("heading", "bullets"))
            if extras:
                errors.append(f"{block_path}: unsupported properties: {', '.join(extras)}")

            heading = block.get("heading")
            if not isinstance(heading, str) or not heading.strip():
                errors.append(f"{block_path}.heading: expected a non-empty string")

            bullets = block.get("bullets")
            if not isinstance(bullets, list) or not 1 <= len(bullets) <= 3:
                errors.append(f"{block_path}.bullets: expected 1 to 3 bullets")
                continue

            normalised: set[str] = set()
            for bullet_index, bullet in enumerate(bullets, start=1):
                bullet_path = f"{block_path}.bullets[{bullet_index}]"
                if not isinstance(bullet, str) or not bullet.strip():
                    errors.append(f"{bullet_path}: expected a non-empty string")
                    continue

                clean = bullet.strip()
                lowered = clean.casefold()
                if lowered in normalised:
                    errors.append(f"{bullet_path}: duplicate bullet within heading")
                normalised.add(lowered)

                words = word_count(clean)
                total_words += words
                if words > 12:
                    errors.append(f"{bullet_path}: maximum is 12 words; found {words}")
                elif words < 4 or words > 8:
                    warnings.append(f"{bullet_path}: target is 4 to 8 words; found {words}")

        if total_words > 60:
            errors.append(f"{card_path}: maximum is 60 cue words; found {total_words}")

    return errors, warnings


def validate_file(path: Path) -> tuple[list[str], list[str], Any]:
    try:
        with path.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
    except FileNotFoundError:
        return [f"file: not found: {path}"], [], None
    except UnicodeDecodeError:
        return ["file: expected UTF-8 encoding"], [], None
    except json.JSONDecodeError as exc:
        return [f"json: {exc.msg} at line {exc.lineno}, column {exc.colno}"], [], None

    errors, warnings = validate_data(data)
    if not path.name.lower().endswith(".cued.json"):
        errors.append("file: name must end with .cued.json")
    return errors, warnings, data


def main() -> int:
    parser = argparse.ArgumentParser(description="Validate a Cued deck.")
    parser.add_argument("deck", type=Path, help="Path to a .cued.json file")
    parser.add_argument("--quiet", action="store_true", help="Only print errors")
    args = parser.parse_args()

    errors, warnings, data = validate_file(args.deck.resolve())
    for message in errors:
        print(f"ERROR: {message}", file=sys.stderr)
    if not args.quiet:
        for message in warnings:
            print(f"WARNING: {message}")

    if errors:
        return 1

    if not args.quiet:
        print(f"VALID: {len(data['cards'])} cards; schema version 2")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
