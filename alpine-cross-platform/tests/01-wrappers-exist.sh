#!/bin/sh
# 01-wrappers-exist.sh — Verify all wrapper scripts exist and are executable
. "$(dirname "$0")/helpers.sh"

echo "=== Wrapper existence and permissions ==="

# Compiler wrappers: clang-<target> and clang++-<target>
for target in $(filter_targets $ALL_TARGETS); do
    for prefix in clang clang++; do
        wrapper="/usr/local/bin/${prefix}-${target}"
        if [ -f "$wrapper" ]; then
            if [ -x "$wrapper" ]; then
                test_pass "${prefix}-${target} exists and executable"
            else
                test_fail "${prefix}-${target} not executable" "$wrapper exists but lacks +x"
            fi
        else
            test_fail "${prefix}-${target} missing" "$wrapper not found"
        fi
    done
done

# Linker wrappers: lld-<target> for all targets (uniform naming)
for target in $(filter_targets $ALL_TARGETS); do
    wrapper="/usr/local/bin/lld-${target}"
    if [ -f "$wrapper" ]; then
        if [ -x "$wrapper" ]; then
            test_pass "linker wrapper for ${target} exists and executable"
        else
            test_fail "linker wrapper for ${target} not executable"
        fi
    else
        test_fail "linker wrapper for ${target} missing" "$wrapper not found"
    fi
done

# Utility wrappers: windres and dlltool for Windows GNU targets
for arch in x86_64 aarch64; do
    for tool in windres dlltool; do
        wrapper="/usr/local/bin/${tool}-${arch}-windows-gnu"
        if [ -f "$wrapper" ]; then
            if [ -x "$wrapper" ]; then
                test_pass "${tool}-${arch}-windows-gnu exists and executable"
            else
                test_fail "${tool}-${arch}-windows-gnu not executable"
            fi
        else
            test_fail "${tool}-${arch}-windows-gnu missing" "$wrapper not found"
        fi
    done
done

test_summary
