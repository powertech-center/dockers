#!/bin/sh
# 05-cpp-link.sh — C++ compile+link for all targets
# Verifies: full C++ pipeline works, output file created
. "$(dirname "$0")/helpers.sh"

echo "=== C++ compile+link (all targets) ==="

for target in $(filter_targets $ALL_TARGETS); do
    wrapper="clang++-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/hello_cpp_${target}${ext}"
    desc="${target}: C++ compile+link"

    if compile_and_link "$wrapper" "$SRCDIR/hello.cpp" -o "$output"; then
        if assert_file_exists "$output" "$desc (output exists)"; then
            if assert_no_stderr "$desc (no warnings)" "$LINK_STDERR"; then
                test_pass "$desc"
            fi
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

test_summary
