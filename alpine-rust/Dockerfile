# PowerTech Alpine Rust (native)
# Rust development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-rust

FROM ghcr.io/powertech-center/alpine-dev:latest

COPY shared/alpine-rust.sh /tmp/alpine-rust.sh
RUN sh /tmp/alpine-rust.sh && rm /tmp/alpine-rust.sh

ENV PATH="/root/.cargo/bin:${PATH}"

CMD ["/bin/sh"]
