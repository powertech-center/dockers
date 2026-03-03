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

# PowerShell dependencies
RUN apk add --no-cache \
    less \
    ncurses-terminfo-base \
    krb5-libs \
    libintl \
    libssl3 \
    tzdata \
    userspace-rcu \
    zlib \
    icu-libs

# PowerShell (musl build for Alpine) — latest stable release
RUN PWSH_VERSION=$(wget -qO- "https://api.github.com/repos/PowerShell/PowerShell/releases" | \
        jq -r '[.[] | select(.prerelease == false)] | first | .tag_name | ltrimstr("v")') && \
    wget -q https://github.com/PowerShell/PowerShell/releases/download/v${PWSH_VERSION}/powershell-${PWSH_VERSION}-linux-musl-x64.tar.gz && \
    mkdir -p /opt/microsoft/powershell/7 && \
    tar xzf powershell-${PWSH_VERSION}-linux-musl-x64.tar.gz -C /opt/microsoft/powershell/7 && \
    chmod +x /opt/microsoft/powershell/7/pwsh && \
    ln -s /opt/microsoft/powershell/7/pwsh /usr/local/bin/pwsh && \
    rm powershell-${PWSH_VERSION}-linux-musl-x64.tar.gz

# Build musl from git master: some musl-based binaries (e.g. VS Code extensions built against musl master)
# use dynamic linking and depend on symbols not yet present in the Alpine system musl — this ensures compatibility
RUN git clone https://git.musl-libc.org/git/musl \
    && cd musl \
    && ./configure --prefix=/usr \
    && make -j$(nproc) \
    && make install \
    && cd / && rm -rf musl

# Create a non-root user 'dev' — useful in development environments,
# e.g. as the default user inside a devcontainer
RUN adduser -D -s /bin/sh dev

CMD ["/bin/sh"]
