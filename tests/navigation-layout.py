#!/usr/bin/env python3
"""Verify Roadmap typography, alignment, distribution, and active styling."""

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
        sources = []
        for page in (2, 3, 4, 5, 6):
            bbox = Path(temp) / f"roadmap-{page}.html"
            subprocess.run(
                ["pdftotext", "-f", str(page), "-l", str(page), "-bbox", str(pdf), str(bbox)],
                check=True,
            )
            sources.append(bbox.read_text(encoding="utf-8"))
        xml_path = Path(temp) / "roadmap.xml"
        subprocess.run(
            ["pdftohtml", "-f", "2", "-l", "4", "-xml", "-hidden", str(pdf), str(xml_path)],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
        xml_source = xml_path.read_text(encoding="utf-8")

    pattern = re.compile(
        r'<word\s+[^>]*yMin="([0-9.]+)"[^>]*yMax="([0-9.]+)"[^>]*>(.*?)</word>'
    )
    words_by_page = [
        [
            (html.unescape(text), float(top), float(bottom))
            for top, bottom, text in pattern.findall(source)
        ]
        for source in sources
    ]
    words = words_by_page[0]
    entries = []
    for label in ("Problem", "Observation", "Design", "Implementation", "Evaluation", "Conclusion"):
        matches = [(top, bottom) for text, top, bottom in words if text == label]
        if len(matches) != 1:
            fail(f"expected one {label} entry on page 2, found {len(matches)}")
        top, bottom = matches[0]
        entries.append((top + bottom) / 2)

    bullets = [(top + bottom) / 2 for text, top, bottom in words if text == "•"]
    if len(bullets) != 6:
        fail(f"expected six bullet markers on page 2, found {len(bullets)}")
    if any(abs(bullet - entry) > 0.05 for bullet, entry in zip(bullets, entries)):
        fail("bullet markers are not aligned with their Roadmap entries")

    gaps = [entries[index + 1] - entries[index] for index in range(len(entries) - 1)]
    if abs(gaps[0] - gaps[1]) > 0.05:
        fail(f"automatic Roadmap gaps are not equal: {gaps[0]:.3f}pt vs {gaps[1]:.3f}pt")
    if max(gaps) - min(gaps) > 0.05:
        fail(f"automatic Roadmap gaps are not equal: {gaps}")

    for label, expected_center in zip(
        ("Problem", "Observation", "Design", "Implementation", "Evaluation", "Conclusion"),
        entries,
    ):
        highlighted = [
            (top + bottom) / 2
            for text, top, bottom in words_by_page[1]
            if text == label
        ]
        if len(highlighted) != 1 or abs(highlighted[0] - expected_center) > 0.1:
            fail(f"current highlighting moves {label!r} between pages 2 and 3")

    fixed_problem = [
        (top + bottom) / 2
        for text, top, bottom in words_by_page[3]
        if text == "Problem"
    ]
    if len(fixed_problem) != 1 or abs(fixed_problem[0] - entries[0]) > 0.05:
        fail(
            "auto-layout changes the first entry position: "
            f"auto={entries[0]:.3f}pt, fixed={fixed_problem[0] if fixed_problem else 'missing'}"
        )

    manual_words = words_by_page[4]
    manual_entries = []
    for label in ("Problem", "Observation", "Design", "Implementation", "Evaluation", "Conclusion"):
        matches = [
            (top + bottom) / 2
            for text, top, bottom in manual_words
            if text == label
        ]
        if len(matches) != 1:
            fail(f"expected one {label} entry on manual-spacing page, found {len(matches)}")
        manual_entries.append(matches[0])
    if abs((manual_entries[0] - entries[0]) - 20.0) > 0.05:
        fail(
            "top-spacing does not independently move the first entry by 20pt: "
            f"default={entries[0]:.3f}pt, manual={manual_entries[0]:.3f}pt"
        )
    if abs((entries[-1] - manual_entries[-1]) - 30.0) > 0.05:
        fail(
            "bottom-spacing does not independently move the last entry by 30pt: "
            f"default={entries[-1]:.3f}pt, manual={manual_entries[-1]:.3f}pt"
        )
    manual_gaps = [
        manual_entries[index + 1] - manual_entries[index]
        for index in range(len(manual_entries) - 1)
    ]
    if max(manual_gaps) - min(manual_gaps) > 0.05:
        fail(f"manual outer spacing changes automatic internal distribution: {manual_gaps}")

    numbered = [text for text, _, _ in words_by_page[2] if re.fullmatch(r"[1-6]\.", text)]
    if numbered != ["1.", "2.", "3.", "4.", "5.", "6."]:
        fail(f"numbering override did not render 1.–6.; got {numbered}")

    font_specs = {
        font_id: {"size": size, "family": family, "color": color}
        for font_id, size, family, color in re.findall(
            r'<fontspec id="([^"]+)" size="([^"]+)" family="([^"]+)" color="([^"]+)"/>',
            xml_source,
        )
    }
    xml_pages = {
        int(number): body
        for number, body in re.findall(
            r'<page number="([^"]+)"[^>]*>(.*?)</page>', xml_source, re.DOTALL
        )
    }

    def roadmap_text(page_number: int, label: str) -> dict[str, str]:
        for font_id, body in re.findall(
            r'<text [^>]*font="([^"]+)"[^>]*>(.*?)</text>',
            xml_pages[page_number],
            re.DOTALL,
        ):
            text = html.unescape(re.sub(r"<[^>]+>", "", body))
            if label in text:
                return font_specs[font_id]
        fail(f"missing {label!r} in XML layout for page {page_number}")

    default_problem = roadmap_text(2, "Problem")
    current_design = roadmap_text(3, "Design")
    if default_problem.get("size") != "48" or "SemiBold" not in default_problem.get("family", ""):
        fail(f"default Roadmap is not 32pt semibold: {default_problem}")
    if current_design.get("size") != default_problem.get("size"):
        fail("current highlighting changes the Roadmap text size")
    if current_design.get("color", "").lower() != "#6f2f9f":
        fail(f"current Roadmap item does not use the Theme accent: {current_design}")

    print(
        "navigation layout: six default bullet entries use equal vertical spacing; "
        "current, numbered, and independent outer-spacing pages rendered"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
