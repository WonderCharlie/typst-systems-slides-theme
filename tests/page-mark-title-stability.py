#!/usr/bin/env python3
"""Prove a page mark cannot move otherwise identical title pixels."""

from __future__ import annotations

import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path


DPI = 288
SCALE = DPI // 72


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


def crop(image: tuple[int, int, bytes], box: tuple[int, int, int, int]) -> bytes:
    width, _, pixels = image
    left, top, right, bottom = box
    return b"".join(
        pixels[(y * width + left) * 3:(y * width + right) * 3]
        for y in range(top, bottom)
    )


def title_box(pdf: Path, page: int) -> tuple[float, float, float, float]:
    bbox = subprocess.run(
        ["pdftotext", "-f", str(page), "-l", str(page), "-bbox-layout", str(pdf), "-"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout
    match = re.search(
        r'<block xMin="([^"]+)" yMin="([^"]+)" xMax="([^"]+)" yMax="([^"]+)"',
        bbox,
    )
    if match is None:
        raise RuntimeError(f"page {page} has no title bbox")
    return tuple(float(value) for value in match.groups())


def main() -> int:
    pdf = Path(sys.argv[1] if len(sys.argv) > 1 else "build/tests/page-mark-title-stability.pdf")
    if not pdf.is_file():
        print(f"Page-mark title stability check failed: missing {pdf}", file=sys.stderr)
        return 1
    for command in ("pdftoppm", "pdftotext"):
        if shutil.which(command) is None:
            print(f"Page-mark title stability check failed: {command} is required", file=sys.stderr)
            return 1

    boxes = tuple(title_box(pdf, page) for page in range(1, 5))
    errors: list[str] = []
    if len(set(boxes)) != 1:
        errors.append(f"title bbox moved after adding page mark or section progress: {boxes}")

    with tempfile.TemporaryDirectory(prefix="systems-slides-template-page-mark-") as temporary:
        images = []
        for page in range(1, 5):
            prefix = Path(temporary) / f"page-{page}"
            subprocess.run(
                ["pdftoppm", "-f", str(page), "-l", str(page), "-r", str(DPI), "-singlefile", str(pdf), str(prefix)],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            images.append(read_ppm(prefix.with_suffix(".ppm")))
        title_crop = (20 * SCALE, 0, 700 * SCALE, 68 * SCALE)
        reference = crop(images[0], title_crop)
        for page, image in enumerate(images[1:], 2):
            if crop(image, title_crop) != reference:
                errors.append(f"title pixels changed after adding mark/progress on page {page}")

    if errors:
        print("Page-mark title stability check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Page-mark title stability check passed: marks and section progress do not move identical title bbox or pixels.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
