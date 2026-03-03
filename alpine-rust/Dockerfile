# PowerTech Alpine Rust (native)
# Rust development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-rust

FROM ghcr.io/powertech-center/alpine-dev:latest

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | \
    sh -s -- -y --default-toolchain stable

ENV PATH="/root/.cargo/bin:${PATH}"

RUN rustup component add rustfmt clippy && \
    cargo install cargo-audit --locked

CMD ["/bin/sh"]
