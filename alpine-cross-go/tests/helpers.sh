#!/bin/sh
# helpers.sh — Test framework for Go cross-compilation tests

set -u

_passed=0
_failed=0
_skipped=0
_test_errors=""

WORKDIR=$(mktemp -d /tmp/go-test.XXXXXX)
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

# Go cross-compilation targets (GOOS/GOARCH pairs)
# Format: "goos goarch cc_env_var"
GO_TARGETS="
    linux:amd64:CGO_CC_linux_amd64
    linux:arm64:CGO_CC_linux_arm64
    darwin:amd64:CGO_CC_darwin_amd64
    darwin:arm64:CGO_CC_darwin_arm64
    windows:amd64:CGO_CC_windows_amd64
    windows:arm64:CGO_CC_windows_arm64
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
