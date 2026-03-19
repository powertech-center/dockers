#!/bin/sh
# alpine-clang.sh — LLVM/Clang development libraries installation
# Used by: alpine-clang, alpine-cross-clang

set -e

apk add --no-cache \
    clang \
    clang-dev \
    lld \
    llvm-dev \
    llvm-static \
    compiler-rt

# Alpine installs llvm-config with version suffix (e.g. llvm-config-21);
# create unversioned symlink so tools and tests can find it
ver=$(ls /usr/bin/llvm-config-* 2>/dev/null | head -1)
[ -n "$ver" ] && ln -sf "$(basename "$ver")" /usr/bin/llvm-config
