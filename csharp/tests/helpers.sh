#!/bin/sh
# helpers.sh — Test framework for C# (.NET) tests

set -u

_passed=0
_failed=0
_skipped=0
_test_errors=""

WORKDIR=$(mktemp -d /tmp/csharp-test.XXXXXX)
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
