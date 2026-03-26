#!/bin/sh
# 04-publish-managed.sh — Standard self-contained publish for Windows/macOS targets
. "$(dirname "$0")/helpers.sh"

echo "=== Self-contained publish (managed IL) ==="

PROJECT="$SRCDIR/hello_aot"

for rid in $(filter_targets $PUBLISH_TARGETS); do
    desc="dotnet publish -r $rid --self-contained"
    output="$WORKDIR/managed_${rid}"

    stderr=$(cd "$PROJECT" && \
        dotnet publish -r "$rid" \
            --self-contained \
            -p:PublishAot=false \
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
    fi
done

test_summary
