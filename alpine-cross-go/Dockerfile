# PowerTech Alpine Go
# Go development and cross-compilation environment
# Inherits Zig cross-compilation for all 6 targets from alpine-cross-platform
#
# Image: ghcr.io/powertech-center/alpine-cross-go

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

RUN GO_VERSION=$(wget -qO- https://go.dev/VERSION?m=text | head -1 | sed 's/^go//') && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

# CGo cross-compilation: set CC manually per build, e.g.:
#   GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=zig-cc-aarch64-linux-musl go build
#   GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 CC=zig-cc-x86_64-macos go build
# Available zig-cc wrappers (from alpine-cross-platform):
#   zig-cc-x86_64-linux-musl, zig-cc-aarch64-linux-musl
#   zig-cc-x86_64-macos, zig-cc-aarch64-macos
#   zig-cc-x86_64-windows-gnu, zig-cc-aarch64-windows-gnu

CMD ["/bin/sh"]
