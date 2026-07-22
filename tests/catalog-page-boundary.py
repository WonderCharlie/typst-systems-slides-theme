#!/usr/bin/env python3
"""Audit every Catalog text box against page and chrome boundaries."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
from pathlib import Path


RULE_Y = 68.375
FOOTER_Y = 500.5
FOOTER_CENTER_Y = (FOOTER_Y + 540.0) / 2
FOOTER_CENTER_TOLERANCE = 0.05
FOOTER_TEXT_X_MIN = 200.0
BODY_TEXT_X_MAX = 830.0
ORDINARY_PAGES = set(range(2, 46)) | {47}


def attributes(source: str) -> dict[str, float]:
    return {
        key: float(value)
        for key, value in re.findall(r'(width|height|xMin|yMin|xMax|yMax)="([^"]+)"', source)
    }


def main() -> int:
    pdf = Path(sys.argv[1] if len(sys.argv) > 1 else "build/catalog.pdf")
    if not pdf.is_file():
        print(f"Catalog page-boundary check failed: missing {pdf}", file=sys.stderr)
        return 1
    if shutil.which("pdftotext") is None:
        print("Catalog page-boundary check failed: pdftotext is required", file=sys.stderr)
        return 1

    bbox = subprocess.run(
        ["pdftotext", "-bbox-layout", str(pdf), "-"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout
    pages = re.findall(r"<page\b([^>]*)>(.*?)</page>", bbox, re.DOTALL)
    errors: list[str] = []
    for page_number, (page_attributes, body) in enumerate(pages, 1):
        page = attributes(page_attributes)
        blocks = [attributes(item) for item in re.findall(r"<block\b([^>]*)>", body)]
        for block_number, block in enumerate(blocks, 1):
            if (
                block["xMin"] < 0
                or block["yMin"] < 0
                or block["xMax"] > page["width"]
                or block["yMax"] > page["height"]
            ):
                errors.append(
                    f"page {page_number} block {block_number} leaves the "
                    f"{page['width']:.0f}x{page['height']:.0f}pt page: {block}"
                )
            # The left logo may contain outlined or embedded brand text and
            # follows its own media slot. This contract covers the Theme-owned
            # footer title, date, and page-number text columns.
            if block["yMin"] >= FOOTER_Y and block["xMin"] >= FOOTER_TEXT_X_MIN:
                center = (block["yMin"] + block["yMax"]) / 2
                if abs(center - FOOTER_CENTER_Y) > FOOTER_CENTER_TOLERANCE:
                    errors.append(
                        f"page {page_number} Footer block {block_number} is not vertically centered: "
                        f"center={center:.3f}pt, expected={FOOTER_CENTER_Y:.3f}pt"
                    )
        if page_number in ORDINARY_PAGES and blocks:
            title = blocks[0]
            if title["yMin"] < 0:
                errors.append(f"page {page_number} title crosses the page top: {title}")
            for block_number, block in enumerate(blocks[1:], 2):
                if block["yMin"] < RULE_Y and block["yMax"] > 0 and block["xMin"] < BODY_TEXT_X_MAX:
                    errors.append(
                        f"page {page_number} block {block_number} enters the title band: {block}"
                    )

    text = subprocess.run(
        ["pdftotext", "-f", "46", "-l", "46", str(pdf), "-"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout
    normalized = " ".join(text.split())
    required = "Use a chrome-free surface only when the whole page is the composition."
    if required not in normalized:
        errors.append("page 46 does not contain the complete narrow-column lead sentence")

    if errors:
        print("Catalog page-boundary check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        "Catalog page-boundary check passed: text stays on-page, body text stays below the rule, "
        "Footer text is vertically centered, and the narrow-column lead is complete."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
