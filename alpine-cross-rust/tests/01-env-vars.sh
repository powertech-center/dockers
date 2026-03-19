#!/bin/sh
# 01-env-vars.sh — Verify Rust cross-compilation environment variables are set
. "$(dirname "$0")/helpers.sh"

echo "=== Rust cross-compilation environment variables ==="

# CC_<target> and CXX_<target> env vars
check_env() {
    var_name="$1"
    expected="$2"
    desc="$3"
    actual=$(eval echo "\${${var_name}:-}")
    if [ "$actual" = "$expected" ]; then
        test_pass "$desc"
    elif [ -n "$actual" ]; then
        test_fail "$desc" "expected '$expected', got '$actual'"
    else
        test_fail "$desc" "$var_name not set"
    fi
}

# Linux musl
check_env CC_x86_64_unknown_linux_musl "clang-x86_64-linux-musl" "CC for x86_64-unknown-linux-musl"
check_env CXX_x86_64_unknown_linux_musl "clang++-x86_64-linux-musl" "CXX for x86_64-unknown-linux-musl"
check_env CC_aarch64_unknown_linux_musl "clang-aarch64-linux-musl" "CC for aarch64-unknown-linux-musl"
check_env CXX_aarch64_unknown_linux_musl "clang++-aarch64-linux-musl" "CXX for aarch64-unknown-linux-musl"

# Linux gnu
check_env CC_x86_64_unknown_linux_gnu "clang-x86_64-linux-gnu" "CC for x86_64-unknown-linux-gnu"
check_env CXX_x86_64_unknown_linux_gnu "clang++-x86_64-linux-gnu" "CXX for x86_64-unknown-linux-gnu"
check_env CC_aarch64_unknown_linux_gnu "clang-aarch64-linux-gnu" "CC for aarch64-unknown-linux-gnu"
check_env CXX_aarch64_unknown_linux_gnu "clang++-aarch64-linux-gnu" "CXX for aarch64-unknown-linux-gnu"

# macOS
check_env CC_x86_64_apple_darwin "clang-x86_64-apple-darwin" "CC for x86_64-apple-darwin"
check_env CXX_x86_64_apple_darwin "clang++-x86_64-apple-darwin" "CXX for x86_64-apple-darwin"
check_env CC_aarch64_apple_darwin "clang-aarch64-apple-darwin" "CC for aarch64-apple-darwin"
check_env CXX_aarch64_apple_darwin "clang++-aarch64-apple-darwin" "CXX for aarch64-apple-darwin"

# Windows MSVC
check_env CC_x86_64_pc_windows_msvc "clang-x86_64-windows-msvc" "CC for x86_64-pc-windows-msvc"
check_env CXX_x86_64_pc_windows_msvc "clang++-x86_64-windows-msvc" "CXX for x86_64-pc-windows-msvc"
check_env CC_aarch64_pc_windows_msvc "clang-aarch64-windows-msvc" "CC for aarch64-pc-windows-msvc"
check_env CXX_aarch64_pc_windows_msvc "clang++-aarch64-windows-msvc" "CXX for aarch64-pc-windows-msvc"

# CARGO_TARGET_*_LINKER env vars
# Rust passes compiler-driver flags (-Wl,*, -nostartfiles, etc.) to the linker,
# so we use clang wrappers (not raw lld) — clang translates these and calls lld internally.
check_env CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER "clang-x86_64-linux-musl" "LINKER for x86_64-unknown-linux-musl"
check_env CARGO_TARGET_AARCH64_UNKNOWN_LINUX_MUSL_LINKER "clang-aarch64-linux-musl" "LINKER for aarch64-unknown-linux-musl"
check_env CARGO_TARGET_X86_64_UNKNOWN_LINUX_GNU_LINKER "clang-x86_64-linux-gnu" "LINKER for x86_64-unknown-linux-gnu"
check_env CARGO_TARGET_AARCH64_UNKNOWN_LINUX_GNU_LINKER "clang-aarch64-linux-gnu" "LINKER for aarch64-unknown-linux-gnu"
check_env CARGO_TARGET_X86_64_APPLE_DARWIN_LINKER "clang-x86_64-apple-darwin" "LINKER for x86_64-apple-darwin"
check_env CARGO_TARGET_AARCH64_APPLE_DARWIN_LINKER "clang-aarch64-apple-darwin" "LINKER for aarch64-apple-darwin"
check_env CARGO_TARGET_X86_64_PC_WINDOWS_MSVC_LINKER "lld-x86_64-windows-msvc" "LINKER for x86_64-pc-windows-msvc"
check_env CARGO_TARGET_AARCH64_PC_WINDOWS_MSVC_LINKER "lld-aarch64-windows-msvc" "LINKER for aarch64-pc-windows-msvc"

# AR for MSVC
check_env AR_x86_64_pc_windows_msvc "llvm-lib" "AR for x86_64-pc-windows-msvc"
check_env AR_aarch64_pc_windows_msvc "llvm-lib" "AR for aarch64-pc-windows-msvc"

test_summary
