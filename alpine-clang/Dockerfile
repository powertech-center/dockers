# PowerTech Alpine Clang (native)
# LLVM/Clang development environment for native (host) compilation
#
# Image: ghcr.io/powertech-center/alpine-clang

FROM ghcr.io/powertech-center/alpine-dev:latest

COPY shared/alpine-clang.sh /tmp/alpine-clang.sh
RUN sh /tmp/alpine-clang.sh && rm /tmp/alpine-clang.sh

CMD ["/bin/sh"]
