#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"

fail() {
  printf 'public boundary check failed: %s\n' "$1" >&2
  exit 1
}

for required in \
  lib.typ typst.toml themes/systems-slides-template/theme.typ themes/systems-slides-template/master.typ \
  themes/systems-slides-template/marks.typ \
  src/exports.typ src/slides.typ src/runtime-api.typ src/flow.typ src/layouts.typ \
  src/points.typ src/media.typ src/containers.typ template/main.typ \
  themes/systems-slides-template/assets/fonts/poppins/Poppins-Regular.ttf \
  themes/systems-slides-template/assets/fonts/source-code-pro/SourceCodePro-Regular.ttf \
  themes/systems-slides-template/assets/fonts/new-computer-modern/NewCMMath-Regular.otf \
  themes/systems-slides-template/assets/fonts/libertinus/LibertinusSerif-Regular.otf \
  examples/catalog/main.typ \
  tools/local-package.py packaging/install-files.txt; do
  test -e "$PROJECT_ROOT/$required" || fail "required package file is missing: $required"
done

test ! -e "$PROJECT_ROOT/template/fonts" \
  || fail "starter source duplicates the Theme-owned font dependency"

for retired in \
  deck src/compat src/components src/components.typ src/charts.typ src/diagrams.typ \
  src/layouts-api.typ src/profiles-api.typ tools/deck.sh \
  docs/AUDIT.md docs/MIGRATION.md; do
  test ! -e "$PROJECT_ROOT/$retired" || fail "retired product surface remains: $retired"
done

root_typ=()
while IFS= read -r source; do root_typ+=("$source"); done < <(
  find "$PROJECT_ROOT" -maxdepth 1 -type f -name '*.typ' -print | sort
)
test "${#root_typ[@]}" = "1" || fail "root must contain only one Typst source"
test "${root_typ[0]}" = "$PROJECT_ROOT/lib.typ" || fail "root Typst source must be lib.typ"
test "$(rg -c '^#import\b' "$PROJECT_ROOT/lib.typ")" = "1" \
  || fail "lib.typ must contain exactly one curated export import"
rg -q '^#import "src/exports\.typ": \*$' "$PROJECT_ROOT/lib.typ" \
  || fail "lib.typ must re-export only src/exports.typ"

if rg -n '#import[^\n]*:\s*\*' "$PROJECT_ROOT/src/exports.typ"; then
  fail "src/exports.typ wildcard-imports an implementation module"
fi

# The package consumes the official framework only at Theme, lifecycle,
# runtime, and master boundaries. There is no vendored framework tree.
touying_imports="$(
  rg -l '#import "@preview/touying:0\.7\.4"' "$PROJECT_ROOT/src" "$PROJECT_ROOT/themes" \
    -g '*.typ' | sed "s#^$PROJECT_ROOT/##" | sort | tr '\n' ' '
)"
expected_touying="src/runtime.typ src/slides.typ themes/systems-slides-template/marks.typ themes/systems-slides-template/master.typ themes/systems-slides-template/theme.typ "
test "$touying_imports" = "$expected_touying" \
  || fail "official Touying imports drifted: $touying_imports"
if find "$PROJECT_ROOT" -type d \( -name touying -o -name touying-src \) -print -quit | grep -q .; then
  fail "repository contains a vendored or fork-like Touying directory"
fi

core_files=()
while IFS= read -r source; do core_files+=("$source"); done < <(
  find "$PROJECT_ROOT/src" "$PROJECT_ROOT/themes" -type f -name '*.typ' -print | sort
)
if rg -n "['\"](?:\.\./)*(examples|template|tests|deck|legacy)/" "${core_files[@]}"; then
  fail "package implementation has a reverse dependency on a consumer or test tree"
fi
if ! python3 "$PROJECT_ROOT/tests/public_vocabulary.py" scan-core \
  "$PROJECT_ROOT/src" "$PROJECT_ROOT/themes"; then
  fail "package implementation contains paper, conference, or narrative-role vocabulary"
fi

# The two foundational engines stay independent from Theme and Touying.
if rg -n '^#[[:space:]]*import\b' "$PROJECT_ROOT/src/layouts.typ"; then
  fail "src/layouts.typ must remain import-free"
fi
if rg -n '#[[:space:]]*(import|include)\b' "$PROJECT_ROOT/src/points.typ"; then
  fail "src/points.typ must remain import-free"
fi

consumers=()
while IFS= read -r source; do consumers+=("$source"); done < <(
  find "$PROJECT_ROOT/template" "$PROJECT_ROOT/examples/catalog" \
    -type f -name '*.typ' -print | sort
)
if rg -n '#[[:space:]]*import.*(src/|themes/)' "${consumers[@]}"; then
  fail "starter or product Catalog imports an internal implementation path"
fi
if rg -n '#[[:space:]]*import[[:space:]]*"@preview/touying' "${consumers[@]}"; then
  fail "starter or product Catalog bypasses the package lifecycle/runtime facade"
fi
if rg -n '#[[:space:]]*(import|include).*\.\./\.\./' "$PROJECT_ROOT/template" -g '*.typ'; then
  fail "initialized starter escapes its copied project directory"
fi
if rg -n '\bchildren[[:space:]]*:' "$PROJECT_ROOT/src/points.typ" \
  "$PROJECT_ROOT/template" "$PROJECT_ROOT/examples/catalog" -g '*.typ'; then
  fail "Points authoring must use flat point(..., level: n) streams"
fi
if rg -n '(^|[^[:alnum:]_-])body-points(-profile)?([^[:alnum:]_-]|$)' \
  "$PROJECT_ROOT/template" "$PROJECT_ROOT/examples/catalog" -g '*.typ'; then
  fail "consumers must call points directly instead of defining body-points aliases"
fi
if rg -n '(^|[^[:alnum:]_-])media-(profile|item|caption|figure|row)([^[:alnum:]_-]|$)' \
  "$PROJECT_ROOT/template" "$PROJECT_ROOT/examples/catalog" -g '*.typ'; then
  fail "consumers must use native image/figure and public layout primitives instead of media aliases"
fi

if rg -n 'parameter-reference|parameter-table|usage-guide|reference-deck' \
  "$PROJECT_ROOT/examples/catalog" -g '*.typ'; then
  fail "catalog must be a public capability story without API tables or real-deck dependencies"
fi
test ! -d "$PROJECT_ROOT/examples/catalog/components" \
  || fail "catalog must not carry a second component layer"

install_entries="$(sed -e '/^[[:space:]]*#/d' -e '/^[[:space:]]*$/d' \
  "$PROJECT_ROOT/packaging/install-files.txt" | tr '\n' ' ')"
expected_install="typst.toml lib.typ LICENSE thumbnail.png src themes template "
test "$install_entries" = "$expected_install" \
  || fail "installation allowlist must contain only the seven product roots"

printf 'public boundary check passed: one entry, official Touying, lean product roots\n'
