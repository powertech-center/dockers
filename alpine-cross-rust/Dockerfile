# PowerTech Alpine Rust
# Rust development and cross-compilation environment
# Uses cargo-zigbuild for Linux/macOS, inherited xwin+clang-cl for Windows MSVC
#
# Image: ghcr.io/powertech-center/alpine-cross-rust

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable

ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup component add rustfmt clippy && \
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

CMD ["/bin/sh"]
