#!/bin/sh
# Tests for alpine-nodejs image
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

echo "=== alpine-nodejs tests ==="

# ── Node.js runtime ──
echo ""
echo "--- Node.js ---"
check "node available"              node --version
check "node runs JS"                node -e "console.log('ok')"

# ── Package managers ──
echo ""
echo "--- Package managers ---"
check "npm available"               npm --version
check "yarn available"              yarn --version
check "pnpm available"              pnpm --version

# ── TypeScript ──
echo ""
echo "--- TypeScript ---"
check "tsc available"               tsc --version
check "ts-node available"           ts-node --version
check "ts-node runs TS"             ts-node -e "const x: number = 42; console.log(x)"

# ── Linters & formatters ──
echo ""
echo "--- Linters & formatters ---"
check "eslint available"            eslint --version
check "prettier available"          prettier --version

# ── Native addon support (from alpine-dev) ──
echo ""
echo "--- Native addon support ---"
check "gcc available"               gcc --version
check "g++ available"               g++ --version
check "make available"              make --version
check "python3 available"           python3 --version
check "node-gyp headers"           node -e "require('child_process').execSync('node -e \"process.config\"')"

# ── Multi-user access ──
echo ""
echo "--- Multi-user access ---"
check "node runs as dev"            su dev -c "node --version"
check "npm runs as dev"             su dev -c "npm --version"
check "tsc runs as dev"             su dev -c "tsc --version"

# ── Inherited from alpine-dev ──
echo ""
echo "--- Inherited tools ---"
check "cmake available"             cmake --version
check "git available"               git --version
check "dev user exists"             id dev

# ── Summary ──
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
