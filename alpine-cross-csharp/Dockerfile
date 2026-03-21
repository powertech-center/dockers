# PowerTech Alpine C#
# .NET development and cross-compilation environment
#
# NativeAOT cross-compilation targets (native binaries via clang wrappers):
#   linux-musl-x64      — native host (no cross needed)
#   linux-musl-arm64    — aarch64 musl sysroot + clang wrapper
#   linux-x64           — x86_64 glibc sysroot + clang wrapper
#   linux-arm64         — aarch64 glibc sysroot + clang wrapper
#
# Standard `dotnet publish` targets (managed IL, no native linker needed):
#   All .NET RIDs including win-x64, win-arm64, osx-x64, osx-arm64
#
# NativeAOT to Windows/macOS is NOT supported by .NET — those targets require
# native platform toolchains (MSVC link.exe / Apple ld64).
# Use standard `dotnet publish` (self-contained, ReadyToRun) for those platforms.
#
# Image: ghcr.io/powertech-center/alpine-cross-csharp

FROM ghcr.io/powertech-center/alpine-cross-platform:latest

# Install .NET SDK and NativeAOT dependencies
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/alpine-csharp.sh

ENV DOTNET_ROOT="/usr/lib/dotnet"
ENV PATH="${PATH}:/home/dev/.dotnet/tools"

# Install .NET dev tools as 'dev' user
USER dev
RUN --mount=type=bind,source=shared,target=/tmp/shared \
    sh /tmp/shared/csharp-dev-tools.sh
USER root

# =============================================================================
# NativeAOT cross-compilation environment
#
# .NET NativeAOT uses a C linker to produce the final native binary.
# MSBuild properties that control this:
#   CppCompilerAndLinker — the C compiler/linker binary (e.g., clang wrapper)
#   SysRoot              — sysroot path for target platform headers/libs
#   LinkerFlavor         — linker type: lld (required for cross-arch, our wrappers use lld)
#   ObjCopyName          — objcopy tool for symbol stripping
#   StripSymbols         — whether to strip debug symbols
#
# IMPORTANT: Always pass -p:LinkerFlavor=lld for cross-architecture builds.
# NativeAOT defaults to -fuse-ld=bfd which invokes the host ld.bfd — that only
# supports x86_64. Our clang wrappers already use -fuse-ld=lld internally, but
# NativeAOT injects -fuse-ld=bfd before our wrapper runs, overriding it.
# LinkerFlavor=lld tells NativeAOT to pass -fuse-ld=lld instead.
#
# Usage (NativeAOT cross-compile to Linux arm64 musl):
#   dotnet publish -r linux-musl-arm64 \
#     -p:PublishAot=true \
#     -p:CppCompilerAndLinker=clang-aarch64-linux-musl \
#     -p:SysRoot=/usr/aarch64-alpine-linux-musl \
#     -p:LinkerFlavor=lld \
#     -p:ObjCopyName=llvm-objcopy
#
# Usage (NativeAOT cross-compile to Linux x64 glibc):
#   dotnet publish -r linux-x64 \
#     -p:PublishAot=true \
#     -p:CppCompilerAndLinker=clang-x86_64-linux-gnu \
#     -p:SysRoot=/usr/x86_64-linux-gnu \
#     -p:LinkerFlavor=lld \
#     -p:ObjCopyName=llvm-objcopy
#
# Usage (standard publish for Windows/macOS — managed IL, not NativeAOT):
#   dotnet publish -r win-x64 --self-contained
#   dotnet publish -r osx-arm64 --self-contained
# =============================================================================

# Default ObjCopyName for all NativeAOT builds (Alpine ships GNU objcopy)
ENV ObjCopyName=llvm-objcopy

CMD ["/bin/sh"]
