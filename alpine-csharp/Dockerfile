# PowerTech Alpine C# (native)
# .NET development environment for native (host) compilation
# Includes NativeAOT support for producing fully native Linux binaries.
#
# Image: ghcr.io/powertech-center/alpine-csharp

FROM ghcr.io/powertech-center/alpine-dev:latest

# Install .NET SDK and NativeAOT dependencies
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/alpine-csharp.sh

ENV DOTNET_ROOT="/usr/lib/dotnet"
ENV PATH="${PATH}:/home/dev/.dotnet/tools"

# Install .NET dev tools as 'dev' user so binaries land in ~/.dotnet/tools
USER dev
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/csharp-dev-tools.sh
USER root

CMD ["/bin/sh"]
