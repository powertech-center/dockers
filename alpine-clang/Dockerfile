# PowerTech Alpine Clang (native)
# LLVM/Clang development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-clang

FROM ghcr.io/powertech-center/alpine-dev:latest

RUN apk add --no-cache \
    clang \
    clang-dev \
    lld \
    llvm-dev \
    llvm-static \
    compiler-rt

CMD ["/bin/sh"]
