# PowerTech Alpine Rust (native)
# Rust development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-rust

FROM ghcr.io/powertech-center/alpine-dev:latest

RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/alpine-rust.sh

ENV PATH="/root/.cargo/bin:${PATH}"

CMD ["/bin/sh"]
