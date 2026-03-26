#!/bin/sh
# 03-native-aot-cross.sh — NativeAOT cross-compilation for all targets
#
# Linux/macOS: CppCompilerAndLinker (clang wrapper) + SysRoot
# Windows:     CppLinker (lld wrapper) + IlcUseEnvironmentalTools
#              (Windows.targets uses MSVC-style flags, needs lld-link not clang)
. "$(dirname "$0")/helpers.sh"

echo "=== NativeAOT cross-compilation ==="

PROJECT="$SRCDIR/hello_aot"

# --- Linux and macOS targets (Unix.targets: CppCompilerAndLinker + SysRoot) ---
for entry in $AOT_TARGETS; do
    rid=$(echo "$entry" | cut -d: -f1)
    compiler=$(echo "$entry" | cut -d: -f2)
    sysroot=$(echo "$entry" | cut -d: -f3)

    if [ -n "$TARGET_FILTER" ]; then
        case "$rid" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    desc="NativeAOT publish -r $rid (CC=$compiler)"
    output="$WORKDIR/aot_${rid}"

    # Platform-specific MSBuild properties:
    # - Linux: LinkerFlavor=lld (NativeAOT defaults to -fuse-ld=bfd which is x64-only)
    # - macOS: DisableUnsupportedError (cross-OS policy gate), StripSymbols=false
    extra_props=""
    case "$rid" in
        linux-*) extra_props="-p:LinkerFlavor=lld -p:ObjCopyName=llvm-objcopy" ;;
        osx-*)   extra_props="-p:DisableUnsupportedError=true -p:StripSymbols=false -p:ObjCopyName=llvm-objcopy" ;;
    esac

    stderr=$(cd "$PROJECT" && \
        dotnet publish -r "$rid" \
            -p:PublishAot=true \
            -p:CppCompilerAndLinker="$compiler" \
            -p:SysRoot="$sysroot" \
            $extra_props \
            -o "$output" \
            --nologo -v quiet 2>&1)
    rc=$?

    # Determine expected binary name
    case "$rid" in
        win-*)  binary="$output/hello_aot.exe" ;;
        *)      binary="$output/hello_aot" ;;
    esac

    if [ $rc -eq 0 ] && [ -f "$binary" ]; then
        test_pass "$desc"
    else
        err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -3)
        test_fail "$desc" "$err_line"
        continue
    fi

    # For native host target, verify it actually runs
    if [ "$rid" = "linux-musl-x64" ]; then
        run_output=$("$binary" 2>&1)
        if [ $? -eq 0 ] && echo "$run_output" | grep -q "Hello from NativeAOT"; then
            test_pass "$rid: binary runs correctly"
        else
            test_fail "$rid: binary runs correctly" "$run_output"
        fi
    fi
done

# --- Windows targets (Windows.targets: CppLinker + lld-link style flags) ---
for entry in $AOT_WINDOWS_TARGETS; do
    rid=$(echo "$entry" | cut -d: -f1)
    linker=$(echo "$entry" | cut -d: -f2)

    if [ -n "$TARGET_FILTER" ]; then
        case "$rid" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    desc="NativeAOT publish -r $rid (linker=$linker)"
    output="$WORKDIR/aot_${rid}"

    stderr=$(cd "$PROJECT" && \
        dotnet publish -r "$rid" \
            -p:PublishAot=true \
            -p:DisableUnsupportedError=true \
            -p:CppLinker="$linker" \
            -p:IlcUseEnvironmentalTools=true \
            -p:StripSymbols=false \
            -p:EnableSourceLink=false \
            -o "$output" \
            --nologo -v quiet 2>&1)
    rc=$?

    binary="$output/hello_aot.exe"

    if [ $rc -eq 0 ] && [ -f "$binary" ]; then
        test_pass "$desc"
    else
        err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -3)
        test_fail "$desc" "$err_line"
    fi
done

test_summary
