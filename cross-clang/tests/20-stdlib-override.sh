#!/bin/sh
# 21-stdlib-override.sh — Verify that users can override the default C++ stdlib
# Default wrapper uses libc++, but users may want libstdc++ or custom headers.
. "$(dirname "$0")/helpers.sh"

echo "=== C++ stdlib override ==="

# Test 1: -stdlib=libc++ works explicitly (should compile, no errors)
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang++-${target}"
    desc="${target}: -stdlib=libc++ compiles"

    if compile_only "$wrapper" "$SRCDIR/cpp_stdlib.cpp" -stdlib=libc++; then
        test_pass "$desc"
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

# Test 2: -nostdinc++ allows user to control headers entirely
# With -nostdinc++ the compiler should not inject any C++ header paths.
# We only test that -nostdinc++ is accepted without error (compile will fail
# due to missing headers, but no "unknown option" error).
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang++-${target}"
    desc="${target}: -nostdinc++ accepted"

    COMPILE_STDERR=$("$wrapper" -nostdinc++ -fsyntax-only -x c++ - < /dev/null 2>&1)
    rc=$?
    # clang should accept -nostdinc++ (rc=0 for empty input)
    if [ $rc -eq 0 ]; then
        test_pass "$desc"
    else
        # Even if it fails, it should be because of missing headers, not unknown flag
        if echo "$COMPILE_STDERR" | grep -qi "unknown.*argument\|invalid.*option"; then
            test_fail "$desc" "flag not recognized: $COMPILE_STDERR"
        else
            test_pass "$desc"
        fi
    fi
done

# Test 3: libc++ headers resolve from sysroot (not host install dir)
# Compile a file that uses <locale> — this will fail if host (glibc) headers
# are picked up instead of sysroot (musl) headers.
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang++-${target}"
    desc="${target}: libc++ headers from sysroot"

    COMPILE_STDERR=$("$wrapper" -stdlib=libc++ -c "$SRCDIR/cpp_stdlib.cpp" -o "$WORKDIR/sysroot_test_${target}.o" 2>&1)
    rc=$?
    if [ $rc -eq 0 ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "exit code $rc, stderr: $COMPILE_STDERR"
    fi
done

test_summary
