# PowerTech Alpine Go
# Go development and cross-compilation environment
# Inherits clang cross-compilation for all 6 targets from alpine-cross-platform
#
# Smart compiler wrappers auto-inject -fuse-ld=lld when linking is detected.
# No CGO_LDFLAGS needed — just set CC=clang-<arch>-<os>.
#
# Image: ghcr.io/powertech-center/alpine-cross-go

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

RUN GO_VERSION=$(wget -qO- https://go.dev/VERSION?m=text | head -1 | sed 's/^go//') && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

# CGo cross-compilation: set CC per build. Smart wrappers handle everything else.
# Available clang wrappers (from alpine-cross-platform):
#
#   Linux:
#     GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-linux-musl go build
#     GOOS=linux GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-linux-musl go build
#
#   macOS:
#     GOOS=darwin GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-apple-darwin go build
#     GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-apple-darwin go build
#
#   Windows GNU (GCC-compatible driver, MSVC sysroot, no MinGW DLLs):
#     GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=clang-x86_64-windows-gnu go build
#     GOOS=windows GOARCH=arm64 CGO_ENABLED=1 CC=clang-aarch64-windows-gnu go build

CMD ["/bin/sh"]
