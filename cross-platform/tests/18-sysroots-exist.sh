#!/bin/sh
# 18-sysroots-exist.sh — Verify all sysroots and key SDK files exist
# Checks that the image was built correctly and all sysroots have expected structure.
. "$(dirname "$0")/helpers.sh"

echo "=== Sysroot and SDK existence ==="

# Helper: check directory exists
check_dir() {
    desc="$1"; path="$2"
    if [ -d "$path" ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "directory not found: $path"
    fi
}

# Helper: check file exists
check_file() {
    desc="$1"; path="$2"
    if [ -f "$path" ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "file not found: $path"
    fi
}

# --- macOS SDK ---
check_dir  "macOS SDK exists" "/usr/macosx.sdk"
check_file "macOS SDK: stdio.h" "/usr/macosx.sdk/usr/include/stdio.h"
check_dir  "macOS SDK: Frameworks" "/usr/macosx.sdk/System/Library/Frameworks"

# --- Windows MSVC (xwin) ---
check_dir  "Windows MSVC sysroot" "/usr/windows-msvc"
check_dir  "Windows MSVC: CRT headers" "/usr/windows-msvc/crt/include"
check_dir  "Windows MSVC: SDK ucrt headers" "/usr/windows-msvc/sdk/include/ucrt"
check_dir  "Windows MSVC: SDK um headers" "/usr/windows-msvc/sdk/include/um"
check_dir  "Windows MSVC: x86_64 CRT libs" "/usr/windows-msvc/crt/lib/x86_64"
check_dir  "Windows MSVC: aarch64 CRT libs" "/usr/windows-msvc/crt/lib/aarch64"
check_dir  "Windows MSVC: x86_64 SDK um libs" "/usr/windows-msvc/sdk/lib/um/x86_64"
check_dir  "Windows MSVC: aarch64 SDK um libs" "/usr/windows-msvc/sdk/lib/um/aarch64"

# --- Windows GNU (llvm-mingw) ---
check_dir  "Windows GNU sysroot" "/usr/windows-gnu"
check_dir  "Windows GNU: headers" "/usr/windows-gnu/include"
check_dir  "Windows GNU: x86_64 libs" "/usr/windows-gnu/x86_64/lib"
check_dir  "Windows GNU: aarch64 libs" "/usr/windows-gnu/aarch64/lib"
# libc++ headers (built in Stage 4)
check_dir  "Windows GNU: libc++ headers" "/usr/windows-gnu/include/c++/v1"
# CRT objects
for arch in x86_64 aarch64; do
    check_file "Windows GNU ${arch}: crt2.o" "/usr/windows-gnu/${arch}/lib/crt2.o"
    check_file "Windows GNU ${arch}: libmingw32.a" "/usr/windows-gnu/${arch}/lib/libmingw32.a"
    check_file "Windows GNU ${arch}: libkernel32.a" "/usr/windows-gnu/${arch}/lib/libkernel32.a"
    # Stub libs for clang MinGW driver
    check_file "Windows GNU ${arch}: libgcc.a (stub)" "/usr/windows-gnu/${arch}/lib/libgcc.a"
done

# --- aarch64 musl sysroot ---
check_dir  "aarch64 musl sysroot" "/usr/aarch64-alpine-linux-musl"
check_file "aarch64 musl: libc.so" "/usr/aarch64-alpine-linux-musl/lib/ld-musl-aarch64.so.1"
check_dir  "aarch64 musl: include" "/usr/aarch64-alpine-linux-musl/usr/include"
# Kernel UAPI headers (needed for libc++ atomic wait)
check_dir  "aarch64 musl: linux headers" "/usr/aarch64-alpine-linux-musl/usr/include/linux"
check_dir  "aarch64 musl: asm headers" "/usr/aarch64-alpine-linux-musl/usr/include/asm"

# --- glibc sysroots ---
for arch in x86_64 aarch64; do
    sr="/usr/${arch}-linux-gnu"
    check_dir  "glibc ${arch}: sysroot" "$sr"
    check_dir  "glibc ${arch}: include" "$sr/usr/include"
    check_file "glibc ${arch}: libc.so (linker script)" "$sr/usr/lib/libc.so"
    check_file "glibc ${arch}: crt1.o" "$sr/usr/lib/crt1.o"
    check_file "glibc ${arch}: libssp_nonshared.a (stub)" "$sr/usr/lib/libssp_nonshared.a"
    # Kernel UAPI headers
    check_dir  "glibc ${arch}: linux headers" "$sr/usr/include/linux"
    check_dir  "glibc ${arch}: asm headers" "$sr/usr/include/asm"
done

# --- compiler-rt builtins (installed in clang resource dir) ---
CLANG_RES=$(clang --print-resource-dir 2>/dev/null || echo "")
if [ -n "$CLANG_RES" ]; then
    for target in x86_64-unknown-linux-musl aarch64-unknown-linux-musl \
                  x86_64-unknown-linux-gnu aarch64-unknown-linux-gnu \
                  x86_64-pc-windows-gnu aarch64-pc-windows-gnu; do
        check_file "compiler-rt builtins: ${target}" \
            "${CLANG_RES}/lib/${target}/libclang_rt.builtins.a"
    done
else
    test_fail "clang --print-resource-dir" "clang not found"
fi

# --- libc++ static libraries ---
for path in \
    /usr/lib/libc++.a \
    /usr/aarch64-alpine-linux-musl/usr/lib/libc++.a \
    /usr/x86_64-linux-gnu/usr/lib/libc++.a \
    /usr/aarch64-linux-gnu/usr/lib/libc++.a \
    /usr/windows-gnu/x86_64/lib/libc++.a \
    /usr/windows-gnu/aarch64/lib/libc++.a; do
    name=$(echo "$path" | sed 's|/usr/||; s|/lib/libc++.a||; s|/usr||')
    check_file "libc++.a: ${name}" "$path"
done

test_summary
