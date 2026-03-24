#!/bin/sh
# 03-cpp-compile.sh — C++ compile-only (-c) for all targets
# Verifies: compilation succeeds, NO warnings on stderr
. "$(dirname "$0")/helpers.sh"

echo "=== C++ compile-only (all targets) ==="

for target in $(filter_targets $ALL_TARGETS); do
    wrapper="clang++-${target}"
    desc="${target}: C++ compile-only"

    if compile_only "$wrapper" "$SRCDIR/hello.cpp"; then
        if assert_no_stderr "$desc (no warnings)" "$COMPILE_STDERR"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

test_summary
