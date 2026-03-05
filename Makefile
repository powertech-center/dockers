# PowerTech Docker Images
# Hierarchical build system for cross-compilation Docker images
#
# Hierarchy:
#   alpine:latest
#     └── alpine-tools          (wget, curl, git, zip, 7z, jq...)
#           └── alpine-dev      (make, cmake, gcc, musl git master, dev user)
#                 ├── alpine-clang      (LLVM/Clang, native host)
#                 ├── alpine-go         (Go toolchain, native host)
#                 ├── alpine-rust       (Rust toolchain, native host)
#                 └── alpine-cross-platform  (clang wrappers, macOS SDK, xwin)
#                       ├── alpine-cross-clang    (LLVM/Clang toolchain + dev libs)
#                       ├── alpine-cross-go       (Go toolchain)
#                       └── alpine-cross-rust     (Rust + cargo-audit)

REGISTRY := ghcr.io/powertech-center

IMAGES         := alpine-tools alpine-dev alpine-clang alpine-go alpine-rust alpine-cross-platform alpine-cross-clang alpine-cross-go alpine-cross-rust
BUILD_TARGETS  := $(IMAGES)
CLEAN_TARGETS  := $(addprefix clean-,$(IMAGES))
PUSH_TARGETS   := $(addprefix push-,$(IMAGES))

.PHONY: $(BUILD_TARGETS) all $(CLEAN_TARGETS) clean $(PUSH_TARGETS) push

# === Build targets (with dependency chain) ===

all: $(BUILD_TARGETS)

define BUILD_template
$(1): $(2)
	@echo "Building $(REGISTRY)/$(1):latest..."
	docker build -t $(REGISTRY)/$(1):latest $(1)/
endef

$(eval $(call BUILD_template,alpine-tools,))
$(eval $(call BUILD_template,alpine-dev,alpine-tools))
$(eval $(call BUILD_template,alpine-clang,alpine-dev))
$(eval $(call BUILD_template,alpine-go,alpine-dev))
$(eval $(call BUILD_template,alpine-rust,alpine-dev))
$(eval $(call BUILD_template,alpine-cross-platform,alpine-dev))
$(eval $(call BUILD_template,alpine-cross-clang,alpine-cross-platform))
$(eval $(call BUILD_template,alpine-cross-go,alpine-cross-platform))
$(eval $(call BUILD_template,alpine-cross-rust,alpine-cross-platform))

# === Clean targets per image ===

clean: $(CLEAN_TARGETS)

define CLEAN_template
clean-$(1):
	@echo "Removing $(REGISTRY)/$(1):latest..."
	docker rmi $(REGISTRY)/$(1):latest 2>/dev/null || true
endef

$(foreach img,$(IMAGES),$(eval $(call CLEAN_template,$(img))))

# === Push targets per image ===

push: $(PUSH_TARGETS)

define PUSH_template
push-$(1):
	@echo "Pushing $(REGISTRY)/$(1):latest..."
	docker push $(REGISTRY)/$(1):latest
endef

$(foreach img,$(IMAGES),$(eval $(call PUSH_template,$(img))))
