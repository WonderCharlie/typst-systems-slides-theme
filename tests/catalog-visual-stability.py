#!/usr/bin/env python3
"""Verify declared Catalog stable regions at 288 DPI using Poppler and stdlib."""

from __future__ import annotations

import shutil
import subprocess
import sys
import tempfile
import re
from pathlib import Path


DPI = 288
SCALE = DPI // 72


def read_ppm(path: Path) -> tuple[int, int, bytes]:
    raw = path.read_bytes()
    tokens: list[bytes] = []
    index = 0
    while len(tokens) < 4:
        while index < len(raw) and raw[index:index + 1].isspace():
            index += 1
        if raw[index:index + 1] == b"#":
            index = raw.index(b"\n", index) + 1
            continue
        end = index
        while end < len(raw) and not raw[end:end + 1].isspace():
            end += 1
        tokens.append(raw[index:end])
        index = end
    while index < len(raw) and raw[index:index + 1].isspace():
        index += 1
    magic, width, height, maximum = tokens
    if magic != b"P6" or maximum != b"255":
        raise RuntimeError(f"unsupported PPM header in {path}")
    width_i, height_i = int(width), int(height)
    pixels = raw[index:]
    if len(pixels) != width_i * height_i * 3:
        raise RuntimeError(f"truncated PPM data in {path}")
    return width_i, height_i, pixels


def crop(image: tuple[int, int, bytes], box: tuple[int, int, int, int]) -> bytes:
    width, height, pixels = image
    left, top, right, bottom = box
    if not (0 <= left < right <= width and 0 <= top < bottom <= height):
        raise RuntimeError(f"invalid crop {box} for {width}x{height}")
    rows: list[bytes] = []
    for y in range(top, bottom):
        start = (y * width + left) * 3
        rows.append(pixels[start:start + (right - left) * 3])
    return b"".join(rows)


def nonwhite_ratio(data: bytes) -> float:
    nonwhite = 0
    for offset in range(0, len(data), 3):
        if min(data[offset:offset + 3]) < 245:
            nonwhite += 1
    return nonwhite / (len(data) // 3)


def purple_bounds(image: tuple[int, int, bytes], box: tuple[int, int, int, int]) -> tuple[int, int]:
    width, _, pixels = image
    left, top, right, bottom = box
    ys: list[int] = []
    for y in range(top, bottom):
        for x in range(left, right):
            offset = (y * width + x) * 3
            red, green, blue = pixels[offset:offset + 3]
            if 45 <= red <= 180 and green < 150 and blue > red + 15:
                ys.append(y)
    if not ys:
        raise RuntimeError("no title-colored pixels found")
    return min(ys), max(ys)


def dark_pixel_count(image: tuple[int, int, bytes], box: tuple[int, int, int, int]) -> int:
    """Count body-like dark pixels while excluding purple titles and pale rules."""
    width, _, pixels = image
    left, top, right, bottom = box
    count = 0
    for y in range(top, bottom):
        for x in range(left, right):
            offset = (y * width + x) * 3
            red, green, blue = pixels[offset:offset + 3]
            if red < 90 and green < 90 and blue < 90:
                count += 1
    return count


def light_pixel_count(image: tuple[int, int, bytes], box: tuple[int, int, int, int]) -> int:
    """Count near-white foreground pixels inside a dark Theme surface."""
    width, _, pixels = image
    left, top, right, bottom = box
    count = 0
    for y in range(top, bottom):
        for x in range(left, right):
            offset = (y * width + x) * 3
            if min(pixels[offset:offset + 3]) > 245:
                count += 1
    return count


def single_line_title_contract(pdf: Path) -> list[str]:
    """Verify every ordinary title is one line, at least 30pt, and in-band."""
    completed = subprocess.run(
        ["pdftotext", "-bbox-layout", str(pdf), "-"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    )
    errors: list[str] = []
    pages = re.findall(r"<page\b[^>]*>(.*?)</page>", completed.stdout, re.DOTALL)
    ordinary_pages = set(range(2, 46)) | {47}
    for page_number in ordinary_pages:
        blocks = re.findall(r"<block\b([^>]*)>(.*?)</block>", pages[page_number - 1], re.DOTALL)
        if not blocks:
            errors.append(f"page {page_number} has no title block")
            continue
        title_attributes, title_content = blocks[0]
        lines = re.findall(r"<line\b", title_content)
        if len(lines) != 1:
            errors.append(f"page {page_number} title must occupy exactly one line; found {len(lines)}")
        top_match = re.search(r'\byMin="([^"]+)"', title_attributes)
        bottom_match = re.search(r'\byMax="([^"]+)"', title_attributes)
        title_top = float(top_match.group(1)) if top_match else float("-inf")
        title_bottom = float(bottom_match.group(1)) if bottom_match else float("inf")
        if title_top <= 0:
            errors.append(f"page {page_number} title touches the page top: yMin={title_top:.2f}pt")
        if title_bottom >= 68:
            errors.append(f"page {page_number} title reaches the rule: yMax={title_bottom:.2f}pt")
        words = re.findall(r"<word\b([^>]*)>", title_content)
        heights = []
        for attributes in words:
            minimum = re.search(r'\byMin="([^"]+)"', attributes)
            maximum = re.search(r'\byMax="([^"]+)"', attributes)
            if minimum and maximum:
                heights.append(float(maximum.group(1)) - float(minimum.group(1)))
        # Poppler reports Poppins glyph boxes at approximately 1.4x Typst size.
        if not heights or min(heights) < 41.5:
            measured = min(heights) if heights else 0
            errors.append(
                f"page {page_number} title falls below the 30pt contract: glyph box={measured:.2f}pt"
            )
        if page_number == 45 and heights and max(heights) > 43:
            errors.append(
                f"page 45 no longer exercises near-minimum title fitting: glyph box={max(heights):.2f}pt"
            )
    return errors


def main() -> int:
    pdf = Path(sys.argv[1] if len(sys.argv) > 1 else "build/catalog.pdf")
    if not pdf.is_file():
        print(f"Catalog visual stability check failed: missing {pdf}", file=sys.stderr)
        return 1
    if shutil.which("pdftoppm") is None:
        print("Catalog visual stability check failed: pdftoppm is required", file=sys.stderr)
        return 1

    stable = (
        ((7, 8, 9), (180, 310, 3660, 1150), "top chart"),
        ((10, 11, 12), (700, 1350, 3150, 1995), "bottom architecture"),
        ((16, 17, 18), (700, 1690, 3200, 1995), "bottom storage foundation"),
        ((19, 20, 21), (120, 270, 1700, 450), "top distributed point"),
        ((27, 28, 29), (100, 330, 1810, 1120), "baseline comparison column"),
        ((30, 31, 32), (60, 330, 1520, 780), "existing pipeline stages"),
        ((33, 34), (60, 530, 3780, 650), "timeline axis"),
        ((36, 37, 38), (230, 350, 2360, 1100), "existing result table cells"),
    )
    pages_needed = set(range(1, 48))
    stored: dict[tuple[str, int], bytes] = {}
    title_bounds: dict[int, tuple[int, int]] = {}
    errors: list[str] = []

    with tempfile.TemporaryDirectory(prefix="systems-slides-template-catalog-288dpi-") as temporary:
        directory = Path(temporary)
        for page in sorted(pages_needed):
            prefix = directory / f"page-{page}"
            subprocess.run(
                ["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(DPI), "-singlefile", str(pdf), str(prefix)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            ppm = prefix.with_suffix(".ppm")
            image = read_ppm(ppm)
            ppm.unlink()

            for sequence, box, label in stable:
                if page in sequence:
                    data = crop(image, box)
                    if nonwhite_ratio(data) < 0.002:
                        errors.append(f"{label} crop is unexpectedly empty on page {page}")
                    stored[(label, page)] = data

            if page not in (1, 46):
                # Footer begins at 502pt. The 12pt band immediately above it
                # must remain clear on every ordinary-chrome page.
                safety = crop(image, (0, 1954, 960 * SCALE, 2002))
                ratio = nonwhite_ratio(safety)
                if ratio > 0.003:
                    errors.append(f"page {page} enters the 12pt Footer safety band ({ratio:.3%} non-white)")

            if page == 5:
                # The final Y in the Catalog's RELAY wordmark occupies this
                # right-edge strip. An undersized SVG viewBox clips it entirely.
                logo_tail = light_pixel_count(
                    image,
                    (60 * SCALE, 506 * SCALE, 65 * SCALE, 534 * SCALE),
                )
                if logo_tail < 20:
                    errors.append(
                        f"Catalog Footer logo is clipped at its right edge ({logo_tail} tail pixels)"
                    )

            if page in set(range(2, 46)) | {47}:
                title_bounds[page] = purple_bounds(
                    image,
                    (20 * SCALE, 0, 940 * SCALE, 68 * SCALE),
                )
                # The title is purple. Any black body ink in the left content
                # span above the rule indicates upward overflow from the body.
                body_ink = dark_pixel_count(
                    image,
                    (30 * SCALE, 0, 830 * SCALE, 68 * SCALE),
                )
                if body_ink > 8:
                    errors.append(
                        f"page {page} contains {body_ink} body-colored pixels inside the title band"
                    )

    for sequence, _, label in stable:
        reference = stored[(label, sequence[0])]
        for page in sequence[1:]:
            if stored[(label, page)] != reference:
                errors.append(f"{label} moved or changed between pages {sequence[0]} and {page}")

    # Every ordinary title stays within the same single-line title band.
    for page, (top, bottom) in title_bounds.items():
        if top <= 0:
            errors.append(f"page {page} title touches the page top: first pixel y={top}px")
        if bottom >= 67 * SCALE:
            errors.append(
                f"page {page} title touches the rule: ink={top}..{bottom}px"
            )
    errors.extend(single_line_title_contract(pdf))

    if errors:
        print("Catalog visual stability check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Catalog visual stability check passed at 288 DPI: stable regions hold; every ordinary title is one line at >=30pt; body and Footer clearances hold.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
