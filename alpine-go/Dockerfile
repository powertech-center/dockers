# PowerTech Alpine Go
# Go development and cross-compilation environment
# Inherits Zig cross-compilation for all 6 targets from alpine-crossplatform
#
# Image: ghcr.io/powertech-center/alpine-go

FROM ghcr.io/powertech-center/alpine-crossplatform:latest

ARG GO_VERSION=1.25.5
RUN wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

CMD ["/bin/sh"]
