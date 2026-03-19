#!/bin/sh
# 02-llvm-headers.sh — Test that LLVM development headers compile correctly
. "$(dirname "$0")/helpers.sh"

echo "=== LLVM development headers compilation ==="

# Test: compile a file that includes LLVM headers (compile-only)
desc="compile with LLVM headers (host)"

# Get LLVM flags from llvm-config
if ! command -v llvm-config >/dev/null 2>&1; then
    test_skip "$desc" "llvm-config not available"
    test_summary
    exit $?
fi

cxxflags=$(llvm-config --cxxflags 2>/dev/null)
obj="$WORKDIR/use_llvm.o"
stderr=$(clang++ $cxxflags -c "$SRCDIR/use_llvm.cpp" -o "$obj" 2>&1)
rc=$?

if [ $rc -eq 0 ] && [ -f "$obj" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "exit code $rc, stderr: $stderr"
fi

# Test: link with LLVM libraries (host only)
desc="link with LLVM libraries (host)"

ldflags=$(llvm-config --ldflags --libs support 2>/dev/null)
syslibs=$(llvm-config --system-libs 2>/dev/null)
output="$WORKDIR/use_llvm"
stderr=$(clang++ $cxxflags "$SRCDIR/use_llvm.cpp" $ldflags $syslibs -o "$output" 2>&1)
rc=$?

if [ $rc -eq 0 ] && [ -f "$output" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "exit code $rc, stderr: $(echo "$stderr" | head -3)"
fi

test_summary
