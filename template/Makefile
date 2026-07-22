TYPST ?= typst
PROJECT_ROOT := $(CURDIR)
LOCAL_POPPINS_PATH := $(PROJECT_ROOT)/fonts/poppins
LOCAL_MONO_PATH := $(PROJECT_ROOT)/fonts/source-code-pro
POPPINS_FONT_PATH ?= $(LOCAL_POPPINS_PATH)
MONO_FONT_PATH ?= $(LOCAL_MONO_PATH)
MATH_FONT_PATH ?= $(PROJECT_ROOT)/fonts/new-computer-modern
MATH_TEXT_FONT_PATH ?= $(PROJECT_ROOT)/fonts/libertinus
FONT_ARGS := --ignore-system-fonts --ignore-embedded-fonts --font-path $(POPPINS_FONT_PATH) --font-path $(MONO_FONT_PATH) --font-path $(MATH_FONT_PATH) --font-path $(MATH_TEXT_FONT_PATH)
BUILD_DIR := build
PDF := $(BUILD_DIR)/slides.pdf
DEBUG_PDF := $(BUILD_DIR)/slides-layout-debug.pdf
PDFPC := $(BUILD_DIR)/slides.pdfpc
TYPST_PACKAGE_PATH ?=
PACKAGE_ARG := $(if $(strip $(TYPST_PACKAGE_PATH)),--package-path $(TYPST_PACKAGE_PATH),)
ASSETS := $(shell find assets -type f 2>/dev/null)
FONTS := $(shell find fonts -type f 2>/dev/null)
THEME_FONTS := $(shell find $(POPPINS_FONT_PATH) $(MONO_FONT_PATH) $(MATH_FONT_PATH) $(MATH_TEXT_FONT_PATH) -type f 2>/dev/null)
SOURCES := main.typ globals.typ metadata.typ $(wildcard sections/*.typ) $(ASSETS) $(FONTS) $(THEME_FONTS)

.PHONY: all pdf debug pdfpc watch clean

all: pdf

pdf: $(PDF)

debug:
	@mkdir -p $(BUILD_DIR)
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		--input layout-debug=labels $(PACKAGE_ARG) main.typ $(DEBUG_PDF)

pdfpc: $(PDFPC)

$(PDF): $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(TYPST) compile --root $(PROJECT_ROOT) $(FONT_ARGS) \
		$(PACKAGE_ARG) main.typ $@

$(PDFPC): $(PDF) $(SOURCES)
	@mkdir -p $(BUILD_DIR)
	$(TYPST) eval 'query(<pdfpc-file>).first().value' --in main.typ \
		--root $(PROJECT_ROOT) $(FONT_ARGS) $(PACKAGE_ARG) > $@

watch:
	@mkdir -p $(BUILD_DIR)
	$(TYPST) watch --root $(PROJECT_ROOT) $(FONT_ARGS) \
		$(PACKAGE_ARG) main.typ $(PDF)

clean:
	@test "$(abspath $(BUILD_DIR))" = "$(PROJECT_ROOT)/build" || { \
		echo "refusing to clean anything except this Deck's build/ directory" >&2; exit 2; \
	}
	rm -rf -- "$(PROJECT_ROOT)/build"
