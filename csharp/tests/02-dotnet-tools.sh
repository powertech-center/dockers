#!/bin/sh
# 02-dotnet-tools.sh — Verify .NET dev tools are installed
. "$(dirname "$0")/helpers.sh"

echo "=== .NET dev tools ==="

# Check global tools in /opt/dotnet-tools (shared for all users)
for tool in csharpier dotnet-outdated reportgenerator; do
    if [ -f "/opt/dotnet-tools/.dotnet/tools/$tool" ]; then
        test_pass "$tool available"
    else
        test_skip "$tool available" "not installed (optional)"
    fi
done

test_summary
