#!/bin/sh
# clang.sh — LLVM/Clang development libraries installation
# Used by: clang, cross-clang
#
# Usage: sh clang.sh <pkg>
#   pkg = apk | deb

set -e

PKG="${1:?Usage: clang.sh <pkg>}"

case "$PKG" in
    apk)
        apk add --no-cache \
            clang \
            clang-dev \
            lld \
            llvm \
            llvm-dev \
            llvm-static \
            compiler-rt
        ;;
    deb)
        apt-get update && apt-get install -y --no-install-recommends \
            clang \
            lld \
            llvm-dev \
            libclang-dev \
            libc++-dev \
            libc++abi-dev \
            && rm -rf /var/lib/apt/lists/*
        ;;
    *)
        echo "Unknown pkg manager: $PKG" >&2
        exit 1
        ;;
esac

# Some distros install llvm-config with version suffix (e.g. llvm-config-21);
# create unversioned symlink so tools and tests can find it
if ! command -v llvm-config >/dev/null 2>&1; then
    ver=$(ls /usr/bin/llvm-config-* 2>/dev/null | head -1)
    [ -n "$ver" ] && ln -sf "$(basename "$ver")" /usr/bin/llvm-config
fi
