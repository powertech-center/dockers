# PowerTech Alpine Clang
# LLVM/Clang development and cross-compilation environment
# Inherits Zig cross-compilation for all 6 targets from alpine-crossplatform
#
# Image: ghcr.io/powertech-center/alpine-cross-clang

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

# clang already inherited from alpine-crossplatform
RUN apk add --no-cache \
    clang-dev \
    lld \
    llvm-dev \
    llvm-static \
    compiler-rt

CMD ["/bin/sh"]
