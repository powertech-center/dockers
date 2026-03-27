#!/bin/sh
# test.sh — Test runner for cross-clang cross-compilation wrappers
#
# Usage:
#   ./test.sh                         # run all tests
#   ./test.sh 02-c-compile 04-c-link  # run specific tests (by name, without .sh)
#   ./test.sh --target x86_64-linux   # filter by target substring
#   ./test.sh --list                  # list available tests
#
# Run inside container:
#   docker run --rm -v ./cross-clang:/tests <image> sh /tests/test.sh
#
# Exit code: 0 if all tests pass, 1 if any test fails.

set -u

TESTDIR="$(cd "$(dirname "$0")/tests" && pwd)"
export TARGET_FILTER=""

# --- Parse arguments ---
tests_to_run=""
while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            shift
            export TARGET_FILTER="$1"
            ;;
        --list)
            echo "Available tests:"
            for f in "$TESTDIR"/[0-9]*.sh; do
                name=$(basename "$f" .sh)
                # Extract description from second comment line
                desc=$(sed -n '2s/^# //p' "$f")
                printf "  %-30s %s\n" "$name" "$desc"
            done
            exit 0
            ;;
        --help|-h)
            echo "Usage: $0 [--target <filter>] [--list] [test-name ...]"
            echo ""
            echo "Options:"
            echo "  --target <filter>   Only test targets matching <filter> (e.g. x86_64-linux)"
            echo "  --list              List available tests"
            echo "  --help              Show this help"
            echo ""
            echo "Arguments:"
            echo "  test-name           Run specific tests (e.g. 02-c-compile 04-c-link)"
            echo "                      Without arguments, runs all tests."
            exit 0
            ;;
        *)
            tests_to_run="$tests_to_run $1"
            ;;
    esac
    shift
done

# --- Colors ---
if [ -t 1 ]; then
    BOLD='\033[1m'
    RESET='\033[0m'
    GREEN='\033[0;32m'
    RED='\033[0;31m'
else
    BOLD='' RESET='' GREEN='' RED=''
fi

# --- Discover tests ---
if [ -n "$tests_to_run" ]; then
    test_files=""
    for name in $tests_to_run; do
        f="$TESTDIR/${name}.sh"
        if [ -f "$f" ]; then
            test_files="$test_files $f"
        else
            echo "error: test '$name' not found ($f)" >&2
            exit 1
        fi
    done
else
    test_files=$(ls "$TESTDIR"/[0-9]*.sh 2>/dev/null)
fi

if [ -z "$test_files" ]; then
    echo "No tests found in $TESTDIR"
    exit 1
fi

# --- Run tests ---
total_suites=0
failed_suites=0
failed_names=""

if [ -n "$TARGET_FILTER" ]; then
    printf "${BOLD}Running tests (target filter: ${TARGET_FILTER})${RESET}\n"
else
    printf "${BOLD}Running cross-compilation tests${RESET}\n"
fi
echo ""

for test_file in $test_files; do
    name=$(basename "$test_file" .sh)
    total_suites=$((total_suites + 1))

    printf "%s--- %s ---%s\n" "$BOLD" "$name" "$RESET"
    sh "$test_file"
    rc=$?

    if [ $rc -ne 0 ]; then
        failed_suites=$((failed_suites + 1))
        failed_names="$failed_names $name"
    fi
    echo ""
done

# --- Summary ---
echo "================================================================"
if [ $failed_suites -eq 0 ]; then
    printf "${GREEN}${BOLD}ALL %d test suites passed${RESET}\n" "$total_suites"
    exit 0
else
    printf "${RED}${BOLD}%d of %d test suites FAILED:${RESET}\n" "$failed_suites" "$total_suites"
    for name in $failed_names; do
        printf "  ${RED}%s${RESET}\n" "$name"
    done
    exit 1
fi
