#!/bin/sh
# 06-cpp-stdlib.sh — C++ standard library tests
# Verifies:
#   - Linux targets: -stdlib=libc++ auto-injected by wrapper
#   - User override: explicit -stdlib= respected (no duplicate)
#   - C++ STL features (vector, algorithm) work
. "$(dirname "$0")/helpers.sh"

echo "=== C++ standard library ==="

# Test 1: STL features compile+link for all targets
for target in $(filter_targets $ALL_TARGETS); do
    wrapper="clang++-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/stdlib_${target}${ext}"
    desc="${target}: C++ STL (vector, sort)"

    if compile_and_link "$wrapper" "$SRCDIR/cpp_stdlib.cpp" -o "$output"; then
        if assert_no_stderr "$desc (no warnings)" "$LINK_STDERR"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 2: Explicit -stdlib=libc++ should not cause duplicate or warning (Linux + Windows GNU)
for target in $(filter_targets $LINUX_TARGETS $WINDOWS_GNU_TARGETS); do
    wrapper="clang++-${target}"
    desc="${target}: explicit -stdlib=libc++ (no warning)"

    if compile_only "$wrapper" "$SRCDIR/hello.cpp" -stdlib=libc++; then
        if assert_no_stderr "$desc" "$COMPILE_STDERR"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

test_summary
