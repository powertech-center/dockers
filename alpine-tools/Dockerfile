# PowerTech Alpine Tools
# Base image with common utilities for development workflows
#
# Image: ghcr.io/powertech-center/alpine-tools

FROM alpine:latest

RUN apk add --no-cache \
    bash \
    git \
    ca-certificates \
    wget \
    curl \
    tar \
    xz \
    zip \
    unzip \
    p7zip \
    jq \
    grep \
    sed \
    nano \
    openssh-client

CMD ["/bin/sh"]
