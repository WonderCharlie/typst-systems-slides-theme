#!/usr/bin/env python3
"""Verify the page count, geometry, and visible text of a PDF.

The checker deliberately uses only Python's standard library and the Poppler
commands ``pdfinfo`` and ``pdftotext``.  It is therefore suitable for the
repository's default validation path and does not maintain image baselines.
"""

from __future__ import annotations

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path
from typing import Iterable


class CheckFailure(RuntimeError):
    """Raised when a PDF violates a declared contract."""


def _parse_page_value(spec: str) -> tuple[int, str]:
    try:
        raw_page, value = spec.split(":", 1)
        page = int(raw_page)
    except (ValueError, TypeError) as exc:
        raise argparse.ArgumentTypeError(
            f"expected PAGE:VALUE, received {spec!r}"
        ) from exc
    if page < 1 or not value:
        raise argparse.ArgumentTypeError(f"invalid PAGE:VALUE contract: {spec!r}")
    return page, value


def _parse_size(spec: str) -> tuple[float, float]:
    match = re.fullmatch(r"\s*([0-9.]+)\s*[xX]\s*([0-9.]+)\s*", spec)
    if not match:
        raise argparse.ArgumentTypeError("expected WIDTHxHEIGHT")
    return float(match.group(1)), float(match.group(2))


def _run(command: list[str]) -> str:
    try:
        result = subprocess.run(command, check=True, text=True, capture_output=True)
    except FileNotFoundError as exc:
        raise CheckFailure(
            f"required command {command[0]!r} is unavailable; install Poppler"
        ) from exc
    except subprocess.CalledProcessError as exc:
        detail = (exc.stderr or exc.stdout or str(exc)).strip()
        raise CheckFailure(f"{command[0]} failed: {detail}") from exc
    return result.stdout


def _pdf_metadata(path: Path) -> tuple[int, float, float]:
    output = _run(["pdfinfo", str(path)])
    pages_match = re.search(r"^Pages:\s+(\d+)\s*$", output, re.MULTILINE)
    size_match = re.search(
        r"^Page size:\s+([0-9.]+)\s+x\s+([0-9.]+)\s+pts\s*$",
        output,
        re.MULTILINE,
    )
    if pages_match is None or size_match is None:
        raise CheckFailure(f"could not read page count and size from {path}")
    return (
        int(pages_match.group(1)),
        float(size_match.group(1)),
        float(size_match.group(2)),
    )


def _page_text(path: Path, page: int) -> str:
    return _run(
        [
            "pdftotext",
            "-f",
            str(page),
            "-l",
            str(page),
            "-layout",
            str(path),
            "-",
        ]
    )


def verify(args: argparse.Namespace) -> None:
    path = Path(args.pdf)
    if not path.is_file():
        raise CheckFailure(f"PDF does not exist: {path}")

    pages, width, height = _pdf_metadata(path)
    if args.pages is not None and pages != args.pages:
        raise CheckFailure(f"expected {args.pages} pages, found {pages} in {path}")

    if args.size is not None:
        expected_width, expected_height = args.size
        if (
            abs(width - expected_width) > args.size_tolerance
            or abs(height - expected_height) > args.size_tolerance
        ):
            raise CheckFailure(
                f"PDF pages are {width:.3f}x{height:.3f} pt; expected "
                f"{expected_width:.3f}x{expected_height:.3f} pt"
            )

    text_cache: dict[int, str] = {}

    def text_for(page: int) -> str:
        if page > pages:
            raise CheckFailure(f"page {page} requested, but the PDF has only {pages} pages")
        if page not in text_cache:
            text_cache[page] = _page_text(path, page)
        return text_cache[page]

    for page, needle in args.contains:
        if needle not in text_for(page):
            raise CheckFailure(f"page {page} does not contain {needle!r}")

    for page, pattern in args.regex:
        text = text_for(page)
        if re.search(pattern, text, flags=re.MULTILINE | re.DOTALL) is None:
            raise CheckFailure(f"page {page} text does not match /{pattern}/; text was {text!r}")

    print(f"verified {path}: {pages} pages, {width:g}x{height:g} pt")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=("verify",))
    parser.add_argument("pdf")
    parser.add_argument("--pages", type=int)
    parser.add_argument("--size", type=_parse_size, default=(960.0, 540.0))
    parser.add_argument("--size-tolerance", type=float, default=0.05)
    parser.add_argument(
        "--contains", type=_parse_page_value, action="append", default=[], metavar="PAGE:TEXT"
    )
    parser.add_argument(
        "--regex", type=_parse_page_value, action="append", default=[], metavar="PAGE:REGEX"
    )
    return parser


def main(argv: Iterable[str] | None = None) -> int:
    if shutil.which("pdfinfo") is None or shutil.which("pdftotext") is None:
        print("PDF checks require Poppler commands pdfinfo and pdftotext", file=sys.stderr)
        return 2
    args = build_parser().parse_args(list(argv) if argv is not None else None)
    try:
        verify(args)
    except (CheckFailure, re.error) as exc:
        print(f"PDF check failed: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
