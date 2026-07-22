#!/usr/bin/env python3
"""Validate Tinymist-facing documentation for the stable public API.

Tinymist derives hover text and signature-help parameter documentation from a
contiguous ``///`` block immediately before a Typst binding. The parameter
allowlist is shared with the single-source check, while all user-facing prose
lives only in these ``///`` blocks.
"""

from __future__ import annotations

import re
import runpy
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
COMMENT_CONTRACT = runpy.run_path(str(ROOT / "tests/check-api-comments.py"))
SOURCE_PARAMS: dict[str, dict[str, tuple[str, ...]]] = COMMENT_CONTRACT["EXPECTED_PARAMS"]


def source_params(path: str, *names: str) -> dict[str, tuple[str, ...]]:
    """Select parameter contracts already checked against real signatures."""
    available = SOURCE_PARAMS[path]
    return {name: available[name] for name in names}


# This is intentionally an explicit stable-API allowlist.  Internal helpers,
# compatibility functions, examples, and project calibration functions must
# not become part of the Tinymist contract merely because they have comments.
STABLE_FUNCTIONS: dict[str, dict[str, tuple[str, ...]]] = {
    "themes/systems-slides-template/marks.typ": source_params(
        "themes/systems-slides-template/marks.typ", "page-mark"
    ),
    "themes/systems-slides-template/theme.typ": source_params(
        "themes/systems-slides-template/theme.typ", "systems-slides-theme"
    ),
    "src/slides.typ": source_params(
        "src/slides.typ", "slide", "title-slide", "outline-slide", "section-slide"
    ),
    "src/page-frame.typ": source_params(
        "src/page-frame.typ", "page-layer", "page-frame"
    ),
    "src/flow.typ": source_params("src/flow.typ", "body-flow"),
    "src/layouts.typ": source_params(
        "src/layouts.typ", "layout-profile", "region", "row-split", "column-split"
    ),
    "src/points.typ": source_params(
        "src/points.typ", "point", "points"
    ),
    "src/typography.typ": source_params(
        "src/typography.typ",
        "danger",
        "lead",
    ),
    "src/containers.typ": source_params(
        "src/containers.typ", "panel", "callout"
    ),
    "src/runtime-api.typ": {
        "speaker-note": ("mode", "setting", "subslide", "note"),
        "jump": ("n", "relative"),
        "uncover": ("visible-subslides", "uncover-cont", "cover-fn", "self"),
        "only": ("visible-subslides", "only-cont"),
        "alternatives": ("start", "repeat-last", "position", "stretch", "at", "..args"),
        "presenter-view": ("side",),
    },
}

# ``pause`` and ``meanwhile`` are author-facing content values rather than
# callable functions.  They still require hover documentation and a return
# type, but have no parameter bullets.
STABLE_VALUES: dict[str, tuple[str, ...]] = {
    "src/runtime-api.typ": ("pause", "meanwhile"),
}

DOC_PARAM_RE = re.compile(
    r"^-\s+([A-Za-z][A-Za-z0-9-]*)\s+\(([^)]+)\):\s*(.+)$"
)
CHINESE_RE = re.compile(r"[\u3400-\u4dbf\u4e00-\u9fff]")

# Tinymist 0.15.2 accepts this vocabulary in ``/// - param (types):`` lists.
# Typst's runtime value kind ``alignment`` is intentionally absent: Tinymist's
# structured-doc parser does not recognize either ``alignment`` or ``align``.
# Such parameters use ``any`` here and state the alignment constraint in prose.
TINYMIST_0152_TYPES = {
    "any",
    "arguments",
    "array",
    "auto",
    "bool",
    "bytes",
    "color",
    "content",
    "datetime",
    "decimal",
    "dictionary",
    "duration",
    "float",
    "fraction",
    "function",
    "gradient",
    "int",
    "label",
    "length",
    "module",
    "none",
    "ratio",
    "regex",
    "relative",
    "str",
    "symbol",
    "tiling",
    "type",
    "version",
}


def normalized_param(name: str) -> str:
    return name[2:] if name.startswith("..") else name


def strip_typst_comments(text: str) -> str:
    """Remove Typst comments while preserving strings and line structure."""
    result: list[str] = []
    index = 0
    quote: str | None = None
    escaped = False
    block_depth = 0
    while index < len(text):
        char = text[index]
        pair = text[index : index + 2]
        if block_depth:
            if pair == "/*":
                block_depth += 1
                index += 2
            elif pair == "*/":
                block_depth -= 1
                index += 2
            else:
                if char == "\n":
                    result.append(char)
                index += 1
            continue
        if quote is not None:
            result.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char in ('"', "'"):
            quote = char
            result.append(char)
            index += 1
            continue
        if pair == "//":
            newline = text.find("\n", index + 2)
            if newline < 0:
                break
            result.append("\n")
            index = newline + 1
            continue
        if pair == "/*":
            block_depth = 1
            index += 2
            continue
        result.append(char)
        index += 1
    return "".join(result)


def signature_params(text: str, name: str) -> tuple[str, ...] | None:
    """Parse top-level parameter names from a Typst function declaration."""
    cleaned = strip_typst_comments(text)
    match = re.search(rf"(?m)^#let\s+{re.escape(name)}\s*\(", cleaned)
    if match is None:
        return None
    opening = cleaned.find("(", match.start())
    depth = 1
    quote: str | None = None
    escaped = False
    current: list[str] = []
    entries: list[str] = []
    index = opening + 1
    while index < len(cleaned):
        char = cleaned[index]
        if quote is not None:
            current.append(char)
            if escaped:
                escaped = False
            elif char == "\\":
                escaped = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char in ('"', "'"):
            quote = char
            current.append(char)
        elif char in "([{":
            depth += 1
            current.append(char)
        elif char in ")]}":
            depth -= 1
            if depth == 0:
                if "".join(current).strip():
                    entries.append("".join(current).strip())
                break
            current.append(char)
        elif char == "," and depth == 1:
            if "".join(current).strip():
                entries.append("".join(current).strip())
            current = []
        else:
            current.append(char)
        index += 1
    else:
        return None

    params: list[str] = []
    for entry in entries:
        param = re.match(r"^(\.\.)?([A-Za-z][A-Za-z0-9-]*)\s*(?::|$)", entry)
        if param is None:
            return None
        prefix, identifier = param.groups()
        params.append((prefix or "") + identifier)
    return tuple(params)


def declaration_line(lines: list[str], name: str, *, value: bool = False) -> int | None:
    if value:
        pattern = re.compile(rf"^#let\s+{re.escape(name)}\s*=")
    else:
        pattern = re.compile(rf"^#let\s+{re.escape(name)}\s*\(")
    for index, line in enumerate(lines):
        if pattern.match(line):
            return index
    return None


def adjacent_doc_block(lines: list[str], declaration: int) -> tuple[int, list[str]]:
    cursor = declaration - 1
    block: list[str] = []
    while cursor >= 0 and lines[cursor].startswith("///"):
        block.append(lines[cursor][3:].lstrip())
        cursor -= 1
    block.reverse()
    return cursor + 2, block


def validate_binding(
    relative: str,
    name: str,
    expected_params: tuple[str, ...],
    *,
    value: bool = False,
) -> list[str]:
    errors: list[str] = []
    path = ROOT / relative
    if not path.exists():
        return [f"{relative}: 文件不存在"]

    lines = path.read_text(encoding="utf-8").splitlines()
    declaration = declaration_line(lines, name, value=value)
    if declaration is None:
        kind = "公开值" if value else "公共函数"
        return [f"{relative}: 找不到{kind} {name}"]

    if not value:
        actual_params = signature_params("\n".join(lines), name)
        if actual_params is None:
            errors.append(f"{relative}:{declaration + 1}: 无法解析 {name} 的真实函数签名")
        elif actual_params != expected_params:
            errors.append(
                f"{relative}:{declaration + 1}: {name} 的稳定参数清单已漂移；"
                f"期望 {expected_params}，实际 {actual_params}"
            )

    doc_line, block = adjacent_doc_block(lines, declaration)
    location = f"{relative}:{declaration + 1}"
    if not block:
        return [f"{location}: {name} 前缺少连续且相邻的 /// 文档块"]

    previous_index = doc_line - 2
    if previous_index >= 0:
        previous = lines[previous_index].lstrip()
        if previous.startswith("//") and not previous.startswith("///"):
            errors.append(
                f"{relative}:{previous_index + 1}: {name} 的 /// 文档块前必须用空行隔离普通 // 注释，"
                "否则 Tinymist 可能把内部英文说明并入 hover"
            )

    nonempty = [line for line in block if line.strip()]
    if not nonempty or nonempty[0].startswith(("- ", "->")):
        errors.append(f"{relative}:{doc_line}: {name} 缺少函数职责摘要")
    elif not CHINESE_RE.search(nonempty[0]):
        errors.append(f"{relative}:{doc_line}: {name} 的职责摘要必须包含中文说明")

    found_params: list[str] = []
    return_types: list[str] = []
    parameter_started = False
    parameter_finished = False
    offset = 0
    while offset < len(block):
        line = block[offset]
        stripped = line.strip()
        source_line = doc_line + offset
        if len(lines[source_line - 1]) > 100:
            errors.append(
                f"{relative}:{source_line}: {name} 的 /// 行超过 100 个字符；"
                "请使用缩进续行"
            )
        if not stripped:
            next_nonempty = next(
                (candidate.strip() for candidate in block[offset + 1 :] if candidate.strip()),
                "",
            )
            if parameter_started and not parameter_finished and next_nonempty.startswith("- "):
                errors.append(
                    f"{relative}:{source_line}: {name} 的参数之间不能插入空 /// 行；"
                    "Tinymist 可能丢失 signature-help 文档"
                )
            offset += 1
            continue
        match = DOC_PARAM_RE.match(stripped)
        if match:
            param, type_text, description = match.groups()
            found_params.append(param)
            parameter_started = True
            continuation: list[str] = []
            cursor = offset + 1
            while cursor < len(block):
                candidate = block[cursor].strip()
                if not candidate or candidate.startswith(("- ", "->")):
                    break
                continuation.append(candidate)
                cursor += 1
            full_description = " ".join((description, *continuation))
            if not type_text.strip():
                errors.append(f"{relative}:{source_line}: {name}.{param} 缺少类型")
            else:
                documented_types = {part.strip() for part in type_text.split(",")}
                unknown_types = sorted(documented_types - TINYMIST_0152_TYPES)
                if unknown_types:
                    errors.append(
                        f"{relative}:{source_line}: {name}.{param} 使用 Tinymist 0.15.2 "
                        f"不识别的文档类型 {unknown_types}"
                    )
            if not full_description.strip():
                errors.append(f"{relative}:{source_line}: {name}.{param} 缺少说明")
            elif not CHINESE_RE.search(full_description):
                errors.append(
                    f"{relative}:{source_line}: {name}.{param} 的说明必须包含中文"
                )
            else:
                # Sentinel values must be explained explicitly, but prose is
                # intentionally free-form. Requiring a fixed checklist of
                # labels produced repetitive hover text without improving the
                # contract.
                documented_types = {part.strip() for part in type_text.split(",")}
                for sentinel in ("auto", "none"):
                    if sentinel in documented_types and sentinel not in full_description:
                        errors.append(
                            f"{relative}:{source_line}: {name}.{param} "
                            f"必须说明 `{sentinel}` 的含义"
                        )
            offset = cursor
            continue
        if stripped.startswith("->"):
            parameter_finished = True
            return_types.append(stripped[2:].strip())
        offset += 1

    expected = [normalized_param(param) for param in expected_params]
    if found_params != expected:
        errors.append(
            f"{location}: {name} 的 Tinymist 参数文档不匹配；"
            f"期望 {tuple(expected)}，实际 {tuple(found_params)}"
        )

    duplicates = sorted({param for param in found_params if found_params.count(param) > 1})
    if duplicates:
        errors.append(f"{location}: {name} 重复记录参数 {duplicates}")

    if len(return_types) != 1 or not return_types[0]:
        errors.append(f"{location}: {name} 必须恰好声明一个非空的 `/// -> type` 返回类型")
    else:
        return_index = next(
            index for index, line in enumerate(block) if line.strip().startswith("->")
        )
        trailing = [line for line in block[return_index + 1 :] if line.strip()]
        if trailing:
            errors.append(f"{location}: {name} 的返回类型必须是文档块最后一项")

    return errors


def main() -> int:
    errors: list[str] = []
    binding_count = 0
    parameter_count = 0

    for relative, functions in STABLE_FUNCTIONS.items():
        for name, params in functions.items():
            errors.extend(validate_binding(relative, name, params))
            binding_count += 1
            parameter_count += len(params)

    for relative, values in STABLE_VALUES.items():
        for name in values:
            errors.extend(validate_binding(relative, name, (), value=True))
            binding_count += 1

    if errors:
        print("Tinymist 公共文档静态检查失败：", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(
        "Tinymist 公共文档静态检查通过："
        f"{binding_count} 个稳定绑定，{parameter_count} 个参数，全部具有中文职责、类型与返回契约。"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
