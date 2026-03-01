# PowerTech Docker Images

Hierarchical Docker images for cross-platform development. Based on Alpine Linux with musl.
All images are published to `ghcr.io/powertech-center/`.

## Image Hierarchy

```
alpine:3.19
  └── alpine-tools              base utilities
        └── alpine-dev          build tools & scripting
              └── alpine-crossplatform  Zig, macOS SDK, Windows MSVC SDK
                    ├── alpine-clang    LLVM/Clang toolchain
                    ├── alpine-go       Go toolchain
                    └── alpine-rust     Rust toolchain
```

## Images

### alpine-tools

Base image with common utilities. Changes rarely.

```
ghcr.io/powertech-center/alpine-tools:latest
```

Includes: bash, git, wget, curl, tar, xz, zip, unzip, p7zip, jq, grep, sed, nano, openssh-client, ca-certificates.

### alpine-dev

Native development tools and scripting environments.

```
ghcr.io/powertech-center/alpine-dev:latest
```

Adds: make, cmake, ninja, gcc, g++, musl-dev, pkgconf, python3, pip, PowerShell (pwsh).

### alpine-crossplatform

Cross-compilation for 3 OS (Linux, macOS, Windows) × 2 architectures (x64, ARM64).

```
ghcr.io/powertech-center/alpine-crossplatform:latest
```

Adds: Zig, clang, macOS SDK, Windows MSVC SDK (xwin), clang-cl, zig-cc wrapper scripts.

**Zig cross-compiler** (via zig-cc wrappers):

| Target | Wrapper |
|--------|---------|
| Linux x64 | `zig-cc-x86_64-linux-musl` |
| Linux ARM64 | `zig-cc-aarch64-linux-musl` |
| macOS x64 | `zig-cc-x86_64-macos` |
| macOS ARM64 | `zig-cc-aarch64-macos` |
| Windows x64 (GNU) | `zig-cc-x86_64-windows-gnu` |
| Windows ARM64 (GNU) | `zig-cc-aarch64-windows-gnu` |

**Windows MSVC** (via xwin + clang-cl):

| Component | Path |
|-----------|------|
| Windows SDK & CRT | `/xwin` |
| MSVC-compatible compiler | `clang-cl` |
| Environment variable | `XWIN_CACHE_DIR=/xwin` |

### alpine-clang

LLVM/Clang development environment.

```
ghcr.io/powertech-center/alpine-clang:latest
```

Adds: clang-dev, lld, llvm-dev, llvm-static, compiler-rt (clang inherited from alpine-crossplatform).

### alpine-go

Go development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine-go:latest
```

Adds: Go toolchain. Use zig-cc wrappers as `CC` for CGo cross-compilation.

Example (CGo cross-compilation for macOS ARM64):

```bash
CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 CC=zig-cc-aarch64-macos go build ./cmd/myapp
```

### alpine-rust

Rust development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine-rust:latest
```

Adds: Rust (via rustup), cargo-zigbuild, cargo-audit, rustfmt, clippy, llvm-lib (MSVC archiver).
Targets: linux-musl (x64, arm64), windows-msvc (x64, arm64), apple-darwin (x64, arm64).

Linux/macOS targets use `cargo zigbuild`, Windows MSVC targets use inherited xwin + clang-cl.

Example:

```bash
# macOS/Linux via Zig
cargo zigbuild --release --target aarch64-apple-darwin

# Windows MSVC via xwin
cargo build --release --target x86_64-pc-windows-msvc
```

## Building

```bash
# Build all images
make all

# Build a specific image (dependencies are resolved automatically)
make alpine-go

# Push all images to ghcr.io
make push

# Clean local images
make clean
```

## Using in Projects

Inherit from the appropriate language image and add project-specific dependencies:

```dockerfile
FROM ghcr.io/powertech-center/alpine-go:latest

# Project-specific dev libraries
RUN apk add --no-cache alsa-lib-dev libx11-dev gtk+3.0-dev

WORKDIR /workspace
```

## Versions

| Component | Version |
|-----------|---------|
| Alpine | 3.19 |
| Zig | 0.15.2 |
| macOS SDK | 14.5 |
| Go | 1.25.5 |
| PowerShell | 7.5.4 |
| Rust | stable (via rustup) |
| xwin | 0.8.0 |

## License

MIT
