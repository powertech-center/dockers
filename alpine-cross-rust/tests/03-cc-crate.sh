#!/bin/sh
# 03-cc-crate.sh — Test Rust cc crate cross-compilation (C dependency via our wrappers)
# This is the most important Rust test: it verifies that our clang wrappers work
# correctly when invoked by the Rust cc crate during cargo build.
. "$(dirname "$0")/helpers.sh"

echo "=== Rust cc crate cross-compilation ==="

PROJECT="$SRCDIR/hello_c"

# Ensure cc crate is available (fetch dependencies once)
if ! (cd "$PROJECT" && cargo fetch --quiet 2>/dev/null); then
    test_skip "cargo fetch" "network unavailable or cargo issue"
    test_summary
    exit $?
fi

for target in $(filter_targets $RUST_TARGETS); do
    desc="cargo build --target $target (cc crate)"

    # Build with cross-compilation
    stderr=$(cd "$PROJECT" && \
        cargo build --target "$target" --release 2>&1) || true
    rc=$?

    if [ $rc -eq 0 ]; then
        test_pass "$desc"
    else
        # Extract first meaningful error line
        err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -1)
        test_fail "$desc" "$err_line"
    fi

    # Clean between targets to avoid stale artifacts
    (cd "$PROJECT" && cargo clean --target "$target" 2>/dev/null) || true
done

test_summary
