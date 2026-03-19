#!/bin/sh
# 03-cc-crate.sh — Test Rust cc crate cross-compilation (C dependency via our wrappers)
# This is the most important Rust test: it verifies that our clang wrappers work
# correctly when invoked by the Rust cc crate during cargo build,
# AND that the linker (clang driver) successfully produces a binary.
. "$(dirname "$0")/helpers.sh"

echo "=== Rust cc crate cross-compilation ==="

PROJECT="$SRCDIR/hello_c"

# Ensure cc crate is available (fetch dependencies once)
if ! (cd "$PROJECT" && cargo fetch --quiet 2>/dev/null); then
    test_skip "cargo fetch" "network unavailable or cargo issue"
    test_summary
    exit $?
fi

# Binary name and extension per target
bin_path() {
    target="$1"
    case "$target" in
        *-windows-*) echo "target/$target/release/hello_c.exe" ;;
        *)           echo "target/$target/release/hello_c" ;;
    esac
}

for target in $(filter_targets $RUST_TARGETS); do
    desc="cargo build --target $target (cc crate)"

    # Remove previous artifact to ensure we detect fresh link
    artifact="$PROJECT/$(bin_path "$target")"
    rm -f "$artifact"

    # Build with cross-compilation
    stderr=$(cd "$PROJECT" && cargo build --target "$target" --release 2>&1)
    rc=$?

    if [ $rc -ne 0 ]; then
        err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -1)
        test_fail "$desc" "$err_line"
    elif [ ! -f "$artifact" ]; then
        test_fail "$desc" "build succeeded but binary not found: $(bin_path "$target")"
    else
        test_pass "$desc"
    fi

    # Clean between targets to avoid stale artifacts
    (cd "$PROJECT" && cargo clean --target "$target" 2>/dev/null) || true
done

test_summary
