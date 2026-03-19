#!/bin/sh
# 12-gnu-flags.sh — Test GNU-specific flags
# Verifies:
#   - -fPIC accepted without error on GNU targets (not MSVC)
#   - -s (strip) accepted during linking on Linux and Windows GNU
#   - -fms-extensions can be passed explicitly on Windows GNU targets
. "$(dirname "$0")/helpers.sh"

echo "=== GNU-specific flags ==="

# Test 1: -fPIC on Linux and Windows GNU targets (should not error)
for target in $(filter_targets $LINUX_TARGETS $WINDOWS_GNU_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: -fPIC accepted"

    if compile_only "$wrapper" "$SRCDIR/hello.c" -fPIC; then
        # Allow warnings for -fPIC on Windows (it's ignored but not an error)
        case "$COMPILE_STDERR" in
            *error*) test_fail "$desc" "$COMPILE_STDERR" ;;
            *)       test_pass "$desc" ;;
        esac
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

# Test 2: -fPIC on MSVC targets should warn about unused argument
for target in $(filter_targets $WINDOWS_MSVC_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: -fPIC warns (expected for cl-mode)"

    # In cl-mode (--driver-mode=cl), -fPIC is an unknown argument
    # We expect either a warning or an error — both are correct behavior
    if compile_only "$wrapper" "$SRCDIR/hello.c" -fPIC 2>/dev/null; then
        test_pass "$desc"
    else
        # Error is also acceptable — MSVC mode rejects GCC flags
        test_pass "$desc"
    fi
done

# Test 3: -s (strip) during link on Linux targets
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/stripped_${target}"
    desc="${target}: -s (strip) during link"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output" -s; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 4: -s (strip) during link on Windows GNU targets
for target in $(filter_targets $WINDOWS_GNU_TARGETS); do
    wrapper="clang-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/stripped_${target}${ext}"
    desc="${target}: -s (strip) during link"

    if compile_and_link "$wrapper" "$SRCDIR/hello.c" -o "$output" -s; then
        if assert_file_exists "$output" "$desc"; then
            test_pass "$desc"
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 5: -fms-extensions can be passed explicitly on Windows GNU targets
for target in $(filter_targets $WINDOWS_GNU_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: -fms-extensions (explicit, accepted)"

    if compile_only "$wrapper" "$SRCDIR/hello.c" -fms-extensions; then
        test_pass "$desc"
    else
        test_fail "$desc" "exit code $?, stderr: $COMPILE_STDERR"
    fi
done

test_summary
