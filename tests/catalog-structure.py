#!/usr/bin/env python3
"""Keep the Catalog a 28-scene public-API specification with native content."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / "examples/catalog"


def main() -> int:
    sections = tuple(sorted((CATALOG / "sections").glob("*.typ")))
    source = "\n".join(path.read_text(encoding="utf-8") for path in sections)
    main_source = (CATALOG / "main.typ").read_text(encoding="utf-8")
    globals_source = (CATALOG / "globals.typ").read_text(encoding="utf-8")
    errors: list[str] = []

    expected_sections = (
        "1_foundations.typ",
        "2_progressive_vertical.typ",
        "3_media_and_figures.typ",
        "4_comparison_and_pipeline.typ",
        "5_tables.typ",
        "6_technical_content.typ",
        "7_surfaces.typ",
    )
    if tuple(path.name for path in sections) != expected_sections:
        errors.append("Catalog must contain exactly seven capability-oriented sections")
    for name in expected_sections:
        if f'#include "sections/{name}"' not in main_source:
            errors.append(f"main.typ does not include {name}")

    logical = source.count("#slide(") + source.count("#title-slide(") + source.count("#outline-slide(")
    if logical != 28 or source.count("#slide(") != 26:
        errors.append(f"Catalog must define 28 logical scenes (26 ordinary + cover + roadmap); found {logical}")
    if source.count("repeat: 3") != 8 or source.count("repeat: 2") != 1:
        errors.append("Catalog must use eight 3-state and one 2-state lifecycle sequences")

    slide_titles = re.findall(r"#slide\(\s*(?:\n\s*)?title:\s*\[([^\]]+)\]", source)
    minimum_size_title = "Dependency-Aware Scheduling Preserves Ordering"
    if slide_titles.count(minimum_size_title) != 1:
        errors.append("Catalog must contain exactly one deliberate single-line minimum-size title scene")

    header_terms = ("Purpose:", "Public API:", "Defaults:", "Stable regions:")
    for section in sections:
        section_source = section.read_text(encoding="utf-8")
        header = "\n".join(section_source.splitlines()[:8])
        for term in header_terms:
            if term not in header:
                errors.append(f"{section.name} header does not declare {term}")
        if '#import "@local/systems-slides-template:0.4.0"' not in section_source:
            errors.append(f"{section.name} must import the installed public package directly")
        for forbidden in ('../../lib.typ', '/src/', '/themes/', 'compat.typ'):
            if forbidden in section_source:
                errors.append(f"{section.name} imports forbidden internal path {forbidden!r}")

    if '#import "@local/systems-slides-template:0.4.0": systems-slides-theme' not in globals_source:
        errors.append("globals.typ must obtain Theme configuration from the installed public package")
    for leaked in ("stage-box", "body-flow", "column-split", "points", "table"):
        if leaked in globals_source:
            errors.append(f"globals.typ retains scene or layout implementation {leaked!r}")
    for path_guard in ('type(relative) == str', 'not relative.starts-with("/")', 'not relative.contains("\\\\")'):
        if path_guard not in globals_source:
            errors.append(f"Catalog asset-path is missing Starter-equivalent guard {path_guard!r}")

    if re.search(r"block\([^)]*height\s*:[^)]*\)\s*\[\s*\]", source, re.DOTALL):
        errors.append("Catalog contains an empty block used only as a placeholder")
    for forbidden_layout in ("place(", "move("):
        if forbidden_layout in source:
            errors.append(f"Catalog uses coordinate repair {forbidden_layout!r}")
    for runtime_call in ("runtime.uncover", "runtime.only", "runtime.alternatives"):
        if runtime_call not in source:
            errors.append(f"Catalog must execute {runtime_call} in a real scene")
    for native in ("#table(", "#figure(", "#raw(", "#quote(", "#footnote["):
        if native not in source:
            errors.append(f"Catalog must demonstrate native Typst interface {native}")
    if "#panel(" not in source:
        errors.append("Catalog must provide an executable consumer for the stable panel API")
    for reference in ("<experimental-configuration>", "@experimental-configuration", "<relay-design>", "@relay-design"):
        if reference not in source:
            errors.append(f"Catalog must demonstrate native reference {reference}")
    if "@relay-design-note" not in source or "#bibliography(" not in source:
        errors.append("Catalog must demonstrate native cite and bibliography semantics")
    if not (CATALOG / "assets/references.bib").is_file():
        errors.append("Catalog synthetic bibliography fixture is missing")
    for forbidden_text in ("Figure @relay-design", "Equation @visible-latency", 'uncover("2-")[[8.6]]'):
        if forbidden_text in source:
            errors.append(f"Catalog retains a known reference/rendering error: {forbidden_text!r}")
    if re.search(r'(?:image|path)\(\s*"/', source):
        errors.append("Catalog must not contain absolute resource paths")
    if (CATALOG / "components").exists():
        errors.append("Catalog must not carry a second component layer")

    catalog_sources = "\n".join(
        path.read_text(encoding="utf-8")
        for path in CATALOG.rglob("*.typ")
    )
    for asset in sorted((CATALOG / "assets").rglob("*")):
        if not asset.is_file():
            continue
        relative = asset.relative_to(CATALOG / "assets").as_posix()
        if relative not in catalog_sources:
            errors.append(f"Catalog asset has no source consumer: assets/{relative}")

    tables = (CATALOG / "sections/5_tables.typ").read_text(encoding="utf-8")
    for forbidden_wrapper in ("systems-table", "body-table", "table-profile"):
        if forbidden_wrapper in tables:
            errors.append(f"Catalog created forbidden table wrapper {forbidden_wrapper}")
    if "table-text-size" in tables or "set table" in tables:
        errors.append("default table scene must obtain presentation styling from Theme defaults")

    if errors:
        print("Catalog structure check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Catalog structure check passed: 28 scenes, seven capability sections, native technical content, and public-package-only imports.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
