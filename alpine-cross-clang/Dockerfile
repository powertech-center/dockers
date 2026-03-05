# PowerTech Alpine Clang
# LLVM/Clang development and cross-compilation environment
# Inherits clang cross-compilation for all 8 targets from alpine-cross-platform
#
# Image: ghcr.io/powertech-center/alpine-cross-clang

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

# clang is already installed in alpine-cross-platform (used for cross-compilation wrappers)
# Here we add LLVM/Clang development libraries for C/C++ development:
#   clang-dev    — libclang headers and libraries (for tools using libclang API)
#   llvm-dev     — LLVM headers and libraries (for tools using LLVM API, e.g. custom passes)
#   llvm-static  — static LLVM libraries (for statically linked LLVM tools)
#   compiler-rt  — runtime library (builtins, sanitizers, profiling)
#   lld          — already in alpine-cross-platform, listed explicitly for clarity
RUN apk add --no-cache \
    clang-dev \
    llvm-dev \
    llvm-static \
    compiler-rt

CMD ["/bin/sh"]
