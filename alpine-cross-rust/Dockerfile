# PowerTech Alpine Rust
# Rust development and cross-compilation environment
# Uses cargo-zigbuild for Linux/macOS, inherited xwin+clang-cl for Windows MSVC
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

RUN cargo install cargo-zigbuild --locked && \
    cargo install cargo-audit --locked

# llvm-lib: MSVC-compatible archiver for C deps (e.g. zstd-sys) on windows-msvc targets
# llvm-ar creates COFF archives when invoked as llvm-lib
RUN apk add --no-cache llvm && \
    ln -sf /usr/bin/llvm-ar /usr/local/bin/llvm-lib

# AR_* — archiver for each Windows MSVC target
# Used by: Rust cc crate when building static C libraries
ENV AR_x86_64_pc_windows_msvc=llvm-lib
ENV AR_aarch64_pc_windows_msvc=llvm-lib

# CC_* — C compiler for Windows MSVC targets
# Used by: Rust cc crate when compiling C dependencies (e.g. zstd-sys, ring)
# clang-cl accepts MSVC-compatible --target flags
ENV CC_x86_64_pc_windows_msvc=clang-cl
ENV CC_aarch64_pc_windows_msvc=clang-cl

# CFLAGS_* — compiler flags for Windows MSVC targets (xwin SDK/CRT include paths)
ENV CFLAGS_x86_64_pc_windows_msvc="--target=x86_64-pc-windows-msvc /imsvc/xwin/crt/include /imsvc/xwin/sdk/include/ucrt /imsvc/xwin/sdk/include/um /imsvc/xwin/sdk/include/shared"
ENV CFLAGS_aarch64_pc_windows_msvc="--target=aarch64-pc-windows-msvc /imsvc/xwin/crt/include /imsvc/xwin/sdk/include/ucrt /imsvc/xwin/sdk/include/um /imsvc/xwin/sdk/include/shared"

# Cross-compilation config: linker and xwin library paths per target
# Written to $CARGO_HOME/config.toml so project's .cargo/config.toml takes priority
# (project rustflags override image defaults; linker/lib paths are infrastructure)
RUN mkdir -p /root/.cargo && cat >> /root/.cargo/config.toml << 'EOF'

# === PowerTech cross-compilation defaults (alpine-cross-rust) ===
# Note: x86_64-unknown-linux-musl is the host platform — no custom linker needed,
# rust uses the default (gcc from alpine-dev).

[target.aarch64-unknown-linux-musl]
linker = "zig-cc-aarch64-linux-musl"

[target.x86_64-apple-darwin]
linker = "zig-cc-x86_64-macos"

[target.aarch64-apple-darwin]
linker = "zig-cc-aarch64-macos"

[target.x86_64-pc-windows-msvc]
linker = "rust-lld"
rustflags = [
    "-C", "linker-flavor=lld-link",
    "-Lnative=/xwin/crt/lib/x86_64",
    "-Lnative=/xwin/sdk/lib/um/x86_64",
    "-Lnative=/xwin/sdk/lib/ucrt/x86_64",
]

[target.aarch64-pc-windows-msvc]
linker = "rust-lld"
rustflags = [
    "-C", "linker-flavor=lld-link",
    "-Lnative=/xwin/crt/lib/aarch64",
    "-Lnative=/xwin/sdk/lib/um/aarch64",
    "-Lnative=/xwin/sdk/lib/ucrt/aarch64",
]
EOF

CMD ["/bin/sh"]
