#!/bin/sh
# 07-windows-headers.sh — Windows SDK header inclusion tests
# Verifies:
#   - windows.h compiles for MSVC targets (xwin headers)
#   - windows.h compiles for GNU targets (native mingw-w64 headers)
#   - No warnings from SDK headers
. "$(dirname "$0")/helpers.sh"

echo "=== Windows SDK headers ==="

# Test: windows.h compile-only for all Windows targets
for target in $(filter_targets $WINDOWS_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: windows.h compile-only"

    if compile_only "$wrapper" "$SRCDIR/windows_h.c"; then
        if assert_no_stderr "$desc (no warnings)" "$COMPILE_STDERR"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

# Test: windows.h with C++ for all Windows targets
# -Wno-deprecated: suppress "treating 'c' input as 'c++'" for .c source with clang++
for target in $(filter_targets $WINDOWS_TARGETS); do
    wrapper="clang++-${target}"
    desc="${target}: windows.h C++ compile-only"

    if compile_only "$wrapper" "$SRCDIR/windows_h.c" -Wno-deprecated; then
        if assert_no_stderr "$desc (no warnings)" "$COMPILE_STDERR"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

test_summary
