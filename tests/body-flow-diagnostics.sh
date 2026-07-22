#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
FONT_PATH="$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/poppins"

QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-slides-template-body-flow.XXXXXX")"
cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-slides-template-body-flow.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

expect_failure() {
  local case_name="$1"
  local expected="$2"
  if typst compile --input "case=$case_name" \
    --root "$PROJECT_ROOT" --font-path "$FONT_PATH" \
    "$TEST_DIR/body-flow-diagnostics.typ" "$QA_TMP/$case_name.pdf" \
    >"$QA_TMP/$case_name.log" 2>&1; then
    printf 'body-flow diagnostic case unexpectedly compiled: %s\n' "$case_name" >&2
    exit 1
  fi
  if ! rg -Fq -- "$expected" "$QA_TMP/$case_name.log"; then
    printf 'body-flow diagnostic case %s did not report: %s\n' "$case_name" "$expected" >&2
    sed -n '1,80p' "$QA_TMP/$case_name.log" >&2
    exit 1
  fi
}

expect_failure unbounded-width \
  'requires a finite parent width'
expect_failure track-count \
  'rows defines 1 tracks but received 2 regions'
expect_failure auto-exhausted \
  'body-flow "auto-exhausted": auto rows and fixed spacing need 80pt, but the finite body provides only 60pt'
expect_failure fractional-gutter-exhausted \
  'body-flow "fractional-gutter-exhausted": auto rows consume the finite body and leave no positive height for fractional gutters'
expect_failure fractional-outer-gutter-exhausted \
  'body-flow "fractional-outer-gutter-exhausted": auto rows consume the finite body and leave no positive height for fractional outer gutters'
expect_failure outer-gutter-count \
  'body-flow "outer-gutter-count": outer-gutter must be one value or a two-item (top, bottom) array; got 1'
expect_failure nested-finite-budget \
  'row-split "nested-remainder": fixed/percentage tracks and gutters require 70pt, but only 30pt is available'
