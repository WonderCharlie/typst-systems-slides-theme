#!/usr/bin/env python3
"""Verify Catalog logical counters and the nine progressive state groups."""

from __future__ import annotations

import json
import sys
from pathlib import Path


def main() -> int:
    path = Path(sys.argv[1] if len(sys.argv) > 1 else "build/catalog.pdfpc")
    try:
        pages = json.loads(path.read_text(encoding="utf-8"))["pages"]
    except (OSError, KeyError, json.JSONDecodeError) as error:
        print(f"Catalog lifecycle check failed: cannot read {path}: {error}", file=sys.stderr)
        return 1

    expected_labels = (
        "1", "1", "2", "3", "4", "4", "4", "5", "5", "5", "6", "6", "6", "7", "7", "7",
        "8", "8", "8", "9", "10", "11", "12", "13", "14", "14", "14", "15", "15", "15",
        "16", "16", "17", "18", "18", "18", "19", "20", "21", "22", "23", "24", "25", "26", "27",
    )
    labels = tuple(str(page.get("label")) for page in pages)
    errors: list[str] = []
    if labels != expected_labels:
        errors.append(f"unexpected logical labels: {labels}")

    progressive = ((5, 7), (8, 10), (11, 13), (14, 16), (17, 19), (25, 27), (28, 30), (31, 32), (34, 36))
    for first, last in progressive:
        group = pages[first - 1:last]
        if len({page.get("label") for page in group}) != 1:
            errors.append(f"pages {first}-{last} do not share one logical label")
        if tuple(page.get("overlay") for page in group) != tuple(range(last - first + 1)):
            errors.append(f"pages {first}-{last} do not expose consecutive overlay indices")

    if errors:
        print("Catalog lifecycle check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Catalog lifecycle check passed: 45 physical pages preserve nine progressive logical-scene groups.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
