#!/usr/bin/env bash
set -euo pipefail

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$TEST_DIR/.." && pwd)"
PYTHON_BIN="${PYTHON:-python3}"
TYPST_BIN="${TYPST:-typst}"
PACKAGE_NAME="$(sed -n 's/^name = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/typst.toml" | head -n 1)"
PACKAGE_VERSION="$(sed -n 's/^version = "\([^"]*\)"/\1/p' "$PROJECT_ROOT/typst.toml" | head -n 1)"
PACKAGE_SPEC="@local/$PACKAGE_NAME:$PACKAGE_VERSION"
MODE="${1:-isolated}"

fail() {
  printf 'local install check failed: %s\n' "$1" >&2
  exit 1
}

# Search only Typst sources with POSIX/macOS tools. `make install` invokes this
# lifecycle test and must not depend on the optional ripgrep developer tool.
typ_sources_match() {
  local pattern="$1"
  local root="$2"
  local source
  local found=1
  while IFS= read -r -d '' source; do
    if grep -EnH -- "$pattern" "$source"; then
      found=0
    fi
  done < <(find "$root" -type f -name '*.typ' -print0)
  return "$found"
}

case "$MODE" in
  isolated | --installed) ;;
  *) fail "usage: tests/local-install.sh [--installed]" ;;
esac

QA_TMP="$(mktemp -d "${TMPDIR:-/tmp}/systems-slides-template-local-install.XXXXXX")"
cleanup() {
  case "$QA_TMP" in
    "${TMPDIR:-/tmp}"/systems-slides-template-local-install.*) rm -rf -- "$QA_TMP" ;;
    *) printf 'refusing to remove unexpected temporary path: %s\n' "$QA_TMP" >&2 ;;
  esac
}
trap cleanup EXIT

compile_initialized_deck() {
  local package_path="$1"
  local deck_dir="$2"
  local package_args=()
  if [[ -n "$package_path" ]]; then
    package_args=(--package-path "$package_path")
  fi

  "$TYPST_BIN" init "${package_args[@]}" "$PACKAGE_SPEC" "$deck_dir"
  test -f "$deck_dir/main.typ" || fail "typst init did not copy main.typ"
  test -f "$deck_dir/globals.typ" || fail "typst init did not copy globals.typ"
  test -f "$deck_dir/metadata.typ" || fail "typst init did not copy metadata.typ"
  test -d "$deck_dir/sections" || fail "typst init did not copy starter sections"
  test -f "$deck_dir/assets/README.md" || fail "typst init did not copy the asset boundary"
  test -f "$deck_dir/assets/example-mark.svg" \
    || fail "typst init did not copy the starter asset-path fixture"
  test -f "$deck_dir/fonts/poppins/Poppins-Regular.ttf" \
    || fail "typst init did not copy the Theme font deployment"
  test -f "$deck_dir/fonts/source-code-pro/SourceCodePro-Regular.ttf" \
    || fail "typst init did not copy the Theme code-font deployment"
  test -f "$deck_dir/fonts/new-computer-modern/NewCMMath-Regular.otf" \
    || fail "typst init did not copy the Theme math-font deployment"
  test -f "$deck_dir/fonts/libertinus/LibertinusSerif-Regular.otf" \
    || fail "typst init did not copy the Theme math-text deployment"
  test -f "$deck_dir/.vscode/settings.json" \
    || fail "typst init did not copy the Tinymist settings"
  if make -C "$deck_dir" clean BUILD_DIR=.. >/dev/null 2>&1; then
    fail "initialized Deck clean target accepted a path outside its build directory"
  fi
  test ! -e "$deck_dir/.git" || fail "typst init unexpectedly created nested Git metadata"
  grep -Fq -- "@local/$PACKAGE_NAME:$PACKAGE_VERSION" "$deck_dir/globals.typ" \
    || fail "initialized deck does not self-import the installed @local version"
  grep -Fq -- '#let asset-path(relative)' "$deck_dir/globals.typ" \
    || fail "initialized deck does not define its project-local asset-path helper"
  if grep -Fq -- 'date:' "$deck_dir/metadata.typ" \
    || grep -Fq -- 'date: deck-meta.date' "$deck_dir/globals.typ"; then
    fail "initialized starter overrides the Theme automatic date"
  fi
  grep -Fq -- 'event-mark: asset-path("example-mark.svg")' \
    "$deck_dir/sections/1_frontmatter.typ" \
    || fail "initialized starter does not exercise a native path Theme slot"
  if typ_sources_match '(/decks/|/assets/|\.\./assets/)' "$deck_dir"; then
    fail "initialized source hard-codes a project name or section-relative asset path"
  fi
  if typ_sources_match \
    '#(import|include).*(\.\./\.\./|src/|compat)' "$deck_dir"; then
    fail "initialized source depends on repository-relative or internal paths"
  fi
  if typ_sources_match \
    '#import "@local/systems-slides-template:[^"]+": \*' "$deck_dir"; then
    fail "initialized source wildcard-imports the complete package surface"
  fi
  mkdir -p "$deck_dir/build"
  local font_args=(
    --ignore-system-fonts
    --ignore-embedded-fonts
    --font-path "$deck_dir/fonts/poppins"
    --font-path "$deck_dir/fonts/source-code-pro"
    --font-path "$deck_dir/fonts/new-computer-modern"
    --font-path "$deck_dir/fonts/libertinus"
  )
  "$TYPST_BIN" compile \
    --root "$deck_dir" \
    "${font_args[@]}" \
    "${package_args[@]}" \
    "$deck_dir/main.typ" \
    "$deck_dir/build/slides.pdf"
  # The path helper must remain anchored to this deck even when an editor or
  # monorepo build chooses the parent `decks/` directory as the Typst root.
  "$TYPST_BIN" compile \
    --root "$(dirname "$deck_dir")" \
    "${font_args[@]}" \
    "${package_args[@]}" \
    "$deck_dir/main.typ" \
    "$deck_dir/build/slides-outer-root.pdf"
  test -s "$deck_dir/build/slides-outer-root.pdf" \
    || fail "initialized starter did not compile from an outer decks root"
  local pages
  pages="$(pdfinfo "$deck_dir/build/slides.pdf" | awk '/^Pages:/ { print $2; exit }')"
  test "${pages:-0}" = "4" || fail "initialized starter must compile to four pages"
  "$TYPST_BIN" compile \
    --root "$deck_dir" \
    "${font_args[@]}" \
    --input layout-debug=labels \
    "${package_args[@]}" \
    "$deck_dir/main.typ" \
    "$deck_dir/build/slides-layout-debug.pdf"
  test -s "$deck_dir/build/slides-layout-debug.pdf" \
    || fail "initialized starter did not compile its explicit layout debug PDF"
  pdftotext "$deck_dir/build/slides-layout-debug.pdf" - \
    | grep -Fq -- 'Theme body' \
    || fail "initialized layout debug PDF does not contain Theme region labels"
  "$TYPST_BIN" eval 'query(<pdfpc-file>).first().value' --in "$deck_dir/main.typ" \
    --root "$deck_dir" "${font_args[@]}" \
    "${package_args[@]}" > "$deck_dir/build/slides.pdfpc"
  test -s "$deck_dir/build/slides.pdfpc" || fail "initialized starter did not export PDFPC notes"
  grep -Fq -- 'Connect the system constraint' "$deck_dir/build/slides.pdfpc" \
    || fail "initialized PDFPC output does not contain the speaker note"
}

if [[ "$MODE" == "--installed" ]]; then
  export TYPST_PACKAGE_PATH="$QA_TMP/ambient-path-must-be-ignored"
  "$PYTHON_BIN" "$PROJECT_ROOT/tools/local-package.py" check
  unset TYPST_PACKAGE_PATH
  compile_initialized_deck "" "$QA_TMP/deck"
  printf 'system install check passed: %s\n' "$PACKAGE_SPEC"
  exit 0
fi

PACKAGE_ROOT="$QA_TMP/packages"
TARGET="$PACKAGE_ROOT/local/$PACKAGE_NAME/$PACKAGE_VERSION"
TOOL=("$PYTHON_BIN" "$PROJECT_ROOT/tools/local-package.py")

"${TOOL[@]}" install --package-root "$PACKAGE_ROOT"
test -d "$TARGET" || fail "installer did not create the exact local package target"
test ! -L "$TARGET" || fail "formal package target is a symbolic link"
if find "$TARGET" -type l -print -quit | grep -q .; then
  fail "formal package contains a symbolic link"
fi

for expected in typst.toml lib.typ LICENSE thumbnail.png src themes template; do
  test -e "$TARGET/$expected" || fail "installed package is missing $expected"
done
for font_file in OFL.txt Poppins-Regular.ttf Poppins-SemiBold.ttf Poppins-Bold.ttf; do
  test -f "$TARGET/themes/systems-slides-template/assets/fonts/poppins/$font_file" \
    || fail "installed package is missing the Theme-owned Poppins source: $font_file"
  test -f "$TARGET/template/fonts/poppins/$font_file" \
    || fail "installed package did not materialize the starter font deployment: $font_file"
  cmp "$TARGET/themes/systems-slides-template/assets/fonts/poppins/$font_file" \
    "$TARGET/template/fonts/poppins/$font_file" \
    || fail "starter font deployment drifted from the Theme source: $font_file"
done
for font_asset in \
  source-code-pro/SourceCodePro-Regular.ttf \
  source-code-pro/SourceCodePro-Bold.ttf \
  source-code-pro/LICENSE.md \
  new-computer-modern/NewCM10-Regular.otf \
  new-computer-modern/NewCMMath-Regular.otf \
  new-computer-modern/LICENSE.txt \
  libertinus/LibertinusSerif-Regular.otf \
  libertinus/OFL.txt; do
  test -f "$TARGET/themes/systems-slides-template/assets/fonts/$font_asset" \
    || fail "installed package is missing Theme font source: $font_asset"
  test -f "$TARGET/template/fonts/$font_asset" \
    || fail "installed package did not materialize starter font: $font_asset"
  cmp "$TARGET/themes/systems-slides-template/assets/fonts/$font_asset" \
    "$TARGET/template/fonts/$font_asset" \
    || fail "starter font deployment drifted from Theme source: $font_asset"
done
while IFS= read -r source; do
  relative="${source#"$PROJECT_ROOT/"}"
  test -f "$TARGET/$relative" || fail "runtime Typst source is missing: $relative"
done < <(find "$PROJECT_ROOT/src" -type f -name '*.typ' | sort)
test ! -e "$TARGET/src/README.md" || fail "maintenance-only src/README.md leaked into package"
for excluded in build docs examples tests tools packaging Makefile README.md CHANGELOG.md; do
  test ! -e "$TARGET/$excluded" || fail "development-only path leaked into package: $excluded"
done

"${TOOL[@]}" check --package-root "$PACKAGE_ROOT"
"${TOOL[@]}" install --package-root "$PACKAGE_ROOT"
compile_initialized_deck "$PACKAGE_ROOT" "$QA_TMP/deck"

ln -s "$QA_TMP/unused-sibling-target" "$TARGET/../0.3.0"
"${TOOL[@]}" install --package-root "$PACKAGE_ROOT" >/dev/null
unlink "$TARGET/../0.3.0"

printf '\n// intentional isolated-test modification\n' >> "$TARGET/lib.typ"
ln -s "$QA_TMP/intentional-broken-link" "$TARGET/intentional-broken-link"
if "${TOOL[@]}" install --package-root "$PACKAGE_ROOT" >/dev/null 2>&1; then
  fail "install overwrote different content for the same version"
fi
if "${TOOL[@]}" uninstall --package-root "$PACKAGE_ROOT" >/dev/null 2>&1; then
  fail "uninstall removed marker-owned but modified content"
fi
"${TOOL[@]}" reinstall --package-root "$PACKAGE_ROOT"
test ! -e "$TARGET/intentional-broken-link" && test ! -L "$TARGET/intentional-broken-link" \
  || fail "explicit reinstall did not repair a symlink-corrupted package"
"${TOOL[@]}" check --package-root "$PACKAGE_ROOT"

INTERRUPTED_BACKUP="$TARGET/../.$PACKAGE_VERSION.backup-interrupted-test"
mv "$TARGET" "$INTERRUPTED_BACKUP"
if "${TOOL[@]}" check --package-root "$PACKAGE_ROOT" >/dev/null 2>&1; then
  fail "read-only check silently accepted an interrupted replacement"
fi
"${TOOL[@]}" reinstall --package-root "$PACKAGE_ROOT" >/dev/null
"${TOOL[@]}" check --package-root "$PACKAGE_ROOT"
test -d "$TARGET" || fail "reinstall did not restore an interrupted replacement backup"
test ! -e "$INTERRUPTED_BACKUP" || fail "recovery left an interrupted backup behind"

"${TOOL[@]}" uninstall --package-root "$PACKAGE_ROOT"
test ! -e "$TARGET" || fail "uninstall left the exact version directory behind"
test -d "$PACKAGE_ROOT/local/$PACKAGE_NAME" \
  || fail "uninstall unexpectedly removed package parent directories"

mkdir -p "$TARGET"
printf 'foreign directory\n' > "$TARGET/foreign.txt"
if "${TOOL[@]}" uninstall --package-root "$PACKAGE_ROOT" >/dev/null 2>&1; then
  fail "uninstall removed a directory without the ownership marker"
fi
if "${TOOL[@]}" install --package-root "$PACKAGE_ROOT" >/dev/null 2>&1; then
  fail "install overwrote a directory without the ownership marker"
fi
if "${TOOL[@]}" reinstall --package-root "$PACKAGE_ROOT" >/dev/null 2>&1; then
  fail "reinstall overwrote a directory without the ownership marker"
fi

ESCAPE_ROOT="$QA_TMP/escape-root"
ESCAPE_TARGET="$QA_TMP/escape-target"
mkdir -p "$ESCAPE_ROOT" "$ESCAPE_TARGET"
ln -s "$ESCAPE_TARGET" "$ESCAPE_ROOT/local"
if "${TOOL[@]}" install --package-root "$ESCAPE_ROOT" >/dev/null 2>&1; then
  fail "install followed a symlinked local namespace outside the package root"
fi
test ! -e "$ESCAPE_TARGET/$PACKAGE_NAME/$PACKAGE_VERSION" \
  || fail "install wrote through a symlinked local namespace"

LEGIT_ROOT="$QA_TMP/legitimate-root"
ATTACK_ROOT="$QA_TMP/attack-root"
"${TOOL[@]}" install --package-root "$LEGIT_ROOT" >/dev/null
mkdir -p "$ATTACK_ROOT"
ln -s "$LEGIT_ROOT/local" "$ATTACK_ROOT/local"
if "${TOOL[@]}" uninstall --package-root "$ATTACK_ROOT" >/dev/null 2>&1; then
  fail "uninstall followed a symlinked local namespace"
fi
test -d "$LEGIT_ROOT/local/$PACKAGE_NAME/$PACKAGE_VERSION" \
  || fail "uninstall removed a package through a symlinked namespace"

printf 'isolated local package lifecycle passed: %s\n' "$PACKAGE_SPEC"
