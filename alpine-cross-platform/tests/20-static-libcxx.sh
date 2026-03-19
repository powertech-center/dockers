#!/bin/sh
# 20-static-libcxx.sh — Verify static libc++ linkage for Windows GNU targets
# Windows GNU wrappers default to -Wl,-Bstatic for libc++.
# This test verifies that the resulting binary does not import libc++ DLL symbols.
. "$(dirname "$0")/helpers.sh"

echo "=== Static libc++ for Windows GNU ==="

# Test 1: C++ compile+link produces binary (implicit static libc++)
for target in $(filter_targets $WINDOWS_GNU_TARGETS); do
    wrapper="clang++-${target}"
    ext=$(exe_ext "$target")
    output="$WORKDIR/static_libcxx_${target}${ext}"
    desc="${target}: C++ link with static libc++ (default)"

    if compile_and_link "$wrapper" "$SRCDIR/cpp_stdlib.cpp" -o "$output"; then
        if assert_file_exists "$output" "$desc"; then
            # Check that the binary does not import libc++.dll
            # llvm-readobj --coff-imports shows DLL imports
            if command -v llvm-readobj >/dev/null 2>&1; then
                imports=$(llvm-readobj --coff-imports "$output" 2>/dev/null | grep -i "libc++" || true)
                if [ -z "$imports" ]; then
                    test_pass "$desc"
                else
                    test_fail "$desc" "binary imports libc++ DLL: $imports"
                fi
            else
                # No llvm-readobj, just check the binary was created
                test_pass "$desc (no llvm-readobj to verify imports)"
            fi
        fi
    else
        test_fail "$desc" "exit code $?, stderr: $LINK_STDERR"
    fi
done

# Test 2: Verify libc++ static library exists for each Windows GNU arch
for arch in x86_64 aarch64; do
    target="${arch}-windows-gnu"
    if [ -n "$TARGET_FILTER" ]; then
        case "$target" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    desc="${target}: libc++.a exists in sysroot"
    if [ -f "/usr/windows-gnu/${arch}/lib/libc++.a" ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "/usr/windows-gnu/${arch}/lib/libc++.a not found"
    fi

    desc="${target}: libc++abi.a exists in sysroot"
    if [ -f "/usr/windows-gnu/${arch}/lib/libc++abi.a" ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "/usr/windows-gnu/${arch}/lib/libc++abi.a not found"
    fi
done

test_summary
