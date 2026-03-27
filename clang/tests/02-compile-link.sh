#!/bin/sh
# 02-compile-link.sh — Verify C and C++ compilation and linking work
. "$(dirname "$0")/helpers.sh"

echo "=== Compilation and linking ==="

# ── C compile ──
desc="C compile (hello.c)"
stderr=$(clang -c "$SRCDIR/hello.c" -o "$WORKDIR/hello_c.o" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/hello_c.o" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

# ── C link ──
desc="C link (hello.c → executable)"
stderr=$(clang "$WORKDIR/hello_c.o" -o "$WORKDIR/hello_c" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/hello_c" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

# ── C run ──
desc="C executable runs"
output=$("$WORKDIR/hello_c" 2>&1)
if [ $? -eq 0 ] && echo "$output" | grep -q "Hello from C"; then
    test_pass "$desc"
else
    test_fail "$desc" "output: $output"
fi

# ── C++ compile ──
desc="C++ compile (hello.cpp)"
stderr=$(clang++ -c "$SRCDIR/hello.cpp" -o "$WORKDIR/hello_cpp.o" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/hello_cpp.o" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

# ── C++ link ──
desc="C++ link (hello.cpp → executable)"
stderr=$(clang++ "$WORKDIR/hello_cpp.o" -o "$WORKDIR/hello_cpp" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/hello_cpp" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

# ── C++ run ──
desc="C++ executable runs"
output=$("$WORKDIR/hello_cpp" 2>&1)
if [ $? -eq 0 ] && echo "$output" | grep -q "Hello from C++"; then
    test_pass "$desc"
else
    test_fail "$desc" "output: $output"
fi

# ── Link with lld ──
desc="C link with lld (-fuse-ld=lld)"
stderr=$(clang -fuse-ld=lld "$SRCDIR/hello.c" -o "$WORKDIR/hello_lld" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/hello_lld" ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

test_summary
