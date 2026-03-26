#!/bin/sh
# 11-nostdlib.sh — Test -nostdlib flag handling
# Verifies:
#   - Windows GNU: -nostdlib prevents CRT injection
#   - Linux: -nostdlib works (clang handles natively)
#   - Compilation of nostdlib.c with custom entry point
. "$(dirname "$0")/helpers.sh"

echo "=== -nostdlib flag handling ==="

# Test 1: Compile nostdlib.c for Windows GNU with -nostdlib
for target in $(filter_targets $WINDOWS_GNU_TARGETS); do
    wrapper="clang-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/nostdlib_${target}${ext}"
    desc="${target}: -nostdlib compile+link"

    # Compile object first
    obj="$WORKDIR/nostdlib_${target}.o"
    if "$wrapper" -c "$SRCDIR/nostdlib.c" -o "$obj" 2>/dev/null; then
        # Link with -nostdlib — should NOT inject CRT
        # Use -Wl,--entry,_start for MinGW lld
        stderr=$("$wrapper" -nostdlib -o "$output" "$obj" -Wl,--entry,_start 2>&1 1>/dev/null) || true
        if [ -f "$output" ]; then
            test_pass "$desc"
        else
            test_fail "$desc" "output not created, stderr: $stderr"
        fi
    else
        test_fail "$desc" "compilation failed"
    fi
done

# Test 2: Compile nostdlib.c for Linux with -nostdlib
for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang-${target}"
    output="$WORKDIR/nostdlib_${target}"
    desc="${target}: -nostdlib compile+link"

    obj="$WORKDIR/nostdlib_linux_${target}.o"
    if "$wrapper" -c "$SRCDIR/nostdlib.c" -o "$obj" 2>/dev/null; then
        stderr=$("$wrapper" -nostdlib -o "$output" "$obj" -Wl,-e,_start 2>&1 1>/dev/null) || true
        if [ -f "$output" ]; then
            test_pass "$desc"
        else
            test_fail "$desc" "output not created, stderr: $stderr"
        fi
    else
        test_fail "$desc" "compilation failed"
    fi
done

test_summary
