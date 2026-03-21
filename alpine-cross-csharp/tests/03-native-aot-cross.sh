#!/bin/sh
# 03-native-aot-cross.sh — NativeAOT cross-compilation for all Linux targets
. "$(dirname "$0")/helpers.sh"

echo "=== NativeAOT cross-compilation ==="

PROJECT="$SRCDIR/hello_aot"

for entry in $AOT_TARGETS; do
    rid=$(echo "$entry" | cut -d: -f1)
    compiler=$(echo "$entry" | cut -d: -f2)
    sysroot=$(echo "$entry" | cut -d: -f3)

    if [ -n "$TARGET_FILTER" ]; then
        case "$rid" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    desc="NativeAOT publish -r $rid (CC=$compiler)"
    output="$WORKDIR/aot_${rid}"

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

    if [ $rc -eq 0 ] && [ -f "$output/hello_aot" ]; then
        test_pass "$desc"
    else
        err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -3)
        test_fail "$desc" "$err_line"
        continue
    fi

    # Verify it's an ELF binary
    if readelf -h "$output/hello_aot" >/dev/null 2>&1; then
        test_pass "$rid: output is ELF binary"
    else
        test_fail "$rid: output is ELF binary" "readelf failed — not a valid ELF"
    fi

    # For native host target, verify it actually runs
    if [ "$rid" = "linux-musl-x64" ]; then
        run_output=$("$output/hello_aot" 2>&1)
        if [ $? -eq 0 ] && echo "$run_output" | grep -q "Hello from NativeAOT"; then
            test_pass "$rid: binary runs correctly"
        else
            test_fail "$rid: binary runs correctly" "$run_output"
        fi
    fi
done

test_summary
