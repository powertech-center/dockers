#!/bin/sh
# Tests for clang image — distro-independent
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

echo "=== clang tests ==="

# -- Compilers --
echo ""
echo "--- Compilers ---"
check "clang available"                clang --version
check "clang++ available"              clang++ --version

# -- Linker --
echo ""
echo "--- Linker ---"
check "ld.lld available"               ld.lld --version

# -- LLVM tools --
echo ""
echo "--- LLVM tools ---"
check "llvm-ar available"              llvm-ar --version
check "llvm-config available"          llvm-config --version

# -- LLVM development --
echo ""
echo "--- LLVM development ---"
check "LLVM include dir exists"        test -d "$(llvm-config --includedir 2>/dev/null || echo /nonexistent)"
check "LLVM lib dir exists"            test -d "$(llvm-config --libdir 2>/dev/null || echo /nonexistent)"
check "compiler-rt installed"          test -d /usr/lib/clang -o -d /usr/lib/llvm/lib/clang

# -- Summary --
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
