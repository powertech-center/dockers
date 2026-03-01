# PowerTech Alpine Crossplatform
# Cross-compilation environment for 6 targets:
#   Linux x64, Linux ARM64, macOS x64, macOS ARM64, Windows x64, Windows ARM64
#
# Toolchains:
#   Zig       — universal C cross-compiler (Linux, macOS, Windows GNU)
#   macOS SDK — framework headers for Cocoa, AppKit, etc.
#   xwin      — Windows MSVC SDK and CRT (for Rust MSVC targets)
#   clang-cl  — clang in MSVC-compatible mode
#
# Image: ghcr.io/powertech-center/alpine-crossplatform

FROM ghcr.io/powertech-center/alpine-dev:latest

# clang is needed for clang-cl (MSVC-compatible C compilation for Windows)
RUN apk add --no-cache clang

# Zig — universal C/C++ cross-compiler
ARG ZIG_VERSION=0.15.2
RUN wget https://ziglang.org/download/${ZIG_VERSION}/zig-x86_64-linux-${ZIG_VERSION}.tar.xz && \
    tar -xJf zig-x86_64-linux-${ZIG_VERSION}.tar.xz -C /opt && \
    ln -s /opt/zig-x86_64-linux-${ZIG_VERSION}/zig /usr/local/bin/zig && \
    rm zig-x86_64-linux-${ZIG_VERSION}.tar.xz

# Create zig-cc wrapper scripts for non-macOS targets
# Wrappers allow Go/Rust to use a single executable path as CC
RUN for target in \
    x86_64-linux-musl \
    aarch64-linux-musl \
    x86_64-windows-gnu \
    aarch64-windows-gnu; \
    do \
    printf '#!/bin/sh\nexec zig cc -target %s "$@"\n' "$target" > /usr/local/bin/zig-cc-${target} && \
    chmod +x /usr/local/bin/zig-cc-${target}; \
    done

# Download macOS SDK (extract only, no compilation)
ARG MACOSX_SDK_VERSION=14.5
RUN wget -q https://github.com/joseluisq/macosx-sdks/releases/download/${MACOSX_SDK_VERSION}/MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz && \
    tar -xJf MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz -C /opt && \
    rm MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz

# SDKROOT: standard macOS environment variable pointing to SDK location
# Used by: cc crate (Rust), CGo, clang, CMake, and other build tools
# Avoids xcrun warnings and SDK search issues during cross-compilation
ENV SDKROOT=/opt/MacOSX${MACOSX_SDK_VERSION}.sdk

# Create zig-cc wrapper scripts for macOS targets (with SDK sysroot)
# -w suppresses warnings from macOS SDK headers (deprecated APIs, nullability, availability)
RUN SDK=/opt/MacOSX${MACOSX_SDK_VERSION}.sdk && \
    for target in x86_64-macos aarch64-macos; do \
    printf '#!/bin/sh\nexec zig cc -target %s --sysroot=%s -F%s/System/Library/Frameworks -I%s/usr/include -L/usr/lib -w "$@"\n' \
    "$target" "$SDK" "$SDK" "$SDK" \
    > /usr/local/bin/zig-cc-${target} && \
    chmod +x /usr/local/bin/zig-cc-${target}; \
    done

# xwin — Windows MSVC SDK and CRT for cross-compilation
# Downloaded as pre-built binary (no Rust/Cargo dependency)
ARG XWIN_VERSION=0.8.0
RUN wget -q https://github.com/Jake-Shadle/xwin/releases/download/${XWIN_VERSION}/xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    tar xzf xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    ./xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl/xwin --accept-license --arch x86_64,aarch64 splat --output /xwin && \
    rm -rf xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl*

ENV XWIN_CACHE_DIR=/xwin

# clang-cl wrapper (clang in MSVC-compatible mode)
RUN printf '#!/bin/sh\nexec clang --driver-mode=cl "$@"\n' > /usr/local/bin/clang-cl && \
    chmod +x /usr/local/bin/clang-cl

CMD ["/bin/sh"]
