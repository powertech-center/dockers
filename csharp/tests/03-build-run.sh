#!/bin/sh
# 03-build-run.sh — Build and run a simple .NET console app
. "$(dirname "$0")/helpers.sh"

echo "=== .NET build and run ==="

PROJECT="$SRCDIR/hello_console"

# Build
stderr=$(cd "$PROJECT" && dotnet build --nologo -v quiet 2>&1)
rc=$?
if [ $rc -eq 0 ]; then
    test_pass "dotnet build hello_console"
else
    err_line=$(echo "$stderr" | grep -m1 "error" || echo "$stderr" | tail -3)
    test_fail "dotnet build hello_console" "$err_line"
fi

# Run
output=$(cd "$PROJECT" && dotnet run --no-build 2>&1)
rc=$?
if [ $rc -eq 0 ] && echo "$output" | grep -q "Hello from C#"; then
    test_pass "dotnet run hello_console"
else
    test_fail "dotnet run hello_console" "expected 'Hello from C#', got: $output"
fi

test_summary
