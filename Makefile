# PowerTech Docker Images
# Hierarchical build system for cross-compilation Docker images
#
# Hierarchy:
#   alpine:latest
#     └── alpine-tools          (wget, curl, git, zip, 7z, jq...)
#           └── alpine-dev      (make, cmake, gcc, musl git master, dev user)
#                 └── alpine-cross-platform  (zig-cc wrappers, macOS SDK)
#                       ├── alpine-cross-clang    (LLVM/Clang toolchain)
#                       ├── alpine-cross-go       (Go toolchain)
#                       └── alpine-cross-rust     (Rust + cargo-zigbuild)

REGISTRY := ghcr.io/powertech-center

IMAGES := alpine-tools alpine-dev alpine-cross-platform alpine-cross-clang alpine-cross-go alpine-cross-rust

.PHONY: all clean push $(IMAGES)

all: alpine-cross-clang alpine-cross-go alpine-cross-rust

# === Build targets (with dependency chain) ===

alpine-tools:
	docker build -t $(REGISTRY)/alpine-tools:latest alpine-tools/

alpine-dev: alpine-tools
	docker build -t $(REGISTRY)/alpine-dev:latest alpine-dev/

alpine-cross-platform: alpine-dev
	docker build -t $(REGISTRY)/alpine-cross-platform:latest alpine-cross-platform/

alpine-cross-clang: alpine-cross-platform
	docker build -t $(REGISTRY)/alpine-cross-clang:latest alpine-cross-clang/

alpine-cross-go: alpine-cross-platform
	docker build -t $(REGISTRY)/alpine-cross-go:latest alpine-cross-go/

alpine-cross-rust: alpine-cross-platform
	docker build -t $(REGISTRY)/alpine-cross-rust:latest alpine-cross-rust/

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
