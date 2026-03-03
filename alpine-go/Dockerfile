# PowerTech Alpine Go (native)
# Go development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-go

FROM ghcr.io/powertech-center/alpine-dev:latest

RUN GO_VERSION=$(wget -qO- https://go.dev/VERSION?m=text | head -1 | sed 's/^go//') && \
    wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:/go/bin:${PATH}"
ENV GOPATH="/go"

CMD ["/bin/sh"]
