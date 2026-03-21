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
ENV DOTNET_CLI_HOME=/opt/dotnet-tools
ENV PATH="${PATH}:/opt/dotnet-tools/.dotnet/tools"

# Install .NET dev tools to global path (accessible to all users)
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/dev-tools-csharp.sh

CMD ["/bin/sh"]
