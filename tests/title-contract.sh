#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
FIXTURE="$TEST_DIR/title-contract.typ"
FONT_ARGS=(
  --ignore-system-fonts
  --ignore-embedded-fonts
  --font-path "$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/poppins"
  --font-path "$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/source-code-pro"
  --font-path "$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/new-computer-modern"
  --font-path "$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/libertinus"
)
QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-slides-template-title-contract.XXXXXX")"

cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-slides-template-title-contract.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

fail() {
  printf 'title contract check failed: %s\n' "$1" >&2
  exit 1
}

typst compile --root "$PROJECT_ROOT" "${FONT_ARGS[@]}" "$FIXTURE" "$QA_TMP/valid.pdf"

expect_failure() {
  local case_name="$1"
  local expected="$2"
  local log="$QA_TMP/$case_name.log"
  if typst compile --input "case=$case_name" --root "$PROJECT_ROOT" \
    "${FONT_ARGS[@]}" "$FIXTURE" "$QA_TMP/$case_name.pdf" >"$log" 2>&1; then
    fail "$case_name unexpectedly compiled"
  fi
  if ! grep -Fq -- "$expected" "$log"; then
    sed -n '1,100p' "$log" >&2
    fail "$case_name did not report: $expected"
  fi
  printf 'ok: %s -> %s\n' "$case_name" "$expected"
}

expect_failure "too-long" "slide title does not fit on one line at the 30pt minimum"
expect_failure "explicit-break" "slide title must be a single line"
expect_failure "mark-capacity" "slide title does not fit on one line at the 30pt minimum"

printf 'title contract check passed: valid titles compile and every multiline/undersized title fails clearly\n'
