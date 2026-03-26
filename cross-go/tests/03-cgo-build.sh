#!/bin/sh
# 03-cgo-build.sh — Test CGO cross-compilation for all targets
# This is the key Go test: verifies CGO_ENABLED=1 + our clang wrappers work.
. "$(dirname "$0")/helpers.sh"

echo "=== CGO cross-compilation ==="

PROJECT="$SRCDIR/cgo_hello"

# Build for each target
for entry in $GO_TARGETS; do
    goos=$(echo "$entry" | cut -d: -f1)
    goarch=$(echo "$entry" | cut -d: -f2)
    cc_var=$(echo "$entry" | cut -d: -f3)

    target_desc="${goos}/${goarch}"
    if [ -n "$TARGET_FILTER" ]; then
        case "$target_desc" in *"$TARGET_FILTER"*) ;; *) continue ;; esac
    fi

    cc_val=$(eval echo "\${${cc_var}:-}")
    if [ -z "$cc_val" ]; then
        test_fail "$target_desc: CGO build" "$cc_var not set"
        continue
    fi

    desc="${target_desc}: CGO build (CC=$cc_val)"

    # Determine output extension
    ext=""
    [ "$goos" = "windows" ] && ext=".exe"
    output="$WORKDIR/cgo_hello_${goos}_${goarch}${ext}"

    stderr=$(cd "$PROJECT" && \
        GOOS="$goos" GOARCH="$goarch" CGO_ENABLED=1 CC="$cc_val" \
        go build -o "$output" . 2>&1)
    rc=$?

    if [ $rc -eq 0 ] && [ -f "$output" ]; then
        test_pass "$desc"
    else
        err_line=$(echo "$stderr" | grep -m1 "error\|Error\|cannot" || echo "$stderr" | tail -3)
        test_fail "$desc" "$err_line"
    fi
done

test_summary
