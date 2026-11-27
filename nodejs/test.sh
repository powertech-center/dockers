#!/bin/sh
# Tests for nodejs image — distro-independent
set -e

PASS=0
FAIL=0

check() {
    desc="$1"; shift
    if output=$("$@" 2>&1); then
        echo "  PASS  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $desc"
        printf '%s\n' "$output"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Node.js tests ==="

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
check "tsx available"               tsx --version

TEST_DIR=$(mktemp -d)
trap 'rm -rf "$TEST_DIR"' EXIT HUP INT TERM
# Accessible to dev; fixtures require transformation beyond Node's type stripping.
chmod 755 "$TEST_DIR"
cat > "$TEST_DIR/main.cts" <<'EOF'
enum Answer { Value = 42 }
const value: number = Answer.Value;
if (value !== 42) throw new Error('unexpected TypeScript result');
EOF
cp "$TEST_DIR/main.cts" "$TEST_DIR/main.mts"
printf '%s\n' 'const value: number = "invalid";' > "$TEST_DIR/invalid.ts"

reject_type_error() {
    if diagnostic=$(tsc --noEmit --strict --pretty false "$TEST_DIR/invalid.ts" 2>&1); then
        echo "tsc accepted an invalid assignment"
        return 1
    fi
    printf '%s\n' "$diagnostic"
    printf '%s\n' "$diagnostic" | grep -q 'error TS2322:'
}

check "tsc checks valid TS"         tsc --noEmit --strict --module nodenext "$TEST_DIR/main.cts"
check "tsc rejects type errors"     reject_type_error
check "tsc compiles TS"             tsc --strict --module nodenext --outDir "$TEST_DIR/out" "$TEST_DIR/main.cts"
check "compiled TS runs"            node "$TEST_DIR/out/main.cjs"
check "tsx runs CommonJS TS"        tsx "$TEST_DIR/main.cts"
check "tsx runs ES module TS"       tsx "$TEST_DIR/main.mts"

# ── Linters & formatters ──
echo ""
echo "--- Linters & formatters ---"
check "eslint available"            eslint --version
check "prettier available"          prettier --version

# ── Native addon support (from dev) ──
echo ""
echo "--- Native addon support ---"
check "gcc available"               gcc --version
check "g++ available"               g++ --version
check "make available"              make --version
check "python3 available"           python3 --version

# ── Multi-user access ──
echo ""
echo "--- Multi-user access ---"
check "node runs as dev"            su dev -c "node --version"
check "npm runs as dev"             su dev -c "npm --version"
check "tsc runs as dev"             su dev -c "tsc --version"
check "tsx runs TS as dev"          su dev -c "tsx '$TEST_DIR/main.cts'"

# ── Summary ──
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
