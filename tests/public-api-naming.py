#!/usr/bin/env python3
"""Freeze the small, content-neutral public API and its namespace boundaries."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

from public_vocabulary import naming_violation


ROOT = Path(__file__).resolve().parents[1]
TOP_LET_RE = re.compile(r"(?m)^#let\s+([A-Za-z_][A-Za-z0-9_-]*)\b")
IMPORT_ALIAS_RE = re.compile(
    r'(?m)^#import\s+"[^"]+"\s+as\s+([A-Za-z_][A-Za-z0-9_-]*)\s*$'
)
IMPORT_GROUP_RE = re.compile(r'(?ms)^#import\s+"[^"]+"\s*:\s*\((.*?)\)')
IMPORT_LINE_RE = re.compile(r'(?m)^#import\s+"[^"]+"\s*:\s*([^\n(][^\n]*)$')

EXPECTED_STABLE_EXPORTS = {
    "systems-slides-theme",
    "slide",
    "title-slide",
    "outline-slide",
    "section-slide",
    "page-mark",
    "page-frame",
    "page-layer",
    "runtime",
    "layout-profile",
    "region",
    "row-split",
    "column-split",
    "body-flow",
    "point",
    "points",
    "typography",
    "lead",
    "panel",
    "callout",
}

EXPECTED_NAMESPACES = {
    "runtime": (
        "src/runtime-api.typ",
        {
            "speaker-note",
            "pause",
            "jump",
            "meanwhile",
            "uncover",
            "only",
            "alternatives",
            "presenter-view",
        },
    ),
    "typography": (
        "src/typography-api.typ",
        {
            "danger",
            "font-family",
            "tone-primary",
            "tone-deep",
            "tone-ink",
            "tone-white",
            "tone-danger",
            "tone-cyan",
            "tone-blue",
            "tone-amber",
            "tone-yellow",
            "tone-green",
            "tone-chart-blue",
            "tone-link",
            "tone-grey",
            "tone-mid-grey",
            "tone-dark-grey",
            "tone-light-grey",
            "tone-faint-grey",
        },
    ),
}

POSITIVE_PROBES = (
    "pkg.slide",
    "pkg.page-mark",
    "pkg.row-split",
    "pkg.points",
    "pkg.runtime.presenter-view",
)
NEGATIVE_PROBES = (
    "pkg.compat",
    "pkg.layouts",
    "pkg.profiles",
    "pkg.charts",
    "pkg.diagrams",
    "pkg.runtime._runtime",
    "pkg.typography._tokens",
    "pkg.systems-layout",
    "pkg.master-header",
    "pkg.media-slot",
    "pkg.media-profile",
    "pkg.media-item",
    "pkg.media-caption",
    "pkg.media-figure",
    "pkg.media-row",
)


def read(relative: str) -> str:
    return (ROOT / relative).read_text(encoding="utf-8")


def imported_names(text: str) -> set[str]:
    names = set(IMPORT_ALIAS_RE.findall(text))
    for body in IMPORT_GROUP_RE.findall(text):
        body = re.sub(r"(?m)//.*$", "", body)
        for item in body.split(","):
            item = item.strip()
            if not item:
                continue
            if item == "*":
                raise ValueError("wildcard import is not a finite facade")
            names.add(re.split(r"\s+as\s+", item)[-1].strip())
    for line in IMPORT_LINE_RE.findall(text):
        line = re.sub(r"//.*$", "", line)
        if line.strip().startswith("("):
            continue
        for item in line.split(","):
            item = item.strip()
            if not item:
                continue
            if item == "*":
                raise ValueError("wildcard import is not a finite facade")
            names.add(re.split(r"\s+as\s+", item)[-1].strip())
    return names


def module_exports(relative: str) -> set[str]:
    text = read(relative)
    return set(TOP_LET_RE.findall(text)) | imported_names(text)


def catalog_interfaces() -> list[tuple[Path, str]]:
    result: list[tuple[Path, str]] = []
    for source in sorted((ROOT / "examples/catalog").rglob("*.typ")):
        for name in TOP_LET_RE.findall(source.read_text(encoding="utf-8")):
            if not name.startswith("_"):
                result.append((source, name))
    return result


def probe(expression: str) -> bool:
    result = subprocess.run(
        [
            "typst", "eval", "--root", str(ROOT),
            '{ import "lib.typ" as pkg; repr(' + expression + ") }",
        ],
        cwd=ROOT,
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        check=False,
    )
    return not re.search(r"(?m)^error:", result.stderr)


def main() -> int:
    errors: list[str] = []
    try:
        stable = module_exports("src/exports.typ")
    except ValueError as error:
        errors.append(f"src/exports.typ: {error}")
        stable = set()
    if stable != EXPECTED_STABLE_EXPORTS:
        errors.append(
            "stable export allowlist mismatch; missing "
            f"{sorted(EXPECTED_STABLE_EXPORTS - stable)}; extra {sorted(stable - EXPECTED_STABLE_EXPORTS)}"
        )

    public_identifiers = set(stable)
    for namespace, (relative, expected) in EXPECTED_NAMESPACES.items():
        try:
            actual = module_exports(relative)
        except ValueError as error:
            errors.append(f"{namespace}: {error}")
            continue
        if actual != expected:
            errors.append(
                f"namespace {namespace} mismatch; missing {sorted(expected - actual)}; "
                f"extra {sorted(actual - expected)}"
            )
        public_identifiers.update(actual)

    for identifier in sorted(public_identifiers):
        violation = naming_violation(identifier)
        if violation:
            errors.append(f"public identifier `{identifier}` contains {violation}")

    for source, identifier in catalog_interfaces():
        violation = naming_violation(identifier)
        if violation:
            errors.append(
                f"catalog helper {source.relative_to(ROOT)}::{identifier} contains {violation}"
            )

    for expression in POSITIVE_PROBES:
        if not probe(expression):
            errors.append(f"recommended public member is not accessible: {expression}")
    for expression in NEGATIVE_PROBES:
        if probe(expression):
            errors.append(f"retired or internal member remains accessible: {expression}")

    if errors:
        print("public API naming check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("public API naming check passed: exact exports, two curated namespaces, neutral names")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
