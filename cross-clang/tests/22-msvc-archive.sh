#!/bin/sh
# 22-msvc-archive.sh — Create and link MSVC archives using the conventional lib name
. "$(dirname "$0")/helpers.sh"

echo "=== MSVC archive compatibility ==="

printf 'int add(int a, int b) { return a + b; }\n' > "$WORKDIR/add.c"
printf 'int add(int, int); int main(void) { return add(1, 2) != 3; }\n' > "$WORKDIR/main.c"

for target in $(filter_targets $WINDOWS_MSVC_TARGETS); do
    desc="${target}: compile, lib -out:, and link"
    # Match the archive command emitted by jemalloc's configure/Makefile.
    if stderr=$({
        cd "$WORKDIR" &&
        "clang-${target}" /c add.c /Foadd.obj &&
        lib -nologo -out:add.lib add.obj &&
        llvm-ar t add.lib | grep -qx add.obj &&
        "clang-${target}" main.c add.lib /Femain.exe
    } 2>&1); then
        test_pass "$desc"
    else
        test_fail "$desc" "$stderr"
    fi
done

test_summary
