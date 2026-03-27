#!/bin/sh
# 17-gnu-target-macros.sh — Test that GNU targets define expected predefined macros
# Verifies:
#   - Windows GNU: __MINGW32__, __GNUC__ defined; _MSC_VER NOT defined
#   - Windows MSVC: _MSC_VER defined; __MINGW32__ NOT defined
#   - This is critical for user code that branches on #ifdef _MSC_VER
. "$(dirname "$0")/helpers.sh"

echo "=== Target-specific predefined macros ==="

# Test 1: Windows GNU targets must have __MINGW32__ and NOT _MSC_VER
gnu_macro_test="$WORKDIR/gnu_macros.c"
cat > "$gnu_macro_test" << 'EOF'
#ifdef _MSC_VER
#error "_MSC_VER should NOT be defined for GNU targets"
#endif
#ifndef __GNUC__
#error "__GNUC__ must be defined for GNU targets"
#endif
#ifndef __MINGW32__
#error "__MINGW32__ must be defined for Windows GNU targets"
#endif
#ifndef _WIN32
#error "_WIN32 must be defined for Windows targets"
#endif
int main(void) { return 0; }
EOF

for target in $(filter_targets $WINDOWS_GNU_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: __MINGW32__ yes, _MSC_VER no"

    if compile_only "$wrapper" "$gnu_macro_test"; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $COMPILE_STDERR"
    fi
done

# Test 2: Windows MSVC targets must have _MSC_VER and NOT __MINGW32__
msvc_macro_test="$WORKDIR/msvc_macros.c"
cat > "$msvc_macro_test" << 'EOF'
#ifndef _MSC_VER
#error "_MSC_VER must be defined for MSVC targets"
#endif
#ifdef __MINGW32__
#error "__MINGW32__ should NOT be defined for MSVC targets"
#endif
#ifndef _WIN32
#error "_WIN32 must be defined for Windows targets"
#endif
int main(void) { return 0; }
EOF

for target in $(filter_targets $WINDOWS_MSVC_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: _MSC_VER yes, __MINGW32__ no"

    if compile_only "$wrapper" "$msvc_macro_test"; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $COMPILE_STDERR"
    fi
done

# Test 3: Linux targets must have __linux__ and NOT _WIN32
linux_macro_test="$WORKDIR/linux_macros.c"
cat > "$linux_macro_test" << 'EOF'
#ifndef __linux__
#error "__linux__ must be defined for Linux targets"
#endif
#ifdef _WIN32
#error "_WIN32 should NOT be defined for Linux targets"
#endif
int main(void) { return 0; }
EOF

for target in $(filter_targets $LINUX_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: __linux__ yes, _WIN32 no"

    if compile_only "$wrapper" "$linux_macro_test"; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $COMPILE_STDERR"
    fi
done

# Test 4: macOS targets must have __APPLE__ and NOT _WIN32
darwin_macro_test="$WORKDIR/darwin_macros.c"
cat > "$darwin_macro_test" << 'EOF'
#ifndef __APPLE__
#error "__APPLE__ must be defined for macOS targets"
#endif
#ifdef _WIN32
#error "_WIN32 should NOT be defined for macOS targets"
#endif
int main(void) { return 0; }
EOF

for target in $(filter_targets $DARWIN_TARGETS); do
    wrapper="clang-${target}"
    desc="${target}: __APPLE__ yes, _WIN32 no"

    if compile_only "$wrapper" "$darwin_macro_test"; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $COMPILE_STDERR"
    fi
done

test_summary
