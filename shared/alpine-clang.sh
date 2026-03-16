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
