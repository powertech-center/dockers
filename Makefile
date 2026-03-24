# PowerTech Docker Images
# Hierarchical build system for cross-compilation Docker images
#
# Hierarchy (per distro):
#   <distro>:latest
#     └── <distro>/tools          (wget, curl, git, zip, 7z, jq...)
#           └── <distro>/dev      (make, cmake, gcc, musl git master, dev user)
#                 ├── <distro>/clang      (LLVM/Clang, native host)
#                 ├── <distro>/go         (Go toolchain, native host)
#                 ├── <distro>/rust       (Rust toolchain, native host)
#                 ├── <distro>/csharp     (.NET SDK + NativeAOT, native host)
#                 ├── <distro>/nodejs     (Node.js, TypeScript, JS/TS tooling)
#                 │     └── <distro>/mobile     (Android SDK, Flutter, React Native)
#                 │           NOTE: mobile inherits from nodejs purely as a build
#                 │           optimization (reuses Node.js layers needed for React
#                 │           Native). For the user, these are independent peer images.
#                 │           Do NOT reflect this dependency in README.md.
#                 └── <distro>/cross-platform  (clang wrappers, macOS SDK, xwin)
#                       ├── <distro>/cross-clang    (LLVM/Clang toolchain + dev libs)
#                       ├── <distro>/cross-go       (Go toolchain)
#                       ├── <distro>/cross-rust     (Rust + cargo-audit)
#                       └── <distro>/cross-csharp   (.NET SDK + NativeAOT cross-compilation)

REGISTRY := ghcr.io/powertech-center
DISTROS  := alpine
#DISTROS += debian ubuntu
IMAGES   := tools dev clang go rust csharp nodejs mobile cross-platform cross-clang cross-go cross-rust cross-csharp

# Generate target lists for all distro/image combinations
FULL_TARGETS  := $(foreach d,$(DISTROS),$(addprefix $(d)/,$(IMAGES)))
BUILD_TARGETS := $(addprefix build-,$(FULL_TARGETS))
TEST_TARGETS  := $(addprefix test-,$(FULL_TARGETS))
PUSH_TARGETS  := $(addprefix push-,$(FULL_TARGETS))
CLEAN_TARGETS := $(addprefix clean-,$(FULL_TARGETS))

.PHONY: all build test push clean \
        $(FULL_TARGETS) $(BUILD_TARGETS) $(TEST_TARGETS) $(PUSH_TARGETS) $(CLEAN_TARGETS)

# === Full targets: build → test → push (sequential) ===

all: $(FULL_TARGETS)

# For each distro/image, run build, then test, then push — in order.
# Using recursive make to enforce sequencing within a single target.
define FULL_template
$(1)/$(2): build-$(1)/$(2)
	@$$(MAKE) --no-print-directory test-$(1)/$(2)
	@$$(MAKE) --no-print-directory push-$(1)/$(2)
endef

$(foreach d,$(DISTROS),$(foreach img,$(IMAGES),$(eval $(call FULL_template,$(d),$(img)))))

# === Build targets (with dependency chain) ===

build: $(BUILD_TARGETS)

# Args: 1=distro, 2=image, 3=build dependency (empty for root)
define BUILD_template
build-$(1)/$(2): $(3)
	@echo "Building $(REGISTRY)/$(1)/$(2):latest..."
	@mkdir -p .cache/$(1)
	@cp $(2)/Dockerfile.template .cache/$(1)/$(2)
	docker build -t $(REGISTRY)/$(1)/$(2):latest -f .cache/$(1)/$(2) .
endef

# Instantiate build targets for each distro
define BUILD_all_for_distro
$(eval $(call BUILD_template,$(1),tools,))
$(eval $(call BUILD_template,$(1),dev,build-$(1)/tools))
$(eval $(call BUILD_template,$(1),clang,build-$(1)/dev))
$(eval $(call BUILD_template,$(1),go,build-$(1)/dev))
$(eval $(call BUILD_template,$(1),rust,build-$(1)/dev))
$(eval $(call BUILD_template,$(1),cross-platform,build-$(1)/dev))
$(eval $(call BUILD_template,$(1),cross-clang,build-$(1)/cross-platform))
$(eval $(call BUILD_template,$(1),cross-go,build-$(1)/cross-platform))
$(eval $(call BUILD_template,$(1),csharp,build-$(1)/dev))
$(eval $(call BUILD_template,$(1),nodejs,build-$(1)/dev))
$(eval $(call BUILD_template,$(1),mobile,build-$(1)/nodejs))
$(eval $(call BUILD_template,$(1),cross-rust,build-$(1)/cross-platform))
$(eval $(call BUILD_template,$(1),cross-csharp,build-$(1)/cross-platform))
endef

$(foreach d,$(DISTROS),$(eval $(call BUILD_all_for_distro,$(d))))

# === Test targets ===

test: $(TEST_TARGETS)

define TEST_template
test-$(1)/$(2):
	@if [ -f $(2)/test.sh ]; then \
		echo "Testing $(REGISTRY)/$(1)/$(2):latest..."; \
		docker run --rm -v ./$(2):/tests $(REGISTRY)/$(1)/$(2):latest sh /tests/test.sh; \
	else \
		echo "No tests defined for $(1)/$(2), skipping."; \
	fi
endef

$(foreach d,$(DISTROS),$(foreach img,$(IMAGES),$(eval $(call TEST_template,$(d),$(img)))))

# === Push targets ===

push: $(PUSH_TARGETS)

define PUSH_template
push-$(1)/$(2):
	@echo "Pushing $(REGISTRY)/$(1)/$(2):latest..."
	docker push $(REGISTRY)/$(1)/$(2):latest
endef

$(foreach d,$(DISTROS),$(foreach img,$(IMAGES),$(eval $(call PUSH_template,$(d),$(img)))))

# === Clean targets ===

clean: $(CLEAN_TARGETS)

define CLEAN_template
clean-$(1)/$(2):
	@echo "Removing $(REGISTRY)/$(1)/$(2):latest..."
	docker rmi $(REGISTRY)/$(1)/$(2):latest 2>/dev/null || true
endef

$(foreach d,$(DISTROS),$(foreach img,$(IMAGES),$(eval $(call CLEAN_template,$(d),$(img)))))
