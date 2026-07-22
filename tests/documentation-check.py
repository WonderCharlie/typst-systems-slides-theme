#!/usr/bin/env python3
"""Validate documentation ownership, links, versions, and retired vocabulary."""

from __future__ import annotations

import re
import sys
import tomllib
from pathlib import Path
from urllib.parse import unquote

from public_vocabulary import RETIRED_IDENTIFIERS


ROOT = Path(__file__).resolve().parents[1]
MARKDOWN = tuple(sorted(ROOT.rglob("*.md")))
LINK_RE = re.compile(r"(?<!!)\[[^\]]+\]\(([^)]+)\)")
MECHANICAL_DOC_RE = re.compile(r"职责：|允许：|特殊值：|覆盖/继承：|约束：")
RETIRED = RETIRED_IDENTIFIERS
REQUIRED = (
    "README.md",
    "docs/INSTALL.md",
    "docs/USER_GUIDE.md",
    "docs/API_DOCUMENTATION.md",
    "docs/MAINTAINING.md",
    "template/README.md",
    "tests/README.md",
    "examples/catalog/README.md",
)


def local_target(source: Path, raw: str) -> Path | None:
    target = raw.strip().split(maxsplit=1)[0].strip("<>")
    if not target or target.startswith(("#", "http://", "https://", "mailto:")):
        return None
    path_text = unquote(target.split("#", 1)[0])
    if not path_text:
        return None
    return (source.parent / path_text).resolve()


def main() -> int:
    errors: list[str] = []
    manifest = tomllib.loads((ROOT / "typst.toml").read_text(encoding="utf-8"))
    version = manifest["package"]["version"]
    package_ref = f"@local/systems-slides-template:{version}"

    for relative in REQUIRED:
        if not (ROOT / relative).exists():
            errors.append(f"缺少职责明确的文档：{relative}")

    root_readme = (ROOT / "README.md").read_text(encoding="utf-8")
    for relative in REQUIRED[1:]:
        if relative.startswith(("template/", "tests/", "examples/")):
            continue
        if relative not in root_readme:
            errors.append(f"README.md 未导航到 {relative}")

    for path in MARKDOWN:
        relative = path.relative_to(ROOT)
        text = path.read_text(encoding="utf-8")
        for match in LINK_RE.finditer(text):
            target = local_target(path, match.group(1))
            if target is not None and not target.exists():
                line = text.count("\n", 0, match.start()) + 1
                errors.append(f"{relative}:{line}: 失效本地链接 {match.group(1)!r}")
        for retired in RETIRED:
            if retired in text:
                errors.append(f"{relative}: 正式文字材料重新出现已移除接口/路径 {retired!r}")

    for path in (
        ROOT / "src",
        ROOT / "themes",
    ):
        for source in path.rglob("*.typ"):
            text = source.read_text(encoding="utf-8")
            for match in MECHANICAL_DOC_RE.finditer(text):
                line = text.count("\n", 0, match.start()) + 1
                errors.append(
                    f"{source.relative_to(ROOT)}:{line}: /// 使用机械重复标签 {match.group(0)!r}"
                )

    catalog_source = "\n".join(
        path.read_text(encoding="utf-8")
        for path in (ROOT / "examples/catalog").rglob("*.typ")
    )
    for duplicate in ("parameter-reference", "parameter-table", "[Default]", "item.default"):
        if duplicate in catalog_source:
            errors.append(f"examples/catalog/: Catalog 不得维护第二份 API 参数资料 {duplicate!r}")

    for relative in ("README.md", "docs/INSTALL.md", "template/README.md"):
        text = (ROOT / relative).read_text(encoding="utf-8")
        if package_ref not in text:
            errors.append(f"{relative}: 缺少当前本地包坐标 {package_ref}")

    if errors:
        print("文档体系检查失败：", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        f"文档体系检查通过：{len(MARKDOWN)} 个 Markdown 文件，"
        f"本地链接、{package_ref}、退役词汇与 API 注释风格均一致。"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
