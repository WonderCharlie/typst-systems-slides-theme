#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "$TEST_DIR/.." && pwd)"
PROJECT_ROOT="$THEME_DIR"
FONT_PATH="$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/poppins"
FIXTURE="$TEST_DIR/layout-diagnostics.typ"

QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-layout-diagnostics.XXXXXX")"
cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-layout-diagnostics.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

fail() {
  printf 'layout diagnostics check failed: %s\n' "$1" >&2
  exit 1
}

command -v typst >/dev/null 2>&1 || fail "typst is not available"
test -f "$FIXTURE" || fail "fixture is missing: $FIXTURE"

# The no-input path must remain a valid positive control.
typst compile \
  --root "$PROJECT_ROOT" \
  --font-path "$FONT_PATH" \
  "$FIXTURE" "$QA_TMP/positive-control.pdf"

expect_failure() {
  local case_name="$1"
  local expected="$2"
  local output="$QA_TMP/$case_name.pdf"
  local log="$QA_TMP/$case_name.log"

  if typst compile \
    --input "case=$case_name" \
    --root "$PROJECT_ROOT" \
    --font-path "$FONT_PATH" \
    "$FIXTURE" "$output" >"$log" 2>&1; then
    fail "$case_name unexpectedly compiled"
  fi

  if ! rg -Fq -- "$expected" "$log"; then
    printf '%s\n' "--- $case_name compiler output ---" >&2
    sed -n '1,100p' "$log" >&2
    fail "$case_name did not report: $expected"
  fi
  printf 'ok: %s -> %s\n' "$case_name" "$expected"
}

expect_failure \
  "row-track-count" \
  'row-split "row-count": rows defines 1 tracks but received 2 regions'
expect_failure \
  "column-track-count" \
  'column-split "column-count": columns defines 1 tracks but received 2 regions'
expect_failure \
  "gutter-count" \
  'row-split "gutter-count": gutter must be one value or 2 values for 3 regions; got 1'
expect_failure \
  "align-count" \
  'row-split "align-count": align array must match the number of regions; expected 2, got 1'
expect_failure \
  "fit-count" \
  'row-split "fit-count": fit array must match the number of regions; expected 2, got 1'
expect_failure \
  "overflow-count" \
  'row-split "overflow-count": overflow array must match the number of regions; expected 2, got 1'
expect_failure \
  "column-profile-on-row" \
  'row-split "profile-direction" cannot consume layout-profile "column-only" because it defines columns'
expect_failure \
  "row-profile-on-column" \
  'column-split "profile-direction" cannot consume layout-profile "row-only" because it defines rows'
expect_failure \
  "inherited-profile-axis" \
  'layout-profile "mixed-derived": rows and columns cannot both be defined'
expect_failure \
  "invalid-fit" \
  'row-split "invalid-fit": fit must be flow, contain, cover, or stretch; got "squash"'
expect_failure \
  "invalid-overflow" \
  'row-split "invalid-overflow": overflow must be visible, clip, or error; got "hide"'
expect_failure \
  "fractional-rows-no-height" \
  'row-split "fractional-rows": fractional or percentage rows/gutters require a finite height'
expect_failure \
  "fixed-budget" \
  'row-split "fixed-budget": fixed/percentage tracks and gutters require 130pt, but only 100pt is available; reduce tracks/gutter or use fr/auto'
expect_failure \
  "strict-auto" \
  'region "strict-auto": fit/overflow policies require a finite, non-auto row track'
expect_failure \
  "content-overflow" \
  'region "overflowing-content": content needs 100pt x 30pt, but the region provides 100pt x 20pt; use fit: "contain", overflow: "clip", or increase the track'
expect_failure \
  "nested-fixed-budget" \
  'row-split "nested-budget": fixed/percentage tracks and gutters require 70pt, but only 50pt is available; reduce tracks/gutter or use fr/auto'
expect_failure \
  "page-layer-invalid-area" \
  'page-layer "invalid-area": area must be page or body; got "title"'
expect_failure \
  "overlay-body-area" \
  'page-frame "invalid-overlay": overlay must cover the full page; omit area or use area: "page"'
expect_failure \
  "media-overflow" \
  'region "oversized-media": content needs 100pt x 60pt, but the region provides 100pt x 50pt; use fit: "contain", overflow: "clip", or increase the track'

printf 'layout diagnostics: all negative cases reported their public contract messages\n'
