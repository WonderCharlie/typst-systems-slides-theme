#!/usr/bin/env python3
"""Verify Footer slots, logo center, exact geometry, and bottom-edge fill."""

from __future__ import annotations

import re
import subprocess
import sys
import tempfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
PAGE_HEIGHT = 540.0
FOOTER_Y = 500.5
FOOTER_HEIGHT = 39.5
FOOTER_CENTER = FOOTER_Y + FOOTER_HEIGHT / 2
PURPLE = (0x40, 0x2B, 0x63)


def read_ppm(path: Path) -> tuple[int, int, bytes]:
    data = path.read_bytes()
    match = re.match(rb"P6\s+(?:#[^\n]*\s+)*(\d+)\s+(\d+)\s+255\s", data)
    if match is None:
        raise RuntimeError(f"unsupported PPM header: {path}")
    width, height = (int(value) for value in match.groups())
    pixels = data[match.end():]
    if len(pixels) != width * height * 3:
        raise RuntimeError(f"truncated PPM raster: {path}")
    return width, height, pixels


def pixel(pixels: bytes, width: int, x: int, y: int) -> tuple[int, int, int]:
    offset = (y * width + x) * 3
    return tuple(pixels[offset:offset + 3])


def main() -> int:
    if len(sys.argv) != 2:
        raise SystemExit("usage: footer-contract.py FOOTER-CONTRACT.pdf")
    pdf = Path(sys.argv[1])
    geometry = (ROOT / "themes/systems-slides-template/geometry.typ").read_text(encoding="utf-8")
    tokens = (ROOT / "themes/systems-slides-template/tokens.typ").read_text(encoding="utf-8")
    master = (ROOT / "themes/systems-slides-template/master.typ").read_text(encoding="utf-8")
    errors: list[str] = []

    if not re.search(r"#let footer-y = 500\.5pt\b", tokens):
        errors.append("Theme footer.y must remain exactly 500.5pt")
    if not re.search(r"#let slide-height = 540pt\b", tokens):
        errors.append("Theme page height must remain exactly 540pt")
    if "footer-height = slide-height - footer-y" not in tokens:
        errors.append("footer.height must be derived as page height minus footer.y")
    if "logo-dy" in geometry or "logo-dy" in master:
        errors.append("Footer logo must not use a fixed vertical offset")
    if "let footer-slot" not in master or "align(horizontal + horizon" not in master:
        errors.append("Footer elements must share one full-height horizon-aligned slot helper")
    if abs(FOOTER_Y + FOOTER_HEIGHT - PAGE_HEIGHT) > 1e-9:
        errors.append("footer.y + footer.height must equal the page height")

    with tempfile.TemporaryDirectory(prefix="systems-slides-footer-contract-") as temporary:
        directory = Path(temporary)
        for dpi in (72, 96, 144, 288):
            prefix = directory / f"footer-{dpi}"
            subprocess.run(
                [
                    "pdftoppm", "-f", "1", "-l", "2", "-r", str(dpi),
                    str(pdf), str(prefix),
                ],
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            scale = dpi / 72
            footer_rasters: list[bytes] = []
            for page in (1, 2):
                width, height, pixels = read_ppm(Path(f"{prefix}-{page}.ppm"))
                if width != round(960 * scale) or height != round(PAGE_HEIGHT * scale):
                    errors.append(f"{dpi} DPI page {page} has unexpected size {width}x{height}")
                    continue

                bottom = {pixel(pixels, width, x, height - 1) for x in range(width)}
                if bottom != {PURPLE}:
                    errors.append(f"{dpi} DPI page {page} Footer bottom row is not uniformly #402B63")

                probe_x = 2
                first_purple = next(
                    (y for y in range(height) if pixel(pixels, width, probe_x, y) == PURPLE),
                    None,
                )
                boundary = first_purple / scale if first_purple is not None else None
                if boundary is None or abs(boundary - FOOTER_Y) > 0.5:
                    errors.append(
                        f"{dpi} DPI page {page} Footer begins at row {first_purple} ({boundary}pt), "
                        f"expected y={FOOTER_Y}pt within raster rounding"
                    )
                if first_purple is None:
                    continue

                footer_rasters.append(pixels[first_purple * width * 3:])
                x0, x1 = round(8 * scale), round(70 * scale)
                y0, y1 = first_purple, height
                white_rows = []
                for y in range(y0, y1):
                    if any(all(channel >= 250 for channel in pixel(pixels, width, x, y)) for x in range(x0, x1)):
                        white_rows.append(y)
                if not white_rows:
                    errors.append(f"{dpi} DPI page {page} symmetric Footer logo is not visible")
                    continue
                visible_center = ((white_rows[0] + white_rows[-1] + 1) / 2) / scale
                if abs(visible_center - FOOTER_CENTER) > 0.5:
                    errors.append(
                        f"{dpi} DPI page {page} Footer logo center is {visible_center:.3f}pt, "
                        f"expected {FOOTER_CENTER:.3f}pt"
                    )

            if len(footer_rasters) == 2 and footer_rasters[0] != footer_rasters[1]:
                errors.append(f"{dpi} DPI body-inset changed Footer pixels")

    if errors:
        print("Footer contract check failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(
        "Footer contract check passed: y=500.5pt, all slots use vertical centering, "
        "the symmetric logo is centered within 0.5pt, body-inset leaves Footer pixels unchanged, "
        "and #402B63 reaches the bottom edge at 72/96/144/288 DPI."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
