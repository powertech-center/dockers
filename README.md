# PowerTech Docker Images

Hierarchical Docker images for cross-platform development. Based on Alpine Linux with musl.
All images are published to `ghcr.io/powertech-center/`.

## Image Hierarchy

```
alpine:latest
  └── alpine-tools              base utilities
        └── alpine-dev          build tools & scripting
              ├── alpine-clang      LLVM/Clang (native host)
              ├── alpine-go         Go toolchain (native host)
              ├── alpine-rust       Rust toolchain (native host)
              └── alpine-cross-platform  clang cross-compilers, macOS SDK, Windows SDK
                    ├── alpine-cross-clang    LLVM/Clang toolchain (cross)
                    ├── alpine-cross-go       Go toolchain (cross)
                    └── alpine-cross-rust     Rust toolchain (cross)
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

Adds: make, cmake, ninja, gcc, g++, musl-dev, pkgconf, python3, pip, pwsh, musl from git master (provides `posix_getdents` for Claude Code), [crossler](https://github.com/powertech-center/crossler), user `dev`.

### alpine-clang

Native LLVM/Clang development environment (host compilation only).

```
ghcr.io/powertech-center/alpine-clang:latest
```

Adds: clang, clang-dev, lld, llvm-dev, llvm-static, compiler-rt.

### alpine-go

Native Go development environment (host compilation only).

```
ghcr.io/powertech-center/alpine-go:latest
```

Adds: Go toolchain (latest stable). `CGO_ENABLED=1` works out of the box via the gcc inherited from alpine-dev.

### alpine-rust

Native Rust development environment (host compilation only).

```
ghcr.io/powertech-center/alpine-rust:latest
```

Adds: Rust (via rustup, stable), rustfmt, clippy, cargo-audit.

### alpine-cross-platform

Cross-compilation infrastructure for 3 OS × 2 architectures, with 2 Windows toolchains (8 targets total).

```
ghcr.io/powertech-center/alpine-cross-platform:latest
```

Adds: clang, lld, aarch64 musl sysroot, macOS SDK, Windows SDK (xwin), smart compiler/linker wrapper scripts.

**Smart wrappers** — compiler wrappers auto-detect compile vs link mode:
- In compile-only mode (`-c`, `-S`, `-E`): pass args directly to clang
- In link mode: auto-inject `-fuse-ld=lld` for the correct linker
- No `CGO_LDFLAGS` or manual linker configuration needed in Makefiles

**Clang cross-compilers** — C/C++ wrappers for all targets:

| Target | C wrapper | C++ wrapper | Linker |
|--------|-----------|-------------|--------|
| Linux x64 | `clang-x86_64-linux-musl` | `clang++-x86_64-linux-musl` | `lld-x86_64-linux-musl` |
| Linux ARM64 | `clang-aarch64-linux-musl` | `clang++-aarch64-linux-musl` | `lld-aarch64-linux-musl` |
| macOS x64 | `clang-x86_64-apple-darwin` | `clang++-x86_64-apple-darwin` | `lld-x86_64-apple-darwin` |
| macOS ARM64 | `clang-aarch64-apple-darwin` | `clang++-aarch64-apple-darwin` | `lld-aarch64-apple-darwin` |
| Windows x64 MSVC | `clang-x86_64-windows-msvc` | `clang++-x86_64-windows-msvc` | `lld-link-x86_64-windows-msvc` |
| Windows ARM64 MSVC | `clang-aarch64-windows-msvc` | `clang++-aarch64-windows-msvc` | `lld-link-aarch64-windows-msvc` |
| Windows x64 GNU | `clang-x86_64-windows-gnu` | `clang++-x86_64-windows-gnu` | `lld-x86_64-windows-gnu` |
| Windows ARM64 GNU | `clang-aarch64-windows-gnu` | `clang++-aarch64-windows-gnu` | `lld-aarch64-windows-gnu` |

**Windows MSVC** (`clang-*-windows-msvc`): clang in MSVC-compatible mode (`--driver-mode=cl`). Uses xwin SDK/CRT includes (`/imsvc`). For Rust cross-compilation.

**Windows GNU** (`clang-*-windows-gnu`): clang in GCC-compatible mode (standard `-I`, `-D` flags), MSVC target and xwin sysroot (`-isystem`). No MinGW headers or runtime — links against system UCRT. For Go CGO cross-compilation.

| Component | Path |
|-----------|------|
| Windows SDK & CRT | `/xwin` |
| macOS SDK | `/opt/MacOSX14.5.sdk` |
| aarch64 musl sysroot | `/usr/aarch64-alpine-linux-musl` |
| macOS SDK env var | `SDKROOT=/opt/MacOSX14.5.sdk` |
| xwin env var | `XWIN_CACHE_DIR=/xwin` |

### alpine-cross-clang

LLVM/Clang development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine-cross-clang:latest
```

Inherits all 8-target cross-compilation infrastructure from alpine-cross-platform. Adds LLVM/Clang development libraries for C/C++ work:

- `clang-dev` — libclang headers and libraries (for tools using libclang API)
- `llvm-dev` — LLVM headers and libraries (for custom passes, LLVM-based tools)
- `llvm-static` — static LLVM libraries
- `compiler-rt` — runtime library (builtins, sanitizers, profiling)

Use this image when developing C/C++ projects that need cross-compilation or when building LLVM-based tools.

### alpine-cross-go

Go development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine-cross-go:latest
```

Adds: Go toolchain (latest stable). Smart wrappers handle everything — just set `CC`:

```bash
# Linux
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-linux-musl go build ./...
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-linux-musl go build ./...

# macOS
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-apple-darwin go build ./...
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-apple-darwin go build ./...

# Windows (GNU mode — GCC-compatible driver, no MinGW DLLs)
GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-windows-gnu go build ./...
GOOS=windows GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-windows-gnu go build ./...
```

### alpine-cross-rust

Rust development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine-cross-rust:latest
```

Adds: Rust (via rustup, stable), rustfmt, clippy, cargo-audit, llvm-lib (MSVC archiver).
Targets: linux-musl (x64, arm64), windows-msvc (x64, arm64), apple-darwin (x64, arm64).

All targets use `cargo build` directly — CC/CXX/linker configured via ENV variables.

```bash
# All targets via cargo build
cargo build --release --target x86_64-unknown-linux-musl
cargo build --release --target aarch64-unknown-linux-musl
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-pc-windows-msvc
cargo build --release --target aarch64-pc-windows-msvc
```

## Building

```bash
# Build all images (native + cross)
make all

# Build a specific image (dependencies are resolved automatically)
make alpine-go
make alpine-cross-go

# Push all images to ghcr.io
make push

# Clean local images
make clean
```

## Using in Projects

Inherit from the appropriate language image and add project-specific dependencies:

```dockerfile
FROM ghcr.io/powertech-center/alpine-cross-go:latest

# Project-specific dev libraries
RUN apk add --no-cache alsa-lib-dev libx11-dev gtk+3.0-dev

WORKDIR /workspace
```

## Versions

| Component | Version | How |
|-----------|---------|-----|
| Alpine | latest | `alpine:latest` |
| macOS SDK | 14.5 | fixed (`ARG MACOSX_SDK_VERSION`) |
| xwin | 0.8.0 | fixed (`ARG XWIN_VERSION`) |
| PowerShell | latest stable | auto via GitHub API |
| Go | latest stable | auto via `go.dev/VERSION` |
| Rust | latest stable | auto via rustup |
| LLVM/Clang | latest | via `apk` (Alpine packages) |

## License

MIT
