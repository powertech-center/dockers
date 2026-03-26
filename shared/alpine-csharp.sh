#!/bin/sh
# alpine-csharp.sh — .NET SDK installation
# Used by: alpine-csharp, alpine-cross-csharp
#
# Installs the latest .NET 9 SDK from Alpine repos,
# plus NativeAOT build dependencies (clang, zlib).

set -e

# .NET SDK and NativeAOT dependencies
apk add --no-cache \
    dotnet-sdk-9.0 \
    zlib-dev

# Warm up the NuGet package cache and verify SDK works
dotnet --info > /dev/null 2>&1

# Prepare solution directory — writable for all users
mkdir -p /app && chmod 777 /app
