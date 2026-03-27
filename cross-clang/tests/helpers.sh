#!/bin/sh
# helpers.sh — Minimal test framework for cross-compilation wrapper testing
#
# Usage: source this file at the top of each test script.
#   . "$(dirname "$0")/helpers.sh"
#
# Functions:
#   test_pass "description"
#   test_fail "description" "reason"
#   test_skip "description" "reason"
#   test_summary  — prints totals and exits with 0 (all pass) or 1 (any fail)
#
# Helpers:
#   compile_only <wrapper> <source> [extra flags...]
#   compile_and_link <wrapper> <source> -o <output> [extra flags...]
#   assert_no_stderr <description> <command...>  — fail if command writes to stderr
#   assert_file_exists <path> <description>
#   assert_file_is_executable <path> <description>

set -u

# --- State ---
_passed=0
_failed=0
_skipped=0
_test_errors=""

# --- Temp directory (cleaned up on exit) ---
WORKDIR=$(mktemp -d /tmp/cross-test.XXXXXX)
trap 'rm -rf "$WORKDIR"' EXIT

# --- Source directory (where test .c/.cpp files live) ---
SRCDIR="$(cd "$(dirname "$0")/src" && pwd)"

# --- Colors (disabled if not a terminal) ---
if [ -t 1 ]; then
    _GREEN='\033[0;32m'
    _RED='\033[0;31m'
    _YELLOW='\033[0;33m'
    _BOLD='\033[1m'
    _RESET='\033[0m'
else
    _GREEN='' _RED='' _YELLOW='' _BOLD='' _RESET=''
fi

# --- All 10 cross-compilation targets ---
ALL_TARGETS="
    x86_64-linux-musl
    aarch64-linux-musl
    x86_64-linux-gnu
    aarch64-linux-gnu
    x86_64-apple-darwin
    aarch64-apple-darwin
    x86_64-windows-msvc
    aarch64-windows-msvc
    x86_64-windows-gnu
    aarch64-windows-gnu
"

LINUX_TARGETS="x86_64-linux-musl aarch64-linux-musl x86_64-linux-gnu aarch64-linux-gnu"
DARWIN_TARGETS="x86_64-apple-darwin aarch64-apple-darwin"
WINDOWS_MSVC_TARGETS="x86_64-windows-msvc aarch64-windows-msvc"
WINDOWS_GNU_TARGETS="x86_64-windows-gnu aarch64-windows-gnu"
WINDOWS_TARGETS="$WINDOWS_MSVC_TARGETS $WINDOWS_GNU_TARGETS"

# --- Target filter (set via --target flag in test.sh) ---
TARGET_FILTER="${TARGET_FILTER:-}"

# Filter targets if TARGET_FILTER is set
filter_targets() {
    if [ -z "$TARGET_FILTER" ]; then
        echo "$@"
    else
        for t in $@; do
            case "$t" in
                *"$TARGET_FILTER"*) printf '%s ' "$t" ;;
            esac
        done
    fi
}

# --- Reporting ---

test_pass() {
    _passed=$((_passed + 1))
    printf "  ${_GREEN}PASS${_RESET}  %s\n" "$1"
}

test_fail() {
    _failed=$((_failed + 1))
    printf "  ${_RED}FAIL${_RESET}  %s\n" "$1"
    if [ -n "${2:-}" ]; then
        printf "        %s\n" "$2"
    fi
    _test_errors="${_test_errors}FAIL: $1\n"
}

test_skip() {
    _skipped=$((_skipped + 1))
    printf "  ${_YELLOW}SKIP${_RESET}  %s\n" "$1"
    if [ -n "${2:-}" ]; then
        printf "        %s\n" "$2"
    fi
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

# --- Compilation helpers ---

# _is_msvc <wrapper_name>
# Returns 0 if the wrapper is a cl-mode MSVC wrapper.
_is_msvc() {
    case "$1" in *-windows-msvc|*clang-*-windows-msvc|*clang++-*-windows-msvc) return 0 ;; esac
    return 1
}

# compile_only <wrapper> <source> [extra flags...]
# Compiles with -c flag, captures stderr, checks exit code.
# Returns 0 on success, 1 on failure.
# Sets COMPILE_STDERR to captured stderr content.
# For MSVC (cl-mode): uses /c /Fo and relative paths (cd to WORKDIR).
compile_only() {
    _wrapper="$1"; shift
    _source="$1"; shift
    _base="$(basename "$_source" | sed 's/\.[^.]*$//')"
    if _is_msvc "$_wrapper"; then
        cp "$_source" "$WORKDIR/${_base}$(echo "$_source" | sed 's/.*\./\./')"
        _src_name="${_base}$(echo "$_source" | sed 's/.*\./\./')"
        _obj="${_base}.obj"
        COMPILE_STDERR=$(cd "$WORKDIR" && "$_wrapper" /c "$_src_name" /Fo"$_obj" "$@" 2>&1 1>/dev/null) || return 1
    else
        _obj="$WORKDIR/${_base}.o"
        COMPILE_STDERR=$("$_wrapper" -c "$_source" -o "$_obj" "$@" 2>&1 1>/dev/null) || return 1
    fi
    return 0
}

# compile_and_link <wrapper> <source> -o <output> [extra flags...]
# Compiles and links in one step.
# For MSVC (cl-mode): translates -o → /Fe, sources use relative paths in WORKDIR.
# Sets LINK_STDERR to captured stderr content.
compile_and_link() {
    _wrapper="$1"; shift
    if _is_msvc "$_wrapper"; then
        # Translate GCC-style args to cl-style, copy source files to WORKDIR
        _cl_args=""
        _next_is_output=false
        for _a in "$@"; do
            if [ "$_next_is_output" = "true" ]; then
                _cl_args="$_cl_args /Fe$(basename "$_a")"
                _next_is_output=false
            elif [ "$_a" = "-o" ]; then
                _next_is_output=true
            else
                case "$_a" in
                    /*.*[chp]|/*.*[chp]pp)
                        _bn=$(basename "$_a")
                        cp "$_a" "$WORKDIR/$_bn"
                        _cl_args="$_cl_args $_bn"
                        ;;
                    *) _cl_args="$_cl_args $_a" ;;
                esac
            fi
        done
        LINK_STDERR=$(cd "$WORKDIR" && "$_wrapper" $_cl_args 2>&1 1>/dev/null) || return 1
    else
        LINK_STDERR=$("$_wrapper" "$@" 2>&1 1>/dev/null) || return 1
    fi
    return 0
}

# --- Assertion helpers ---

# assert_no_stderr <description> <stderr_content>
# Fails if stderr is non-empty.
assert_no_stderr() {
    _desc="$1"
    _stderr="$2"
    if [ -n "$_stderr" ]; then
        test_fail "$_desc" "unexpected stderr: $_stderr"
        return 1
    fi
    return 0
}

assert_file_exists() {
    if [ -f "$1" ]; then
        return 0
    else
        test_fail "${2:-file exists: $1}" "file not found: $1"
        return 1
    fi
}

assert_file_is_executable() {
    if [ -x "$1" ]; then
        return 0
    else
        test_fail "${2:-file executable: $1}" "not executable: $1"
        return 1
    fi
}

# --- Output extension helper ---
# Returns the expected output extension for a target
obj_ext() {
    echo ".o"
}

exe_ext() {
    _target="$1"
    case "$_target" in
        *windows*) echo ".exe" ;;
        *darwin*)  echo "" ;;
        *linux*)   echo "" ;;
        *)         echo "" ;;
    esac
}
