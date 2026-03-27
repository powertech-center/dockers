#!/bin/sh
# 05-stdlib-override.sh — Verify C++ stdlib can be selected by the user
# Tests that both libc++ and the default stdlib work on the host compiler.
. "$(dirname "$0")/helpers.sh"

echo "=== C++ stdlib override ==="

cat > "$WORKDIR/stdlib_test.cpp" << 'CPPEOF'
#include <vector>
#include <algorithm>
#include <string>
int main() {
    std::vector<int> v = {3, 1, 2};
    std::sort(v.begin(), v.end());
    std::string s = "hello";
    return 0;
}
CPPEOF

# ── Test 1: default stdlib (no flag) ──
desc="C++ compile with default stdlib"
stderr=$(clang++ -c "$WORKDIR/stdlib_test.cpp" -o "$WORKDIR/default.o" 2>&1)
if [ $? -eq 0 ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

# ── Test 2: explicit -stdlib=libc++ ──
desc="C++ compile with -stdlib=libc++"
stderr=$(clang++ -stdlib=libc++ -c "$WORKDIR/stdlib_test.cpp" -o "$WORKDIR/libcxx.o" 2>&1)
if [ $? -eq 0 ]; then
    test_pass "$desc"
else
    test_fail "$desc" "$stderr"
fi

# ── Test 3: -stdlib=libc++ compile+link+run ──
desc="C++ build+run with -stdlib=libc++"
stderr=$(clang++ -stdlib=libc++ -fuse-ld=lld \
    -rtlib=compiler-rt --unwindlib=libunwind -lc++abi \
    "$WORKDIR/stdlib_test.cpp" -o "$WORKDIR/libcxx_test" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/libcxx_test" ]; then
    "$WORKDIR/libcxx_test" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "compiled but failed to run"
    fi
else
    test_fail "$desc" "$stderr"
fi

# ── Test 4: -nostdinc++ accepted ──
desc="-nostdinc++ flag accepted"
stderr=$(clang++ -nostdinc++ -fsyntax-only -x c++ - < /dev/null 2>&1)
if [ $? -eq 0 ]; then
    test_pass "$desc"
else
    if echo "$stderr" | grep -qi "unknown.*argument\|invalid.*option"; then
        test_fail "$desc" "flag not recognized: $stderr"
    else
        test_pass "$desc"
    fi
fi

test_summary
