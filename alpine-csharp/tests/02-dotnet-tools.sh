#!/bin/sh
# 02-dotnet-tools.sh — Verify .NET dev tools are installed
. "$(dirname "$0")/helpers.sh"

echo "=== .NET dev tools ==="

# Check global tools installed for 'dev' user
for tool in csharpier dotnet-outdated reportgenerator; do
    # Global tools are in ~/.dotnet/tools; check as dev user
    if [ -f "/home/dev/.dotnet/tools/$tool" ]; then
        test_pass "$tool available"
    else
        test_skip "$tool available" "not installed (optional)"
    fi
done

test_summary
