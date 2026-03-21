#!/bin/sh
# 02-cross-wrappers.sh — Verify clang cross-compilation wrappers exist for NativeAOT targets
. "$(dirname "$0")/helpers.sh"

echo "=== Cross-compilation wrappers for NativeAOT ==="

# Check that each NativeAOT target's clang wrapper exists and is executable
for entry in $AOT_TARGETS; do
    rid=$(echo "$entry" | cut -d: -f1)
    compiler=$(echo "$entry" | cut -d: -f2)
    sysroot=$(echo "$entry" | cut -d: -f3)

    if [ -n "$TARGET_FILTER" ]; then
        case "$rid" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    # Check compiler wrapper
    if command -v "$compiler" >/dev/null 2>&1; then
        test_pass "$compiler exists (for $rid)"
    else
        test_fail "$compiler exists (for $rid)" "not found in PATH"
    fi

    # Check sysroot directory
    if [ -d "$sysroot" ]; then
        test_pass "sysroot $sysroot exists (for $rid)"
    else
        test_fail "sysroot $sysroot exists (for $rid)" "directory not found"
    fi
done

test_summary
