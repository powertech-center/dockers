#!/bin/sh
# 01-tools.sh — Verify LLVM/Clang tools are installed and accessible
. "$(dirname "$0")/helpers.sh"

echo "=== LLVM/Clang tools ==="

# Core compiler
for cmd in clang clang++; do
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$cmd available"
    else
        test_fail "$cmd available" "not found in PATH"
    fi
done

# IDE / code quality
for cmd in clangd clang-format clang-tidy; do
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$cmd available"
    else
        test_fail "$cmd available" "not found in PATH"
    fi
done

# Linker
for cmd in lld ld.lld; do
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$cmd available"
    else
        test_fail "$cmd available" "not found in PATH"
    fi
done

# LLVM utilities
for cmd in llvm-ar llvm-nm llvm-objcopy llvm-objdump llvm-readelf \
           llvm-size llvm-strip llvm-symbolizer \
           llvm-profdata llvm-cov llvm-strings llvm-ranlib; do
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$cmd available"
    else
        test_fail "$cmd available" "not found in PATH"
    fi
done

# Verify clang and lld major versions match
clang_ver=$(clang --version 2>/dev/null | head -1 | grep -oP '\d+\.\d+\.\d+' | head -1)
lld_ver=$(ld.lld --version 2>/dev/null | grep -oP '\d+\.\d+\.\d+' | head -1)
clang_major=$(echo "$clang_ver" | cut -d. -f1)
lld_major=$(echo "$lld_ver" | cut -d. -f1)

if [ -n "$clang_major" ] && [ -n "$lld_major" ] && [ "$clang_major" = "$lld_major" ]; then
    test_pass "clang ($clang_ver) and lld ($lld_ver) major versions match"
else
    test_fail "clang/lld version match" "clang=$clang_ver lld=$lld_ver"
fi

test_summary
