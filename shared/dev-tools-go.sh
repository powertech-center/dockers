#!/bin/sh
# Shared Go tools installation
# Used by: go, cross-go
#
# Installs Go tools for IDE support and development workflow.
# Runs as root; GOPATH (/go) is made writable for all users afterward.

set -e

# Language server (IDE support)
go install golang.org/x/tools/gopls@latest

# Debugger
go install github.com/go-delve/delve/cmd/dlv@latest

# Import formatter
go install golang.org/x/tools/cmd/goimports@latest

# Static analysis
go install honnef.co/go/tools/cmd/staticcheck@latest

# Linter aggregator
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Vulnerability scanner
go install golang.org/x/vuln/cmd/govulncheck@latest

# Test runner with better output
go install gotest.tools/gotestsum@latest
