# PowerTech Docker Images
# Hierarchical build system for cross-compilation Docker images
#
# Hierarchy (per distro):
#   <distro>:latest
#     └── <distro>/tools          (wget, curl, git, zip, 7z, jq...)
#           └── <distro>/dev      (make, cmake, gcc, musl git master, dev user)
#                 ├── <distro>/clang      (LLVM/Clang, native host)
#                 │     └── <distro>/cross-clang  (cross-compilation: SDKs, sysroots, wrappers)
#                 │           ├── <distro>/cross-go       (Go toolchain)
#                 │           ├── <distro>/cross-rust     (Rust + cargo-audit)
#                 │           └── <distro>/cross-csharp   (.NET SDK + NativeAOT cross-compilation)
#                 ├── <distro>/go         (Go toolchain, native host)
#                 ├── <distro>/rust       (Rust toolchain, native host)
#                 ├── <distro>/csharp     (.NET SDK + NativeAOT, native host)
#                 ├── <distro>/nodejs     (Node.js, TypeScript, JS/TS tooling)
#                 │     └── <distro>/mobile     (Android SDK, Flutter, React Native)

PYTHON ?= python3

REGISTRY  := ghcr.io/powertech-center
DISTROS   := alpine debian ubuntu
TEMPLATES := tools dev clang go rust csharp nodejs mobile cross-clang cross-go cross-rust cross-csharp

# Optional cleanup filter: keep images listed by full tag, one per line.
# A missing file keeps no images; this filter does not protect builder cache.
KEEP_IMAGES_FILE ?= /etc/powertech/docker-keep-images.txt

# ===========================================================================
# 1. Base targets: <do>-<distro>/<template> — actual recipes
# ===========================================================================

# --- setup ---

setup:
	@$(PYTHON) -c "import jinja2" 2>/dev/null || { \
		if command -v apk >/dev/null 2>&1; then \
			apk add --no-cache py3-jinja2; \
		elif command -v apt-get >/dev/null 2>&1; then \
			apt-get install -y python3-jinja2; \
		else \
			$(PYTHON) -m pip install -r shared/requirements.txt; \
		fi; \
	}

# --- build-<distro>/<template> ---

# Args: 1=distro, 2=template, 3=build dependency
define rule_build
build-$(1)/$(2): $(3)
	@echo "Building $(REGISTRY)/$(1)/$(2):latest..."
	@$(PYTHON) shared/configure.py $(1) $(2)
	docker build -t $(REGISTRY)/$(1)/$(2):latest -f .cache/$(1)/$(2) .
	@$(PYTHON) shared/check-image.py $(1) $(2)
endef

define rule_build_deps
$(eval $(call rule_build,$(1),tools,setup))
$(eval $(call rule_build,$(1),dev,build-$(1)/tools))
$(eval $(call rule_build,$(1),clang,build-$(1)/dev))
$(eval $(call rule_build,$(1),go,build-$(1)/dev))
$(eval $(call rule_build,$(1),rust,build-$(1)/dev))
$(eval $(call rule_build,$(1),cross-clang,build-$(1)/clang))
$(eval $(call rule_build,$(1),cross-go,build-$(1)/cross-clang))
$(eval $(call rule_build,$(1),csharp,build-$(1)/dev))
$(eval $(call rule_build,$(1),nodejs,build-$(1)/dev))
$(eval $(call rule_build,$(1),mobile,build-$(1)/nodejs))
$(eval $(call rule_build,$(1),cross-rust,build-$(1)/cross-clang))
$(eval $(call rule_build,$(1),cross-csharp,build-$(1)/cross-clang))
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

# --- clean-<distro>: remove distro images, then builder cache ---
# Rebuilding a kept tag can leave its previous version referenced by digest.

define rule_clean
clean-$(1):
	@status=0; \
	for template in $(TEMPLATES); do \
		image="$(REGISTRY)/$(1)/$$$$template:latest"; \
		if [ -f "$(KEEP_IMAGES_FILE)" ] && grep -Fxq -- "$$$$image" "$(KEEP_IMAGES_FILE)"; then \
			printf '\033[33mWARNING: Keeping %s (listed in %s)\033[0m\n' "$$$$image" "$(KEEP_IMAGES_FILE)"; \
		elif docker image inspect "$$$$image" >/dev/null 2>&1; then \
			echo "Removing $$$$image..."; \
			docker rmi "$$$$image" || status=1; \
		fi; \
	done; \
	images=$$$$(docker image ls --all --digests --format '{{if eq .Tag "<none>"}}{{.Repository}}@{{.Digest}}{{end}}') || status=1; \
	for image in $$$$images; do \
		case "$$$$image" in \
			$(REGISTRY)/$(1)/*@sha256:*) \
				echo "Removing obsolete $$$$image..."; \
				docker rmi "$$$$image" || status=1 ;; \
		esac; \
	done; \
	docker builder prune --all --force || status=1; \
	exit $$$$status
endef

$(foreach d,$(DISTROS),$(eval $(call rule_clean,$(d))))

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
# 3. Aggregate targets
# ===========================================================================

# --- <do>: all distros, all templates ---
build: $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),build-$(d)/$(t)))
test:  $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),test-$(d)/$(t)))
push:  $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),push-$(d)/$(t)))
clean: $(foreach d,$(DISTROS),clean-$(d))
# Distro cleanups share one builder cache; avoid concurrent prune operations.
# Make 4.3 treats .NOTPARALLEL as global, even with target prerequisites.
ifneq ($(filter clean clean-%,$(MAKECMDGOALS)),)
.NOTPARALLEL:
endif

# --- <do>-<distro>: all templates for one distro ---
$(foreach d,$(DISTROS),$(eval build-$(d): $(foreach t,$(TEMPLATES),build-$(d)/$(t))))
$(foreach d,$(DISTROS),$(eval test-$(d):  $(foreach t,$(TEMPLATES),test-$(d)/$(t))))
$(foreach d,$(DISTROS),$(eval push-$(d):  $(foreach t,$(TEMPLATES),push-$(d)/$(t))))

# --- <do>-<template>: all distros for one template ---
$(foreach t,$(TEMPLATES),$(eval build-$(t): $(foreach d,$(DISTROS),build-$(d)/$(t))))
$(foreach t,$(TEMPLATES),$(eval test-$(t):  $(foreach d,$(DISTROS),test-$(d)/$(t))))
$(foreach t,$(TEMPLATES),$(eval push-$(t):  $(foreach d,$(DISTROS),push-$(d)/$(t))))

# --- <template>: all distros, full cycle (build → test → push) ---
$(foreach t,$(TEMPLATES),$(eval $(t): $(foreach d,$(DISTROS),$(d)/$(t))))

# --- all ---
all: $(TEMPLATES)

# ===========================================================================
# 4. Internal CI/CD release targets
# ===========================================================================

# Sequential recursion preserves the parent's jobserver (-j), never multiply -j.
release:
	$(MAKE) release-alpine
	$(MAKE) release-debian
	$(MAKE) release-ubuntu

define rule_release
release-$(1):
	+$$(MAKE) build-$(1)
	+$$(MAKE) test-$(1)
	+$$(MAKE) push-$(1)
	+$$(MAKE) clean-$(1)
endef
$(foreach d,$(DISTROS),$(eval $(call rule_release,$(d))))

# ===========================================================================
# .PHONY
# ===========================================================================

.PHONY: all setup build test push clean \
        $(DISTROS) $(TEMPLATES) \
        $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),$(d)/$(t))) \
        $(foreach d,$(DISTROS),$(foreach t,$(TEMPLATES),build-$(d)/$(t) test-$(d)/$(t) push-$(d)/$(t))) \
        $(foreach d,$(DISTROS),build-$(d) test-$(d) push-$(d) clean-$(d)) \
        $(foreach t,$(TEMPLATES),build-$(t) test-$(t) push-$(t))

.PHONY: release $(foreach d,$(DISTROS),release-$(d))
