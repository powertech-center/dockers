#!/bin/sh
# Shared .NET tools installation
# Used by: alpine-csharp, alpine-cross-csharp
#
# Installs .NET global tools to /opt/dotnet-tools (via DOTNET_CLI_HOME)
# so they are available to all users, not just the installing user.

set -e

export DOTNET_CLI_HOME=/opt/dotnet-tools

# Code formatting (opinionated, like Prettier for C#)
dotnet tool install -g csharpier

# NuGet package updates
dotnet tool install -g dotnet-outdated-tool

# Code coverage reporting
dotnet tool install -g dotnet-reportgenerator-globaltool

# Make accessible to all users
chmod -R a+rX ${DOTNET_CLI_HOME}
