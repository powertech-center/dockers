# PowerTech Alpine Rust (native)
# Rust development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-rust

FROM ghcr.io/powertech-center/alpine-dev:latest

ENV RUSTUP_HOME=/opt/rust/rustup
ENV CARGO_HOME=/opt/rust/cargo

RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/alpine-rust.sh

ENV PATH="${CARGO_HOME}/bin:${PATH}"

CMD ["/bin/sh"]
