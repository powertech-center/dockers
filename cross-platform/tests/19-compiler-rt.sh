#!/bin/sh
# 19-compiler-rt.sh — Verify compiler-rt builtins work for all targets that use them
# Wrappers inject -rtlib=compiler-rt for Linux and Windows GNU targets.
# This test verifies that 128-bit operations (which require builtins) compile+link.
. "$(dirname "$0")/helpers.sh"

echo "=== compiler-rt builtins ==="

# Create test source that uses 128-bit integer division (requires __udivti3 from builtins)
rt_test="$WORKDIR/compiler_rt_test.c"
cat > "$rt_test" << 'EOF'
#include <stdio.h>

/* Force use of 128-bit integer operations — these require compiler-rt builtins
   (__udivti3, __umodti3) on targets without hardware 128-bit division. */
#if defined(__SIZEOF_INT128__)
__uint128_t divide128(__uint128_t a, __uint128_t b) {
    return a / b;
}
#endif

int main(void) {
#if defined(__SIZEOF_INT128__)
    __uint128_t result = divide128(100, 7);
    printf("128-bit division works: %d\n", (int)result);
#else
    printf("128-bit integers not supported on this target\n");
#endif
    return 0;
}
EOF

# Test: compile+link with implicit -rtlib=compiler-rt (Linux targets)
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/rt_${target}"
    desc="${target}: compiler-rt builtins (128-bit ops)"

    if compile_and_link "$wrapper" "$rt_test" -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test: compile+link with implicit -rtlib=compiler-rt (Windows GNU targets)
for target in $(filter_targets $WINDOWS_GNU_TARGETS); do
    wrapper="clang-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/rt_${target}${ext}"
    desc="${target}: compiler-rt builtins (128-bit ops)"

    if compile_and_link "$wrapper" "$rt_test" -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test: explicit -rtlib=compiler-rt should not conflict with wrapper's injection
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/rt_explicit_${target}"
    desc="${target}: explicit -rtlib=compiler-rt (no conflict)"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output" -rtlib=compiler-rt; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

test_summary
