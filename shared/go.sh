#!/bin/sh
# go.sh — Go toolchain and dev tools installation
# Used by: go, cross-go
#
# Installs the latest stable Go release, sets up GOPATH,
# and installs common Go tools for IDE support and development workflow.

set -e

# Install Go toolchain
GO_VERSION=$(wget -qO- https://go.dev/VERSION?m=text | head -1 | sed 's/^go//')
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Prepare GOPATH — writable for all users (dev, root, CI runners, etc.)
mkdir -p /go && chmod 777 /go

# ── Dev tools (IDE support, linting, debugging) ─────────────────────────────
export PATH="/usr/local/go/bin:/go/bin:${PATH}"
export GOPATH="/go"

go install golang.org/x/tools/gopls@latest
go install github.com/go-delve/delve/cmd/dlv@latest
go install golang.org/x/tools/cmd/goimports@latest
go install honnef.co/go/tools/cmd/staticcheck@latest
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
go install golang.org/x/vuln/cmd/govulncheck@latest
go install gotest.tools/gotestsum@latest
