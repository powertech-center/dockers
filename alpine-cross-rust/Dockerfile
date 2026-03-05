# PowerTech Alpine Rust
# Rust development and cross-compilation environment
# All 6 targets use cargo build with clang cross-compilers (from alpine-cross-platform):
#   Linux/macOS: clang-<arch>-<os> wrappers + lld-<arch>-<os> linkers
#   Windows MSVC: clang-<arch>-windows-msvc (clang --driver-mode=cl) + lld-link-<arch>-windows-msvc
#
# Image: ghcr.io/powertech-center/alpine-cross-rust

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable

ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup component add rustfmt clippy llvm-tools && \
    rustup target add \
    x86_64-unknown-linux-musl \
    aarch64-unknown-linux-musl \
    x86_64-pc-windows-msvc \
    aarch64-pc-windows-msvc \
    x86_64-apple-darwin \
    aarch64-apple-darwin

RUN cargo install cargo-audit --locked

# llvm-lib: MSVC-compatible archiver for C deps (e.g. zstd-sys) on windows-msvc targets
# llvm-ar creates COFF archives when invoked as llvm-lib
# llvm package also provides llvm-ar; lld is already installed from alpine-cross-platform
RUN apk add --no-cache llvm && \
    ln -sf /usr/bin/llvm-ar /usr/local/bin/llvm-lib

# =============================================================================
# C compiler environment variables (Rust cc crate)
# CC_<target>  — C compiler wrapper for each cross-compilation target
# CXX_<target> — C++ compiler wrapper for each cross-compilation target
# Wrappers are defined in alpine-cross-platform.
# =============================================================================

# Linux musl targets
ENV CC_x86_64_unknown_linux_musl=clang-x86_64-linux-musl
ENV CXX_x86_64_unknown_linux_musl=clang++-x86_64-linux-musl
ENV CC_aarch64_unknown_linux_musl=clang-aarch64-linux-musl
ENV CXX_aarch64_unknown_linux_musl=clang++-aarch64-linux-musl

# macOS targets
ENV CC_x86_64_apple_darwin=clang-x86_64-apple-darwin
ENV CXX_x86_64_apple_darwin=clang++-x86_64-apple-darwin
ENV CC_aarch64_apple_darwin=clang-aarch64-apple-darwin
ENV CXX_aarch64_apple_darwin=clang++-aarch64-apple-darwin

# Windows MSVC targets (clang --driver-mode=cl wrappers from alpine-cross-platform)
ENV CC_x86_64_pc_windows_msvc=clang-x86_64-windows-msvc
ENV CC_aarch64_pc_windows_msvc=clang-aarch64-windows-msvc

# AR for Windows MSVC targets
ENV AR_x86_64_pc_windows_msvc=llvm-lib
ENV AR_aarch64_pc_windows_msvc=llvm-lib

# =============================================================================
# Linker environment variables (Cargo)
# CARGO_TARGET_<TRIPLE>_LINKER — linker for each target
# Linux: lld-<arch>-linux-musl wrappers (ld.lld)
# macOS: lld-<arch>-apple-darwin wrappers (ld64.lld)
# Windows MSVC: lld-link-<arch>-windows-msvc wrappers (lld-link)
# All linker wrappers are defined in alpine-cross-platform.
# =============================================================================

# Linux musl linkers
ENV CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER=lld-x86_64-linux-musl
ENV CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER=lld-aarch64-linux-musl

# macOS linkers
ENV CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER=lld-x86_64-apple-darwin
ENV CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER=lld-aarch64-apple-darwin

# Windows MSVC linkers
# ENV takes highest priority in Cargo config and works regardless of CARGO_HOME
# (GitLab CI overrides CARGO_HOME to project dir for caching, which hides ~/.cargo/config.toml)
ENV CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER=lld-link-x86_64-windows-msvc
ENV CARGO_TARGET_AARCH64_PC_WINDOWS_MSVC_LINKER=lld-link-aarch64-windows-msvc

CMD ["/bin/sh"]
