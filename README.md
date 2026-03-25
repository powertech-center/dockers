# PowerTech Docker Images

Hierarchical Docker images for cross-platform development. Based on Alpine Linux with musl.
All images are published to `ghcr.io/powertech-center/`.

## Table of Contents

- [Image Hierarchy](#image-hierarchy)
- [Images](#images)
  - [alpine/tools](#alpinetools)
  - [alpine/dev](#alpinedev)
  - [alpine/clang](#alpineclang)
  - [alpine/csharp](#alpinecsharp)
  - [alpine/go](#alpinego)
  - [alpine/rust](#alpinerust)
  - [alpine/nodejs](#alpinenodejs)
  - [alpine/mobile](#alpinemobile)
  - [alpine/cross-platform](#alpinecross-platform)
  - [alpine/cross-clang](#alpinecross-clang)
  - [alpine/cross-csharp](#alpinecross-csharp)
  - [alpine/cross-go](#alpinecross-go)
  - [alpine/cross-rust](#alpinecross-rust)
- [Using as a WSL Distribution](#using-as-a-wsl-distribution)
- [Building](#building)
- [Using in Projects](#using-in-projects)
- [Versions](#versions)
- [License](#license)

## Image Hierarchy

```
alpine:latest
  └── alpine/tools              base utilities
        └── alpine/dev          build tools & scripting
              ├── alpine/clang      LLVM/Clang (native host)
              ├── alpine/csharp     .NET/C# (native host)
              ├── alpine/go         Go toolchain (native host)
              ├── alpine/rust       Rust toolchain (native host)
              ├── alpine/nodejs     Node.js, TypeScript, JS/TS tooling
              ├── alpine/mobile     Android SDK, Flutter, React Native
              └── alpine/cross-platform  clang cross-compilers, macOS SDK, Windows SDKs
                    ├── alpine/cross-clang    LLVM/Clang toolchain (cross)
                    ├── alpine/cross-csharp   .NET/C# NativeAOT (cross)
                    ├── alpine/cross-go       Go toolchain (cross)
                    └── alpine/cross-rust     Rust toolchain (cross)
```

## Images

### alpine/tools

Base image with common utilities. Changes rarely.

```
ghcr.io/powertech-center/alpine/tools:latest
```

Includes: bash, git, wget, curl, tar, xz, zip, unzip, p7zip, jq, grep, sed, nano, openssh-client, ca-certificates.

### alpine/dev

Native development tools and scripting environments.

```
ghcr.io/powertech-center/alpine/dev:latest
```

Adds: make, cmake, ninja, gcc, g++, musl-dev, pkgconf, python3, pip, pwsh, musl from git master (provides `posix_getdents` for Claude Code), [crossler](https://github.com/powertech-center/crossler), user `dev`.

### alpine/clang

Native LLVM/Clang development environment (host compilation only).

```
ghcr.io/powertech-center/alpine/clang:latest
```

Adds: clang, clang-dev, lld, llvm-dev, llvm-static, compiler-rt.

### alpine/csharp

Native .NET/C# development environment with NativeAOT support (host compilation only).

```
ghcr.io/powertech-center/alpine/csharp:latest
```

Adds: .NET 9 SDK, zlib-dev (NativeAOT dependency), dev tools (csharpier, dotnet-outdated, reportgenerator), pre-cached ILC runtime for `linux-musl-x64`.

NativeAOT compiles C# to native ELF binaries on the host — no package download needed on first build:

```bash
dotnet publish -r linux-musl-x64 -p:PublishAot=true
```

### alpine/go

Native Go development environment (host compilation only).

```
ghcr.io/powertech-center/alpine/go:latest
```

Adds: Go toolchain (latest stable). `CGO_ENABLED=1` works out of the box via the gcc inherited from alpine/dev.

### alpine/rust

Native Rust development environment (host compilation only).

```
ghcr.io/powertech-center/alpine/rust:latest
```

Adds: Rust (via rustup, stable), rustfmt, clippy, cargo-audit.

### alpine/nodejs

Universal JavaScript/TypeScript development environment. Suitable for CI/CD and as a VS Code Dev Container.

```
ghcr.io/powertech-center/alpine/nodejs:latest
```

Adds: Node.js LTS, npm, yarn, pnpm, TypeScript, ts-node, ESLint, Prettier.

Native npm modules (node-gyp) compile out of the box — gcc, g++, make, python3 are inherited from alpine/dev.

```bash
# TypeScript project
cd /workspace/my-project
npm install
npx tsc --build
npm test

# Run .ts files directly
ts-node src/index.ts

# Lint & format
eslint src/
prettier --write src/
```

### alpine/mobile

Universal mobile development environment for Android, Flutter, and React Native.

```
ghcr.io/powertech-center/alpine/mobile:latest
```

Adds: gcompat (glibc shim), OpenJDK (latest LTS), Android SDK (cmdline-tools, build-tools, platform-tools, platforms, NDK), Gradle, Node.js LTS, npm, yarn, pnpm, Flutter SDK, Dart SDK.

Suitable for CI/CD Android builds and as a VS Code Dev Container for mobile development.

**Android builds** — Gradle-based projects build out of the box:

```bash
# Inside the container
cd /workspace/my-android-app
./gradlew assembleRelease
```

**Flutter** — Android and web targets:

```bash
flutter create my_app && cd my_app
flutter build apk
flutter build web
```

**React Native** — Android builds via Gradle:

```bash
cd /workspace/my-rn-app
npm install
npx react-native build-android --mode=release
```

**iOS note**: Full iOS development requires macOS (Xcode). For limited SwiftPM-based iOS cross-compilation from Linux, see [xtool](https://github.com/xtool-org/xtool).

**Environment variables**:

| Variable | Value |
|----------|-------|
| `JAVA_HOME` | `/usr/lib/jvm/java-openjdk` (symlink to latest LTS) |
| `ANDROID_HOME` | `/opt/android-sdk` |
| `GRADLE_HOME` | `/opt/gradle` |
| `FLUTTER_HOME` | `/opt/flutter` |

### alpine/cross-platform

Cross-compilation infrastructure for 10 targets (Linux musl + glibc, macOS, Windows MSVC + GNU, each x64/arm64).

```
ghcr.io/powertech-center/alpine/cross-platform:latest
```

Adds: clang, lld, aarch64 musl sysroot, glibc sysroots (x64/arm64), libc++ (static), compiler-rt, macOS SDK, Windows MSVC SDK (xwin), Windows GNU sysroot (llvm-mingw), smart compiler/linker wrapper scripts.

**Smart wrappers** — compiler wrappers auto-detect compile vs link mode:
- In compile-only mode (`-c`, `-S`, `-E`): pass args directly to clang
- In link mode: auto-inject `-fuse-ld=lld` for the correct linker
- No `CGO_LDFLAGS` or manual linker configuration needed in Makefiles

**Clang cross-compilers** — C/C++ wrappers for all targets:

| Target | C wrapper | C++ wrapper | Linker |
|--------|-----------|-------------|--------|
| Linux x64 (musl) | `clang-x86_64-linux-musl` | `clang++-x86_64-linux-musl` | `lld-x86_64-linux-musl` |
| Linux arm64 (musl) | `clang-aarch64-linux-musl` | `clang++-aarch64-linux-musl` | `lld-aarch64-linux-musl` |
| Linux x64 (glibc) | `clang-x86_64-linux-gnu` | `clang++-x86_64-linux-gnu` | `lld-x86_64-linux-gnu` |
| Linux arm64 (glibc) | `clang-aarch64-linux-gnu` | `clang++-aarch64-linux-gnu` | `lld-aarch64-linux-gnu` |
| macOS x64 | `clang-x86_64-apple-darwin` | `clang++-x86_64-apple-darwin` | `lld-x86_64-apple-darwin` |
| macOS arm64 | `clang-aarch64-apple-darwin` | `clang++-aarch64-apple-darwin` | `lld-aarch64-apple-darwin` |
| Windows x64 MSVC | `clang-x86_64-windows-msvc` | `clang++-x86_64-windows-msvc` | `lld-x86_64-windows-msvc` |
| Windows arm64 MSVC | `clang-aarch64-windows-msvc` | `clang++-aarch64-windows-msvc` | `lld-aarch64-windows-msvc` |
| Windows x64 GNU | `clang-x86_64-windows-gnu` | `clang++-x86_64-windows-gnu` | `lld-x86_64-windows-gnu` |
| Windows arm64 GNU | `clang-aarch64-windows-gnu` | `clang++-aarch64-windows-gnu` | `lld-aarch64-windows-gnu` |

| Component | Path |
|-----------|------|
| Windows MSVC SDK & CRT (xwin) | `/usr/windows-msvc` |
| Windows GNU sysroot (llvm-mingw) | `/usr/windows-gnu` |
| macOS SDK | `/usr/macosx.sdk` |
| aarch64 musl sysroot | `/usr/aarch64-alpine-linux-musl` |
| x86_64 glibc sysroot | `/usr/x86_64-linux-gnu` |
| aarch64 glibc sysroot | `/usr/aarch64-linux-gnu` |
| macOS SDK env var | `SDKROOT=/usr/macosx.sdk` |

### alpine/cross-clang

LLVM/Clang development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine/cross-clang:latest
```

Inherits all 10-target cross-compilation infrastructure from alpine/cross-platform. Adds LLVM/Clang development libraries for C/C++ work:

- `clang-dev` — libclang headers and libraries (for tools using libclang API)
- `llvm-dev` — LLVM headers and libraries (for custom passes, LLVM-based tools)
- `llvm-static` — static LLVM libraries
- `compiler-rt` — runtime library (builtins, sanitizers, profiling)

Use this image when developing C/C++ projects that need cross-compilation or when building LLVM-based tools.

### alpine/cross-csharp

.NET/C# development and NativeAOT cross-compilation environment.

```
ghcr.io/powertech-center/alpine/cross-csharp:latest
```

Adds: .NET 9 SDK, zlib-dev, dev tools (csharpier, dotnet-outdated, reportgenerator), pre-cached ILC runtimes for all 8 NativeAOT targets.

NativeAOT cross-compiles C# to native binaries for 8 targets: Linux, macOS, and Windows — no package download needed on first build. Standard `dotnet publish` (managed IL) works for all RIDs.

```bash
# Linux (CppCompilerAndLinker + SysRoot)
dotnet publish -r linux-musl-arm64 -p:PublishAot=true \
  -p:CppCompilerAndLinker=clang-aarch64-linux-musl \
  -p:SysRoot=/usr/aarch64-alpine-linux-musl \
  -p:LinkerFlavor=lld -p:ObjCopyName=llvm-objcopy

# macOS (CppCompilerAndLinker + SysRoot + DisableUnsupportedError)
dotnet publish -r osx-arm64 -p:PublishAot=true \
  -p:DisableUnsupportedError=true \
  -p:CppCompilerAndLinker=clang-aarch64-apple-darwin \
  -p:SysRoot=/usr/macosx.sdk \
  -p:StripSymbols=false -p:ObjCopyName=llvm-objcopy

# Windows (CppLinker = lld-link wrapper, MSVC-style linking)
dotnet publish -r win-x64 -p:PublishAot=true \
  -p:DisableUnsupportedError=true \
  -p:CppLinker=lld-x86_64-windows-msvc \
  -p:IlcUseEnvironmentalTools=true \
  -p:StripSymbols=false -p:EnableSourceLink=false
```

| NativeAOT Target | RID | Compiler/Linker | SysRoot |
|------------------|-----|-----------------|---------|
| Linux x64 (musl) | `linux-musl-x64` | `clang-x86_64-linux-musl` | `/` |
| Linux arm64 (musl) | `linux-musl-arm64` | `clang-aarch64-linux-musl` | `/usr/aarch64-alpine-linux-musl` |
| Linux x64 (glibc) | `linux-x64` | `clang-x86_64-linux-gnu` | `/usr/x86_64-linux-gnu` |
| Linux arm64 (glibc) | `linux-arm64` | `clang-aarch64-linux-gnu` | `/usr/aarch64-linux-gnu` |
| macOS x64 | `osx-x64` | `clang-x86_64-apple-darwin` | `/usr/macosx.sdk` |
| macOS arm64 | `osx-arm64` | `clang-aarch64-apple-darwin` | `/usr/macosx.sdk` |
| Windows x64 | `win-x64` | `lld-x86_64-windows-msvc` | (built into wrapper) |
| Windows arm64 | `win-arm64` | `lld-aarch64-windows-msvc` | (built into wrapper) |

**Notes**:
- Always pass `-p:LinkerFlavor=lld` for cross-architecture Linux builds. NativeAOT defaults to `-fuse-ld=bfd` which only supports x86_64.
- macOS and Windows targets require `-p:DisableUnsupportedError=true` (cross-OS NativeAOT is blocked by MSBuild policy, not by technical limitations — ILC generates COFF/Mach-O natively via LLVM).
- Windows targets use `CppLinker` (not `CppCompilerAndLinker`) because NativeAOT's Windows.targets passes MSVC-style flags (`/OUT:`, `/SUBSYSTEM:`) directly to the linker.

### alpine/cross-go

Go development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine/cross-go:latest
```

Adds: Go toolchain (latest stable). 6 CGO targets (Linux musl, macOS, Windows GNU). Smart wrappers handle everything — just set `CC`:

```bash
# Linux
GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-linux-musl go build ./...
GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-linux-musl go build ./...

# macOS
GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-apple-darwin go build ./...
GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-apple-darwin go build ./...

# Windows (GNU mode — native MinGW sysroot from llvm-mingw)
GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-windows-gnu go build ./...
GOOS=windows GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-windows-gnu go build ./...
```

### alpine/cross-rust

Rust development and cross-compilation environment.

```
ghcr.io/powertech-center/alpine/cross-rust:latest
```

Adds: Rust (via rustup, stable), rustfmt, clippy, cargo-audit, llvm-lib (MSVC archiver).
8 cargo targets: linux-musl (x64, arm64), linux-gnu (x64, arm64), apple-darwin (x64, arm64), windows-msvc (x64, arm64).

All targets use `cargo build` directly — CC/CXX/linker configured via ENV variables.

```bash
# All targets via cargo build
cargo build --release --target x86_64-unknown-linux-musl
cargo build --release --target aarch64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-gnu
cargo build --release --target aarch64-unknown-linux-gnu
cargo build --release --target x86_64-apple-darwin
cargo build --release --target aarch64-apple-darwin
cargo build --release --target x86_64-pc-windows-msvc
cargo build --release --target aarch64-pc-windows-msvc
```

## Using as a WSL Distribution

Any published image can be imported into WSL as a full Linux distribution — useful if you want a ready-made development environment on Windows without running Docker containers.

### Why

- Persistent environment with full filesystem access (unlike ephemeral containers)
- Native performance (no Docker overhead)
- Seamless integration with Windows: access host files via `/mnt/c/`, call Windows executables, use VS Code Remote-WSL

### Step 1 — Export the image as a tar archive

Install [Docker Desktop](https://www.docker.com/products/docker-desktop/) and run in PowerShell:

```powershell
$IMG = "ghcr.io/powertech-center/alpine/dev:latest"; $CID = docker create $IMG; docker export $CID -o dev.tar; docker rm $CID; docker rmi $IMG
```

### Step 2 — Import into WSL

```powershell
wsl --import AlpineDev C:\WSL\AlpineDev dev.tar
```

This creates a WSL distribution named `AlpineDev` with its virtual disk stored in `C:\WSL\AlpineDev`.

### Step 3 — Launch

```powershell
# Start an interactive shell
wsl -d AlpineDev

# Or make it your default distribution
wsl --set-default AlpineDev
```

## Building

```bash
# Build all images (native + cross)
make all

# Build a specific image (dependencies are resolved automatically)
make build-alpine/go
make build-alpine/cross-go

# Run tests for all images
make test

# Run tests for a specific image
make test-alpine/cross-platform

# Push all images to ghcr.io
make push

# Clean local images
make clean
```

## Using in Projects

Inherit from the appropriate language image and add project-specific dependencies:

```dockerfile
FROM ghcr.io/powertech-center/alpine/cross-go:latest

# Project-specific dev libraries
RUN apk add --no-cache alsa-lib-dev libx11-dev gtk+3.0-dev

WORKDIR /workspace
```

## Versions

| Component | Version | How |
|-----------|---------|-----|
| Alpine | latest | `alpine:latest` |
| macOS SDK | latest stable | auto via GitHub API |
| xwin | latest stable | auto via GitHub API |
| llvm-mingw | latest stable | auto via GitHub API |
| LLVM source | latest stable | auto via GitHub API (for compiler-rt, libc++) |
| PowerShell | latest stable | auto via GitHub API |
| .NET | 9.0 | via `apk` (Alpine packages) |
| Go | latest stable | auto via `go.dev/VERSION` |
| Rust | latest stable | auto via rustup |
| Node.js | latest LTS | via `apk` (Alpine packages) |
| TypeScript | latest stable | via `npm install -g` |
| OpenJDK | latest compatible LTS | auto via `apk` + Gradle compatibility check |
| Android SDK | latest | auto via `sdkmanager` |
| Flutter | latest stable | auto via Google API |
| Gradle | latest stable | auto via Gradle API |
| glibc sysroots | 2.28 | Anaconda conda-forge |
| LLVM/Clang | latest | via `apk` (Alpine packages) |

## License

MIT
