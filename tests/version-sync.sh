#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
PACKAGE_NAME="$(sed -n 's/^name = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/typst.toml" | head -n 1)"
PACKAGE_VERSION="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/typst.toml" | head -n 1)"
PACKAGE_SPEC="@local/$PACKAGE_NAME:$PACKAGE_VERSION"

fail() {
  printf 'version sync check failed: %s\n' "$1" >&2
  exit 1
}

test -n "$PACKAGE_NAME" || fail "typst.toml has no package name"
test -n "$PACKAGE_VERSION" || fail "typst.toml has no package version"

if rg -n '@preview/systems-slides-template:' "$PROJECT_ROOT" \
  -g '!build/**' -g '!tmp/**' -g '!.git/**' -g '!tests/version-sync.sh'; then
  fail "the private package still has an @preview self-reference"
fi

references="$(
  rg -o '@local/systems-slides-template:[0-9A-Za-z.+-]+' "$PROJECT_ROOT" \
    -g '!build/**' -g '!tmp/**' -g '!.git/**' -g '!tests/version-sync.sh' \
    | sed 's/.*:@local/@local/' \
    | sort -u
)"
test -n "$references" || fail "no @local self-reference was found"
for reference in $references; do
  test "$reference" = "$PACKAGE_SPEC" \
    || fail "self-reference $reference does not match $PACKAGE_SPEC"
done

rg -q "#import \"$PACKAGE_SPEC\"" "$PROJECT_ROOT/template/globals.typ" \
  || fail "starter globals do not import $PACKAGE_SPEC"
rg -q '^\[template\]$' "$PROJECT_ROOT/typst.toml" \
  || fail "typst.toml has no template initialization section"
rg -q '@preview/touying:0\.7\.4' "$PROJECT_ROOT/src" "$PROJECT_ROOT/themes" \
  || fail "the external Touying dependency is no longer pinned to @preview/touying:0.7.4"

printf 'version sync check passed: %s\n' "$PACKAGE_SPEC"
