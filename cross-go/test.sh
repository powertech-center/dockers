#!/bin/sh
# test.sh — Test runner for alpine-cross-go
#
# Usage:
#   ./test.sh                         # run all tests
#   ./test.sh 01-env-vars             # run specific test
#   ./test.sh --target windows        # filter by target
#   ./test.sh --list                  # list available tests

set -u

TESTDIR="$(cd "$(dirname "$0")/tests" && pwd)"
export TARGET_FILTER=""

tests_to_run=""
while [ $# -gt 0 ]; do
    case "$1" in
        --target) shift; export TARGET_FILTER="$1" ;;
        --list)
            echo "Available tests:"
            for f in "$TESTDIR"/[0-9]*.sh; do
                name=$(basename "$f" .sh)
                desc=$(sed -n '2s/^# //p' "$f")
                printf "  %-30s %s\n" "$name" "$desc"
            done
            exit 0 ;;
        --help|-h)
            echo "Usage: $0 [--target <filter>] [--list] [test-name ...]"
            exit 0 ;;
        *) tests_to_run="$tests_to_run $1" ;;
    esac
    shift
done

if [ -t 1 ]; then
    BOLD='\033[1m' RESET='\033[0m' GREEN='\033[0;32m' RED='\033[0;31m'
else
    BOLD='' RESET='' GREEN='' RED=''
fi

if [ -n "$tests_to_run" ]; then
    test_files=""
    for name in $tests_to_run; do
        f="$TESTDIR/${name}.sh"
        [ -f "$f" ] && test_files="$test_files $f" || { echo "error: test '$name' not found" >&2; exit 1; }
    done
else
    test_files=$(ls "$TESTDIR"/[0-9]*.sh 2>/dev/null)
fi

[ -z "$test_files" ] && { echo "No tests found in $TESTDIR"; exit 1; }

total_suites=0 failed_suites=0 failed_names=""
printf "${BOLD}Running Go cross-compilation tests${RESET}\n\n"

for test_file in $test_files; do
    name=$(basename "$test_file" .sh)
    total_suites=$((total_suites + 1))
    printf "%s--- %s ---%s\n" "$BOLD" "$name" "$RESET"
    sh "$test_file"
    [ $? -ne 0 ] && { failed_suites=$((failed_suites + 1)); failed_names="$failed_names $name"; }
    echo ""
done

echo "================================================================"
if [ $failed_suites -eq 0 ]; then
    printf "${GREEN}${BOLD}ALL %d test suites passed${RESET}\n" "$total_suites"; exit 0
else
    printf "${RED}${BOLD}%d of %d test suites FAILED:${RESET}\n" "$failed_suites" "$total_suites"
    for name in $failed_names; do printf "  ${RED}%s${RESET}\n" "$name"; done; exit 1
fi
