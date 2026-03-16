# PowerTech Alpine Clang
# LLVM/Clang development and cross-compilation environment
# Inherits clang cross-compilation for all 10 targets from alpine-cross-platform
#
# Image: ghcr.io/powertech-center/alpine-cross-clang

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

COPY shared/alpine-clang.sh /tmp/alpine-clang.sh
RUN sh /tmp/alpine-clang.sh && rm /tmp/alpine-clang.sh

CMD ["/bin/sh"]
