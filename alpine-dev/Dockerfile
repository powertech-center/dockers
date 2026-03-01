# PowerTech Alpine Dev
# Build tools, compilers and scripting environments for native development
#
# Image: ghcr.io/powertech-center/alpine-dev

FROM ghcr.io/powertech-center/alpine-tools:latest

RUN apk add --no-cache \
    make \
    cmake \
    ninja-build \
    gcc \
    g++ \
    musl-dev \
    pkgconf \
    linux-headers \
    python3 \
    py3-pip

# PowerShell (musl build for Alpine)
ARG PWSH_VERSION=7.5.4
RUN wget -q https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-musl-x64.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar xzf powershell-${PWSH_VERSION}-linux-musl-x64.tar.gz -C /opt/microsoft/powershell/7 && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh && \
    rm powershell-${PWSH_VERSION}-linux-musl-x64.tar.gz

CMD ["/bin/sh"]
