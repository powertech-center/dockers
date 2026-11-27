#!/bin/sh
# 06-static-library.sh — NativeAOT static libraries use the image's archive tools
. "$(dirname "$0")/helpers.sh"

for rid in linux-musl-x64 linux-musl-arm64 linux-x64 linux-arm64 osx-x64 osx-arm64 win-x64 win-arm64; do
    case "$rid" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    desc="${rid}: NativeAOT static library"
    tool_path="$PATH"
    case "$rid" in
        win-x64) tool_path="/opt/toolchains/windows-x86_64/bin:$PATH" ;;
        win-arm64) tool_path="/opt/toolchains/windows-aarch64/bin:$PATH" ;;
    esac
    if stderr=$(cd "$SRCDIR/native_lib" && PATH="$tool_path" dotnet publish -r "$rid" \
        -p:DisableUnsupportedError=true -p:IlcUseEnvironmentalTools=true \
        -p:StripSymbols=false -o "$WORKDIR/$rid" --nologo -v quiet 2>&1); then
        case "$rid" in
            win-*) library="$WORKDIR/$rid/native_lib.lib" ;;
            *) library="$WORKDIR/$rid/native_lib.a" ;;
        esac
        if [ -f "$library" ] && llvm-nm "$library" 2>/dev/null | grep -q 'answer'; then
            test_pass "$desc"
        else
            test_fail "$desc" "archive missing or exported answer symbol missing"
        fi
    else
        test_fail "$desc" "$(printf '%s\n' "$stderr" | tail -10)"
    fi
done
test_summary
