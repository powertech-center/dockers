#!/bin/sh
# 04-native-aot.sh — Build a NativeAOT binary for the host platform
. "$(dirname "$0")/helpers.sh"

echo "=== NativeAOT native compilation ==="

PROJECT="$SRCDIR/hello_aot"
OUTPUT="$WORKDIR/aot_output"

# Detect host RID (linux-musl-x64 on Alpine, linux-x64 on Debian/Ubuntu)
RID=$(dotnet --info 2>/dev/null | sed -n 's/.*RID:\s*//p' | head -1)
[ -z "$RID" ] && RID="linux-x64"

# Publish as NativeAOT
stderr=$(cd "$PROJECT" && \
    dotnet publish -r "$RID" \
        -p:PublishAot=true \
        -o "$OUTPUT" \
        --nologo -v quiet 2>&1)
rc=$?

if [ $rc -eq 0 ] && [ -f "$OUTPUT/hello_aot" ]; then
    test_pass "NativeAOT publish ($RID)"
else
    err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -3)
    test_fail "NativeAOT publish ($RID)" "$err_line"
    test_summary
    exit $?
fi

# Verify it's a native ELF binary (not a .NET assembly)
if readelf -h "$OUTPUT/hello_aot" >/dev/null 2>&1; then
    test_pass "output is native ELF binary"
else
    test_fail "output is native ELF binary" "readelf failed — not a valid ELF"
fi

# Run the native binary
output=$("$OUTPUT/hello_aot" 2>&1)
rc=$?
if [ $rc -eq 0 ] && echo "$output" | grep -q "Hello from NativeAOT"; then
    test_pass "NativeAOT binary runs correctly"
else
    test_fail "NativeAOT binary runs correctly" "exit=$rc, output: $output"
fi

test_summary
