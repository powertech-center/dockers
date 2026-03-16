#!/bin/sh
# alpine-go.sh — Go toolchain installation
# Used by: alpine-go, alpine-cross-go
#
# Installs the latest stable Go release, sets up GOPATH,
# and installs common Go tools for IDE support and development workflow.

set -e

# Install Go toolchain
GO_VERSION=$(wget -qO- https://go.dev/VERSION?m=text | head -1 | sed 's/^go//')
wget https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz
tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz
rm go${GO_VERSION}.linux-amd64.tar.gz

# Prepare GOPATH for the non-root 'dev' user (created in alpine-dev)
mkdir -p /go && chown dev:dev /go
