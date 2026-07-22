PROJECT_ROOT := $(CURDIR)
POPPINS_FONT_PATH := $(PROJECT_ROOT)/themes/systems-slides-template/assets/fonts/poppins
MONO_FONT_PATH := $(PROJECT_ROOT)/themes/systems-slides-template/assets/fonts/source-code-pro
MATH_FONT_PATH := $(PROJECT_ROOT)/themes/systems-slides-template/assets/fonts/new-computer-modern
MATH_TEXT_FONT_PATH := $(PROJECT_ROOT)/themes/systems-slides-template/assets/fonts/libertinus
FONT_PATH := $(POPPINS_FONT_PATH)
FONT_ARGS := --ignore-system-fonts --ignore-embedded-fonts --font-path $(POPPINS_FONT_PATH) --font-path $(MONO_FONT_PATH) --font-path $(MATH_FONT_PATH) --font-path $(MATH_TEXT_FONT_PATH)
PYTHON ?= python3
TYPST ?= typst

BUILD_DIR ?= build
PACKAGE_PATH := $(BUILD_DIR)/packages
DIST_PACKAGE_PATH := $(BUILD_DIR)/dist/packages
LOCAL_PACKAGE_TOOL := tools/local-package.py
TEST_OUTPUT_DIR := $(BUILD_DIR)/tests
GUIDE_OUTPUT_DIR := $(BUILD_DIR)/guide
GUIDE_EXAMPLE_OUTPUT := $(GUIDE_OUTPUT_DIR)/first-deck.pdf

STARTER_OUTPUT := $(BUILD_DIR)/starter.pdf
CATALOG_OUTPUT := $(BUILD_DIR)/catalog.pdf
STARTER_PDFPC := $(BUILD_DIR)/starter.pdfpc
CATALOG_PDFPC := $(BUILD_DIR)/catalog.pdfpc

STABLE_SOURCES := lib.typ typst.toml $(shell find src themes -type f -name '*.typ' | sort)
THEME_FONT_SOURCES := $(shell find themes/systems-slides-template/assets/fonts -type f | sort)
STARTER_SOURCES := $(shell find template -type f | sort) $(THEME_FONT_SOURCES)
CATALOG_SOURCES := $(shell find examples/catalog -type f | sort) $(STABLE_SOURCES) $(THEME_FONT_SOURCES)

CORE_FIXTURES := \
	theme-api lifecycle navigation special-config section-lifecycle presenter-view \
	layout-contract body-flow points-contract page-frame native-theme
CORE_OUTPUTS := $(addprefix $(TEST_OUTPUT_DIR)/,$(addsuffix .pdf,$(CORE_FIXTURES)))

.PHONY: all starter catalog validate core-check fixture-check presenter-check \
	package package-check package-stage local-install-check init-check \
	install install-path install-check reinstall uninstall \
	starter-verify catalog-verify catalog-structure-check catalog-visual-stability-check catalog-page-boundary-check catalog-lifecycle-check catalog-text-check title-contract-check page-mark-title-stability-check footer-contract-check \
	starter-pdfpc catalog-pdfpc \
	comment-check documentation-check tinymist-docs-static-check tinymist-docs-check \
	tinymist-installed-docs-check editor-font-check font-isolation-check version-check api-naming-check public-check \
	guide-check guide-contract-check guide-examples-check \
	layout-diagnostics-check layout-debug-check body-flow-diagnostics-check body-flow-variation-check body-flow-distribution-check \
	navigation-layout-check navigation-diagnostics-check \
	thumbnail clean

all: starter

starter: $(STARTER_OUTPUT)

catalog: $(CATALOG_OUTPUT)

# Default validation exercises the exact install snapshot, standard Typst
# initialization, starter, product Catalog, presentation runtime, editor docs,
# and the stable public boundary. Real decks are validated in the Slides workspace.
validate: package-check starter-verify catalog-verify \
	local-install-check guide-check core-check

package:
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) package \
		--package-root "$(abspath $(DIST_PACKAGE_PATH))" --replace

package-check: package
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) check \
		--package-root "$(abspath $(DIST_PACKAGE_PATH))"

# Repository-only physical snapshot used by the starter and editor checks.
package-stage:
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) package \
		--package-root "$(abspath $(PACKAGE_PATH))" --replace

local-install-check:
	bash tests/local-install.sh

init-check: local-install-check

install: local-install-check
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) install

install-path:
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) path

install-check:
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) check
	bash tests/local-install.sh --installed

reinstall: local-install-check
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) reinstall

uninstall:
	$(PYTHON) $(LOCAL_PACKAGE_TOOL) uninstall

comment-check:
	$(PYTHON) tests/check-api-comments.py

documentation-check:
	$(PYTHON) tests/documentation-check.py

guide-contract-check: $(CATALOG_OUTPUT)
	$(PYTHON) tests/guide-check.py $(CATALOG_OUTPUT)

guide-examples-check: $(GUIDE_EXAMPLE_OUTPUT)
	$(PYTHON) tests/fidelity_check.py verify $(GUIDE_EXAMPLE_OUTPUT) \
		--pages 5 \
		--contains '1:Relay: Scheduling Dependent I/O' \
		--contains '3:Remote I/O Exposes the Dependency Chain' \
		--contains '4:Synthetic scheduling architecture' \
		--contains '5:Dependency Awareness Reduces Visible Latency'

guide-check: guide-contract-check guide-examples-check

tinymist-docs-static-check:
	$(PYTHON) tests/check-tinymist-docs.py

# Live Tinymist checks intentionally stay outside validate because they depend
# on the editor binary installed on the current workstation.
tinymist-docs-check: tinymist-docs-static-check
	TINYMIST="$(TINYMIST)" $(PYTHON) tests/tinymist-lsp.py

tinymist-installed-docs-check: tinymist-docs-static-check
	TINYMIST="$(TINYMIST)" $(PYTHON) tests/tinymist-lsp.py --installed

editor-font-check:
	$(PYTHON) tests/editor-font-config.py

font-isolation-check: package-stage
	bash tests/font-isolation.sh "$(abspath $(PACKAGE_PATH))" \
		"$(abspath $(POPPINS_FONT_PATH))" "$(abspath $(MONO_FONT_PATH))" \
		"$(abspath $(MATH_FONT_PATH))" "$(abspath $(MATH_TEXT_FONT_PATH))"

version-check:
	bash tests/version-sync.sh

api-naming-check:
	$(PYTHON) tests/public-api-naming.py

public-check: api-naming-check
	bash tests/public-boundary.sh

layout-diagnostics-check:
	bash tests/layout-diagnostics.sh

layout-debug-check:
	@mkdir -p $(TEST_OUTPUT_DIR)
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		tests/layout-debug.typ $(TEST_OUTPUT_DIR)/layout-debug-release.pdf
	@if pdftotext $(TEST_OUTPUT_DIR)/layout-debug-release.pdf - | grep -Fq 'Theme body'; then \
		echo 'release PDF unexpectedly contains layout-debug labels' >&2; exit 1; \
	fi
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		--input layout-debug=boxes tests/layout-debug.typ $(TEST_OUTPUT_DIR)/layout-debug-boxes.pdf
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		--input layout-debug=labels tests/layout-debug.typ $(TEST_OUTPUT_DIR)/layout-debug-labels.pdf
	$(PYTHON) tests/fidelity_check.py verify $(TEST_OUTPUT_DIR)/layout-debug-labels.pdf \
		--pages 1 \
		--contains '1:Theme body' \
		--contains '1:body-flow' \
		--contains '1:debug flow' \
		--contains '1:left media' \
		--contains '1:right points'

body-flow-diagnostics-check:
	bash tests/body-flow-diagnostics.sh

body-flow-variation-check:
	bash tests/body-flow-variation.sh

body-flow-distribution-check: $(TEST_OUTPUT_DIR)/body-flow-distribution.pdf
	$(PYTHON) tests/body-flow-distribution.py $<

navigation-layout-check: $(TEST_OUTPUT_DIR)/navigation.pdf
	$(PYTHON) tests/navigation-layout.py $<

navigation-diagnostics-check:
	bash tests/navigation-diagnostics.sh

fixture-check: $(CORE_OUTPUTS)
	$(PYTHON) tests/fidelity_check.py verify $(TEST_OUTPUT_DIR)/native-theme.pdf \
		--pages 1 \
		--contains '1:Figure 1' \
		--contains '1:Native caption remains referenceable' \
		--contains '1:Reference check: Figure 1'

presenter-check: $(TEST_OUTPUT_DIR)/presenter-view.pdf $(STARTER_PDFPC)
	$(PYTHON) tests/fidelity_check.py verify $(TEST_OUTPUT_DIR)/presenter-view.pdf \
		--pages 1 --size 1920x540 \
		--contains '1:PRESENTER_AUDIENCE_CONTENT' \
		--contains '1:PRESENTER_PRIVATE_NOTE'
	@test -s $(STARTER_PDFPC)
	@rg -q 'Connect the system constraint' $(STARTER_PDFPC)

core-check: comment-check documentation-check tinymist-docs-static-check editor-font-check font-isolation-check version-check public-check title-contract-check page-mark-title-stability-check \
	layout-diagnostics-check layout-debug-check body-flow-diagnostics-check body-flow-variation-check body-flow-distribution-check \
	navigation-layout-check navigation-diagnostics-check \
	footer-contract-check fixture-check presenter-check

starter-verify: $(STARTER_OUTPUT)
	$(PYTHON) tests/fidelity_check.py verify $(STARTER_OUTPUT) \
		--pages 4 \
		--contains '1:Your Systems Presentation Title' \
		--contains '2:Roadmap' \
		--contains '3:Frame the Problem Before the Mechanism' \
		--contains '3:The critical path includes communication' \
		--contains '4:Use Native Images and Figures' \
		--contains '4:A deck-owned SVG rendered through Typst' \
		--contains '4:keeps Typst' \
		--contains '4:native numbering and reference semantics'

catalog-structure-check:
	$(PYTHON) tests/catalog-structure.py

catalog-visual-stability-check: $(CATALOG_OUTPUT)
	$(PYTHON) tests/catalog-visual-stability.py $(CATALOG_OUTPUT)

catalog-page-boundary-check: $(CATALOG_OUTPUT)
	$(PYTHON) tests/catalog-page-boundary.py $(CATALOG_OUTPUT)

catalog-lifecycle-check: $(CATALOG_PDFPC)
	$(PYTHON) tests/catalog-lifecycle.py $(CATALOG_PDFPC)

catalog-text-check: $(CATALOG_OUTPUT)
	$(PYTHON) tests/catalog-text.py $(CATALOG_OUTPUT)

catalog-verify: $(CATALOG_OUTPUT) catalog-structure-check catalog-visual-stability-check catalog-page-boundary-check catalog-lifecycle-check catalog-text-check
	$(PYTHON) tests/fidelity_check.py verify $(CATALOG_OUTPUT) \
		--pages 45 \
		--contains '1:Relay: Dependency-Aware I/O Scheduling' \
		--contains '2:Catalog Roadmap' \
		--contains '5:Fixed Evidence, Progressive Interpretation' \
		--contains '10:Require no application changes' \
		--contains '17:Progressive Points in Stable Free Space' \
		--contains '19:Require no application changes' \
		--contains '22:Native Figure References' \
		--contains '27:network delay overlaps compute' \
		--contains '30:Complete pipeline' \
		--contains '33:Experimental Configuration' \
		--contains '36:Best result' \
		--contains '39:Pseudocode with Explanation' \
		--contains '40:Visible request latency' \
		--contains '43:Dependency-Aware Scheduling Preserves Ordering' \
		--contains '43:Across compute and remote storage boundaries' \
		--contains '44:Titleless technical canvas' \
		--contains '45:2×2 Evidence Matrix'

starter-pdfpc: $(STARTER_PDFPC)

catalog-pdfpc: $(CATALOG_PDFPC)

thumbnail: thumbnail.png

thumbnail.png: $(STARTER_SOURCES) $(STABLE_SOURCES) | package-stage
	$(TYPST) compile --format png --pages 1 --ppi 180 \
		--root $(PROJECT_ROOT) $(FONT_ARGS) --package-path $(PACKAGE_PATH) \
		template/main.typ $@

$(STARTER_OUTPUT): $(STARTER_SOURCES) $(STABLE_SOURCES) | package-stage
	@mkdir -p $(dir $@)
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		--package-path $(PACKAGE_PATH) template/main.typ $@

$(CATALOG_OUTPUT): $(CATALOG_SOURCES) | package-stage
	@mkdir -p $(dir $@)
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		--package-path $(PACKAGE_PATH) examples/catalog/main.typ $@

$(STARTER_PDFPC): $(STARTER_OUTPUT) $(STARTER_SOURCES) | package-stage
	@mkdir -p $(dir $@)
	$(TYPST) eval 'query(<pdfpc-file>).first().value' --in template/main.typ \
		--root $(PROJECT_ROOT) $(FONT_ARGS) --package-path $(PACKAGE_PATH) > $@

$(CATALOG_PDFPC): $(CATALOG_OUTPUT) $(CATALOG_SOURCES) | package-stage
	@mkdir -p $(dir $@)
	$(TYPST) eval 'query(<pdfpc-file>).first().value' --in examples/catalog/main.typ \
		--root $(PROJECT_ROOT) $(FONT_ARGS) --package-path $(PACKAGE_PATH) > $@

$(TEST_OUTPUT_DIR)/%.pdf: tests/%.typ $(STABLE_SOURCES) $(THEME_FONT_SOURCES)
	@mkdir -p $(dir $@)
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) $< $@

$(GUIDE_EXAMPLE_OUTPUT): $(shell find docs/guide/examples -type f | sort) $(STABLE_SOURCES) $(THEME_FONT_SOURCES) | package-stage
	@mkdir -p $(dir $@)
	$(TYPST) compile --root docs/guide/examples $(FONT_ARGS) \
		--package-path $(PACKAGE_PATH) docs/guide/examples/first-deck.typ $@

page-mark-title-stability-check: $(TEST_OUTPUT_DIR)/page-mark-title-stability.pdf
	$(PYTHON) tests/page-mark-title-stability.py $<

footer-contract-check: $(TEST_OUTPUT_DIR)/footer-contract.pdf
	$(PYTHON) tests/footer-contract.py $<

title-contract-check:
	bash tests/title-contract.sh

clean:
	@test "$(abspath $(BUILD_DIR))" = "$(PROJECT_ROOT)/build" || { \
		echo "refusing to clean anything except the root build/ directory" >&2; exit 2; \
	}
	rm -rf -- "$(abspath $(BUILD_DIR))" "$(PROJECT_ROOT)/tmp" \
		"$(PROJECT_ROOT)/tests/__pycache__" "$(PROJECT_ROOT)/tools/__pycache__"
