#!/bin/sh
# 03-static-libs.sh — Verify static libc++, libc++abi, libunwind, compiler-rt
. "$(dirname "$0")/helpers.sh"

echo "=== Static libraries ==="

# ── compiler-rt resource directory ──
resdir=$(clang --print-resource-dir 2>/dev/null)
if [ -d "$resdir" ]; then
    test_pass "clang resource dir exists ($resdir)"
else
    test_fail "clang resource dir exists" "clang --print-resource-dir returned '$resdir'"
fi

# ── compiler-rt builtins ──
if find "$resdir/lib" -name "libclang_rt.builtins*" 2>/dev/null | grep -q .; then
    test_pass "compiler-rt builtins present"
else
    test_fail "compiler-rt builtins present" "no libclang_rt.builtins* under $resdir/lib"
fi

# ── static libc++ ──
if find /usr -name "libc++.a" 2>/dev/null | grep -q .; then
    path=$(find /usr -name "libc++.a" 2>/dev/null | head -1)
    test_pass "static libc++ ($path)"
else
    test_fail "static libc++" "libc++.a not found"
fi

# ── static libc++abi ──
if find /usr -name "libc++abi.a" 2>/dev/null | grep -q .; then
    path=$(find /usr -name "libc++abi.a" 2>/dev/null | head -1)
    test_pass "static libc++abi ($path)"
else
    test_fail "static libc++abi" "libc++abi.a not found"
fi

# ── static libunwind ──
if find /usr -name "libunwind.a" 2>/dev/null | grep -q .; then
    path=$(find /usr -name "libunwind.a" 2>/dev/null | head -1)
    test_pass "static libunwind ($path)"
else
    test_fail "static libunwind" "libunwind.a not found"
fi

# ── Compile + link static C++ binary ──
desc="static C++ build (-stdlib=libc++ -static)"
cat > "$WORKDIR/static_test.cpp" << 'CPPEOF'
#include <iostream>
#include <vector>
int main() {
    std::vector<int> v = {1, 2, 3};
    for (auto x : v) std::cout << x;
    std::cout << std::endl;
    return 0;
}
CPPEOF

stderr=$(clang++ -stdlib=libc++ -static -fuse-ld=lld \
    -rtlib=compiler-rt --unwindlib=libunwind \
    -lc++abi \
    "$WORKDIR/static_test.cpp" -o "$WORKDIR/static_test" 2>&1)
if [ $? -eq 0 ] && [ -f "$WORKDIR/static_test" ]; then
    test_pass "$desc"
    # Verify it actually runs
    output=$("$WORKDIR/static_test" 2>&1)
    if [ $? -eq 0 ] && echo "$output" | grep -q "123"; then
        test_pass "static binary runs correctly"
    else
        test_fail "static binary runs correctly" "output: $output"
    fi
else
    test_fail "$desc" "$stderr"
fi

test_summary
