#!/bin/sh
# 01-env-vars.sh — Verify Go CGO cross-compilation environment variables
. "$(dirname "$0")/helpers.sh"

echo "=== Go CGO environment variables ==="

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

# CC env vars
check_env CGO_CC_linux_amd64 "clang-x86_64-linux-musl" "CGO_CC for linux/amd64"
check_env CGO_CC_linux_arm64 "clang-aarch64-linux-musl" "CGO_CC for linux/arm64"
check_env CGO_CC_darwin_amd64 "clang-x86_64-apple-darwin" "CGO_CC for darwin/amd64"
check_env CGO_CC_darwin_arm64 "clang-aarch64-apple-darwin" "CGO_CC for darwin/arm64"
check_env CGO_CC_windows_amd64 "clang-x86_64-windows-gnu" "CGO_CC for windows/amd64"
check_env CGO_CC_windows_arm64 "clang-aarch64-windows-gnu" "CGO_CC for windows/arm64"

# CXX env vars
check_env CGO_CXX_linux_amd64 "clang++-x86_64-linux-musl" "CGO_CXX for linux/amd64"
check_env CGO_CXX_linux_arm64 "clang++-aarch64-linux-musl" "CGO_CXX for linux/arm64"
check_env CGO_CXX_darwin_amd64 "clang++-x86_64-apple-darwin" "CGO_CXX for darwin/amd64"
check_env CGO_CXX_darwin_arm64 "clang++-aarch64-apple-darwin" "CGO_CXX for darwin/arm64"
check_env CGO_CXX_windows_amd64 "clang++-x86_64-windows-gnu" "CGO_CXX for windows/amd64"
check_env CGO_CXX_windows_arm64 "clang++-aarch64-windows-gnu" "CGO_CXX for windows/arm64"

test_summary
