#!/bin/sh
# 14-multiobj-link.sh — Test linking multiple object files
# Verifies the full compile+link pipeline with separate compilation units
. "$(dirname "$0")/helpers.sh"

echo "=== Multi-object linking ==="

for target in $(filter_targets $ALL_TARGETS); do
    wrapper="clang-${target}"
    ext=$(exe_ext "$target")
    desc="${target}: multi-object link"

    if _is_msvc "$wrapper"; then
        # MSVC (cl-mode): use /c, /Fo, relative paths in WORKDIR
        cp "$SRCDIR/add.c" "$WORKDIR/add.c"
        cp "$SRCDIR/use_add.c" "$WORKDIR/use_add.c"
        obj_add="add_${target}.obj"
        obj_main="use_add_${target}.obj"
        output="multi_${target}${ext}"

        ok=true
        stderr1=$(cd "$WORKDIR" && "$wrapper" /c add.c /Fo"$obj_add" 2>&1 1>/dev/null) || ok=false
        stderr2=$(cd "$WORKDIR" && "$wrapper" /c use_add.c /Fo"$obj_main" 2>&1 1>/dev/null) || ok=false

        if [ "$ok" = "false" ]; then
            test_fail "$desc (compile)" "stderr: $stderr1 $stderr2"
            continue
        fi

        link_stderr=$(cd "$WORKDIR" && "$wrapper" "$obj_add" "$obj_main" /Fe"$output" 2>&1 1>/dev/null)
        if [ $? -eq 0 ] && [ -f "$WORKDIR/$output" ]; then
            if [ -z "$link_stderr" ]; then
                test_pass "$desc"
            else
                test_fail "$desc (warnings)" "stderr: $link_stderr"
            fi
        else
            test_fail "$desc (link)" "exit code $?, stderr: $link_stderr"
        fi
    else
        # GCC-style: standard -c, -o flags
        obj_add="$WORKDIR/add_${target}.o"
        obj_main="$WORKDIR/use_add_${target}.o"
        output="$WORKDIR/multi_${target}${ext}"

        ok=true
        stderr1=$("$wrapper" -c "$SRCDIR/add.c" -o "$obj_add" 2>&1 1>/dev/null) || ok=false
        stderr2=$("$wrapper" -c "$SRCDIR/use_add.c" -o "$obj_main" 2>&1 1>/dev/null) || ok=false

        if [ "$ok" = "false" ]; then
            test_fail "$desc (compile)" "stderr: $stderr1 $stderr2"
            continue
        fi

        link_stderr=$("$wrapper" -o "$output" "$obj_add" "$obj_main" 2>&1 1>/dev/null)
        if [ $? -eq 0 ] && [ -f "$output" ]; then
            if [ -z "$link_stderr" ]; then
                test_pass "$desc"
            else
                test_fail "$desc (warnings)" "stderr: $link_stderr"
            fi
        else
            test_fail "$desc (link)" "exit code $?, stderr: $link_stderr"
        fi
    fi
done

test_summary
