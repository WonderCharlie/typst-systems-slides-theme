#!/usr/bin/env python3
"""Verify equal fractional gutters and stable progressive Point regions."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


DPI = 288
SCALE = DPI // 72
SAMPLE_X = 40 * SCALE
REGION_COLORS = ((253, 232, 232), (232, 239, 255), (230, 246, 236))
BODY_CONTENT_TOP_PT = 79.56
FOOTER_TOP_PT = 500.5
FIXED_INSET_PT = 12


def read_ppm(path: Path) -> tuple[int, int, bytes]:
    raw = path.read_bytes()
    match = re.match(rb"P6\s+(\d+)\s+(\d+)\s+255\s", raw)
    if match is None:
        raise RuntimeError(f"unsupported PPM header in {path}")
    width, height = int(match.group(1)), int(match.group(2))
    pixels = raw[match.end():]
    if len(pixels) != width * height * 3:
        raise RuntimeError(f"truncated PPM data in {path}")
    return width, height, pixels


def color_bounds(image: tuple[int, int, bytes], color: tuple[int, int, int]) -> tuple[int, int]:
    width, height, pixels = image
    ys = []
    for y in range(height):
        offset = (y * width + SAMPLE_X) * 3
        if tuple(pixels[offset:offset + 3]) == color:
            ys.append(y)
    if not ys:
        raise RuntimeError(f"region color {color} is absent")
    return min(ys), max(ys)


def crop(image: tuple[int, int, bytes], top: int, bottom: int) -> bytes:
    width, _, pixels = image
    left, right = 30 * SCALE, 830 * SCALE
    return b"".join(
        pixels[(y * width + left) * 3:(y * width + right) * 3]
        for y in range(top, bottom + 1)
    )


def main() -> int:
    pdf = Path(sys.argv[1] if len(sys.argv) > 1 else "build/tests/body-flow-distribution.pdf")
    if not pdf.is_file():
        print(f"Body-flow distribution check failed: missing {pdf}", file=sys.stderr)
        return 1
    for command in ("pdftoppm", "pdftotext"):
        if shutil.which(command) is None:
            print(f"Body-flow distribution check failed: {command} is required", file=sys.stderr)
            return 1

    errors: list[str] = []
    images = []
    with tempfile.TemporaryDirectory(prefix="systems-slides-template-flow-distribution-") as temporary:
        for page in range(1, 4):
            prefix = Path(temporary) / f"page-{page}"
            subprocess.run(
                ["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(DPI), "-singlefile", str(pdf), str(prefix)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            images.append(read_ppm(prefix.with_suffix(".ppm")))

    bounds = [[color_bounds(image, color) for color in REGION_COLORS] for image in images]
    if not all(page_bounds == bounds[0] for page_bounds in bounds[1:]):
        errors.append(f"region tracks moved across subslides: {bounds}")
    first, second, third = bounds[2]
    gap_one = second[0] - first[1] - 1
    gap_two = third[0] - second[1] - 1
    if abs(gap_one - gap_two) > 1:
        errors.append(f"fractional gutters differ by more than one pixel: {gap_one}px vs {gap_two}px")
    inner_top = round((BODY_CONTENT_TOP_PT + FIXED_INSET_PT) * SCALE)
    inner_bottom = round((FOOTER_TOP_PT - FIXED_INSET_PT) * SCALE)
    outer_top = first[0] - inner_top
    outer_bottom = inner_bottom - third[1] - 1
    if abs(outer_top - outer_bottom) > 1:
        errors.append(
            f"fractional outer gutters differ by more than one pixel: "
            f"{outer_top}px vs {outer_bottom}px"
        )
    internal_average = (gap_one + gap_two) / 2
    expected_outer = internal_average * 2 / 3
    if abs(outer_top - expected_outer) > 1 or abs(outer_bottom - expected_outer) > 1:
        errors.append(
            "outer/internal fractional spacing does not follow the 2:3 weight ratio: "
            f"outer={outer_top}px/{outer_bottom}px, internal={gap_one}px/{gap_two}px"
        )
    heights = (first[1] - first[0] + 1, second[1] - second[0] + 1, third[1] - third[0] + 1)
    if len(set(heights)) != 3:
        errors.append(f"fixture no longer exercises three different natural heights: {heights}")
    if first[0] < inner_top:
        errors.append(f"first region enters the fixed top inset: y={first[0]}px")
    if third[1] >= inner_bottom:
        errors.append(f"last region enters the fixed bottom inset: y={third[1]}px")

    top_crops = [crop(image, *page_bounds[0]) for image, page_bounds in zip(images, bounds)]
    if len(set(top_crops)) != 1:
        errors.append("the already-visible top Point changed across subslides")
    middle_crops = [crop(images[index], *bounds[index][1]) for index in (1, 2)]
    if middle_crops[0] != middle_crops[1]:
        errors.append("the nested Point group changed after becoming visible")

    text = subprocess.run(
        ["pdftotext", "-f", "3", "-l", "3", str(pdf), "-"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout
    for required in ("Preserve storage ordering", "Avoid unnecessary synchronization", "Keep dependency-critical I/O explicit", "Require no application changes"):
        if required not in text:
            errors.append(f"final subslide is missing {required!r}")

    if errors:
        print("Body-flow distribution check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        "Body-flow distribution check passed: "
        f"outer={outer_top}px/{outer_bottom}px, internal={gap_one}px/{gap_two}px, "
        "2:3 weighting and progressive pixels are stable."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
