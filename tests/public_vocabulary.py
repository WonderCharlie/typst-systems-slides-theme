#!/usr/bin/env python3
"""Single source for retired and project-specific public vocabulary."""

from __future__ import annotations

import re
import sys
from pathlib import Path


FORBIDDEN_PUBLIC_TOKENS = {
    "osdi", "sigcomm", "sosp", "nsdi", "eurosys", "atc", "wofs", "pmfs", "nova",
    "motivation", "key-insight", "conclusion", "question", "problem", "approach", "evaluation",
    "create-stage", "focus-slide", "closing-slide", "showcase", "evidence", "hero-image",
    "three-step-flow", "chart-pair", "grouped-throughput",
}

FORBIDDEN_CORE_TERMS = {
    "osdi", "sigcomm", "sosp", "nsdi", "wofs", "pmfs", "nova",
    "key-insight", "conclusion", "motivation", "evaluation", "create-stage",
}

RETIRED_IDENTIFIERS = (
    "body-points",
    "media-figure",
    "media-row",
    "media-profile",
    "media-item",
    "media-caption",
    "osdi25-asset-path",
    "full-width-image",
    "@preview/systems-slides-template",
)

PAGE_IDENTIFIER_RE = re.compile(r"(?:^|-)(?:p|page|slide)[0-9]{1,3}(?:-|$)")


def naming_violation(identifier: str) -> str | None:
    value = identifier.lower().replace("_", "-")
    if PAGE_IDENTIFIER_RE.search(value):
        return "source-page identifier"
    for phrase in sorted(FORBIDDEN_PUBLIC_TOKENS, key=len, reverse=True):
        if re.search(rf"(?:^|-){re.escape(phrase)}(?:-|$)", value):
            return f"paper or narrative token {phrase}"
    return None


def scan_core(paths: list[Path]) -> int:
    violations: list[str] = []
    for root in paths:
        sources = (root,) if root.is_file() else tuple(sorted(root.rglob("*.typ")))
        for source in sources:
            text = source.read_text(encoding="utf-8")
            for line_number, line in enumerate(text.splitlines(), start=1):
                normalized = line.lower().replace("_", "-")
                for token in FORBIDDEN_CORE_TERMS:
                    if re.search(rf"\b{re.escape(token)}\b", normalized):
                        violations.append(f"{source}:{line_number}: {token}")
    if violations:
        print("public vocabulary check failed:", file=sys.stderr)
        for violation in violations:
            print(f"- {violation}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    if len(sys.argv) < 3 or sys.argv[1] != "scan-core":
        raise SystemExit("usage: public_vocabulary.py scan-core PATH...")
    raise SystemExit(scan_core([Path(value) for value in sys.argv[2:]]))
