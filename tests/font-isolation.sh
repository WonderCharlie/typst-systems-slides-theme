#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
PACKAGE_PATH="${1:-$PROJECT_ROOT/build/packages}"
POPPINS_FONT_PATH="${2:-$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/poppins}"
MONO_FONT_PATH="${3:-$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/source-code-pro}"
MATH_FONT_PATH="${4:-$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/new-computer-modern}"
MATH_TEXT_FONT_PATH="${5:-$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/libertinus}"
TYPST_BIN="${TYPST:-typst}"
PACKAGE_NAME="$(sed -n 's/^name = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/typst.toml" | head -n 1)"
PACKAGE_VERSION="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/typst.toml" | head -n 1)"
PACKAGE_SPEC="@local/$PACKAGE_NAME:$PACKAGE_VERSION"

fail() {
  printf 'font isolation check failed: %s\n' "$1" >&2
  exit 1
}

command -v pdffonts >/dev/null || fail "pdffonts is required"
test -f "$POPPINS_FONT_PATH/Poppins-Regular.ttf" || fail "Theme Poppins source is missing"
test -f "$MONO_FONT_PATH/SourceCodePro-Regular.ttf" || fail "Theme monospace source is missing"
test -f "$MATH_FONT_PATH/NewCMMath-Regular.otf" || fail "Theme math source is missing"
test -f "$MATH_TEXT_FONT_PATH/LibertinusSerif-Regular.otf" || fail "Theme math text source is missing"

QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-slides-template-font-isolation.XXXXXX")"
cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-slides-template-font-isolation.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

compile_clean() {
  local output="$1"
  shift
  local log="$QA_TMP/$(basename "$output").stderr"
  if ! "$@" 2>"$log"; then
    cat "$log" >&2
    fail "Typst failed while producing $output"
  fi
  if [[ -s "$log" ]]; then
    cat "$log" >&2
    fail "Typst emitted a warning or diagnostic while producing $output"
  fi
  test -s "$output" || fail "Typst did not produce $output"
}

assert_no_system_fonts() {
  local pdf="$1"
  local fonts="$QA_TMP/$(basename "$pdf").fonts"
  pdffonts "$pdf" >"$fonts"
  if grep -Eiq 'Arial|Helvetica|Avenir|Liberation Sans|DejaVu Sans Mono|Menlo|Monaco' "$fonts"; then
    cat "$fonts" >&2
    fail "system font leaked into $(basename "$pdf")"
  fi
  grep -Eiq 'Poppins' "$fonts" || {
    cat "$fonts" >&2
    fail "Poppins was not embedded in $(basename "$pdf")"
  }
  if [[ "$(basename "$pdf")" == "catalog.pdf" ]]; then
    grep -Eiq 'SourceCodePro' "$fonts" || {
      cat "$fonts" >&2
      fail "Source Code Pro was not embedded in Catalog"
    }
    grep -Eiq 'NewCMMath-Regular' "$fonts" || {
      cat "$fonts" >&2
      fail "Theme-owned NewCMMath-Regular was not embedded in Catalog"
    }
    if grep -Eiq 'NewCMMath-Book' "$fonts"; then
      cat "$fonts" >&2
      fail "Typst's embedded NewCMMath-Book bypassed the Theme font source"
    fi
    grep -Eiq 'LibertinusSerif' "$fonts" || {
      cat "$fonts" >&2
      fail "Libertinus Serif was not embedded in Catalog"
    }
  fi
}

mkdir -p "$QA_TMP/output"
compile_clean "$QA_TMP/output/starter.pdf" \
  "$TYPST_BIN" compile --ignore-system-fonts --ignore-embedded-fonts \
  --root "$PROJECT_ROOT" --font-path "$POPPINS_FONT_PATH" --font-path "$MONO_FONT_PATH" --font-path "$MATH_FONT_PATH" --font-path "$MATH_TEXT_FONT_PATH" --package-path "$PACKAGE_PATH" \
  "$PROJECT_ROOT/template/main.typ" "$QA_TMP/output/starter.pdf"

compile_clean "$QA_TMP/output/catalog.pdf" \
  "$TYPST_BIN" compile --ignore-system-fonts --ignore-embedded-fonts \
  --root "$PROJECT_ROOT" --font-path "$POPPINS_FONT_PATH" --font-path "$MONO_FONT_PATH" --font-path "$MATH_FONT_PATH" --font-path "$MATH_TEXT_FONT_PATH" --package-path "$PACKAGE_PATH" \
  "$PROJECT_ROOT/examples/catalog/main.typ" "$QA_TMP/output/catalog.pdf"

"$TYPST_BIN" init --package-path "$PACKAGE_PATH" "$PACKAGE_SPEC" "$QA_TMP/deck" >/dev/null
compile_clean "$QA_TMP/output/initialized-deck.pdf" \
  "$TYPST_BIN" compile --ignore-system-fonts --ignore-embedded-fonts \
  --root "$QA_TMP/deck" --font-path "$QA_TMP/deck/fonts/poppins" --font-path "$QA_TMP/deck/fonts/source-code-pro" --font-path "$QA_TMP/deck/fonts/new-computer-modern" --font-path "$QA_TMP/deck/fonts/libertinus" --package-path "$PACKAGE_PATH" \
  "$QA_TMP/deck/main.typ" "$QA_TMP/output/initialized-deck.pdf"

for pdf in "$QA_TMP/output/starter.pdf" "$QA_TMP/output/catalog.pdf" "$QA_TMP/output/initialized-deck.pdf"; do
  assert_no_system_fonts "$pdf"
done

printf 'font isolation check passed: Starter, Catalog, and initialized Deck use Theme-owned text, code, and math fonts without system or embedded fallback\n'
