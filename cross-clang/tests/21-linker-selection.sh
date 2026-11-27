#!/bin/sh
# 21-linker-selection.sh — Linker selection, strict warnings, LTO, and quoted paths
. "$(dirname "$0")/helpers.sh"

echo "=== Linker selection regressions ==="

mkdir "$WORKDIR/with spaces"
printf 'int main(void) { return 0; }\n' > "$WORKDIR/with spaces/main.c"
cp "$WORKDIR/with spaces/main.c" "$WORKDIR/with spaces/main.cpp"

for target in $(filter_targets $ALL_TARGETS); do
    for compiler in clang clang++; do
        wrapper="${compiler}-${target}"
        source="$WORKDIR/with spaces/main.c"
        [ "$compiler" = "clang++" ] && source="$WORKDIR/with spaces/main.cpp"
        output="$WORKDIR/with spaces/${compiler}-${target}$(exe_ext "$target")"

        # Invoke directly: the MSVC helper also joins arguments into a string.
        for mode in compile link lto; do
            if _is_msvc "$wrapper"; then
                set -- /WX /clang:-Wextra "$source"
                case "$mode" in
                    compile) set -- /c "$@" "/Fo${output}.obj" ;;
                    link) set -- "$@" "/Fe${output}" ;;
                    lto) set -- -flto "$@" "/Fe${output}" ;;
                esac
            else
                set -- -Wextra -Werror "$source" -o "$output"
                case "$mode" in
                    compile) set -- -c "$@" ;;
                    lto) set -- -flto "$@" ;;
                esac
            fi
            desc="${wrapper}: ${mode} with strict warnings and spaces"
            if stderr=$("$wrapper" "$@" 2>&1); then
                test_pass "$desc"
            else
                test_fail "$desc" "$stderr"
            fi
        done
    done

    # clang-cl has a separate MSVC linker selection implementation.
    case "$target" in *-windows-msvc) continue ;; esac

    # A real linker probe records invocation, then performs the normal link.
    probe="$WORKDIR/with spaces/linker"
    printf '#!/bin/sh\nprintf "called\\n" >> "%s"\nexec lld-%s "$@"\n' \
        "$WORKDIR/called" "$target" > "$probe"
    chmod +x "$probe"
    for compiler in clang clang++; do
        wrapper="${compiler}-${target}"
        source="$WORKDIR/with spaces/main.c"
        [ "$compiler" = "clang++" ] && source="$WORKDIR/with spaces/main.cpp"
        output="$WORKDIR/with spaces/override$(exe_ext "$target")"
        rm -f "$WORKDIR/called"
        desc="${wrapper}: explicit --ld-path takes precedence"
        if stderr=$("$wrapper" -Wextra -Werror -fuse-ld=lld "--ld-path=$probe" "$source" -o "$output" 2>&1) &&
            [ -s "$WORKDIR/called" ]; then
            test_pass "$desc"
        else
            test_fail "$desc" "$stderr"
        fi

        desc="${wrapper}: last -fuse-ld wins (invalid then lld)"
        if stderr=$("$wrapper" -Wextra -Werror -fuse-ld=invalid -fuse-ld=lld "$source" -o "$output" 2>&1); then
            test_pass "$desc"
        else
            test_fail "$desc" "$stderr"
        fi

        desc="${wrapper}: last -fuse-ld wins (lld then invalid)"
        if stderr=$("$wrapper" -fuse-ld=lld -fuse-ld=invalid "$source" -o "$output" 2>&1); then
            test_fail "$desc" "invalid linker was overridden"
        else
            case "$stderr" in
                *"invalid linker name"*) test_pass "$desc" ;;
                *) test_fail "$desc" "$stderr" ;;
            esac
        fi
    done
done

test_summary
