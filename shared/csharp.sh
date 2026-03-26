#!/bin/sh
# csharp.sh — .NET SDK (latest LTS) installation
# Used by: csharp, cross-csharp
#
# Usage: sh csharp.sh <pkg>
#   pkg = apk | deb

set -e

PKG="${1:?Usage: csharp.sh <pkg>}"

# NativeAOT build dependency
case "$PKG" in
    apk) apk add --no-cache zlib-dev ;;
    deb) apt-get update && apt-get install -y --no-install-recommends zlib1g-dev \
         && rm -rf /var/lib/apt/lists/* ;;
    *)   echo "Unknown pkg manager: $PKG" >&2; exit 1 ;;
esac

# Install .NET SDK (latest LTS) via official install script
export DOTNET_INSTALL_DIR="/usr/share/dotnet"
wget -qO- https://builds.dotnet.microsoft.com/dotnet/scripts/v1/dotnet-install.sh | bash -s -- \
    --channel LTS \
    --install-dir "$DOTNET_INSTALL_DIR"
ln -sf "$DOTNET_INSTALL_DIR/dotnet" /usr/local/bin/dotnet

# Warm up the NuGet package cache and verify SDK works
dotnet --info > /dev/null 2>&1

# Prepare solution directory — writable for all users
mkdir -p /app && chmod 777 /app
