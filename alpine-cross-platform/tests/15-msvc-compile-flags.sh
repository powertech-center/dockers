#!/bin/sh
# 15-msvc-compile-flags.sh — Test MSVC-specific compilation flags
# Verifies:
#   - /c (MSVC compile-only) works for MSVC targets
#   - /O2 (MSVC optimization) works
. "$(dirname "$0")/helpers.sh"

echo "=== MSVC-specific flags ==="

# Test 1: /c flag works for MSVC targets (in addition to -c)
# Note: cl-mode treats /path as options, so use relative paths in WORKDIR
cp "$SRCDIR/hello.c" "$WORKDIR/hello.c"
for target in $(filter_targets $WINDOWS_MSVC_TARGETS); do
    wrapper="clang-${target}"
    obj="msvc_c_${target}.obj"
    desc="${target}: /c (MSVC compile-only)"

    stderr=$(cd "$WORKDIR" && "$wrapper" /c hello.c /Fo"$obj" 2>&1 1>/dev/null)
    if [ $? -eq 0 ]; then
        if [ -z "$stderr" ]; then
            test_pass "$desc"
        else
            test_fail "$desc (warnings)" "stderr: $stderr"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $stderr"
    fi
done

# Test 2: /O2 optimization for MSVC targets
for target in $(filter_targets $WINDOWS_MSVC_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: /O2 optimization"

    if compile_only "$wrapper" "$SRCDIR/hello.c" /O2; then
        if assert_no_stderr "$desc (no warnings)" "$COMPILE_STDERR"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

test_summary
