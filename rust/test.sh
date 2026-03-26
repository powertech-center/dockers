#!/bin/sh
# Tests for rust image — distro-independent
set -e

PASS=0
FAIL=0

check() {
    desc="$1"; shift
    if "$@" > /dev/null 2>&1; then
        echo "  PASS  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $desc"
        FAIL=$((FAIL + 1))
    fi
}

echo "=== Rust toolchain tests ==="

# -- Toolchain --
echo ""
echo "--- Toolchain ---"
check "rustc available"         rustc --version
check "cargo available"         cargo --version
check "rustup available"        rustup --version
check "RUSTUP_HOME set"        test -n "$RUSTUP_HOME"
check "CARGO_HOME set"         test -n "$CARGO_HOME"

# -- Components --
echo ""
echo "--- Components ---"
check "rustfmt available"       rustfmt --version
check "clippy available"        cargo clippy --version

# -- Tools --
echo ""
echo "--- Tools ---"
check "cargo-audit available"   cargo audit --version

# -- Compile test --
echo ""
echo "--- Compile test ---"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

mkdir -p "$tmpdir/src"
cat > "$tmpdir/Cargo.toml" <<'TOML'
[package]
name = "hello"
version = "0.1.0"
edition = "2021"
TOML

cat > "$tmpdir/src/main.rs" <<'RS'
fn main() {
    println!("Hello from Rust");
}
RS

if cargo build --manifest-path "$tmpdir/Cargo.toml" --release 2>/dev/null; then
    check "cargo build succeeds"  true
    output=$("$tmpdir/target/release/hello" 2>&1)
    if echo "$output" | grep -q "Hello from Rust"; then
        check "binary runs correctly" true
    else
        check "binary runs correctly" false
    fi
else
    check "cargo build succeeds" false
fi

# -- Summary --
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="

if [ "$FAIL" -gt 0 ]; then
    exit 1
fi
