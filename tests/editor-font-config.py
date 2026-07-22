#!/usr/bin/env python3
"""Keep Tinymist and command-line builds on the Theme-owned Poppins files."""

from __future__ import annotations

import json
import re
from pathlib import Path

from public_vocabulary import naming_violation


ROOT = Path(__file__).resolve().parents[1]
CONFIGS = {
    ROOT / ".vscode/settings.json": (
        "${workspaceFolder}",
        [
            "${workspaceFolder}/themes/systems-slides-template/assets/fonts/poppins",
            "${workspaceFolder}/themes/systems-slides-template/assets/fonts/source-code-pro",
            "${workspaceFolder}/themes/systems-slides-template/assets/fonts/new-computer-modern",
            "${workspaceFolder}/themes/systems-slides-template/assets/fonts/libertinus",
        ],
    ),
    ROOT / "template/.vscode/settings.json": (
        "${workspaceFolder}",
        [
            "${workspaceFolder}/fonts/poppins",
            "${workspaceFolder}/fonts/source-code-pro",
            "${workspaceFolder}/fonts/new-computer-modern",
            "${workspaceFolder}/fonts/libertinus",
        ],
    ),
}


for path, (expected_root, expected_fonts) in CONFIGS.items():
    data = json.loads(path.read_text())
    assert data.get("tinymist.rootPath") == expected_root, (
        f"{path}: tinymist.rootPath must be {expected_root!r}"
    )
    assert data.get("tinymist.fontPaths") == expected_fonts, (
        f"{path}: tinymist.fontPaths must be {expected_fonts!r}"
    )
    assert data.get("tinymist.projectResolution") == "lockDatabase", (
        f"{path}: multi-file decks must use lockDatabase so section previews resolve to main.typ"
    )
    assert data.get("tinymist.systemFonts") is False, (
        f"{path}: Tinymist must use only the Theme-owned Poppins deployment"
    )
    assert "--ignore-embedded-fonts" in data.get("tinymist.typstExtraArgs", []), (
        f"{path}: Tinymist must prefer the Theme-owned math font over Typst's embedded font"
    )

font_dir = ROOT / "themes/systems-slides-template/assets/fonts/poppins"
for filename in ("Poppins-Regular.ttf", "Poppins-SemiBold.ttf", "Poppins-Bold.ttf"):
    assert (font_dir / filename).is_file(), f"missing Theme-owned font: {filename}"

mono_dir = ROOT / "themes/systems-slides-template/assets/fonts/source-code-pro"
for filename in ("SourceCodePro-Regular.ttf", "SourceCodePro-Bold.ttf", "LICENSE.md"):
    assert (mono_dir / filename).is_file(), f"missing Theme-owned monospace asset: {filename}"

math_dir = ROOT / "themes/systems-slides-template/assets/fonts/new-computer-modern"
for filename in ("NewCM10-Regular.otf", "NewCMMath-Regular.otf", "LICENSE.txt"):
    assert (math_dir / filename).is_file(), f"missing Theme-owned math asset: {filename}"
libertinus_dir = ROOT / "themes/systems-slides-template/assets/fonts/libertinus"
for filename in ("LibertinusSerif-Regular.otf", "OFL.txt"):
    assert (libertinus_dir / filename).is_file(), f"missing Theme-owned math text asset: {filename}"

assert not (ROOT / "template/fonts").exists(), "starter source must not duplicate Theme fonts"
assert not (ROOT / "examples/catalog/.vscode/settings.json").exists(), (
    "Catalog must inherit the repository editor settings instead of maintaining a duplicate"
)
for makefile in (ROOT / "Makefile", ROOT / "template/Makefile"):
    source = makefile.read_text()
    assert "--ignore-system-fonts" in source, f"{makefile}: system fonts must be disabled"
    assert "--ignore-embedded-fonts" in source, f"{makefile}: embedded fonts must be disabled"
    assert "--font-path $(POPPINS_FONT_PATH)" in source, f"{makefile}: Poppins path missing"
    assert "--font-path $(MONO_FONT_PATH)" in source, f"{makefile}: mono path missing"
    assert "--font-path $(MATH_FONT_PATH)" in source, f"{makefile}: math path missing"
    assert "--font-path $(MATH_TEXT_FONT_PATH)" in source, f"{makefile}: math text path missing"

starter_makefile = (ROOT / "template/Makefile").read_text(encoding="utf-8")
assert "../themes/" not in starter_makefile, (
    "initialized Starter must discover fonts only from its own fonts/ directory"
)
starter_settings = (ROOT / "template/.vscode/settings.json").read_text(encoding="utf-8")
assert "../themes/" not in starter_settings, (
    "initialized Starter Tinymist settings must not depend on the Theme source repository"
)

root_makefile = (ROOT / "Makefile").read_text(encoding="utf-8")
make_targets = set(re.findall(r"(?m)^([A-Za-z0-9_.-]+):(?:\s|$)", root_makefile))
tasks = json.loads((ROOT / ".vscode/tasks.json").read_text(encoding="utf-8"))["tasks"]
for task in tasks:
    if task.get("command") != "make":
        continue
    args = task.get("args", [])
    target = args[-1] if args else ""
    assert target in make_targets, (
        f".vscode/tasks.json: task {task.get('label')!r} refers to missing Make target {target!r}"
    )
    for value in (task.get("label", ""), target):
        violation = naming_violation(value)
        assert violation is None, (
            f".vscode/tasks.json: project-specific task {value!r} violates {violation}"
        )

workspace = json.loads((ROOT / ".vscode/systems-slides-template-dev.code-workspace").read_text())
assert "--ignore-embedded-fonts" in workspace["settings"].get("tinymist.typstExtraArgs", []), (
    "development workspace must prefer the Theme-owned math font"
)

for source_root in (ROOT / "src", ROOT / "themes", ROOT / "template", ROOT / "examples"):
    for source_path in source_root.rglob("*.typ"):
        source = source_path.read_text(encoding="utf-8")
        for forbidden_font in ("Arial", "Helvetica Neue", "Avenir Next", "Arial Unicode MS"):
            assert forbidden_font not in source, (
                f"{source_path}: remove system-font dependency {forbidden_font!r}"
            )

tokens = (ROOT / "themes/systems-slides-template/tokens.typ").read_text(encoding="utf-8")
points = (ROOT / "src/points.typ").read_text(encoding="utf-8")
assert '#let font-sans = "Poppins"' in tokens, "Theme font token must name only Poppins"
assert '#let font-mono = "Source Code Pro"' in tokens, "Theme mono token must name Source Code Pro"
assert '#let default-points-font = "Poppins"' in points, (
    "Points text and marker styles must inherit the same Poppins source"
)

print("editor config check passed: Theme-owned text, code, and math fonts are configured consistently")
