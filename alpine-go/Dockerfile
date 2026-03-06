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

# Prepare GOPATH for the non-root 'dev' user (created in alpine-dev)
RUN mkdir -p /go && chown dev:dev /go

# Go tools for IDE support and development workflow
USER dev
RUN go install golang.org/x/tools/gopls@latest && \
    go install github.com/go-delve/delve/cmd/dlv@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install honnef.co/go/tools/cmd/staticcheck@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install golang.org/x/vuln/cmd/govulncheck@latest && \
    go install gotest.tools/gotestsum@latest
USER root

CMD ["/bin/sh"]
