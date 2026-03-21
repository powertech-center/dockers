#!/bin/sh
# Shared .NET tools installation (run as 'dev' user)
# Used by: alpine-csharp, alpine-cross-csharp
#
# Installs .NET global tools for IDE support and development workflow.
# Must be run as the 'dev' user with DOTNET_ROOT and PATH already set.

set -e

# Code formatting (opinionated, like Prettier for C#)
dotnet tool install -g csharpier

# NuGet package updates
dotnet tool install -g dotnet-outdated-tool

# Code coverage reporting
dotnet tool install -g dotnet-reportgenerator-globaltool
