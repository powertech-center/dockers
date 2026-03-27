#!/bin/sh
# 01-dotnet-sdk.sh — Verify .NET SDK is installed and functional
. "$(dirname "$0")/helpers.sh"

echo "=== .NET SDK installation ==="

# Check dotnet is available
if command -v dotnet >/dev/null 2>&1; then
    version=$(dotnet --version 2>&1)
    test_pass "dotnet available (SDK $version)"
else
    test_fail "dotnet available" "dotnet not found in PATH"
fi

# Check SDK version is an even-numbered (LTS) release
major=$(dotnet --version 2>&1 | cut -d. -f1)
if [ "$((major % 2))" -eq 0 ] 2>/dev/null; then
    test_pass "SDK is LTS release (.NET $major)"
else
    test_fail "SDK is LTS release" "expected even major version, got $(dotnet --version 2>&1)"
fi

# Check NativeAOT dependencies
for cmd in clang lld llvm-objcopy; do
    if command -v "$cmd" >/dev/null 2>&1; then
        test_pass "$cmd available (NativeAOT dependency)"
    else
        test_fail "$cmd available (NativeAOT dependency)" "not found in PATH"
    fi
done

test_summary
