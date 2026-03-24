#!/bin/sh
# 05-pinvoke-cross.sh — NativeAOT with P/Invoke (C interop) cross-compilation
. "$(dirname "$0")/helpers.sh"

echo "=== NativeAOT P/Invoke cross-compilation ==="

PROJECT="$SRCDIR/hello_pinvoke"

for entry in $AOT_TARGETS; do
    rid=$(echo "$entry" | cut -d: -f1)
    compiler=$(echo "$entry" | cut -d: -f2)
    sysroot=$(echo "$entry" | cut -d: -f3)

    if [ -n "$TARGET_FILTER" ]; then
        case "$rid" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    desc="NativeAOT P/Invoke -r $rid (CC=$compiler)"
    output="$WORKDIR/pinvoke_${rid}"

    stderr=$(cd "$PROJECT" && \
        dotnet publish -r "$rid" \
            -p:PublishAot=true \
            -p:CppCompilerAndLinker="$compiler" \
            -p:SysRoot="$sysroot" \
            -p:ObjCopyName=llvm-objcopy \
            -p:LinkerFlavor=lld \
            -o "$output" \
            --nologo -v quiet 2>&1)
    rc=$?

    if [ $rc -eq 0 ] && [ -f "$output/hello_pinvoke" ]; then
        test_pass "$desc"
    else
        err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -3)
        test_fail "$desc" "$err_line"
        continue
    fi

    # For native host target, verify it runs and the P/Invoke works
    if [ "$rid" = "linux-musl-x64" ]; then
        run_output=$("$output/hello_pinvoke" 2>&1)
        if [ $? -eq 0 ] && echo "$run_output" | grep -q "getpid()"; then
            test_pass "$rid: P/Invoke binary runs correctly"
        else
            test_fail "$rid: P/Invoke binary runs correctly" "$run_output"
        fi
    fi
done

test_summary
