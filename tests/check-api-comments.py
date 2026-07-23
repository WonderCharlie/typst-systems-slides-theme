#!/usr/bin/env python3
"""Keep one Tinymist documentation source and reject legacy duplicate blocks."""

from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

EXPECTED_PARAMS: dict[str, dict[str, tuple[str, ...]]] = {
    "themes/systems-slides-template/theme.typ": {
        "systems-slides-theme": (
            "title", "short-title", "author", "institution", "date", "footer-title",
            "footer-logo", "footer-logo-width", "footer-date-format", "title-color",
            "rule-color", "image-max-width", "image-grow", "figure-gap",
            "figure-caption-size", "figure-caption-fill", "figure-caption-align",
            "list-indent", "list-body-indent", "list-spacing", "table-text-size",
            "table-inset", "table-stroke", "table-header-fill", "table-header-weight",
            "code-font", "code-size", "footnote-size", "asset-resolver",
            "section-progress", "section-slides", "..args", "body",
        ),
    },
    "src/slides.typ": {
        "slide": ("title", "align", "frame", "marks", "counted", "config", "repeat", "setting", "composer", "..bodies"),
        "title-slide": (
            "config", "title-lines", "author-lines", "subtitle", "affiliations",
            "affiliation-layout", "event-mark", "event-layout", "extra", "counted",
        ),
        "outline-slide": (
            "config", "chapters", "current", "level", "title", "numbering", "size", "weight",
            "spacing", "top-spacing", "bottom-spacing", "auto-layout", "current-style", "setting",
        ),
        "section-slide": ("config", "level", "numbered", "counted", "body"),
    },
    "themes/systems-slides-template/marks.typ": {
        "page-mark": ("body", "slot", "height", "name", "resolver"),
    },
    "src/page-frame.typ": {
        "page-layer": ("body", "name", "area", "align", "inset"),
        "page-frame": (
            "base", "name", "background", "overlay", "foreground", "chrome", "section-progress",
            "header", "footer", "body-inset", "margin", "fill", "width", "height", "header-ascent",
            "footer-descent", "clip", "detect-overflow",
        ),
    },
    "src/flow.typ": {
        "body-flow": (
            "regions", "profile", "rows", "gutter", "outer-gutter", "align", "inset", "overflow",
        ),
    },
    "src/layouts.typ": {
        "layout-profile": ("base", "name", "rows", "columns", "gutter", "align", "width", "height", "inset", "fit", "overflow"),
        "region": ("body", "profile", "name", "width", "height", "inset", "align", "fit", "overflow"),
        "row-split": ("regions", "profile", "name", "rows", "gutter", "align", "width", "height", "inset", "fit", "overflow"),
        "column-split": ("regions", "profile", "name", "columns", "gutter", "align", "width", "height", "inset", "fit", "overflow"),
    },
    "src/points.typ": {
        "point": ("body", "level", "style", "marker", "marker-style"),
        "points": (
            "items", "width", "leading", "gap", "level-gaps", "nest-gap", "style",
            "level-styles", "marker", "level-markers", "marker-style", "level-marker-styles",
        ),
    },
    "src/typography.typ": {
        "danger": ("body",),
        "lead": ("body", "compact", "alignment", "width", "leading"),
    },
    "src/containers.typ": {
        "panel": ("body", "title", "tone", "stroke-tone", "title-tone", "inset"),
        "callout": ("body", "title", "tone", "fill-tone"),
    },
}



LEGACY_MARKER_RE = re.compile(r"(?m)^\s*// @(?:param|field|struct) \S+\s*$")


def main() -> int:
    errors: list[str] = []

    for root_name in ("src", "themes", "template", "examples"):
        for path in sorted((ROOT / root_name).rglob("*.typ")):
            text = path.read_text(encoding="utf-8")
            for match in LEGACY_MARKER_RE.finditer(text):
                line = text.count("\\n", 0, match.start()) + 1
                errors.append(
                    f"{path.relative_to(ROOT)}:{line}: 删除旧的 {match.group(0).strip()} "
                    "重复注释；公共说明只写在函数前的 /// 文档中"
                )

    for relative, functions in EXPECTED_PARAMS.items():
        path = ROOT / relative
        if not path.exists():
            errors.append(f"{relative}: 文件不存在")
            continue
        text = path.read_text(encoding="utf-8")
        for name in functions:
            if not re.search(rf"(?m)^#let\s+{re.escape(name)}\s*\(", text):
                errors.append(f"{relative}: 找不到稳定公共函数 {name}")

    if errors:
        print("公共文档单一来源检查失败：", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    functions = sum(len(items) for items in EXPECTED_PARAMS.values())
    params = sum(len(items) for funcs in EXPECTED_PARAMS.values() for items in funcs.values())
    print(
        f"公共文档单一来源检查通过：{functions} 个函数、{params} 个参数；"
        "src/themes/template/examples 中无 @param/@field/@struct 重复块。"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
