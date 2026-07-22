#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "$TEST_DIR/.." && pwd)"
FONT_PATH="$THEME_DIR/themes/systems-slides-template/assets/fonts/poppins"
QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-navigation-diagnostics.XXXXXX")"

cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-navigation-diagnostics.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

if typst compile --root "$THEME_DIR" --font-path "$FONT_PATH" \
  "$TEST_DIR/navigation-invalid.typ" "$QA_TMP/invalid.pdf" >"$QA_TMP/invalid.log" 2>&1; then
  printf 'navigation diagnostics failed: geometry-changing current style unexpectedly compiled\n' >&2
  exit 1
fi

rg -Fq 'outline-slide.current-style may only define fill and weight' \
  "$QA_TMP/invalid.log" || {
    sed -n '1,100p' "$QA_TMP/invalid.log" >&2
    printf 'navigation diagnostics failed: expected current-style message was not reported\n' >&2
    exit 1
  }

printf 'navigation diagnostics: Roadmap emphasis cannot change geometry\n'
