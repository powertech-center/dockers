#!/bin/sh
# 04-clangd.sh — Verify clangd (Language Server Protocol) is available
. "$(dirname "$0")/helpers.sh"

echo "=== clangd ==="

# ── clangd binary ──
if command -v clangd >/dev/null 2>&1; then
    test_pass "clangd available"
else
    test_fail "clangd available" "not found in PATH"
    test_summary
    exit $?
fi

# ── clangd responds to --version ──
desc="clangd reports version"
ver_output=$(clangd --version 2>&1)
if [ $? -eq 0 ] && echo "$ver_output" | grep -qi "clangd"; then
    ver=$(echo "$ver_output" | grep -oP '\d+\.\d+\.\d+' | head -1)
    test_pass "$desc ($ver)"
else
    test_fail "$desc" "output: $ver_output"
fi

# ── clangd version matches clang ──
clang_major=$(clang --version 2>/dev/null | grep -oP 'clang version \K\d+')
clangd_major=$(echo "$ver_output" | grep -oP '\d+' | head -1)
if [ -n "$clang_major" ] && [ -n "$clangd_major" ] && [ "$clang_major" = "$clangd_major" ]; then
    test_pass "clangd major version matches clang ($clang_major)"
else
    test_fail "clangd/clang version match" "clang=$clang_major clangd=$clangd_major"
fi

test_summary
