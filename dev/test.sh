#!/bin/sh
# Tests for dev image — distro-independent
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

echo "=== dev tests ==="

# -- Build tools --
echo ""
echo "--- Build tools ---"
check "make available"              make --version
check "cmake available"             cmake --version
check "ninja available"             ninja --version

# -- Compilers --
echo ""
echo "--- Compilers ---"
check "gcc available"               gcc --version
check "g++ available"               g++ --version

# -- Compile & link smoke test --
echo ""
echo "--- Compile & link ---"
check "C compile + run" sh -c '
    echo "int main(){return 0;}" > /tmp/test.c &&
    gcc -o /tmp/test /tmp/test.c &&
    /tmp/test &&
    rm -f /tmp/test.c /tmp/test'
check "C++ compile + run" sh -c '
    echo "int main(){return 0;}" > /tmp/test.cpp &&
    g++ -o /tmp/test /tmp/test.cpp &&
    /tmp/test &&
    rm -f /tmp/test.cpp /tmp/test'

# -- Development libraries --
echo ""
echo "--- Development libraries ---"
check "pkg-config available"        pkg-config --version || pkgconf --version
check "linux headers present"       test -d /usr/include/linux

# -- Python --
echo ""
echo "--- Python ---"
check "python3 available"           python3 --version
check "pip available"               pip --version || pip3 --version
check "debugpy installed"           python3 -c "import debugpy"

# -- Debugger --
echo ""
echo "--- Debugger ---"
check "gdb available"               gdb --version
check "strace available"            strace --version || strace -V

# -- PowerShell --
echo ""
echo "--- PowerShell ---"
check "pwsh available"              pwsh --version

# -- User --
echo ""
echo "--- User ---"
check "dev user exists"             id dev

# -- Crossler --
echo ""
echo "--- Crossler ---"
check "nfpm available"              nfpm --version

# -- Summary --
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
