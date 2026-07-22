#!/usr/bin/env python3
"""Validate the task-oriented Guide, Catalog map, API coverage, and example boundary."""

from __future__ import annotations

import re
import subprocess
import sys
import tomllib
from pathlib import Path

from public_vocabulary import RETIRED_IDENTIFIERS


ROOT = Path(__file__).resolve().parents[1]
GUIDE = ROOT / "docs/guide"
ENTRY = ROOT / "docs/USER_GUIDE.md"

CHAPTERS = tuple(f"{number:02d}-{name}.md" for number, name in (
    (1, "getting-started"),
    (2, "mental-model"),
    (3, "typst-essentials"),
    (4, "deck-structure"),
    (5, "theme-basics"),
    (6, "native-content"),
    (7, "points-and-typography"),
    (8, "layout"),
    (9, "progressive-slides"),
    (10, "page-surfaces"),
    (11, "speaker-tools"),
    (12, "recipes"),
    (13, "troubleshooting"),
))

PUBLIC_BINDINGS = (
    "systems-slides-theme", "slide", "title-slide", "outline-slide", "section-slide",
    "page-mark", "page-layer", "row-split", "column-split", "layout-profile", "region",
    "body-flow", "point", "points", "page-frame", "panel", "callout", "lead",
    "typography.danger", "runtime.speaker-note", "runtime.jump", "runtime.uncover",
    "runtime.only", "runtime.alternatives", "runtime.presenter-view", "runtime.pause",
    "runtime.meanwhile",
)

CATALOG = (
    ("Cover", "1", "1_foundations.typ", "Relay: Dependency-Aware I/O Scheduling"),
    ("Roadmap", "2", "1_foundations.typ", "Catalog Roadmap"),
    ("Stable Slide Chrome", "3", "1_foundations.typ", "Stable Slide Chrome"),
    ("Native Typst Content", "4", "1_foundations.typ", "Native Typst Content"),
    ("Fixed Evidence, Progressive Interpretation", "5–7", "2_progressive_vertical.typ", "Fixed Evidence, Progressive Interpretation"),
    ("Progressive Requirements, Fixed Architecture", "8–10", "2_progressive_vertical.typ", "Progressive Requirements, Fixed Architecture"),
    ("Reserve, Release, and Replace", "11–13", "2_progressive_vertical.typ", "Reserve, Release, and Replace"),
    ("Bottom-Aligned Layer Growth", "14–16", "2_progressive_vertical.typ", "Bottom-Aligned Layer Growth"),
    ("Progressive Points in Stable Free Space", "17–19", "2_progressive_vertical.typ", "Progressive Points in Stable Free Space"),
    ("Native Image Ratios", "20", "3_media_and_figures.typ", "Native Image Ratios"),
    ("Caption Placement", "21", "3_media_and_figures.typ", "Caption Placement"),
    ("Native Figure References", "22", "3_media_and_figures.typ", "Native Figure References"),
    ("Dominant Figure and Takeaway", "23", "3_media_and_figures.typ", "Dominant Figure and Takeaway"),
    ("Unequal Evidence Columns", "24", "3_media_and_figures.typ", "Unequal Evidence Columns"),
    ("Stable Before/After Comparison", "25–27", "4_comparison_and_pipeline.typ", "Stable Before/After Comparison"),
    ("Fixed-Track Pipeline", "28–30", "4_comparison_and_pipeline.typ", "Fixed-Track Pipeline"),
    ("Stable Timeline", "31–32", "4_comparison_and_pipeline.typ", "Stable Timeline"),
    ("Experimental Configuration", "33", "5_tables.typ", "Experimental Configuration"),
    ("Progressive Results Table", "34–36", "5_tables.typ", "Progressive Results Table"),
    ("Chart and Exact Values", "37", "5_tables.typ", "Chart and Exact Values"),
    ("Curating Wide Tables", "38", "5_tables.typ", "Curating Wide Tables"),
    ("Pseudocode with Explanation", "39", "6_technical_content.typ", "Pseudocode with Explanation"),
    ("Formula, Symbols, and Conclusion", "40", "6_technical_content.typ", "Formula, Symbols, and Conclusion"),
    ("Quotes, Footnotes, and Sources", "41", "6_technical_content.typ", "Quotes, Footnotes, and Sources"),
    ("Metrics Dashboard", "42", "6_technical_content.typ", "Metrics Dashboard"),
    ("Long Single-Line Title Contract", "43", "7_surfaces.typ", "Dependency-Aware Scheduling Preserves Ordering"),
    ("Titleless Technical Canvas", "44", "7_surfaces.typ", "Titleless technical canvas"),
    ("2×2 Evidence Matrix", "45", "7_surfaces.typ", "2×2 Evidence Matrix"),
)


def fail(message: str) -> None:
    raise SystemExit(f"Guide check failed: {message}")


def expand_pages(spec: str) -> set[int]:
    if "–" not in spec:
        return {int(spec)}
    start, end = (int(value) for value in spec.split("–", 1))
    return set(range(start, end + 1))


entry = ENTRY.read_text(encoding="utf-8")
texts = [entry]
for chapter in CHAPTERS:
    path = GUIDE / chapter
    if not path.is_file():
        fail(f"missing chapter {chapter}")
    text = path.read_text(encoding="utf-8")
    texts.append(text)
    if f"guide/{chapter}" not in entry:
        fail(f"USER_GUIDE.md does not link {chapter}")
    if "读完本章" not in text:
        fail(f"{chapter} does not state its learning outcome")
    if text.count("```") % 2:
        fail(f"{chapter} has an unbalanced fenced code block")

all_text = "\n".join(texts)
for binding in PUBLIC_BINDINGS:
    if binding not in all_text:
        fail(f"stable public binding is not discoverable: {binding}")

if len(sys.argv) != 2:
    fail("usage: guide-check.py CATALOG.pdf")
catalog_pdf = Path(sys.argv[1])
if not catalog_pdf.is_file():
    fail(f"Catalog PDF does not exist: {catalog_pdf}")

recipes = (GUIDE / "12-recipes.md").read_text(encoding="utf-8")
covered_pages: set[int] = set()
for scene, pages, filename, anchor in CATALOG:
    pattern = rf"\| {re.escape(scene)} \| {re.escape(pages)} \| \[{re.escape(filename)}\]"
    if not re.search(pattern, recipes):
        fail(f"Catalog mapping is missing or stale: {scene} pages {pages}")
    if not (ROOT / "examples/catalog/sections" / filename).is_file():
        fail(f"Catalog mapping points to a missing source: {filename}")
    scene_pages = expand_pages(pages)
    covered_pages |= scene_pages
    for page in scene_pages:
        extracted = subprocess.run(
            ["pdftotext", "-f", str(page), "-l", str(page), str(catalog_pdf), "-"],
            check=True,
            text=True,
            capture_output=True,
        ).stdout
        if anchor not in extracted:
            fail(f"Catalog page {page} no longer matches {scene!r}; missing {anchor!r}")
if covered_pages != set(range(1, 46)):
    fail(f"Catalog mapping covers {sorted(covered_pages)}, expected pages 1..45")

manifest = tomllib.loads((ROOT / "typst.toml").read_text(encoding="utf-8"))
package = manifest["package"]
package_ref = f"@local/{package['name']}:{package['version']}"
if package_ref not in entry or package_ref not in (GUIDE / "01-getting-started.md").read_text():
    fail(f"Guide does not use current package coordinate {package_ref}")

for forbidden in (
    "systems" + "-paper", *RETIRED_IDENTIFIERS, "Arial", "Helvetica Neue",
    "Avenir Next", "/Users/", "#import \"../../src/", "#import \"../../themes/",
):
    if forbidden in all_text:
        fail(f"retired/private/system-specific text appears in Guide: {forbidden!r}")

example = (GUIDE / "examples/first-deck.typ").read_text(encoding="utf-8")
if f'#import "{package_ref}"' not in example:
    fail("standalone example does not import the installed public package")
for forbidden in ("src/", "themes/", "/Users/", "Arial", "Helvetica"):
    if forbidden in example:
        fail(f"standalone example crosses its public boundary: {forbidden!r}")

print(
    f"Guide check passed: {len(CHAPTERS)} chapters, {len(PUBLIC_BINDINGS)} public bindings, "
    f"{len(CATALOG)} Catalog scenes / 45 pages, and one public-only executable example."
)
