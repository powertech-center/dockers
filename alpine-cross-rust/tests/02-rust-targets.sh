#!/bin/sh
# 02-rust-targets.sh — Verify all Rust cross-compilation targets are installed
. "$(dirname "$0")/helpers.sh"

echo "=== Rust target installation ==="

# Check rustup is available
if ! command -v rustup >/dev/null 2>&1; then
    test_fail "rustup available" "rustup not found in PATH"
    test_summary
    exit $?
fi
test_pass "rustup available"

# Check each target is installed
installed=$(rustup target list --installed 2>/dev/null)
for target in $(filter_targets $RUST_TARGETS); do
    desc="target installed: $target"
    if echo "$installed" | grep -q "^${target}$"; then
        test_pass "$desc"
    else
        test_fail "$desc" "not in 'rustup target list --installed'"
    fi
done

test_summary
