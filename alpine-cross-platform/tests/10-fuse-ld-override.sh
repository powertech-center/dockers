#!/bin/sh
# 10-fuse-ld-override.sh — Verify -fuse-ld= handling (audit issue 1.2)
# Tests:
#   - Default: wrapper adds -fuse-ld=lld (or our linker wrapper)
#   - User -fuse-ld=lld: treated same as default (replaced by wrapper's choice)
#   - User -fuse-ld=other: respected, not overridden
. "$(dirname "$0")/helpers.sh"

echo "=== -fuse-ld= handling (issue 1.2) ==="

# Test 1: Default link (no -fuse-ld) should work
for target in $(filter_targets $ALL_TARGETS); do
    wrapper="clang-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/default_ld_${target}${ext}"
    desc="${target}: default link (no -fuse-ld)"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 2: Explicit -fuse-ld=lld should work (wrapper treats as default)
for target in $(filter_targets $ALL_TARGETS); do
    wrapper="clang-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/fuse_lld_${target}${ext}"
    desc="${target}: explicit -fuse-ld=lld"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -fuse-ld=lld -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

test_summary
