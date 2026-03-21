#!/usr/bin/env python3
"""Generate an lld cross-linker wrapper script (sh).

Usage:
    python3 gen-wrapper-lld.py <target> --sysroot <path>

Output: shell script to stdout.

Example:
    python3 gen-wrapper-lld.py x86_64-linux-musl --sysroot / > lld-x86_64-linux-musl
    python3 gen-wrapper-lld.py x86_64-windows-gnu --sysroot /usr/windows-gnu > lld-x86_64-windows-gnu
    python3 gen-wrapper-lld.py x86_64-windows-msvc --sysroot /usr/windows-msvc > lld-x86_64-windows-msvc
"""

import argparse
import sys

# =============================================================================
# Target table
# =============================================================================

TARGETS = {
    # Linux musl
    "x86_64-linux-musl": {
        "canonical": "x86_64-unknown-linux-musl",
        "kind": "linux",
    },
    "aarch64-linux-musl": {
        "canonical": "aarch64-unknown-linux-musl",
        "kind": "linux",
    },
    # Linux glibc
    "x86_64-linux-gnu": {
        "canonical": "x86_64-unknown-linux-gnu",
        "kind": "linux",
    },
    "aarch64-linux-gnu": {
        "canonical": "aarch64-unknown-linux-gnu",
        "kind": "linux",
    },
    # macOS
    "x86_64-apple-darwin": {
        "canonical": "x86_64-apple-darwin",
        "kind": "darwin",
    },
    "aarch64-apple-darwin": {
        "canonical": "aarch64-apple-darwin",
        "kind": "darwin",
    },
    # Windows MSVC
    "x86_64-windows-msvc": {
        "canonical": "x86_64-pc-windows-msvc",
        "kind": "windows-msvc",
    },
    "aarch64-windows-msvc": {
        "canonical": "aarch64-pc-windows-msvc",
        "kind": "windows-msvc",
    },
    # Windows GNU
    "x86_64-windows-gnu": {
        "canonical": "x86_64-pc-windows-gnu",
        "kind": "windows-gnu",
    },
    "aarch64-windows-gnu": {
        "canonical": "aarch64-pc-windows-gnu",
        "kind": "windows-gnu",
    },
}

# lld -m emulation for Linux ELF targets
LLD_ELF_EMULATION = {
    "x86_64": "elf_x86_64",
    "aarch64": "aarch64linux",
}

# lld -m emulation for Windows PE targets
LLD_PE_EMULATION = {
    "x86_64": "i386pep",
    "aarch64": "arm64pe",
}

# macOS arch name (ld64.lld -arch flag)
DARWIN_ARCH = {
    "x86_64": "x86_64",
    "aarch64": "arm64",
}


def parse_target(name):
    if name not in TARGETS:
        print(f"error: unknown target '{name}'", file=sys.stderr)
        print(f"known targets: {', '.join(sorted(TARGETS))}", file=sys.stderr)
        sys.exit(1)
    arch = name.split("-", 1)[0]
    info = TARGETS[name]
    return arch, info


def generate(target_name, sysroot):
    arch, info = parse_target(target_name)
    canonical = info["canonical"]
    kind = info["kind"]

    lines = []
    lines.append("#!/bin/sh")

    if kind == "linux":
        generate_linux(lines, target_name, canonical, arch, sysroot)
    elif kind == "darwin":
        generate_darwin(lines, target_name, canonical, arch, sysroot)
    elif kind == "windows-msvc":
        generate_windows_msvc(lines, target_name, arch, sysroot)
    elif kind == "windows-gnu":
        generate_windows_gnu(lines, target_name, arch, sysroot)

    print("\n".join(lines))


def generate_linux(lines, target_name, canonical, arch, sysroot):
    """Linux ELF linker: lld -flavor gnu with sysroot."""
    emulation = LLD_ELF_EMULATION[arch]
    sysroot_flag = f" --sysroot={sysroot}" if sysroot != "/" else ""

    lines.append("has_m=false")
    lines.append('for arg in "$@"; do')
    lines.append('    case "$arg" in')
    lines.append("        -m) has_m=true ;;")
    lines.append("    esac")
    lines.append("done")
    lines.append("")
    lines.append("m_flag=\"\"")
    lines.append('if [ "$has_m" = "false" ]; then')
    lines.append(f'    m_flag="-m {emulation}"')
    lines.append("fi")
    lines.append("")
    lines.append(f'exec lld -flavor gnu $m_flag{sysroot_flag} "$@"')


def generate_darwin(lines, target_name, canonical, arch, sysroot):
    """macOS Mach-O linker: lld -flavor darwin with SDK."""
    darwin_arch = DARWIN_ARCH[arch]

    lines.append("has_arch=false")
    lines.append("has_syslibroot=false")
    lines.append("has_platform=false")
    lines.append('for arg in "$@"; do')
    lines.append('    case "$arg" in')
    lines.append("        -arch) has_arch=true ;;")
    lines.append("        -syslibroot) has_syslibroot=true ;;")
    lines.append("        -platform_version) has_platform=true ;;")
    lines.append("    esac")
    lines.append("done")
    lines.append("")
    lines.append("arch_flag=\"\"")
    lines.append('if [ "$has_arch" = "false" ]; then')
    lines.append(f'    arch_flag="-arch {darwin_arch}"')
    lines.append("fi")
    lines.append("")
    lines.append("syslib_flag=\"\"")
    lines.append('if [ "$has_syslibroot" = "false" ]; then')
    lines.append(f'    syslib_flag="-syslibroot {sysroot}"')
    lines.append("fi")
    lines.append("")
    lines.append("platform_flag=\"\"")
    lines.append('if [ "$has_platform" = "false" ]; then')
    lines.append('    platform_flag="-platform_version macos 11.0 11.0"')
    lines.append("fi")
    lines.append("")
    lines.append('exec lld -flavor darwin $arch_flag $syslib_flag $platform_flag "$@"')


def generate_windows_msvc(lines, target_name, arch, sysroot):
    """Windows MSVC linker: lld-link with xwin lib paths."""
    lines.append(
        # lld-link is essentially: lld -flavor link
        f'exec lld -flavor link'
        f' /libpath:{sysroot}/crt/lib/{arch}'
        f' /libpath:{sysroot}/sdk/lib/um/{arch}'
        f' /libpath:{sysroot}/sdk/lib/ucrt/{arch}'
        f' "$@"'
    )


def generate_windows_gnu(lines, target_name, arch, sysroot):
    """Windows GNU linker: lld -flavor gnu with native MinGW sysroot.

    With native MinGW CRT (from llvm-mingw), no filtering or CRT injection needed.
    clang's MinGW driver passes CRT objects and default -l flags automatically.
    We just add -m flag (if missing) and -L for the arch-specific lib directory.
    """
    m_flag = LLD_PE_EMULATION[arch]
    lib_dir = f"{sysroot}/{arch}/lib"

    # Detect if -m flag already provided
    lines.append("has_m=false")
    lines.append('for arg in "$@"; do')
    lines.append('    case "$arg" in')
    lines.append("        -m) has_m=true ;;")
    lines.append("    esac")
    lines.append("done")
    lines.append("")

    lines.append("m_flag=\"\"")
    lines.append('if [ "$has_m" = "false" ]; then')
    lines.append(f'    m_flag="-m {m_flag}"')
    lines.append("fi")
    lines.append("")

    lines.append(f"exec lld -flavor gnu $m_flag -L{lib_dir} \"$@\"")


def main():
    parser = argparse.ArgumentParser(
        description="Generate an lld cross-linker wrapper script"
    )
    parser.add_argument("target", help="3-component target (e.g. x86_64-linux-musl)")
    parser.add_argument("--sysroot", required=True, help="Path to sysroot/SDK")
    args = parser.parse_args()

    generate(args.target, args.sysroot)


if __name__ == "__main__":
    main()
