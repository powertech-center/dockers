#!/bin/sh
# helpers.sh — Test framework for C# cross-compilation tests

set -u

_passed=0
_failed=0
_skipped=0
_test_errors=""

WORKDIR=$(mktemp -d /tmp/csharp-cross-test.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

SRCDIR="$(cd "$(dirname "$0")/src" && pwd)"

if [ -t 1 ]; then
    _GREEN='\033[0;32m'
    _RED='\033[0;31m'
    _YELLOW='\033[0;33m'
    _BOLD='\033[1m'
    _RESET='\033[0m'
else
    _GREEN='' _RED='' _YELLOW='' _BOLD='' _RESET=''
fi

# NativeAOT cross-compilation targets
# Format: "rid:compiler:sysroot"
AOT_TARGETS="
    linux-musl-x64:clang-x86_64-linux-musl:/
    linux-musl-arm64:clang-aarch64-linux-musl:/usr/aarch64-alpine-linux-musl
    linux-x64:clang-x86_64-linux-gnu:/usr/x86_64-linux-gnu
    linux-arm64:clang-aarch64-linux-gnu:/usr/aarch64-linux-gnu
"

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
