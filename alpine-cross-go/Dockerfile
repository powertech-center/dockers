# PowerTech Alpine Go
# Go development and cross-compilation environment
# 6 CGO cross-compilation targets: Linux musl, macOS, Windows GNU (x64/arm64 each)
#
# Smart compiler wrappers auto-inject -fuse-ld=lld when linking is detected.
# No CGO_LDFLAGS needed — just set CC=clang-<arch>-<os>.
#
# Image: ghcr.io/powertech-center/alpine-cross-go

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

# Install Go toolchain and set up GOPATH
COPY shared/alpine-go.sh /tmp/alpine-go.sh
RUN sh /tmp/alpine-go.sh && rm /tmp/alpine-go.sh

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

# Install Go tools as 'dev' user so binaries land in /go/bin (GOPATH)
COPY shared/go-tools.sh /tmp/go-tools.sh
USER dev
RUN sh /tmp/go-tools.sh
USER root
RUN rm /tmp/go-tools.sh

# =============================================================================
# CGo cross-compilation environment variables
# CGO_CC_<goos>_<goarch>  — C compiler for each CGO cross-compilation target
# CGO_CXX_<goos>_<goarch> — C++ compiler (for SWIG / .swigcxx packages)
#
# Usage:
#   GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=$CGO_CC_linux_amd64 go build
#   GOOS=linux GOARCH=amd64 CGO_ENABLED=1 CC=$CGO_CC_linux_amd64 CXX=$CGO_CXX_linux_amd64 go build
# =============================================================================

# Linux (musl libc — produces fully static, portable binaries)
ENV CGO_CC_linux_amd64=clang-x86_64-linux-musl
ENV CGO_CXX_linux_amd64=clang++-x86_64-linux-musl
ENV CGO_CC_linux_arm64=clang-aarch64-linux-musl
ENV CGO_CXX_linux_arm64=clang++-aarch64-linux-musl

# macOS
ENV CGO_CC_darwin_amd64=clang-x86_64-apple-darwin
ENV CGO_CXX_darwin_amd64=clang++-x86_64-apple-darwin
ENV CGO_CC_darwin_arm64=clang-aarch64-apple-darwin
ENV CGO_CXX_darwin_arm64=clang++-aarch64-apple-darwin

# Windows (GCC-compatible driver, MSVC sysroot, no MinGW DLLs)
ENV CGO_CC_windows_amd64=clang-x86_64-windows-gnu
ENV CGO_CXX_windows_amd64=clang++-x86_64-windows-gnu
ENV CGO_CC_windows_arm64=clang-aarch64-windows-gnu
ENV CGO_CXX_windows_arm64=clang++-aarch64-windows-gnu

# CGo cross-compilation usage:
#   GOOS=linux   GOARCH=amd64 CGO_ENABLED=1 CC=$CGO_CC_linux_amd64  go build
#   GOOS=linux   GOARCH=arm64 CGO_ENABLED=1 CC=$CGO_CC_linux_arm64  go build
#   GOOS=darwin  GOARCH=amd64 CGO_ENABLED=1 CC=$CGO_CC_darwin_amd64 go build
#   GOOS=darwin  GOARCH=arm64 CGO_ENABLED=1 CC=$CGO_CC_darwin_arm64 go build
#   GOOS=windows GOARCH=amd64 CGO_ENABLED=1 CC=$CGO_CC_windows_amd64 go build
#   GOOS=windows GOARCH=arm64 CGO_ENABLED=1 CC=$CGO_CC_windows_arm64 go build

CMD ["/bin/sh"]
