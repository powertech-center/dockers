# PowerTech Alpine Cross-Platform
# Cross-compilation environment for 10 targets:
#   Linux x64/arm64 (musl), Linux x64/arm64 (glibc),
#   macOS x64/arm64, Windows x64/arm64 (MSVC + GNU)
#
# Build stages:
#   Stage 1: Base tools — clang/lld/llvm, macOS SDK, Windows SDK (xwin), aarch64 musl sysroot
#   Stage 2: glibc 2.28 sysroots (x86_64 + aarch64) from Anaconda conda-forge
#   Stage 3: LLVM source + compiler-rt builtins for all 4 Linux targets
#   Stage 4: libc++ for all 4 Linux targets (static + shared)
#   Stage 5: Compiler and linker wrappers for all 10 cross-compilation targets
#
# Image: ghcr.io/powertech-center/alpine-cross-platform

# =============================================================================
# Stage 1: Base cross-compilation environment
# Installs clang/lld/llvm, macOS SDK, Windows SDK (xwin), and aarch64 musl sysroot.
# All SDK versions are auto-detected from GitHub releases (latest stable).
# =============================================================================
FROM ghcr.io/powertech-center/alpine-dev:latest

# clang — C/C++ cross-compiler for all targets (Linux, macOS, Windows)
# lld   — linker suite: ld.lld (ELF/Linux), ld64.lld (Mach-O/macOS), lld-link (PE/Windows)
# llvm  — provides llvm-ar, invoked as llvm-lib for MSVC-compatible COFF archive creation
#         (used by Rust cc crate for C deps on windows-msvc targets, e.g. zstd-sys)
RUN apk add --no-cache clang lld llvm && \
    ln -sf /usr/bin/llvm-ar /usr/local/bin/llvm-lib

# Download macOS SDK (latest stable release, auto-detected)
# Source: https://github.com/joseluisq/macosx-sdks
RUN MACOSX_SDK_VERSION=$(wget -qO- "https://api.github.com/repos/joseluisq/macosx-sdks/releases" | \
        jq -r '[.[] | select(.prerelease == false)] | first | .tag_name') && \
    echo "macOS SDK ${MACOSX_SDK_VERSION}" && \
    wget -q https://github.com/joseluisq/macosx-sdks/releases/download/${MACOSX_SDK_VERSION}/MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz && \
    mkdir -p /usr/macosx.sdk && \
    tar -xJf MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz --strip-components=1 -C /usr/macosx.sdk && \
    rm MacOSX${MACOSX_SDK_VERSION}.sdk.tar.xz

ENV SDKROOT=/usr/macosx.sdk

# Download Windows SDK and CRT via xwin (latest stable release, auto-detected)
# Source: https://github.com/Jake-Shadle/xwin
RUN XWIN_VERSION=$(wget -qO- "https://api.github.com/repos/Jake-Shadle/xwin/releases" | \
        jq -r '[.[] | select(.prerelease == false)] | first | .tag_name') && \
    echo "xwin ${XWIN_VERSION}" && \
    wget -q https://github.com/Jake-Shadle/xwin/releases/download/${XWIN_VERSION}/xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    tar xzf xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl.tar.gz && \
    ./xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl/xwin --accept-license --arch x86_64,aarch64 splat --output /usr/windows.sdk && \
    rm -rf xwin-${XWIN_VERSION}-x86_64-unknown-linux-musl*

ENV XWIN_CACHE_DIR=/usr/windows.sdk

# aarch64 musl sysroot for Linux ARM64 cross-compilation.
# Alpine has no pre-built cross-sysroot package, so we use apk with --arch aarch64
# to install the aarch64 variants of musl and musl-dev into a target directory.
RUN mkdir -p /usr/aarch64-alpine-linux-musl/etc/apk && \
    echo 'https://dl-cdn.alpinelinux.org/alpine/latest-stable/main' \
        > /usr/aarch64-alpine-linux-musl/etc/apk/repositories && \
    apk add --no-cache --arch aarch64 \
        --root /usr/aarch64-alpine-linux-musl \
        --allow-untrusted --initdb \
        musl musl-dev && \
    rm -rf /usr/aarch64-alpine-linux-musl/lib/apk \
           /usr/aarch64-alpine-linux-musl/etc/apk

# =============================================================================
# Stage 2: Download and extract glibc 2.28 sysroots from Anaconda conda-forge
# Anaconda sysroot packages provide a clean, flat layout with only relative
# symlinks — no Debian multiarch subdirectories, no absolute symlinks.
# =============================================================================

ARG CONDA=https://conda.anaconda.org/conda-forge/noarch

# Install zstd for extracting .conda packages (ZIP with zstd-compressed tar inside)
RUN apk add --no-cache zstd

# Download and extract glibc 2.28 sysroot for x86_64
RUN mkdir -p /tmp/conda /usr/x86_64-linux-gnu && \
    wget -q -O /tmp/conda/sysroot.conda \
        ${CONDA}/sysroot_linux-64-2.28-he3f20f0_9.conda && \
    # Extract .conda: ZIP → pkg-*.tar.zst → tar
    unzip -o /tmp/conda/sysroot.conda -d /tmp/conda > /dev/null && \
    cat /tmp/conda/pkg-*.tar.zst | zstd -d | tar xf - -C /tmp/conda && \
    mv /tmp/conda/x86_64-conda-linux-gnu/sysroot/* /usr/x86_64-linux-gnu/ && \
    rm -rf /tmp/conda && \
    SR=/usr/x86_64-linux-gnu && \
    # Rename lib64 -> lib (remove the directory symlink first, then rename)
    rm ${SR}/lib && mv ${SR}/lib64 ${SR}/lib && \
    rm ${SR}/usr/lib && mv ${SR}/usr/lib64 ${SR}/usr/lib && \
    # Fix symlinks that referenced lib64/
    find ${SR} -type l | while read link; do \
        target=$(readlink "$link") && \
        newtarget=$(echo "$target" | sed 's|/lib64/|/lib/|g') && \
        [ "$target" != "$newtarget" ] && ln -sf "$newtarget" "$link" || true; \
    done && \
    # Fix linker scripts (absolute paths /lib64/ -> /lib/, /usr/lib64/ -> /usr/lib/)
    sed -i 's|/lib64/|/lib/|g; s|/usr/lib64/|/usr/lib/|g' \
        ${SR}/usr/lib/libc.so ${SR}/usr/lib/libm.so ${SR}/usr/lib/libm.a 2>/dev/null || true && \
    # Clean up files not needed for cross-compilation
    rm -rf ${SR}/usr/share ${SR}/etc ${SR}/sbin ${SR}/usr/bin ${SR}/usr/sbin ${SR}/usr/libexec \
           ${SR}/usr/lib/locale ${SR}/usr/lib/gconv ${SR}/usr/lib/audit \
           ${SR}/lib/libSegFault.so ${SR}/usr/lib/libmemusage.so ${SR}/usr/lib/libpcprofile.so \
           ${SR}/usr/lib/libg.a ${SR}/usr/lib/libmcheck.a ${SR}/usr/lib/libBrokenLocale.a \
           ${SR}/lib/libBrokenLocale-2.28.so ${SR}/lib/libBrokenLocale.so.1 \
           ${SR}/usr/lib/libBrokenLocale.so \
           ${SR}/usr/lib/gcrt1.o ${SR}/usr/lib/grcrt1.o ${SR}/usr/lib/Mcrt1.o && \
    # Add Linux kernel UAPI headers (linux/, asm/, asm-generic/) — not included in sysroot package
    mkdir -p /tmp/conda && \
    wget -q -O /tmp/conda/kheaders.conda \
        ${CONDA}/kernel-headers_linux-64-6.12.0-he073ed8_6.conda && \
    unzip -o /tmp/conda/kheaders.conda -d /tmp/conda > /dev/null && \
    cat /tmp/conda/pkg-*.tar.zst | zstd -d | tar xf - -C /tmp/conda && \
    cp -r /tmp/conda/x86_64-conda-linux-gnu/sysroot/usr/include/linux ${SR}/usr/include/ && \
    cp -r /tmp/conda/x86_64-conda-linux-gnu/sysroot/usr/include/asm ${SR}/usr/include/ && \
    cp -r /tmp/conda/x86_64-conda-linux-gnu/sysroot/usr/include/asm-generic ${SR}/usr/include/ && \
    rm -rf /tmp/conda

# Download and extract glibc 2.28 sysroot for aarch64
RUN mkdir -p /tmp/conda /usr/aarch64-linux-gnu && \
    wget -q -O /tmp/conda/sysroot.conda \
        ${CONDA}/sysroot_linux-aarch64-2.28-h585391f_9.conda && \
    unzip -o /tmp/conda/sysroot.conda -d /tmp/conda > /dev/null && \
    cat /tmp/conda/pkg-*.tar.zst | zstd -d | tar xf - -C /tmp/conda && \
    mv /tmp/conda/aarch64-conda-linux-gnu/sysroot/* /usr/aarch64-linux-gnu/ && \
    rm -rf /tmp/conda && \
    SR=/usr/aarch64-linux-gnu && \
    # Rename lib64 -> lib
    rm ${SR}/lib && mv ${SR}/lib64 ${SR}/lib && \
    rm ${SR}/usr/lib && mv ${SR}/usr/lib64 ${SR}/usr/lib && \
    # Fix symlinks that referenced lib64/
    find ${SR} -type l | while read link; do \
        target=$(readlink "$link") && \
        newtarget=$(echo "$target" | sed 's|/lib64/|/lib/|g') && \
        [ "$target" != "$newtarget" ] && ln -sf "$newtarget" "$link" || true; \
    done && \
    # Fix linker scripts
    sed -i 's|/lib64/|/lib/|g; s|/usr/lib64/|/usr/lib/|g' \
        ${SR}/usr/lib/libc.so ${SR}/usr/lib/libm.so ${SR}/usr/lib/libm.a 2>/dev/null || true && \
    # Clean up files not needed for cross-compilation
    rm -rf ${SR}/usr/share ${SR}/etc ${SR}/sbin ${SR}/usr/bin ${SR}/usr/sbin ${SR}/usr/libexec \
           ${SR}/usr/lib/locale ${SR}/usr/lib/gconv ${SR}/usr/lib/audit \
           ${SR}/lib/libSegFault.so ${SR}/usr/lib/libmemusage.so ${SR}/usr/lib/libpcprofile.so \
           ${SR}/usr/lib/libg.a ${SR}/usr/lib/libmcheck.a ${SR}/usr/lib/libBrokenLocale.a \
           ${SR}/lib/libBrokenLocale-2.28.so ${SR}/lib/libBrokenLocale.so.1 \
           ${SR}/usr/lib/libBrokenLocale.so \
           ${SR}/usr/lib/gcrt1.o ${SR}/usr/lib/grcrt1.o ${SR}/usr/lib/Mcrt1.o && \
    # Add Linux kernel UAPI headers
    mkdir -p /tmp/conda && \
    wget -q -O /tmp/conda/kheaders.conda \
        ${CONDA}/kernel-headers_linux-aarch64-6.12.0-h05a177a_6.conda && \
    unzip -o /tmp/conda/kheaders.conda -d /tmp/conda > /dev/null && \
    cat /tmp/conda/pkg-*.tar.zst | zstd -d | tar xf - -C /tmp/conda && \
    cp -r /tmp/conda/aarch64-conda-linux-gnu/sysroot/usr/include/linux ${SR}/usr/include/ && \
    cp -r /tmp/conda/aarch64-conda-linux-gnu/sysroot/usr/include/asm ${SR}/usr/include/ && \
    cp -r /tmp/conda/aarch64-conda-linux-gnu/sysroot/usr/include/asm-generic ${SR}/usr/include/ && \
    rm -rf /tmp/conda

# Remove zstd — only needed for extracting .conda packages above
RUN apk del --no-cache zstd

# =============================================================================
# Stage 3: LLVM source + compiler-rt builtins for all 4 Linux targets
# =============================================================================

# Detect latest stable LLVM release and download source (only dirs needed for runtimes build)
RUN LLVM_VERSION=$(wget -qO- "https://api.github.com/repos/llvm/llvm-project/releases" | \
        jq -r '[.[] | select(.prerelease == false and (.tag_name | startswith("llvmorg-")))] | first | .tag_name | ltrimstr("llvmorg-")') && \
    echo "LLVM ${LLVM_VERSION}" && \
    cd /tmp && \
    wget -q https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/llvm-project-${LLVM_VERSION}.src.tar.xz && \
    tar xf llvm-project-${LLVM_VERSION}.src.tar.xz \
        llvm-project-${LLVM_VERSION}.src/runtimes \
        llvm-project-${LLVM_VERSION}.src/libcxx \
        llvm-project-${LLVM_VERSION}.src/libcxxabi \
        llvm-project-${LLVM_VERSION}.src/libunwind \
        llvm-project-${LLVM_VERSION}.src/cmake \
        llvm-project-${LLVM_VERSION}.src/llvm/cmake \
        llvm-project-${LLVM_VERSION}.src/llvm/utils/llvm-lit \
        llvm-project-${LLVM_VERSION}.src/libc \
        llvm-project-${LLVM_VERSION}.src/compiler-rt \
        llvm-project-${LLVM_VERSION}.src/third-party && \
    rm llvm-project-${LLVM_VERSION}.src.tar.xz && \
    mv llvm-project-${LLVM_VERSION}.src /tmp/llvm-src

# Add Linux kernel UAPI headers to the aarch64-musl cross-sysroot.
# libc++ needs <linux/futex.h> (for atomic wait) which pulls <asm/types.h>.
RUN cd /tmp && \
    HEADERS_VER=$(awk '/^P:linux-headers/{getline; print substr($0,3)}' /lib/apk/db/installed) && \
    wget -q https://dl-cdn.alpinelinux.org/alpine/latest-stable/main/aarch64/linux-headers-${HEADERS_VER}.apk && \
    mkdir headers-aarch64 && \
    tar xzf linux-headers-${HEADERS_VER}.apk -C headers-aarch64 && \
    cp -r headers-aarch64/usr/include/linux /usr/aarch64-alpine-linux-musl/usr/include/ && \
    cp -r headers-aarch64/usr/include/asm /usr/aarch64-alpine-linux-musl/usr/include/ && \
    cp -r headers-aarch64/usr/include/asm-generic /usr/aarch64-alpine-linux-musl/usr/include/ && \
    rm -rf headers-aarch64 linux-headers-*.apk

# Build compiler-rt builtins for all 4 Linux targets.
# Shared libc++ needs builtins (__lttf2, __udivti3 etc. — 128-bit float/int ops on aarch64).
# x86_64-musl (native) is included to unify all targets on -rtlib=compiler-rt.
# Install into clang resource dir so -rtlib=compiler-rt finds them automatically.
RUN CLANG_RESOURCE_DIR=$(clang --print-resource-dir) && \
    for target in x86_64-linux-musl aarch64-linux-musl x86_64-linux-gnu aarch64-linux-gnu; do \
        case "$target" in \
            x86_64-linux-musl)  sysroot=/ ;; \
            aarch64-linux-musl) sysroot=/usr/aarch64-alpine-linux-musl ;; \
            x86_64-linux-gnu)   sysroot=/usr/x86_64-linux-gnu ;; \
            aarch64-linux-gnu)  sysroot=/usr/aarch64-linux-gnu ;; \
        esac && \
        cmake -G Ninja \
            -S /tmp/llvm-src/compiler-rt \
            -B /tmp/build-rt-${target} \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_C_COMPILER_TARGET=${target} \
            -DCMAKE_CXX_COMPILER_TARGET=${target} \
            -DCMAKE_ASM_COMPILER_TARGET=${target} \
            -DCMAKE_SYSROOT=${sysroot} \
            -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
            -DCMAKE_BUILD_TYPE=Release \
            -DCOMPILER_RT_BUILD_BUILTINS=ON \
            -DCOMPILER_RT_BUILD_SANITIZERS=OFF \
            -DCOMPILER_RT_BUILD_XRAY=OFF \
            -DCOMPILER_RT_BUILD_LIBFUZZER=OFF \
            -DCOMPILER_RT_BUILD_PROFILE=OFF \
            -DCOMPILER_RT_BUILD_MEMPROF=OFF \
            -DCOMPILER_RT_BUILD_ORC=OFF \
            -DCOMPILER_RT_DEFAULT_TARGET_ONLY=ON \
            -DLLVM_ENABLE_PER_TARGET_RUNTIME_DIR=ON \
            -DCMAKE_INSTALL_PREFIX=${CLANG_RESOURCE_DIR} && \
        ninja -C /tmp/build-rt-${target} && \
        ninja -C /tmp/build-rt-${target} install && \
        rm -rf /tmp/build-rt-${target}; \
    done

# Symlink compiler-rt builtins as libgcc.a in each sysroot.
# libc++abi CMake detects libgcc and adds -lgcc to the shared link line.
# The symlink satisfies -lgcc with real builtins (instead of empty stub).
RUN CLANG_RESOURCE_DIR=$(clang --print-resource-dir) && \
    ln -sf ${CLANG_RESOURCE_DIR}/lib/x86_64-unknown-linux-musl/libclang_rt.builtins.a /usr/lib/libgcc.a && \
    ln -sf ${CLANG_RESOURCE_DIR}/lib/aarch64-unknown-linux-musl/libclang_rt.builtins.a /usr/aarch64-alpine-linux-musl/usr/lib/libgcc.a && \
    ln -sf ${CLANG_RESOURCE_DIR}/lib/x86_64-unknown-linux-gnu/libclang_rt.builtins.a /usr/x86_64-linux-gnu/usr/lib/libgcc.a && \
    ln -sf ${CLANG_RESOURCE_DIR}/lib/aarch64-unknown-linux-gnu/libclang_rt.builtins.a /usr/aarch64-linux-gnu/usr/lib/libgcc.a

# =============================================================================
# Stage 4: Build libc++ for all 4 Linux targets (static + shared)
# Targets: x86_64-musl (native), aarch64-musl (cross), x86_64-gnu (cross), aarch64-gnu (cross)
# =============================================================================

RUN for target in x86_64-linux-musl aarch64-linux-musl x86_64-linux-gnu aarch64-linux-gnu; do \
        echo "=== Building libc++ for ${target} ===" && \
        sysroot_flags="" && musl_flags="" && extra_flags="" && linker_flags="" && install_prefix="" && \
        case "$target" in \
            x86_64-linux-musl) \
                musl_flags="-DLIBCXX_HAS_MUSL_LIBC=ON" && \
                install_prefix="/usr" ;; \
            aarch64-linux-musl) \
                sysroot_flags="-DCMAKE_SYSROOT=/usr/aarch64-alpine-linux-musl -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY" && \
                musl_flags="-DLIBCXX_HAS_MUSL_LIBC=ON -DLIBCXXABI_HAS_CXA_THREAD_ATEXIT_IMPL=OFF" && \
                extra_flags="-DLIBCXX_HAS_ATOMIC_LIB=OFF -DCMAKE_C_IMPLICIT_LINK_LIBRARIES= -DCMAKE_CXX_IMPLICIT_LINK_LIBRARIES=" && \
                linker_flags="--target=aarch64-linux-musl --sysroot=/usr/aarch64-alpine-linux-musl -fuse-ld=lld -nostdlib -lc" && \
                install_prefix="/usr/aarch64-alpine-linux-musl/usr" ;; \
            x86_64-linux-gnu) \
                sysroot_flags="-DCMAKE_SYSROOT=/usr/x86_64-linux-gnu -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY" && \
                extra_flags="-DLIBCXX_HAS_ATOMIC_LIB=OFF -DCMAKE_C_IMPLICIT_LINK_LIBRARIES= -DCMAKE_CXX_IMPLICIT_LINK_LIBRARIES=" && \
                linker_flags="--target=x86_64-linux-gnu --sysroot=/usr/x86_64-linux-gnu -fuse-ld=lld -nostdlib -lc -ldl -lpthread" && \
                install_prefix="/usr/x86_64-linux-gnu/usr" ;; \
            aarch64-linux-gnu) \
                sysroot_flags="-DCMAKE_SYSROOT=/usr/aarch64-linux-gnu -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY" && \
                extra_flags="-DLIBCXX_HAS_ATOMIC_LIB=OFF -DCMAKE_C_IMPLICIT_LINK_LIBRARIES= -DCMAKE_CXX_IMPLICIT_LINK_LIBRARIES=" && \
                linker_flags="--target=aarch64-linux-gnu --sysroot=/usr/aarch64-linux-gnu -fuse-ld=lld -nostdlib -lc -ldl -lpthread" && \
                install_prefix="/usr/aarch64-linux-gnu/usr" ;; \
        esac && \
        cmake -G Ninja \
            -S /tmp/llvm-src/runtimes \
            -B /tmp/build-libcxx-${target} \
            -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" \
            -DCMAKE_C_COMPILER=clang \
            -DCMAKE_CXX_COMPILER=clang++ \
            -DCMAKE_C_COMPILER_TARGET=${target} \
            -DCMAKE_CXX_COMPILER_TARGET=${target} \
            -DCMAKE_ASM_COMPILER_TARGET=${target} \
            -DCMAKE_BUILD_TYPE=Release \
            -DLIBCXX_ENABLE_SHARED=ON -DLIBCXX_ENABLE_STATIC=ON \
            -DLIBCXXABI_ENABLE_SHARED=ON -DLIBCXXABI_ENABLE_STATIC=ON \
            -DLIBUNWIND_ENABLE_SHARED=ON -DLIBUNWIND_ENABLE_STATIC=ON \
            -DLIBCXXABI_USE_LLVM_UNWINDER=ON \
            -DLIBCXX_INCLUDE_BENCHMARKS=OFF \
            -DLIBCXX_INCLUDE_TESTS=OFF \
            -DLIBCXXABI_INCLUDE_TESTS=OFF \
            -DLIBUNWIND_INCLUDE_TESTS=OFF \
            -DCMAKE_INSTALL_PREFIX=${install_prefix} \
            ${sysroot_flags} ${musl_flags} ${extra_flags} \
            ${linker_flags:+-DCMAKE_SHARED_LINKER_FLAGS="${linker_flags}"} && \
        ninja -C /tmp/build-libcxx-${target} && \
        ninja -C /tmp/build-libcxx-${target} install && \
        rm -rf /tmp/build-libcxx-${target}; \
    done

# Clean up LLVM sources — no longer needed after all libc++ targets are built
RUN rm -rf /tmp/llvm-src

# =============================================================================
# Stage 5: Compiler and linker wrappers for all 10 cross-compilation targets
#
# Compiler wrappers (clang-<target>, clang++-<target>):
#   Smart wrappers detect compile-only vs link mode, inject -fuse-ld=lld.
#   clang++ wrappers also add -stdlib=libc++ by default (unless user overrides).
#   Cross-Linux targets use -rtlib=compiler-rt --unwindlib=none (replaces GCC runtime).
#
# Linker wrappers (lld-<target>, lld-link-<target>):
#   Used by Rust (CARGO_TARGET_*_LINKER) and other tools that call the linker directly.
#   Linux/macOS: clang as linker driver — translates GCC-style flags for lld
#   Windows MSVC: lld-link with xwin lib paths
#   Windows GNU: smart GCC-to-MSVC arg translation + lld-link
# =============================================================================

# libssp_nonshared.a stubs for glibc sysroots
# Alpine clang injects -lssp_nonshared for all targets; glibc sysroots lack it.
# Empty archive satisfies the linker without pulling in any symbols.
RUN llvm-ar rc /usr/x86_64-linux-gnu/usr/lib/libssp_nonshared.a && \
    llvm-ar rc /usr/aarch64-linux-gnu/usr/lib/libssp_nonshared.a

# --- Linker wrappers ---

# Linux ELF linkers (clang as driver -> ld.lld)
# All targets use -rtlib=compiler-rt --unwindlib=none (compiler-rt builtins built above).
# This replaces GCC runtime (crtbeginS.o, libgcc, libgcc_s) with our own builtins.
RUN for target in x86_64-linux-musl aarch64-linux-musl x86_64-linux-gnu aarch64-linux-gnu; do \
        case "$target" in \
            x86_64-linux-musl)  sysroot_flag="" ;; \
            aarch64-linux-musl) sysroot_flag="--sysroot=/usr/aarch64-alpine-linux-musl" ;; \
            x86_64-linux-gnu)   sysroot_flag="--sysroot=/usr/x86_64-linux-gnu" ;; \
            aarch64-linux-gnu)  sysroot_flag="--sysroot=/usr/aarch64-linux-gnu" ;; \
        esac && \
        printf '#!/bin/sh\nexec clang --target=%s %s -fuse-ld=lld -rtlib=compiler-rt --unwindlib=none "$@"\n' \
            "$target" "$sysroot_flag" \
            > /usr/local/bin/lld-${target} && \
        chmod +x /usr/local/bin/lld-${target}; \
    done

# macOS Mach-O linkers (clang as driver -> ld64.lld)
# No -nostdlib/-rtlib: clang must auto-link libSystem (provides abort, malloc, etc.)
# SDK contains usr/lib/libSystem.tbd which ld64.lld resolves via --sysroot.
# -mmacosx-version-min=11.0: default deployment target (Big Sur+, minimum for arm64).
# Users can override by passing a later -mmacosx-version-min — clang takes the last one.
RUN for arch in x86_64 aarch64; do \
        printf '#!/bin/sh\nexec clang --target=%s-apple-darwin -mmacosx-version-min=11.0 --sysroot=/usr/macosx.sdk -fuse-ld=lld "$@"\n' \
            "$arch" \
            > /usr/local/bin/lld-${arch}-apple-darwin && \
        chmod +x /usr/local/bin/lld-${arch}-apple-darwin; \
    done

# Windows MSVC linkers (lld-link with xwin lib paths)
RUN for arch in x86_64 aarch64; do \
    printf '#!/bin/sh\nexec lld-link /libpath:/usr/windows.sdk/crt/lib/%s /libpath:/usr/windows.sdk/sdk/lib/um/%s /libpath:/usr/windows.sdk/sdk/lib/ucrt/%s "$@"\n' \
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
        'link_args="/libpath:/usr/windows.sdk/crt/lib/ARCH /libpath:/usr/windows.sdk/sdk/lib/um/ARCH /libpath:/usr/windows.sdk/sdk/lib/ucrt/ARCH libcmt.lib libvcruntime.lib libucrt.lib"' \
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

# --- Smart compiler wrappers ---

# Linux musl and gnu targets (C and C++)
# All targets use -rtlib=compiler-rt --unwindlib=none (compiler-rt builtins built above).
# Cross targets also get --sysroot.
RUN for compiler in clang clang++; do \
    for target in x86_64-linux-musl aarch64-linux-musl x86_64-linux-gnu aarch64-linux-gnu; do \
        # Per-target settings
        sysroot_flag="" && rt_flags="-rtlib=compiler-rt --unwindlib=none" && \
        case "$target" in \
            x86_64-linux-musl)  ;; \
            aarch64-linux-musl) sysroot_flag="--sysroot=/usr/aarch64-alpine-linux-musl" ;; \
            x86_64-linux-gnu)   sysroot_flag="--sysroot=/usr/x86_64-linux-gnu" ;; \
            aarch64-linux-gnu)  sysroot_flag="--sysroot=/usr/aarch64-linux-gnu" ;; \
        esac && \
        # stdlib flag: clang++ adds -stdlib=libc++ unless user overrides
        stdlib_detect="" && stdlib_inject="" && \
        if [ "$compiler" = "clang++" ]; then \
            stdlib_detect='has_stdlib=false; ' && \
            stdlib_inject='-stdlib=libc++' && \
            stdlib_detect="${stdlib_detect}"'for arg in "$@"; do case "$arg" in -stdlib=*) has_stdlib=true ;; esac; done; '; \
        fi && \
        printf '%s\n' \
            '#!/bin/sh' \
            "# Smart ${compiler} wrapper for ${target}" \
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
            > /usr/local/bin/${compiler}-${target} && \
        # Compile-only mode
        if [ "$compiler" = "clang++" ]; then \
            printf '%s\n' \
                'if [ "$compile_only" = "true" ]; then' \
                "    has_stdlib=false; for arg in \"\$@\"; do case \"\$arg\" in -stdlib=*) has_stdlib=true ;; esac; done" \
                "    if [ \"\$has_stdlib\" = \"false\" ]; then" \
                "        exec ${compiler} --target=${target} ${sysroot_flag} -stdlib=libc++ \"\$@\"" \
                '    fi' \
                "    exec ${compiler} --target=${target} ${sysroot_flag} \"\$@\"" \
                'fi' \
                >> /usr/local/bin/${compiler}-${target}; \
        else \
            printf '%s\n' \
                'if [ "$compile_only" = "true" ]; then' \
                "    exec ${compiler} --target=${target} ${sysroot_flag} \"\$@\"" \
                'fi' \
                >> /usr/local/bin/${compiler}-${target}; \
        fi && \
        # Link mode
        if [ "$compiler" = "clang++" ]; then \
            printf '%s\n' \
                '# Link mode: ensure -fuse-ld=lld, add -stdlib=libc++ if not specified' \
                "has_stdlib=false; for arg in \"\$@\"; do case \"\$arg\" in -stdlib=*) has_stdlib=true ;; esac; done" \
                'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
                '    args=""' \
                '    for arg in "$@"; do' \
                '        case "$arg" in' \
                '            -fuse-ld=lld) ;;' \
                '            *)            args="$args $arg" ;;' \
                '        esac' \
                '    done' \
                "    stdlib_flag=\"\"; [ \"\$has_stdlib\" = \"false\" ] && stdlib_flag=\"-stdlib=libc++\"" \
                "    exec ${compiler} --target=${target} ${sysroot_flag} -fuse-ld=lld ${rt_flags} \$stdlib_flag \$args" \
                'else' \
                "    stdlib_flag=\"\"; [ \"\$has_stdlib\" = \"false\" ] && stdlib_flag=\"-stdlib=libc++\"" \
                "    exec ${compiler} --target=${target} ${sysroot_flag} ${rt_flags} \$stdlib_flag \"\$@\"" \
                'fi' \
                >> /usr/local/bin/${compiler}-${target}; \
        else \
            printf '%s\n' \
                '# Link mode: ensure -fuse-ld=lld' \
                'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
                '    args=""' \
                '    for arg in "$@"; do' \
                '        case "$arg" in' \
                '            -fuse-ld=lld) ;;' \
                '            *)            args="$args $arg" ;;' \
                '        esac' \
                '    done' \
                "    exec ${compiler} --target=${target} ${sysroot_flag} -fuse-ld=lld ${rt_flags} \$args" \
                'else' \
                "    exec ${compiler} --target=${target} ${sysroot_flag} ${rt_flags} \"\$@\"" \
                'fi' \
                >> /usr/local/bin/${compiler}-${target}; \
        fi && \
        chmod +x /usr/local/bin/${compiler}-${target}; \
    done; \
    done

# macOS targets (C and C++)
# -w suppresses warnings from macOS SDK headers (deprecated APIs, nullability, availability)
# -mmacosx-version-min=11.0: default deployment target (Big Sur+, minimum for arm64).
# Users can override by passing a later -mmacosx-version-min — clang takes the last one.
RUN SDK=/usr/macosx.sdk && \
    for compiler in clang clang++; do \
    for arch in x86_64 aarch64; do \
        triple="${arch}-apple-darwin" && \
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
            "    exec ${compiler} --target=${triple} -mmacosx-version-min=11.0 --sysroot=${SDK} -F${SDK}/System/Library/Frameworks -I${SDK}/usr/include -w \"\$@\"" \
            'fi' \
            'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
            '    args=""' \
            '    for arg in "$@"; do' \
            '        case "$arg" in' \
            '            -fuse-ld=lld) ;;' \
            '            *)            args="$args $arg" ;;' \
            '        esac' \
            '    done' \
            "    exec ${compiler} --target=${triple} -mmacosx-version-min=11.0 --sysroot=${SDK} -F${SDK}/System/Library/Frameworks -I${SDK}/usr/include -w -fuse-ld=lld \$args" \
            'else' \
            "    exec ${compiler} --target=${triple} -mmacosx-version-min=11.0 --sysroot=${SDK} -F${SDK}/System/Library/Frameworks -I${SDK}/usr/include -w \"\$@\"" \
            'fi' \
            > /usr/local/bin/${compiler}-${arch}-apple-darwin && \
        chmod +x /usr/local/bin/${compiler}-${arch}-apple-darwin; \
    done; \
    done

# Windows MSVC targets (C and C++)
# clang in MSVC-compatible mode (--driver-mode=cl)
# Rust cc crate calls CC with MSVC-style flags (/nologo, /O2, /imsvc, /c).
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
            "    exec clang --driver-mode=cl --target=${arch}-pc-windows-msvc /imsvc/usr/windows.sdk/crt/include /imsvc/usr/windows.sdk/sdk/include/ucrt /imsvc/usr/windows.sdk/sdk/include/um /imsvc/usr/windows.sdk/sdk/include/shared \"\$@\"" \
            'fi' \
            'if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then' \
            '    args=""' \
            '    for arg in "$@"; do' \
            '        case "$arg" in' \
            '            -fuse-ld=lld) ;;' \
            '            *)            args="$args $arg" ;;' \
            '        esac' \
            '    done' \
            "    exec clang --driver-mode=cl --target=${arch}-pc-windows-msvc /imsvc/usr/windows.sdk/crt/include /imsvc/usr/windows.sdk/sdk/include/ucrt /imsvc/usr/windows.sdk/sdk/include/um /imsvc/usr/windows.sdk/sdk/include/shared -fuse-ld=lld \$args" \
            'else' \
            "    exec clang --driver-mode=cl --target=${arch}-pc-windows-msvc /imsvc/usr/windows.sdk/crt/include /imsvc/usr/windows.sdk/sdk/include/ucrt /imsvc/usr/windows.sdk/sdk/include/um /imsvc/usr/windows.sdk/sdk/include/shared \"\$@\"" \
            'fi' \
            > /usr/local/bin/${prefix}-${arch}-windows-msvc && \
        chmod +x /usr/local/bin/${prefix}-${arch}-windows-msvc; \
    done; \
    done

# Windows GNU targets (C and C++)
# Fake-GNU wrappers for Go CGO: GCC-compatible interface, MSVC target internally.
# Detects link mode (output .exe) and calls lld-link directly with translated args.
# Compile mode: filters MinGW flags, forwards to clang with MSVC target.
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
            '    -isystem /usr/windows.sdk/crt/include \' \
            '    -isystem /usr/windows.sdk/sdk/include/ucrt \' \
            '    -isystem /usr/windows.sdk/sdk/include/um \' \
            '    -isystem /usr/windows.sdk/sdk/include/shared \' \
            '    $args' \
            > /usr/local/bin/${compiler}-${arch}-windows-gnu && \
        sed -i "s|ARCH|${arch}|g; s|COMPILER|${compiler}|g" /usr/local/bin/${compiler}-${arch}-windows-gnu && \
        chmod +x /usr/local/bin/${compiler}-${arch}-windows-gnu; \
    done; \
    done

CMD ["/bin/sh"]
