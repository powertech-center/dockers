#!/bin/sh
# csharp.sh — .NET SDK, dev tools, and NativeAOT ILC prefetch
# Used by: csharp, cross-csharp
#
# Usage: sh csharp.sh <pkg> [<rid> ...]
#   pkg = apk | deb
#   rid = NativeAOT runtime IDs to prefetch (e.g. linux-musl-x64, win-x64)

set -e

PKG="${1:?Usage: csharp.sh <pkg> [<rid> ...]}"
shift

# ── NativeAOT build dependency ──────────────────────────────────────────────
case "$PKG" in
    apk) apk add --no-cache zlib-dev ;;
    deb) apt-get update && apt-get install -y --no-install-recommends zlib1g-dev \
         && rm -rf /var/lib/apt/lists/* ;;
    *)   echo "Unknown pkg manager: $PKG" >&2; exit 1 ;;
esac

# ── .NET SDK (latest LTS) ──────────────────────────────────────────────────
export DOTNET_INSTALL_DIR="/usr/share/dotnet"
wget -qO- https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.sh | bash -s -- \
    --channel LTS \
    --install-dir "$DOTNET_INSTALL_DIR"
ln -sf "$DOTNET_INSTALL_DIR/dotnet" /usr/local/bin/dotnet

# Warm up the NuGet package cache and verify SDK works
dotnet --info > /dev/null 2>&1

# Prepare solution directory — writable for all users
mkdir -p /app && chmod 777 /app

# ── Dev tools (formatting, updates, coverage) ───────────────────────────────
export DOTNET_CLI_HOME=/opt/dotnet-tools
export PATH="${PATH}:/opt/dotnet-tools/.dotnet/tools"

dotnet tool install -g csharpier
dotnet tool install -g dotnet-outdated-tool
dotnet tool install -g dotnet-reportgenerator-globaltool

chmod -R a+rX ${DOTNET_CLI_HOME}

# ── Pre-fetch NativeAOT ILC runtime packages ────────────────────────────────
# Downloads runtime.<rid>.Microsoft.DotNet.ILCompiler packages so that
# `dotnet publish -p:PublishAot=true` works instantly without network access.
if [ $# -gt 0 ]; then
    DOTNET_MAJOR=$(dotnet --version | cut -d. -f1)
    TFM="net${DOTNET_MAJOR}.0"

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

    for rid in "$@"; do
        echo "  Fetching ILC runtime for $rid..."
        dotnet restore "$tmpdir/prefetch.csproj" -r "$rid" --nologo -v quiet
    done
    echo "  ILC runtimes cached for: $*"
fi
