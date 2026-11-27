#!/bin/sh
# 23-response-files.sh — Let Clang parse compile/link options inside response files
. "$(dirname "$0")/helpers.sh"

mkdir "$WORKDIR/with spaces"
printf 'int main(void) { return 0; }\n' > "$WORKDIR/with spaces/main.c"
for target in $(filter_targets $ALL_TARGETS); do
    for compiler in clang clang++; do
        for mode in compile link; do
            desc="${compiler}-${target}: ${mode} through @file.rsp"
            if _is_msvc "$target"; then
                set -- /WX "$WORKDIR/with spaces/main.c" "/Fe$WORKDIR/main.exe"
                [ "$mode" = compile ] && set -- /c /WX "$WORKDIR/with spaces/main.c" "/Fo$WORKDIR/main.obj"
            else
                set -- -Wextra -Werror -x c "$WORKDIR/with spaces/main.c" -o "$WORKDIR/main"
                [ "$mode" = compile ] && set -- -c "$@"
            fi
            printf '"%s"\n' "$@" > "$WORKDIR/args.rsp"
            if stderr=$("${compiler}-${target}" "@$WORKDIR/args.rsp" 2>&1); then
                test_pass "$desc"
            else
                test_fail "$desc" "$stderr"
            fi
        done
        case "$target" in *-windows-msvc) continue ;; esac
        printf '"%s"\n' -fuse-ld=lld -fuse-ld=invalid -x c "$WORKDIR/with spaces/main.c" -o "$WORKDIR/main" > "$WORKDIR/args.rsp"
        desc="${compiler}-${target}: linker override inside @file.rsp"
        if stderr=$("${compiler}-${target}" "@$WORKDIR/args.rsp" 2>&1); then
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
