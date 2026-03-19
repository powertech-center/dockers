#!/bin/sh
# 13-windres-dlltool.sh — Test windres and dlltool wrappers (audit issues 1.7, 1.8)
. "$(dirname "$0")/helpers.sh"

echo "=== windres and dlltool wrappers ==="

# Test 1: windres compiles .rc file to .o (COFF)
for arch in x86_64 aarch64; do
    target="${arch}-windows-gnu"
    if [ -n "$TARGET_FILTER" ]; then
        case "$target" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    wrapper="windres-${target}"
    output="$WORKDIR/winres_${arch}.o"
    desc="windres-${target}: compile .rc"

    stderr=$("$wrapper" "$SRCDIR/winres.rc" -O coff -o "$output" 2>&1 1>/dev/null)
    if [ $? -eq 0 ] && [ -f "$output" ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $stderr"
    fi
done

# Test 2: dlltool --help prints usage (smoke test)
# Note: llvm-dlltool --help returns exit code 1 (LLVM convention), so check output instead
for arch in x86_64 aarch64; do
    target="${arch}-windows-gnu"
    if [ -n "$TARGET_FILTER" ]; then
        case "$target" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    wrapper="dlltool-${target}"
    desc="dlltool-${target}: --help"

    output=$("$wrapper" --help 2>&1)
    if echo "$output" | grep -q "USAGE:"; then
        test_pass "$desc"
    else
        test_fail "$desc" "no usage output: $output"
    fi
done

# Test 3: dlltool creates import library from .def
for arch in x86_64 aarch64; do
    target="${arch}-windows-gnu"
    if [ -n "$TARGET_FILTER" ]; then
        case "$target" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    wrapper="dlltool-${target}"
    def_file="$WORKDIR/test_${arch}.def"
    lib_file="$WORKDIR/test_${arch}.a"
    desc="dlltool-${target}: create import lib from .def"

    # Create a minimal .def file
    cat > "$def_file" <<'DEFEOF'
LIBRARY test.dll
EXPORTS
    TestFunction @1
DEFEOF

    stderr=$("$wrapper" -d "$def_file" -l "$lib_file" 2>&1 1>/dev/null)
    if [ $? -eq 0 ] && [ -f "$lib_file" ]; then
        test_pass "$desc"
    else
        test_fail "$desc" "stderr: $stderr"
    fi
done

test_summary
