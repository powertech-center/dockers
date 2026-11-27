#!/usr/bin/env python3
"""Generate a clang/clang++ cross-compilation wrapper script (sh).

Usage:
    python3 gen-wrapper-clang.py <target> --sysroot <path> [--cpp]

Output: shell script to stdout; --print-config prints its Clang configuration.

Example:
    python3 gen-wrapper-clang.py x86_64-linux-musl --sysroot / > clang-x86_64-linux-musl
    python3 gen-wrapper-clang.py x86_64-windows-gnu --sysroot /usr/windows-gnu --cpp > clang++-x86_64-windows-gnu
"""

import argparse
import sys

# =============================================================================
# Target table: 3-component name -> canonical --target= and platform kind
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


def parse_target(name):
    """Parse 3-component target name into (arch, os_env) and look up metadata."""
    if name not in TARGETS:
        print(f"error: unknown target '{name}'", file=sys.stderr)
        print(f"known targets: {', '.join(sorted(TARGETS))}", file=sys.stderr)
        sys.exit(1)
    parts = name.split("-", 1)  # "x86_64", "linux-musl"
    arch = parts[0]
    info = TARGETS[name]
    return arch, info


def generate(target_name, sysroot, cpp, print_config=False):
    arch, info = parse_target(target_name)
    kind = info["kind"]
    compiler = "clang++" if cpp else "clang"
    directory_name = f"windows-{arch}" if kind == "windows-msvc" else target_name
    directory = f"/opt/toolchains/{directory_name}"
    if not print_config:
        mode = " --driver-mode=cl" if kind == "windows-msvc" else ""
        if kind == "darwin":
            # Driver SDK diagnostics are configured before --config is loaded.
            mode = " -Wno-incompatible-sysroot"
        print("#!/bin/sh")
        print(f'exec {compiler}{mode} --target={info["canonical"]} '
              f'--config={directory}/{compiler}.cfg "$@"')
        return

    # Clang parses defaults and response files itself. Config options are claimed
    # by the driver, so link-only defaults do not warn during compilation.
    flags = ["-fuse-ld=lld"]
    if kind != "windows-msvc":
        flags.append(f"-B{directory}/bin")
    if kind == "linux":
        if sysroot != "/":
            flags.append(f"--sysroot={sysroot}")
        flags += ["-rtlib=compiler-rt", "--unwindlib=none"]
        if cpp:
            flags += ["-stdlib=libc++", "$-lc++abi", "$-lunwind"]
    elif kind == "darwin":
        flags += ["-mmacosx-version-min=11.0", f"--sysroot={sysroot}",
                  f"-F{sysroot}/System/Library/Frameworks", f"-I{sysroot}/usr/include"]
    elif kind == "windows-gnu":
        if cpp:
            flags += [f"-isystem {sysroot}/include/c++/v1", "-stdlib=libc++", "-Wl,-Bstatic"]
        flags += [f"-isystem {sysroot}/include", f"-L{sysroot}/{arch}/lib",
                  "-rtlib=compiler-rt", "-unwindlib=libunwind"]
    elif kind == "windows-msvc":
        for path in ("crt/include", "sdk/include/ucrt", "sdk/include/um", "sdk/include/shared"):
            flags.append(f"/imsvc{sysroot}/{path}")
        # $-prefixed options are used only during linking, after caller inputs.
        for path in ("crt/lib", "sdk/lib/um", "sdk/lib/ucrt"):
            flags.append(f"$-Xlinker $/libpath:{sysroot}/{path}/{arch}")
    print("\n".join(flags))


def main():
    parser = argparse.ArgumentParser(
        description="Generate a clang cross-compilation wrapper script"
    )
    parser.add_argument("target", help="3-component target (e.g. x86_64-linux-musl)")
    parser.add_argument("--sysroot", required=True, help="Path to sysroot/SDK")
    parser.add_argument("--cpp", action="store_true", help="Generate clang++ wrapper")
    parser.add_argument("--print-config", action="store_true", help="Print Clang defaults instead of the wrapper")
    args = parser.parse_args()

    generate(args.target, args.sysroot, args.cpp, args.print_config)


if __name__ == "__main__":
    main()
