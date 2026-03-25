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

REGISTRY  := ghcr.io/powertech-center
DISTROS   := alpine debian ubuntu
TEMPLATES := tools dev clang go rust csharp nodejs mobile cross-platform cross-clang cross-go cross-rust cross-csharp

# ===========================================================================
# 1. Base targets: <do>-<distro>/<template> — actual recipes
# ===========================================================================

# --- setup ---

setup:
	@python3 -c "import jinja2" 2>/dev/null || { \
		if command -v apk >/dev/null 2>&1; then \
			apk add --no-cache py3-jinja2; \
		elif command -v apt-get >/dev/null 2>&1; then \
			apt-get install -y python3-jinja2; \
		else \
			pip install -r shared/requirements.txt; \
		fi; \
	}

# --- build-<distro>/<template> ---

# Args: 1=distro, 2=template, 3=build dependency
define rule_build
build-$(1)/$(2): $(3)
	@echo "Building $(REGISTRY)/$(1)/$(2):latest..."
	@python shared/configure.py $(1) $(2)
	docker build -t $(REGISTRY)/$(1)/$(2):latest -f .cache/$(1)/$(2) .
endef

define rule_build_deps
$(eval $(call rule_build,$(1),tools,setup))
$(eval $(call rule_build,$(1),dev,build-$(1)/tools))
$(eval $(call rule_build,$(1),clang,build-$(1)/dev))
$(eval $(call rule_build,$(1),go,build-$(1)/dev))
$(eval $(call rule_build,$(1),rust,build-$(1)/dev))
$(eval $(call rule_build,$(1),cross-platform,build-$(1)/dev))
$(eval $(call rule_build,$(1),cross-clang,build-$(1)/cross-platform))
$(eval $(call rule_build,$(1),cross-go,build-$(1)/cross-platform))
$(eval $(call rule_build,$(1),csharp,build-$(1)/dev))
$(eval $(call rule_build,$(1),nodejs,build-$(1)/dev))
$(eval $(call rule_build,$(1),mobile,build-$(1)/nodejs))
$(eval $(call rule_build,$(1),cross-rust,build-$(1)/cross-platform))
$(eval $(call rule_build,$(1),cross-csharp,build-$(1)/cross-platform))
endef

$(foreach d,$(DISTROS),$(eval $(call rule_build_deps,$(d))))

# --- cmd_test, cmd_push: reusable recipe bodies ---

define cmd_test
	@if [ -f $(1)/test.sh ]; then \
		echo "Testing $(REGISTRY)/$(2)/$(1):latest..."; \
		docker run --rm -v ./$(1):/tests $(REGISTRY)/$(2)/$(1):latest sh /tests/test.sh; \
	else \
		echo "No tests defined for $(2)/$(1), skipping."; \
	fi
endef

define cmd_push
	@echo "Pushing $(REGISTRY)/$(1)/$(2):latest..."
	docker push $(REGISTRY)/$(1)/$(2):latest
endef

# --- test-<distro>/<template> ---

define rule_test
test-$(1)/$(2):
	$(call cmd_test,$(2),$(1))
endef

$(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),$(eval $(call rule_test,$(d),$(t)))))

# --- push-<distro>/<template> ---

define rule_push
push-$(1)/$(2):
	$(call cmd_push,$(1),$(2))
endef

$(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),$(eval $(call rule_push,$(d),$(t)))))

# --- clean-<distro>/<template> ---

define rule_clean
clean-$(1)/$(2):
	@echo "Removing $(REGISTRY)/$(1)/$(2):latest..."
	docker rmi $(REGISTRY)/$(1)/$(2):latest 2>/dev/null || true
endef

$(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),$(eval $(call rule_clean,$(d),$(t)))))

# ===========================================================================
# 2. Image targets: <distro>/<template> — build, then test + push inline
# ===========================================================================

define rule_image
$(1)/$(2): build-$(1)/$(2)
	$(call cmd_test,$(2),$(1))
	$(call cmd_push,$(1),$(2))
endef

$(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),$(eval $(call rule_image,$(d),$(t)))))

# ===========================================================================
# 3. Aggregate targets — pure dependencies, no recipes
# ===========================================================================

# --- <do>: all distros, all templates ---
build: $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),build-$(d)/$(t)))
test:  $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),test-$(d)/$(t)))
push:  $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),push-$(d)/$(t)))
clean: $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),clean-$(d)/$(t)))

# --- <do>-<distro>: all templates for one distro ---
$(foreach d,$(DISTROS),$(eval build-$(d): $(foreach t,$(TEMPLATES),build-$(d)/$(t))))
$(foreach d,$(DISTROS),$(eval test-$(d):  $(foreach t,$(TEMPLATES),test-$(d)/$(t))))
$(foreach d,$(DISTROS),$(eval push-$(d):  $(foreach t,$(TEMPLATES),push-$(d)/$(t))))
$(foreach d,$(DISTROS),$(eval clean-$(d): $(foreach t,$(TEMPLATES),clean-$(d)/$(t))))

# --- <do>-<template>: all distros for one template ---
$(foreach t,$(TEMPLATES),$(eval build-$(t): $(foreach d,$(DISTROS),build-$(d)/$(t))))
$(foreach t,$(TEMPLATES),$(eval test-$(t):  $(foreach d,$(DISTROS),test-$(d)/$(t))))
$(foreach t,$(TEMPLATES),$(eval push-$(t):  $(foreach d,$(DISTROS),push-$(d)/$(t))))
$(foreach t,$(TEMPLATES),$(eval clean-$(t): $(foreach d,$(DISTROS),clean-$(d)/$(t))))

# --- <template>: all distros, full cycle (build → test → push) ---
$(foreach t,$(TEMPLATES),$(eval $(t): $(foreach d,$(DISTROS),$(d)/$(t))))

# --- all ---
all: $(TEMPLATES)

# ===========================================================================
# .PHONY
# ===========================================================================

.PHONY: all setup build test push clean \
        $(DISTROS) $(TEMPLATES) \
        $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),$(d)/$(t))) \
        $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),build-$(d)/$(t) test-$(d)/$(t) push-$(d)/$(t) clean-$(d)/$(t))) \
        $(foreach d,$(DISTROS),build-$(d) test-$(d) push-$(d) clean-$(d)) \
        $(foreach t,$(TEMPLATES),build-$(t) test-$(t) push-$(t) clean-$(t))
