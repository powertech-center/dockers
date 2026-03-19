#!/bin/sh
# 16-xw-macros.sh — Verify XW_* macros are NOT defined
# With MinGW-first approach (feature/mingw):
#   - xwin headers are unpatched (use _MSC_VER natively for MSVC)
#   - MinGW headers don't use _MSC_VER at all (for GNU)
#   - XW_* macros are no longer needed or defined by any wrapper
. "$(dirname "$0")/helpers.sh"

echo "=== XW_* macros NOT defined (MinGW approach) ==="

# Test: XW_C_VER must NOT be defined for any Windows target
no_xw_test="$WORKDIR/no_xw_macros.c"
cat > "$no_xw_test" << 'EOF'
#ifdef XW_C_VER
#error "XW_C_VER should NOT be defined (xwin headers are unpatched)"
#endif
int main(void) { return 0; }
EOF

for target in $(filter_targets $WINDOWS_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: XW_C_VER NOT defined"

    if compile_only "$wrapper" "$no_xw_test"; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $COMPILE_STDERR"
    fi
done

test_summary
