# PowerTech Docker Images
# Hierarchical build system for cross-compilation Docker images
#
# Hierarchy:
#   alpine:3.19
#     └── alpine-tools          (wget, curl, git, zip, 7z, jq...)
#           └── alpine-dev      (make, cmake, gcc, Zig)
#                 └── alpine-crossplatform  (zig-cc wrappers, macOS SDK)
#                       ├── alpine-clang    (LLVM/Clang toolchain)
#                       ├── alpine-go       (Go toolchain)
#                       └── alpine-rust     (Rust + cargo-zigbuild)

REGISTRY := ghcr.io/powertech-center

IMAGES := alpine-tools alpine-dev alpine-crossplatform alpine-clang alpine-go alpine-rust

.PHONY: all clean push $(IMAGES)

all: alpine-clang alpine-go alpine-rust

# === Build targets (with dependency chain) ===

alpine-tools:
	docker build -t $(REGISTRY)/alpine-tools:latest alpine-tools/

alpine-dev: alpine-tools
	docker build -t $(REGISTRY)/alpine-dev:latest alpine-dev/

alpine-crossplatform: alpine-dev
	docker build -t $(REGISTRY)/alpine-crossplatform:latest alpine-crossplatform/

alpine-clang: alpine-crossplatform
	docker build -t $(REGISTRY)/alpine-clang:latest alpine-clang/

alpine-go: alpine-crossplatform
	docker build -t $(REGISTRY)/alpine-go:latest alpine-go/

alpine-rust: alpine-crossplatform
	docker build -t $(REGISTRY)/alpine-rust:latest alpine-rust/

# === Push all images to registry ===

push:
	@for img in $(IMAGES); do \
		echo "Pushing $(REGISTRY)/$$img:latest..."; \
		docker push $(REGISTRY)/$$img:latest; \
	done

# === Clean local images ===

clean:
	@for img in $(IMAGES); do \
		docker rmi $(REGISTRY)/$$img:latest 2>/dev/null || true; \
	done
