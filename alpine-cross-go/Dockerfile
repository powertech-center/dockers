# PowerTech Alpine Go
# Go development and cross-compilation environment
# Inherits Zig cross-compilation for all 6 targets from alpine-crossplatform
#
# Image: ghcr.io/powertech-center/alpine-cross-go

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

RUN GO_VERSION=$(wget -qO- https://go.dev/VERSION?m=text | head -1 | sed 's/^go//') && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

CMD ["/bin/sh"]
