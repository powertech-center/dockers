# PowerTech Docker Images

Hierarchical Docker images for cross-platform development and compilation.
Available for **Alpine**, **Debian**, and **Ubuntu** — each image exists in all three distros with the same toolset and conventions.

Images form an inheritance hierarchy: each layer adds its own tools on top of the parent. This lets you pick exactly the level you need — from a minimal utilities image to a full cross-compilation environment targeting 10 platforms.

All images are published to `ghcr.io/powertech-center/`.

## Table of Contents

- [Image Hierarchy](#image-hierarchy)
- [Images](#images)
- [Using as a WSL Distribution](#using-as-a-wsl-distribution)
- [Building, Testing, Publishing](#building-testing-publishing)
- [Using in Projects](#using-in-projects)
- [Versions](#versions)
- [License](#license)

## Image Hierarchy

| Name | Alpine | Debian | Ubuntu | Description |
|------|--------|--------|--------|-------------|
| [tools](#tools) | 38 MB | 201 MB | 170 MB | Base utilities: bash, git, wget, curl, jq, tar, zip, 7z |
| &ensp;&ensp;[dev](#dev) | 754 MB | 1.2 GB | 1.1 GB | Build tools: make, cmake, gcc, python3, pwsh |
| &ensp;&ensp;&ensp;&ensp;[clang](#clang) | 1.4 GB | 1.8 GB | 1.7 GB | LLVM/Clang native toolchain |
| &ensp;&ensp;&ensp;&ensp;&ensp;&ensp;[cross-clang](#cross-clang) | 6.2 GB | 6.7 GB | 6.5 GB | Cross-compilation: 10 targets, SDKs, sysroots |
| &ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;[cross-csharp](#cross-csharp) | 10.5 GB | 10.9 GB | 10.8 GB | .NET NativeAOT cross-compilation (8 targets) |
| &ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;[cross-go](#cross-go) | 8.1 GB | 8.6 GB | 8.4 GB | Go CGO cross-compilation (6 targets) |
| &ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;&ensp;[cross-rust](#cross-rust) | 9.6 GB | 9.4 GB | 9.3 GB | Rust cross-compilation (8 targets) |
| &ensp;&ensp;&ensp;&ensp;[csharp](#csharp) | 2.0 GB | 2.5 GB | 2.4 GB | .NET SDK, NativeAOT (native host) |
| &ensp;&ensp;&ensp;&ensp;[go](#go) | 2.6 GB | 3.1 GB | 3.0 GB | Go toolchain (native host) |
| &ensp;&ensp;&ensp;&ensp;[rust](#rust) | 2.5 GB | 2.8 GB | 2.7 GB | Rust toolchain (native host) |
| &ensp;&ensp;&ensp;&ensp;[nodejs](#nodejs) | 949 MB | 1.6 GB | 1.5 GB | Node.js LTS, TypeScript, npm, yarn, pnpm |
| &ensp;&ensp;&ensp;&ensp;&ensp;&ensp;[mobile](#mobile) | 7.2 GB | 8.1 GB | 8.0 GB | Android SDK, Flutter, React Native |

## Images

Replace `<distro>` with `alpine`, `debian`, or `ubuntu`:

```
ghcr.io/powertech-center/alpine/dev:latest
ghcr.io/powertech-center/debian/dev:latest
ghcr.io/powertech-center/ubuntu/dev:latest
```

### tools

Base image with common utilities. Changes rarely.

```
ghcr.io/powertech-center/<distro>/tools:latest
```

Includes: bash, git, wget, curl, tar, xz, zip, unzip, p7zip, jq, grep, sed, nano, openssh-client, ca-certificates.

### dev

Native development tools and scripting environments. Inherits from [tools](#tools).

```
ghcr.io/powertech-center/<distro>/dev:latest
```

Adds: make, cmake, ninja, gcc, g++, pkgconf, python3, pip, pwsh, [crossler](https://github.com/powertech-center/crossler), user `dev`.

Alpine-specific: builds musl from git master (provides `posix_getdents` for Claude Code).

### clang

Native LLVM/Clang development environment (host compilation only). Inherits from [dev](#dev).

```
ghcr.io/powertech-center/<distro>/clang:latest
```

Adds: clang, lld, llvm-dev, llvm-static, compiler-rt.

### csharp

Native .NET/C# development environment with NativeAOT support (host compilation only). Inherits from [dev](#dev).

```
ghcr.io/powertech-center/<distro>/csharp:latest
```

Adds: .NET SDK, zlib-dev (NativeAOT dependency), dev tools (csharpier, dotnet-outdated, reportgenerator), pre-cached ILC runtime for the host platform.

NativeAOT compiles C# to native binaries on the host — no package download needed on first build:

```bash
# Alpine
dotnet publish -r linux-musl-x64 -p:PublishAot=true

# Debian / Ubuntu
dotnet publish -r linux-x64 -p:PublishAot=true
```

### go

Native Go development environment (host compilation only). Inherits from [dev](#dev).

```
ghcr.io/powertech-center/<distro>/go:latest
```

Adds: Go toolchain (latest stable). `CGO_ENABLED=1` works out of the box via gcc inherited from dev.

### rust

Native Rust development environment (host compilation only). Inherits from [dev](#dev).

```
ghcr.io/powertech-center/<distro>/rust:latest
```

Adds: Rust (via rustup, stable), rustfmt, clippy, cargo-audit.

### nodejs

Universal JavaScript/TypeScript development environment. Inherits from [dev](#dev).

```
ghcr.io/powertech-center/<distro>/nodejs:latest
```

Adds: Node.js LTS, npm, yarn, pnpm, TypeScript, ts-node, ESLint, Prettier.

Native npm modules (node-gyp) compile out of the box — gcc, g++, make, python3 are inherited from dev.

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

### mobile

Universal mobile development environment for Android, Flutter, and React Native. Inherits from [nodejs](#nodejs).

```
ghcr.io/powertech-center/<distro>/mobile:latest
```

Adds: gcompat (glibc shim, Alpine only), OpenJDK (latest LTS), Android SDK (cmdline-tools, build-tools, platform-tools, platforms, NDK), Gradle, Flutter SDK, Dart SDK.

Suitable for CI/CD Android builds and as a VS Code Dev Container for mobile development.

**Android builds** — Gradle-based projects build out of the box:

```bash
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

### cross-clang

Cross-compilation environment for 10 targets (Linux musl + glibc, macOS, Windows MSVC + GNU, each x64/arm64).
Inherits LLVM/Clang toolchain from [clang](#clang). Adds SDKs, sysroots, compiler-rt builtins, static libc++ for all cross targets, and smart compiler/linker wrapper scripts.

```
ghcr.io/powertech-center/<distro>/cross-clang:latest
```

**Smart wrappers** — compiler wrappers auto-detect compile vs link mode:
- In compile-only mode (`-c`, `-S`, `-E`): pass args directly to clang
- In link mode: auto-inject `-fuse-ld=lld` for the correct linker
- No `CGO_LDFLAGS` or manual linker configuration needed in Makefiles

**Clang cross-compilers** — C/C++ wrappers for all targets:

| Target | C wrapper | C++ wrapper | Linker wrapper |
|--------|-----------|-------------|----------------|
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
| x86_64 musl sysroot | `/usr/x86_64-linux-musl` (Debian/Ubuntu) or `/` (Alpine native) |
| aarch64 musl sysroot | `/usr/aarch64-linux-musl` |
| x86_64 glibc sysroot | `/usr/x86_64-linux-gnu` |
| aarch64 glibc sysroot | `/usr/aarch64-linux-gnu` |
| macOS SDK env var | `SDKROOT=/usr/macosx.sdk` |

### cross-csharp

.NET/C# development and NativeAOT cross-compilation environment. Inherits from [cross-clang](#cross-clang).

```
ghcr.io/powertech-center/<distro>/cross-csharp:latest
```

Adds: .NET SDK, zlib-dev, dev tools (csharpier, dotnet-outdated, reportgenerator), pre-cached ILC runtimes for all 8 NativeAOT targets.

NativeAOT cross-compiles C# to native binaries for 8 targets: Linux, macOS, and Windows — no package download needed on first build. Standard `dotnet publish` (managed IL) works for all RIDs.

```bash
# Linux (CppCompilerAndLinker + SysRoot)
dotnet publish -r linux-musl-arm64 -p:PublishAot=true \
  -p:CppCompilerAndLinker=clang-aarch64-linux-musl \
  -p:SysRoot=/usr/aarch64-linux-musl \
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
| Linux arm64 (musl) | `linux-musl-arm64` | `clang-aarch64-linux-musl` | `/usr/aarch64-linux-musl` |
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

### cross-go

Go development and cross-compilation environment. Inherits from [cross-clang](#cross-clang).

```
ghcr.io/powertech-center/<distro>/cross-go:latest
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

### cross-rust

Rust development and cross-compilation environment. Inherits from [cross-clang](#cross-clang).

```
ghcr.io/powertech-center/<distro>/cross-rust:latest
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

## Building, Testing, Publishing

The repository uses a `Makefile` with dynamically generated targets. Every image template is built for all three distros (Alpine, Debian, Ubuntu) using Jinja2 templates.

### Target naming convention

All targets follow the pattern `<action>-<distro>/<image>`:

| Action | Description | Example |
|--------|-------------|---------|
| `build` | Build a Docker image | `make build-alpine/go` |
| `test` | Run tests for an image | `make test-debian/cross-clang` |
| `push` | Push an image to ghcr.io | `make push-ubuntu/dev` |
| `clean` | Remove a local image | `make clean-alpine/tools` |

### Aggregate targets

Targets can be combined by distro, by image, or globally:

| Scope | Build | Test | Push | Clean |
|-------|-------|------|------|-------|
| **Everything** | `make build` | `make test` | `make push` | `make clean` |
| **One distro** | `make build-alpine` | `make test-debian` | `make push-ubuntu` | `make clean-alpine` |
| **One image** | `make build-go` | `make test-cross-clang` | `make push-csharp` | `make clean-rust` |

### Full cycle (build + test + push)

| Scope | Command |
|-------|---------|
| All images, all distros | `make all` |
| One image, all distros | `make go` |
| One image, one distro | `make alpine/go` |

### Dependency resolution

Build dependencies are resolved automatically. For example, `make build-alpine/cross-go` will first build `alpine/tools`, then `alpine/dev`, `alpine/clang`, and `alpine/cross-clang` if they don't exist yet.

## Using in Projects

Inherit from the appropriate language image and add project-specific dependencies:

```dockerfile
FROM ghcr.io/powertech-center/alpine/cross-go:latest

# Project-specific dev libraries
RUN apk add --no-cache alsa-lib-dev libx11-dev gtk+3.0-dev

WORKDIR /workspace
```

## Versions

The project follows a **latest stable / LTS** policy:

- All SDKs and compilers use the latest stable or LTS version available at build time
- Versions are resolved automatically during build (via GitHub API, package managers, or official endpoints)
- Versions may differ between distros because of different package repositories
- Images are rebuilt regularly to stay up to date

| Component | Policy | Resolution |
|-----------|--------|------------|
| Base distros | latest | `alpine:latest`, `debian:stable-slim`, `ubuntu:latest` |
| LLVM/Clang | latest | distro packages |
| .NET SDK | latest LTS | distro packages |
| Go | latest stable | auto via `go.dev/VERSION` |
| Rust | latest stable | auto via rustup |
| Node.js | latest LTS | distro packages |
| TypeScript | latest stable | via npm |
| PowerShell | latest stable | auto via GitHub API |
| OpenJDK | latest compatible LTS | distro packages + Gradle compatibility |
| Android SDK | latest | auto via sdkmanager |
| Flutter | latest stable | auto via Google API |
| Gradle | latest stable | auto via Gradle API |
| macOS SDK | latest stable | auto via GitHub API |
| xwin (MSVC) | latest stable | auto via GitHub API |
| llvm-mingw | latest stable | auto via GitHub API |
| LLVM source | latest stable | auto via GitHub API (compiler-rt, libc++) |
| glibc sysroots | 2.28 | Anaconda conda-forge |

## License

MIT
