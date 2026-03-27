#!/bin/sh
# helpers.sh — Test framework for C# cross-compilation tests

set -u

_passed=0
_failed=0
_skipped=0
_test_errors=""

WORKDIR=$(mktemp -d /tmp/csharp-cross-test.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

# Detect installed .NET major version → TargetFramework moniker (e.g. net10.0)
DOTNET_MAJOR=$(dotnet --version 2>/dev/null | cut -d. -f1)
TFM="net${DOTNET_MAJOR}.0"

# Copy test sources into WORKDIR and patch TargetFramework to match installed SDK
_orig_src="$(cd "$(dirname "$0")/src" && pwd)"
SRCDIR="$WORKDIR/src"
cp -r "$_orig_src" "$SRCDIR"
find "$SRCDIR" -name '*.csproj' -exec sed -i "s|<TargetFramework>net[0-9]*\.[0-9]*</TargetFramework>|<TargetFramework>${TFM}</TargetFramework>|g" {} +

if [ -t 1 ]; then
    _GREEN='\033[0;32m'
    _RED='\033[0;31m'
    _YELLOW='\033[0;33m'
    _BOLD='\033[1m'
    _RESET='\033[0m'
else
    _GREEN='' _RED='' _YELLOW='' _BOLD='' _RESET=''
fi

# NativeAOT cross-compilation targets (Linux)
# Format: "rid:compiler:sysroot"
AOT_LINUX_TARGETS="
    linux-musl-x64:clang-x86_64-linux-musl:/
    linux-musl-arm64:clang-aarch64-linux-musl:/usr/aarch64-linux-musl
    linux-x64:clang-x86_64-linux-gnu:/usr/x86_64-linux-gnu
    linux-arm64:clang-aarch64-linux-gnu:/usr/aarch64-linux-gnu
"

# NativeAOT cross-compilation targets (macOS)
# Format: "rid:compiler:sysroot"
# Uses Unix.targets — CppCompilerAndLinker works directly
AOT_MACOS_TARGETS="
    osx-x64:clang-x86_64-apple-darwin:/usr/macosx.sdk
    osx-arm64:clang-aarch64-apple-darwin:/usr/macosx.sdk
"

# NativeAOT cross-compilation targets (Windows)
# Format: "rid:linker:arch"
# Uses Windows.targets — CppLinker must be lld-link compatible, not clang wrapper
AOT_WINDOWS_TARGETS="
    win-x64:lld-x86_64-windows-msvc:x86_64
    win-arm64:lld-aarch64-windows-msvc:aarch64
"

# All NativeAOT targets combined (Linux + macOS use same format: rid:compiler:sysroot)
AOT_TARGETS="$AOT_LINUX_TARGETS $AOT_MACOS_TARGETS"

# Standard publish targets (managed IL, no NativeAOT)
PUBLISH_TARGETS="
    win-x64
    win-arm64
    osx-x64
    osx-arm64
"

TARGET_FILTER="${TARGET_FILTER:-}"

filter_targets() {
    if [ -z "$TARGET_FILTER" ]; then
        echo "$@"
    else
        for t in $@; do
            case "$t" in *"$TARGET_FILTER"*) printf '%s ' "$t" ;; esac
        done
    fi
}

test_pass() {
    _passed=$((_passed + 1))
    printf "  ${_GREEN}PASS${_RESET}  %s\n" "$1"
}

test_fail() {
    _failed=$((_failed + 1))
    printf "  ${_RED}FAIL${_RESET}  %s\n" "$1"
    [ -n "${2:-}" ] && printf "        %s\n" "$2"
    _test_errors="${_test_errors}FAIL: $1\n"
}

test_skip() {
    _skipped=$((_skipped + 1))
    printf "  ${_YELLOW}SKIP${_RESET}  %s\n" "$1"
    [ -n "${2:-}" ] && printf "        %s\n" "$2"
}

test_summary() {
    echo ""
    _total=$((_passed + _failed + _skipped))
    printf "${_BOLD}Results: %d passed, %d failed, %d skipped (total %d)${_RESET}\n" \
        "$_passed" "$_failed" "$_skipped" "$_total"
    if [ "$_failed" -gt 0 ]; then
        echo ""
        printf "${_RED}Failures:${_RESET}\n"
        printf "$_test_errors"
        return 1
    fi
    return 0
}
