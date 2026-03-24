#!/bin/sh
# 01-dev-packages.sh — Verify LLVM/Clang development packages are installed
. "$(dirname "$0")/helpers.sh"

echo "=== LLVM/Clang development packages ==="

# Check key commands exist
for cmd in clang clang++ lld llvm-ar llvm-config; do
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$cmd available"
    else
        test_fail "$cmd available" "not found in PATH"
    fi
done

# Check llvm-config reports expected components
if command -v llvm-config >/dev/null 2>&1; then
    # Check that include dir exists
    inc=$(llvm-config --includedir 2>/dev/null)
    if [ -d "$inc" ]; then
        test_pass "LLVM include dir exists ($inc)"
    else
        test_fail "LLVM include dir exists" "llvm-config --includedir returned '$inc'"
    fi

    # Check that lib dir exists
    lib=$(llvm-config --libdir 2>/dev/null)
    if [ -d "$lib" ]; then
        test_pass "LLVM lib dir exists ($lib)"
    else
        test_fail "LLVM lib dir exists" "llvm-config --libdir returned '$lib'"
    fi
else
    test_skip "LLVM include/lib dirs" "llvm-config not available"
fi

# Check clang-dev headers
for header in /usr/lib/llvm*/include/clang/Basic/Version.h; do
    if [ -f "$header" ]; then
        test_pass "clang-dev headers present ($header)"
        break
    fi
done

# Check compiler-rt is installed
if [ -d /usr/lib/clang ] || [ -d /usr/lib/llvm*/lib/clang ]; then
    test_pass "compiler-rt installed"
else
    test_fail "compiler-rt installed" "no /usr/lib/clang directory found"
fi

test_summary
