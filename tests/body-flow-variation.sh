#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
FONT_PATH="$PROJECT_ROOT/themes/systems-slides-template/assets/fonts/poppins"

QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-slides-template-body-variation.XXXXXX")"
cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-slides-template-body-variation.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

for variant in base wrapped more-points; do
  typst compile --input "variant=$variant" \
    --root "$PROJECT_ROOT" --font-path "$FONT_PATH" \
    "$TEST_DIR/body-flow.typ" "$QA_TMP/$variant.pdf"
  pages="$(pdfinfo "$QA_TMP/$variant.pdf" | awk '/^Pages:/ { print $2 }')"
  test "$pages" = "2" || {
    printf 'body-flow variant %s produced %s pages, expected 2\n' "$variant" "$pages" >&2
    exit 1
  }
done

pdftotext "$QA_TMP/wrapped.pdf" - | rg -Fq 'WRAPPED_VARIANT'
pdftotext "$QA_TMP/more-points.pdf" - | rg -Fq 'MORE_POINTS_VARIANT'
printf 'body-flow content wrapping and Bullet-count variations compiled without manual geometry\n'
