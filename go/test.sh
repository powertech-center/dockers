#!/bin/sh
# Tests for go image — distro-independent
set -e

PASS=0
FAIL=0

check() {
    desc="$1"; shift
    if "$@" > /dev/null 2>&1; then
        echo "  PASS  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Go toolchain tests ==="

# -- Toolchain --
echo ""
echo "--- Toolchain ---"
check "go available"        go version
check "GOPATH set"          test -n "$GOPATH"
check "GOPATH writable"     test -w "$GOPATH"

# -- Dev tools --
echo ""
echo "--- Dev tools ---"
check "gopls available"         gopls version
check "dlv available"           dlv version
check "goimports available"     command -v goimports
check "staticcheck available"   staticcheck --version
check "golangci-lint available" golangci-lint --version
check "govulncheck available"   govulncheck --version
check "gotestsum available"     gotestsum --version

# -- Compile test --
echo ""
echo "--- Compile test ---"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/main.go" <<'GO'
package main

import "fmt"

func main() {
    fmt.Println("Hello from Go")
}
GO

if go build -o "$tmpdir/hello" "$tmpdir/main.go" 2>/dev/null; then
    check "go build succeeds"   true
    output=$("$tmpdir/hello" 2>&1)
    if echo "$output" | grep -q "Hello from Go"; then
        check "binary runs correctly" true
    else
        check "binary runs correctly" false
    fi
else
    check "go build succeeds" false
fi

# -- Summary --
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
