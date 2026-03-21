# PowerTech Alpine Go (native)
# Go development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-go

FROM ghcr.io/powertech-center/alpine-dev:latest

# Install Go toolchain and set up GOPATH
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/alpine-go.sh

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

# Install Go tools as 'dev' user so binaries land in /go/bin (GOPATH)
USER dev
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/go-dev-tools.sh
USER root

CMD ["/bin/sh"]
