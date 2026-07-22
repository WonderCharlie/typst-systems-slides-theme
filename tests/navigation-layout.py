#!/usr/bin/env python3
"""Verify Roadmap bullets and automatic vertical distribution."""

from __future__ import annotations

import subprocess
import sys
import tempfile
import html
import re
from pathlib import Path


def fail(message: str) -> None:
    raise SystemExit(f"navigation layout check failed: {message}")


def main() -> int:
    if len(sys.argv) != 2:
        fail("usage: navigation-layout.py <navigation.pdf>")
    pdf = Path(sys.argv[1]).resolve()
    if not pdf.is_file():
        fail(f"missing PDF: {pdf}")

    with tempfile.TemporaryDirectory(prefix="systems-navigation-") as temp:
        bbox = Path(temp) / "roadmap.html"
        subprocess.run(
            ["pdftotext", "-f", "2", "-l", "2", "-bbox", str(pdf), str(bbox)],
            check=True,
        )
        source = bbox.read_text(encoding="utf-8")

    pattern = re.compile(
        r'<word\s+[^>]*yMin="([0-9.]+)"[^>]*yMax="([0-9.]+)"[^>]*>(.*?)</word>'
    )
    words = [
        (html.unescape(text), float(top), float(bottom))
        for top, bottom, text in pattern.findall(source)
    ]
    entries = []
    for label in ("Alpha", "Beta", "Gamma"):
        matches = [(top, bottom) for text, top, bottom in words if text == label]
        if len(matches) != 1:
            fail(f"expected one {label} entry on page 2, found {len(matches)}")
        top, bottom = matches[0]
        entries.append((top + bottom) / 2)

    bullets = [(top + bottom) / 2 for text, top, bottom in words if text == "•"]
    if len(bullets) != 3:
        fail(f"expected three bullet markers on page 2, found {len(bullets)}")
    if any(abs(bullet - entry) > 0.05 for bullet, entry in zip(bullets, entries)):
        fail("bullet markers are not aligned with their Roadmap entries")

    gaps = [entries[index + 1] - entries[index] for index in range(len(entries) - 1)]
    if abs(gaps[0] - gaps[1]) > 0.05:
        fail(f"automatic Roadmap gaps are not equal: {gaps[0]:.3f}pt vs {gaps[1]:.3f}pt")
    print(
        "navigation layout: three bullet entries use equal vertical spacing "
        f"({gaps[0]:.3f}pt, {gaps[1]:.3f}pt)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
