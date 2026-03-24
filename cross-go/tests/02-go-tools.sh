#!/bin/sh
# 02-go-tools.sh — Verify Go toolchain and dev tools are installed
. "$(dirname "$0")/helpers.sh"

echo "=== Go toolchain and tools ==="

# Check Go is available
if command -v go >/dev/null 2>&1; then
    version=$(go version 2>&1)
    test_pass "go available ($version)"
else
    test_fail "go available" "go not found in PATH"
fi

# Check dev tools
for tool in gopls goimports staticcheck; do
    if command -v "$tool" >/dev/null 2>&1; then
        test_pass "$tool available"
    else
        test_skip "$tool available" "not installed (optional)"
    fi
done

test_summary
