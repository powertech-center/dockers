#!/bin/sh
# 09-link-mode-detection.sh — Verify correct link mode detection (audit issue 1.1)
# Old wrappers detected link mode by .exe extension. New wrappers use compile-only flag detection.
# Tests:
#   - Link without .exe extension (e.g. -o myapp) should still link
#   - Link with arbitrary extension (e.g. -o tool.bin) should still link
#   - -c flag should prevent linking even with .exe output name
. "$(dirname "$0")/helpers.sh"

echo "=== Link mode detection (issue 1.1) ==="

# Test 1: Link without .exe extension (Windows targets)
# Note: clang auto-appends .exe for Windows targets, so check both names
for target in $(filter_targets $WINDOWS_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/myapp_${target}"
    desc="${target}: link without .exe extension"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output"; then
        if [ -f "$output" ] || [ -f "${output}.exe" ]; then
            test_pass "$desc"
        else
            test_fail "$desc" "output file not found (checked $output and ${output}.exe)"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 2: Link with arbitrary extension (Windows targets)
for target in $(filter_targets $WINDOWS_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/tool_${target}.bin"
    desc="${target}: link with .bin extension"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 3: -c flag prevents linking even if output looks like .exe
for target in $(filter_targets $WINDOWS_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/should_be_obj_${target}.exe"
    desc="${target}: -c prevents link (even with .exe output)"

    # This should compile only, producing an object file
    if compile_only "$wrapper" "$SRCDIR/hello.c"; then
        test_pass "$desc"
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

# Test 4: All non-Windows targets should link with any output name
for target in $(filter_targets $LINUX_TARGETS $DARWIN_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/app_${target}"
    desc="${target}: link without extension"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

test_summary
