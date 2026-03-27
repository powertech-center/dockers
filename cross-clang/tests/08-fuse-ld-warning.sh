#!/bin/sh
# 08-fuse-ld-warning.sh — Verify no -fuse-ld warnings during compile-only
# Issue: if -fuse-ld= leaks into compile-only mode, clang emits:
#   "argument unused during compilation: '-fuse-ld=...'"
# This test explicitly checks that compile-only mode is clean.
. "$(dirname "$0")/helpers.sh"

echo "=== No -fuse-ld warnings in compile-only mode ==="

for target in $(filter_targets $ALL_TARGETS); do
    for lang in c cpp; do
        if [ "$lang" = "c" ]; then
            wrapper="clang-${target}"
            src="$SRCDIR/hello.c"
        else
            wrapper="clang++-${target}"
            src="$SRCDIR/hello.cpp"
        fi
        desc="${target}: ${lang} compile-only (no -fuse-ld leak)"

        if compile_only "$wrapper" "$src"; then
            # Check specifically for -fuse-ld warning
            case "$COMPILE_STDERR" in
                *"fuse-ld"*|*"argument unused"*)
                    test_fail "$desc" "warning: $COMPILE_STDERR"
                    ;;
                *)
                    if [ -n "$COMPILE_STDERR" ]; then
                        test_fail "$desc" "unexpected stderr: $COMPILE_STDERR"
                    else
                        test_pass "$desc"
                    fi
                    ;;
            esac
        else
            test_fail "$desc" "compilation failed: $COMPILE_STDERR"
        fi
    done
done

test_summary
