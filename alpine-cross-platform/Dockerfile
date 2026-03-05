# PowerTech Alpine Crossplatform
# Cross-compilation environment for 8 targets:
#   Linux x64, Linux ARM64, macOS x64, macOS ARM64,
#   Windows x64 (MSVC + GNU), Windows ARM64 (MSVC + GNU)
#
# Toolchains:
#   clang     — universal C/C++ cross-compiler for all targets
#   macOS SDK — framework headers for Cocoa, AppKit, etc.
#   xwin      — Windows SDK and CRT (for both MSVC and GNU Windows targets)
#   lld       — universal linker (ld.lld for Linux, ld64.lld for macOS, lld-link for Windows)
#
# Smart wrappers:
#   Compiler wrappers auto-detect compile vs link mode and inject -fuse-ld=lld.
#   Linker wrappers handle platform-specific flags (clang as driver for ELF/Mach-O,
#   lld-link for PE/COFF). No CGO_LDFLAGS needed in Makefiles.
#
# Image: ghcr.io/powertech-center/alpine-cross-platform

FROM ghcr.io/powertech-center/alpine-dev:latest

# clang — C/C++ cross-compiler for all targets (Linux, macOS, Windows)
# lld   — linker suite: ld.lld (ELF/Linux), ld64.lld (Mach-O/macOS), lld-link (PE/Windows)
RUN apk add --no-cache clang lld

# aarch64 musl sysroot for Linux ARM64 cross-compilation.
# Alpine has no pre-built cross-sysroot package, so we use apk itself with --arch aarch64
# to install the aarch64 variants of musl and musl-dev into a target directory.
# Result: /usr/aarch64-alpine-linux-musl/{usr/include, lib/libc.musl-aarch64.so.1, ...}
RUN mkdir -p /usr/aarch64-alpine-linux-musl/etc/apk && \
    echo 'https://dl-cdn.alpinelinux.org/alpine/latest-stable/main' \
        > /usr/aarch64-alpine-linux-musl/etc/apk/repositories && \
    apk add --no-cache --arch aarch64 \
        --root /usr/aarch64-alpine-linux-musl \
        --allow-untrusted --initdb \
        musl musl-dev && \
    rm -rf /usr/aarch64-alpine-linux-musl/lib/apk \
           /usr/aarch64-alpine-linux-musl/etc/apk

# Download macOS SDK (extract only, no compilation)
ARG MACOSX_SDK_VERSION=14.5
RUN wget -q https://github.com/joseluisq/macosx-sdks/releases/download/${MACOSX_SDK_VERSION}/MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz && \
    tar -xJf MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz -C /opt && \
    rm MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz

# SDKROOT: standard macOS environment variable pointing to SDK location
# Used by: cc crate (Rust), CGo, clang, CMake, and other build tools
# Avoids xcrun warnings and SDK search issues during cross-compilation
ENV SDKROOT=/opt/MacOSX${MACOSX_SDK_VERSION}.sdk

# xwin — Windows MSVC SDK and CRT for cross-compilation
# Downloaded as pre-built binary (no Rust/Cargo dependency)
ARG XWIN_VERSION=0.8.0
RUN wget -q https://github.com/Jake-Shadle/xwin/releases/download/${XWIN_VERSION}/xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    tar xzf xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    ./xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl/xwin --accept-license --arch x86_64,aarch64 splat --output /xwin && \
    rm -rf xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl*

ENV XWIN_CACHE_DIR=/xwin

# =============================================================================
# Linker wrapper scripts (lld-<arch>-<os>)
#
# Used by Rust (cargo) via CARGO_TARGET_*_LINKER — Rust calls linker directly.
# For Go CGO: compiler wrappers handle linking (clang as driver + -fuse-ld=lld),
# except Windows GNU which calls lld-link directly via linker wrapper.
#
# Linux/macOS: clang as linker driver → translates GCC-style flags for lld
# Windows MSVC: lld-link with xwin lib paths
# Windows GNU: smart GCC-to-MSVC arg translation + lld-link
# =============================================================================

# Linux ELF linkers (clang as driver -> ld.lld)
# Rust invokes the linker with GCC-style flags (-Wl,--as-needed, -nostartfiles, etc.)
# clang translates these to raw linker flags before passing to ld.lld.
# -nostdlib prevents clang from adding its own startup files.
# aarch64: -Wl,-e,0 suppresses "_start not found" warning
# (Rust/Go linker always overwrites the entry point)
RUN printf '#!/bin/sh\nexec clang --target=x86_64-linux-musl -fuse-ld=lld -nostdlib "$@"\n' \
        > /usr/local/bin/lld-x86_64-linux-musl && \
    chmod +x /usr/local/bin/lld-x86_64-linux-musl && \
    printf '#!/bin/sh\nexec clang --target=aarch64-linux-musl --sysroot=/usr/aarch64-alpine-linux-musl -fuse-ld=lld -nostdlib -Wl,-e,0 -lc "$@"\n' \
        > /usr/local/bin/lld-aarch64-linux-musl && \
    chmod +x /usr/local/bin/lld-aarch64-linux-musl

# macOS Mach-O linkers (clang as driver -> ld64.lld)
# Rust invokes the linker with GCC-style flags; clang translates them for ld64.lld.
RUN SDK=/opt/MacOSX${MACOSX_SDK_VERSION}.sdk && \
    for arch in x86_64 aarch64; do \
        case "$arch" in \
            x86_64)  triple="x86_64-apple-macosx${MACOSX_SDK_VERSION}" ;; \
            aarch64) triple="aarch64-apple-macosx${MACOSX_SDK_VERSION}" ;; \
        esac && \
        printf '#!/bin/sh\nexec clang --target=%s --sysroot=%s -fuse-ld=lld -nostdlib "$@"\n' \
            "$triple" "$SDK" \
            > /usr/local/bin/lld-${arch}-apple-darwin && \
        chmod +x /usr/local/bin/lld-${arch}-apple-darwin; \
    done

# Windows MSVC linkers (lld-link with xwin lib paths)
RUN for arch in x86_64 aarch64; do \
    printf '#!/bin/sh\nexec lld-link /libpath:/xwin/crt/lib/%s /libpath:/xwin/sdk/lib/um/%s /libpath:/xwin/sdk/lib/ucrt/%s "$@"\n' \
    "$arch" "$arch" "$arch" \
    > /usr/local/bin/lld-link-${arch}-windows-msvc && \
    chmod +x /usr/local/bin/lld-link-${arch}-windows-msvc; \
    done

# Windows GNU linkers — smart GCC-to-MSVC arg translation + lld-link
# Called directly by compiler wrappers (not via -fuse-ld, since clang can't
# posix_spawn shell scripts). Translates -o, -l, -Wl,... to /out:, .lib, etc.
RUN for arch in x86_64 aarch64; do \
    printf '%s\n' \
        '#!/bin/sh' \
        '# Smart Windows GNU linker: translate GCC args to lld-link MSVC args' \
        'link_args="/libpath:/xwin/crt/lib/ARCH /libpath:/xwin/sdk/lib/um/ARCH /libpath:/xwin/sdk/lib/ucrt/ARCH libcmt.lib libvcruntime.lib libucrt.lib"' \
        'outfile=""' \
        'for arg in "$@"; do' \
        '    case "$arg" in' \
        '        *.o)                link_args="$link_args $arg" ;;' \
        '        -o)                 outfile="next" ;;' \
        '        -Wl,-def:*)         link_args="$link_args /def:${arg#-Wl,-def:}" ;;' \
        '        -Wl,-T,*)           ;;' \
        '        -l*)                link_args="$link_args ${arg#-l}.lib" ;;' \
        '        -fuse-ld=*)         ;;' \
        '        -mthreads)          ;;' \
        '        -m32|-m64)          ;;' \
        '        -s)                 ;;' \
        '        -mconsole)          link_args="$link_args /subsystem:console" ;;' \
        '        -mwindows)          link_args="$link_args /subsystem:windows" ;;' \
        '        -Wl,-tsaware|-Wl,--tsaware)       ;;' \
        '        -Wl,-nxcompat|-Wl,--nxcompat)     ;;' \
        '        -Wl,-dynamicbase|-Wl,--dynamicbase) ;;' \
        '        -Wl,-highentropyva|-Wl,--high-entropy-va) ;;' \
        '        -Wl,--major-os-version,*)          ;;' \
        '        -Wl,--minor-os-version,*)          ;;' \
        '        -Wl,--major-subsystem-version,*)   ;;' \
        '        -Wl,--minor-subsystem-version,*)   ;;' \
        '        -Wl,-Bstatic|-Wl,-Bdynamic)       ;;' \
        '        -Wl,--as-needed|-Wl,--no-as-needed) ;;' \
        '        -nostdlib|-nodefaultlibs)          ;;' \
        '        -shared)            link_args="$link_args /dll" ;;' \
        '        -Wl,*)              ;;' \
        '        -*)                 ;;' \
        '        *)' \
        '            if [ "$outfile" = "next" ]; then' \
        '                link_args="$link_args /out:$arg"' \
        '                outfile=""' \
        '            else' \
        '                link_args="$link_args $arg"' \
        '            fi' \
        '            ;;' \
        '    esac' \
        'done' \
        'exec lld-link $link_args' \
        > /usr/local/bin/lld-${arch}-windows-gnu && \
    sed -i "s|ARCH|${arch}|g" /usr/local/bin/lld-${arch}-windows-gnu && \
    chmod +x /usr/local/bin/lld-${arch}-windows-gnu; \
    done

# =============================================================================
# Smart compiler wrappers (clang-<arch>-<os>, clang++-<arch>-<os>)
#
# Logic for -fuse-ld handling:
#   1. Scan args: detect compile-only mode (-c/-S/-E) and -fuse-ld presence
#   2. If compile-only: pass all args to clang as-is (no linker involved)
#   3. If linking + -fuse-ld=lld or no -fuse-ld: replace/add -fuse-ld=lld
#      (the real lld binary, not a shell script wrapper)
#   4. If linking + -fuse-ld=<other>: pass through as-is
#
# Platform-specific linker flags (like -Wl,-e,0 for aarch64 Linux) are
# injected by the compiler wrapper directly, not via linker wrapper scripts.
# This avoids the posix_spawn limitation (clang can't exec shell scripts).
# =============================================================================

# Linux x86_64 musl (C and C++)
RUN for compiler in clang clang++; do \
    printf '%s\n' \
        '#!/bin/sh' \
        '# Smart compiler wrapper: auto-injects -fuse-ld=lld when linking' \
        'compile_only=false' \
        'has_fuse_ld=false' \
        'fuse_ld_is_lld=false' \
        'for arg in "$@"; do' \
        '    case "$arg" in' \
        '        -c|-S|-E|-fsyntax-only) compile_only=true ;;' \
        '        -fuse-ld=lld)           has_fuse_ld=true; fuse_ld_is_lld=true ;;' \
        '        -fuse-ld=*)             has_fuse_ld=true ;;' \
        '    esac' \
        'done' \
        'if [ "$compile_only" = "true" ]; then' \
        '    exec COMPILER --target=x86_64-linux-musl "$@"' \
        'fi' \
        '# Linking mode: ensure -fuse-ld=lld is present' \
        'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
        '    args=""' \
        '    for arg in "$@"; do' \
        '        case "$arg" in' \
        '            -fuse-ld=lld) ;;' \
        '            *)            args="$args $arg" ;;' \
        '        esac' \
        '    done' \
        '    exec COMPILER --target=x86_64-linux-musl -fuse-ld=lld $args' \
        'else' \
        '    exec COMPILER --target=x86_64-linux-musl "$@"' \
        'fi' \
        > /usr/local/bin/${compiler}-x86_64-linux-musl && \
    sed -i "s|COMPILER|${compiler}|g" /usr/local/bin/${compiler}-x86_64-linux-musl && \
    chmod +x /usr/local/bin/${compiler}-x86_64-linux-musl; \
    done

# Linux aarch64 musl (C and C++)
# Adds -nostartfiles -nodefaultlibs -lc -Wl,-e,0 in link mode:
#   -nostartfiles -nodefaultlibs: no GCC runtime in Alpine aarch64 sysroot (no crtbeginS.o, libgcc)
#   -lc: explicitly link musl libc
#   -Wl,-e,0: suppress "_start not found" warning (Go/Rust always set their own entry point)
RUN for compiler in clang clang++; do \
    printf '%s\n' \
        '#!/bin/sh' \
        'compile_only=false' \
        'has_fuse_ld=false' \
        'fuse_ld_is_lld=false' \
        'for arg in "$@"; do' \
        '    case "$arg" in' \
        '        -c|-S|-E|-fsyntax-only) compile_only=true ;;' \
        '        -fuse-ld=lld)           has_fuse_ld=true; fuse_ld_is_lld=true ;;' \
        '        -fuse-ld=*)             has_fuse_ld=true ;;' \
        '    esac' \
        'done' \
        'if [ "$compile_only" = "true" ]; then' \
        '    exec COMPILER --target=aarch64-linux-musl --sysroot=/usr/aarch64-alpine-linux-musl "$@"' \
        'fi' \
        'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
        '    args=""' \
        '    for arg in "$@"; do' \
        '        case "$arg" in' \
        '            -fuse-ld=lld) ;;' \
        '            *)            args="$args $arg" ;;' \
        '        esac' \
        '    done' \
        '    exec COMPILER --target=aarch64-linux-musl --sysroot=/usr/aarch64-alpine-linux-musl -fuse-ld=lld -nostartfiles -nodefaultlibs -lc -Wl,-e,0 $args' \
        'else' \
        '    exec COMPILER --target=aarch64-linux-musl --sysroot=/usr/aarch64-alpine-linux-musl "$@"' \
        'fi' \
        > /usr/local/bin/${compiler}-aarch64-linux-musl && \
    sed -i "s|COMPILER|${compiler}|g" /usr/local/bin/${compiler}-aarch64-linux-musl && \
    chmod +x /usr/local/bin/${compiler}-aarch64-linux-musl; \
    done

# macOS x86_64 and aarch64 (C and C++)
# -w suppresses warnings from macOS SDK headers (deprecated APIs, nullability, availability)
RUN SDK=/opt/MacOSX${MACOSX_SDK_VERSION}.sdk && \
    for compiler in clang clang++; do \
    for arch in x86_64 aarch64; do \
        case "$arch" in \
            x86_64)  triple="x86_64-apple-macosx${MACOSX_SDK_VERSION}" ;; \
            aarch64) triple="aarch64-apple-macosx${MACOSX_SDK_VERSION}" ;; \
        esac && \
        printf '%s\n' \
            '#!/bin/sh' \
            'compile_only=false' \
            'has_fuse_ld=false' \
            'fuse_ld_is_lld=false' \
            'for arg in "$@"; do' \
            '    case "$arg" in' \
            '        -c|-S|-E|-fsyntax-only) compile_only=true ;;' \
            '        -fuse-ld=lld)           has_fuse_ld=true; fuse_ld_is_lld=true ;;' \
            '        -fuse-ld=*)             has_fuse_ld=true ;;' \
            '    esac' \
            'done' \
            "if [ \"\$compile_only\" = \"true\" ]; then" \
            "    exec ${compiler} --target=${triple} --sysroot=${SDK} -F${SDK}/System/Library/Frameworks -I${SDK}/usr/include -w \"\$@\"" \
            'fi' \
            'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
            '    args=""' \
            '    for arg in "$@"; do' \
            '        case "$arg" in' \
            '            -fuse-ld=lld) ;;' \
            '            *)            args="$args $arg" ;;' \
            '        esac' \
            '    done' \
            "    exec ${compiler} --target=${triple} --sysroot=${SDK} -F${SDK}/System/Library/Frameworks -I${SDK}/usr/include -w -fuse-ld=lld \$args" \
            'else' \
            "    exec ${compiler} --target=${triple} --sysroot=${SDK} -F${SDK}/System/Library/Frameworks -I${SDK}/usr/include -w \"\$@\"" \
            'fi' \
            > /usr/local/bin/${compiler}-${arch}-apple-darwin && \
        chmod +x /usr/local/bin/${compiler}-${arch}-apple-darwin; \
    done; \
    done

# Windows MSVC (C and C++) — clang in MSVC-compatible mode (--driver-mode=cl)
# Rust cc crate calls CC with MSVC-style flags (/nologo, /O2, /imsvc, /c).
# Smart: detects compile-only vs link mode, auto-injects -fuse-ld=lld.
RUN for arch in x86_64 aarch64; do \
    for prefix in clang clang++; do \
        printf '%s\n' \
            '#!/bin/sh' \
            'compile_only=false' \
            'has_fuse_ld=false' \
            'fuse_ld_is_lld=false' \
            'for arg in "$@"; do' \
            '    case "$arg" in' \
            '        /c|-c|-S|-E|-fsyntax-only) compile_only=true ;;' \
            '        -fuse-ld=lld)              has_fuse_ld=true; fuse_ld_is_lld=true ;;' \
            '        -fuse-ld=*)                has_fuse_ld=true ;;' \
            '    esac' \
            'done' \
            "if [ \"\$compile_only\" = \"true\" ]; then" \
            "    exec clang --driver-mode=cl --target=${arch}-pc-windows-msvc /imsvc/xwin/crt/include /imsvc/xwin/sdk/include/ucrt /imsvc/xwin/sdk/include/um /imsvc/xwin/sdk/include/shared \"\$@\"" \
            'fi' \
            'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
            '    args=""' \
            '    for arg in "$@"; do' \
            '        case "$arg" in' \
            '            -fuse-ld=lld) ;;' \
            '            *)            args="$args $arg" ;;' \
            '        esac' \
            '    done' \
            "    exec clang --driver-mode=cl --target=${arch}-pc-windows-msvc /imsvc/xwin/crt/include /imsvc/xwin/sdk/include/ucrt /imsvc/xwin/sdk/include/um /imsvc/xwin/sdk/include/shared -fuse-ld=lld \$args" \
            'else' \
            "    exec clang --driver-mode=cl --target=${arch}-pc-windows-msvc /imsvc/xwin/crt/include /imsvc/xwin/sdk/include/ucrt /imsvc/xwin/sdk/include/um /imsvc/xwin/sdk/include/shared \"\$@\"" \
            'fi' \
            > /usr/local/bin/${prefix}-${arch}-windows-msvc && \
        chmod +x /usr/local/bin/${prefix}-${arch}-windows-msvc; \
    done; \
    done

# Windows GNU (C and C++) — fake-GNU wrappers for Go CGO
# Detects link mode (output .exe) and calls lld-link directly with translated args.
# Compile mode: filters MinGW flags, forwards to clang with MSVC target.
# No MinGW headers/runtime — xwin provides everything.
# No MinGW DLL deps — links against UCRT (Win10+).
RUN for arch in x86_64 aarch64; do \
    for compiler in clang clang++; do \
        printf '%s\n' \
            '#!/bin/sh' \
            '# Smart fake-GNU wrapper: MSVC target with GCC-style interface' \
            '' \
            '# Detect link mode: output file ending in .exe = final link' \
            'final_link=false' \
            'compile_only=false' \
            'prev=""' \
            'for arg in "$@"; do' \
            '    case "$arg" in' \
            '        -c|-S|-E|-fsyntax-only) compile_only=true ;;' \
            '    esac' \
            '    if [ "$prev" = "-o" ]; then' \
            '        case "$arg" in' \
            '            *.exe) final_link=true ;;' \
            '        esac' \
            '    fi' \
            '    prev="$arg"' \
            'done' \
            '' \
            'if [ "$final_link" = "true" ]; then' \
            '    # === FINAL LINK MODE ===' \
            '    # Delegate to our linker wrapper (GCC-to-MSVC translation)' \
            '    exec /usr/local/bin/lld-ARCH-windows-gnu "$@"' \
            'fi' \
            '' \
            '# === COMPILE / OTHER MODE ===' \
            '# Filter MinGW-specific flags' \
            'args=""' \
            'for arg in "$@"; do' \
            '    case "$arg" in' \
            '        -mthreads)    ;;' \
            '        -m32|-m64)    ;;' \
            '        -fuse-ld=*)   ;;' \
            '        *)            args="$args $arg" ;;' \
            '    esac' \
            'done' \
            'exec COMPILER --target=ARCH-pc-windows-msvc \' \
            '    -isystem /xwin/crt/include \' \
            '    -isystem /xwin/sdk/include/ucrt \' \
            '    -isystem /xwin/sdk/include/um \' \
            '    -isystem /xwin/sdk/include/shared \' \
            '    $args' \
            > /usr/local/bin/${compiler}-${arch}-windows-gnu && \
        sed -i "s|ARCH|${arch}|g; s|COMPILER|${compiler}|g" /usr/local/bin/${compiler}-${arch}-windows-gnu && \
        chmod +x /usr/local/bin/${compiler}-${arch}-windows-gnu; \
    done; \
    done

CMD ["/bin/sh"]
