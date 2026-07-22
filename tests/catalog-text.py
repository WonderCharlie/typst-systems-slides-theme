#!/usr/bin/env python3
"""Reject known malformed text in the compiled Catalog PDF."""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path


def main() -> int:
    pdf = Path(sys.argv[1] if len(sys.argv) > 1 else "build/catalog.pdf")
    if not pdf.is_file():
        print(f"Catalog text check failed: missing {pdf}", file=sys.stderr)
        return 1
    if shutil.which("pdftotext") is None:
        print("Catalog text check failed: pdftotext is required", file=sys.stderr)
        return 1
    text = subprocess.run(
        ["pdftotext", str(pdf), "-"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        text=True,
    ).stdout
    forbidden = ("Figure Figure", "Equation Equation", "[8.6]", "[1.42]", "[2.8]")
    errors = [token for token in forbidden if token in text]
    if errors:
        print("Catalog text check failed:", file=sys.stderr)
        for token in errors:
            print(f"- forbidden rendered text remains: {token!r}", file=sys.stderr)
        return 1
    print("Catalog text check passed: references and progressive table values render without duplicated supplements or brackets.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
