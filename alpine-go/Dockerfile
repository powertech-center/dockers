# PowerTech Alpine Go (native)
# Go development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-go

FROM ghcr.io/powertech-center/alpine-dev:latest

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

CMD ["/bin/sh"]
