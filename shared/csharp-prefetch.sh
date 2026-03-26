#!/bin/sh
# prefetch-ilc.sh — Pre-fetch NativeAOT ILC runtime packages into NuGet cache
#
# Usage: sh prefetch-ilc.sh <rid> [<rid> ...]
#
# Downloads runtime.<rid>.Microsoft.DotNet.ILCompiler packages so that
# `dotnet publish -p:PublishAot=true` works instantly without network access.

set -e

if [ $# -eq 0 ]; then
    echo "Usage: prefetch-ilc.sh <rid> [<rid> ...]" >&2
    exit 1
fi

# Detect installed .NET major version → TargetFramework moniker
DOTNET_MAJOR=$(dotnet --version | cut -d. -f1)
TFM="net${DOTNET_MAJOR}.0"

# Create a temporary project with PublishAot=true
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

cat > "$tmpdir/prefetch.csproj" <<CSPROJ
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>${TFM}</TargetFramework>
    <PublishAot>true</PublishAot>
  </PropertyGroup>
</Project>
CSPROJ

cat > "$tmpdir/Program.cs" <<'CS'
System.Console.WriteLine();
CS

# Restore for each RID — this pulls runtime.<rid>.Microsoft.DotNet.ILCompiler
for rid in "$@"; do
    echo "  Fetching ILC runtime for $rid..."
    dotnet restore "$tmpdir/prefetch.csproj" -r "$rid" --nologo -v quiet
done

echo "  ILC runtimes cached for: $*"
