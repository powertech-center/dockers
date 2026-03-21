#!/usr/bin/env python3
"""Generate a clang/clang++ cross-compilation wrapper script (sh).

Usage:
    python3 gen-wrapper-clang.py <target> --sysroot <path> [--cpp]

Output: shell script to stdout.

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


def generate(target_name, sysroot, cpp):
    arch, info = parse_target(target_name)
    canonical = info["canonical"]
    kind = info["kind"]
    compiler = "clang++" if cpp else "clang"
    linker_wrapper = f"lld-{target_name}"

    lines = []
    lines.append("#!/bin/sh")

    # --- Argument scanning block ---
    lines.append("compile_only=false")
    lines.append("has_fuse_ld=false")
    lines.append("fuse_ld_is_lld=false")

    if cpp and (kind == "linux" or kind == "windows-gnu"):
        lines.append("has_stdlib=false")

    lines.append('for arg in "$@"; do')
    lines.append("    case \"$arg\" in")

    if kind == "windows-msvc":
        lines.append("        /c|-c|-S|-E|-fsyntax-only) compile_only=true ;;")
    else:
        lines.append("        -c|-S|-E|-fsyntax-only) compile_only=true ;;")

    lines.append("        -fuse-ld=lld)           has_fuse_ld=true; fuse_ld_is_lld=true ;;")
    lines.append("        -fuse-ld=*)             has_fuse_ld=true ;;")

    if cpp and (kind == "linux" or kind == "windows-gnu"):
        lines.append("        -stdlib=*)              has_stdlib=true ;;")

    lines.append("    esac")
    lines.append("done")

    # --- Build base flags (constant part) ---
    base_flags = []

    if kind == "windows-msvc":
        # --driver-mode=cl must come before --target=
        base_flags.append("--driver-mode=cl")

    base_flags.append(f"--target={canonical}")

    if kind == "linux":
        if sysroot != "/":
            base_flags.append(f"--sysroot={sysroot}")

    elif kind == "darwin":
        base_flags.append("-mmacosx-version-min=11.0")
        base_flags.append(f"--sysroot={sysroot}")
        base_flags.append(f"-F{sysroot}/System/Library/Frameworks")
        base_flags.append(f"-I{sysroot}/usr/include")
        base_flags.append("-w")

    elif kind == "windows-msvc":
        # xwin headers are unpatched — they use _MSC_VER natively,
        # and clang defines _MSC_VER for MSVC target, so no XW_* aliases needed.
        # Include paths go into compile_flags (not base) to avoid warnings during link-only
        pass

    elif kind == "windows-gnu":
        # Native MinGW sysroot: headers and libs from llvm-mingw
        # No XW_* macros needed (mingw-w64 headers don't use _MSC_VER)
        # No -fms-extensions needed (mingw-w64 headers don't use MSVC syntax)
        # Include paths: mingw-w64 headers + libc++ headers for C++
        if cpp:
            base_flags.append(f"-isystem {sysroot}/include/c++/v1")
        base_flags.append(f"-isystem {sysroot}/include")

    base = " ".join(base_flags)

    # --- MSVC include paths (compile-specific but also needed for compile+link) ---
    msvc_includes = ""
    if kind == "windows-msvc":
        msvc_includes = (
            f" /imsvc{sysroot}/crt/include"
            f" /imsvc{sysroot}/sdk/include/ucrt"
            f" /imsvc{sysroot}/sdk/include/um"
            f" /imsvc{sysroot}/sdk/include/shared"
        )

    # --- Compile-only branch ---
    lines.append('if [ "$compile_only" = "true" ]; then')

    if cpp and kind == "linux":
        # Add -stdlib=libc++ unless user specified -stdlib=
        lines.append('    if [ "$has_stdlib" = "false" ]; then')
        lines.append(f'        exec {compiler} {base} -stdlib=libc++ "$@"')
        lines.append("    fi")
        lines.append(f'    exec {compiler} {base} "$@"')
    elif cpp and kind == "windows-gnu":
        # Default to libc++ for MinGW/llvm-mingw sysroot, unless user explicitly overrides.
        lines.append('    if [ "$has_stdlib" = "false" ]; then')
        lines.append(f'        exec {compiler} {base} -stdlib=libc++ "$@"')
        lines.append("    fi")
        lines.append(f'    exec {compiler} {base} "$@"')
    else:
        lines.append(f'    exec {compiler} {base}{msvc_includes} "$@"')

    lines.append("fi")

    # --- Link branch ---
    # Need -fuse-ld= pointing to our linker wrapper (except windows-msvc which uses /link)
    lines.append("# Link mode")

    # Extra flags only needed during linking (not compilation)
    link_extra = ""
    if kind == "linux":
        if cpp:
            # C++ needs libc++abi and libunwind for exception handling / RTTI.
            # clang -stdlib=libc++ does NOT auto-link libc++abi on musl/glibc,
            # so we add them explicitly.
            link_extra = "-rtlib=compiler-rt --unwindlib=none -lc++abi -lunwind"
        else:
            link_extra = "-rtlib=compiler-rt --unwindlib=none"

    if kind == "windows-msvc":
        # MSVC: /link /libpath: always needed, -fuse-ld=lld added if user didn't specify
        # Include paths (/imsvc) included with -Wno-unused-command-line-argument
        # to suppress warnings when linking .obj files without compilation
        link_libpaths = (
            f"/link /libpath:{sysroot}/crt/lib/{arch}"
            f" /libpath:{sysroot}/sdk/lib/um/{arch}"
            f" /libpath:{sysroot}/sdk/lib/ucrt/{arch}"
        )

        lines.append('if [ "$has_fuse_ld" = "false" ]; then')
        lines.append(f'    exec {compiler} {base}{msvc_includes} -Wno-unused-command-line-argument -fuse-ld=lld "$@" {link_libpaths}')
        lines.append("fi")
        # User specified -fuse-ld=, still need /link /libpath:
        lines.append(f'exec {compiler} {base}{msvc_includes} -Wno-unused-command-line-argument "$@" {link_libpaths}')

    elif kind == "windows-gnu":
        # Native MinGW: clang MinGW driver handles CRT objects and default libs
        # We just need -L for the arch-specific lib dir and -fuse-ld= for our lld wrapper
        lib_dir = f"{sysroot}/{arch}/lib"
        fuse_ld = f"-fuse-ld=/usr/local/bin/{linker_wrapper}"
        link_flags_common = f"-L{lib_dir} -rtlib=compiler-rt -unwindlib=libunwind"
        link_flags_with_fuse = f"{link_flags_common} {fuse_ld}"

        if cpp:
            lines.append('stdlib_flag=""')
            lines.append('if [ "$has_stdlib" = "false" ]; then stdlib_flag="-stdlib=libc++"; fi')
            # Default to static libc++ linkage (user can override via -Wl,-Bdynamic/-Bdynamic later).
            lines.append('static_flag="-Wl,-Bstatic"')

        lines.append('if [ "$has_fuse_ld" = "false" ]; then')
        if cpp:
            lines.append(f'    exec {compiler} {base} {link_flags_with_fuse} $stdlib_flag $static_flag "$@"')
        else:
            lines.append(f'    exec {compiler} {base} {link_flags_with_fuse} "$@"')
        lines.append("fi")
        # Strip user's -fuse-ld=lld, replace with our wrapper
        lines.append('if [ "$fuse_ld_is_lld" = "true" ]; then')
        lines.append('    args=""')
        lines.append('    for arg in "$@"; do')
        lines.append('        case "$arg" in')
        lines.append("            -fuse-ld=lld) ;;")
        lines.append('            *)            args="$args $arg" ;;')
        lines.append("        esac")
        lines.append("    done")
        if cpp:
            lines.append(f'    exec {compiler} {base} {link_flags_with_fuse} $stdlib_flag $static_flag $args')
        else:
            lines.append(f'    exec {compiler} {base} {link_flags_with_fuse} $args')
        lines.append("fi")
        # User specified a custom -fuse-ld=something-else, respect it
        if cpp:
            lines.append(f'exec {compiler} {base} {link_flags_common} $stdlib_flag $static_flag "$@"')
        else:
            lines.append(f'exec {compiler} {base} {link_flags_common} "$@"')

    else:
        # Linux / Darwin: use our lld wrapper (calls lld -flavor directly)
        fuse_ld = f"-fuse-ld=/usr/local/bin/{linker_wrapper}"
        le = f" {link_extra}" if link_extra else ""

        lines.append('if [ "$has_fuse_ld" = "false" ] || [ "$fuse_ld_is_lld" = "true" ]; then')
        lines.append('    args=""')
        lines.append('    for arg in "$@"; do')
        lines.append('        case "$arg" in')
        lines.append("            -fuse-ld=lld) ;;")
        lines.append('            *)            args="$args $arg" ;;')
        lines.append("        esac")
        lines.append("    done")

        if cpp and kind == "linux":
            lines.append('    stdlib_flag=""')
            lines.append('    [ "$has_stdlib" = "false" ] && stdlib_flag="-stdlib=libc++"')
            lines.append(f"    exec {compiler} {base}{le} {fuse_ld} $stdlib_flag $args")
        else:
            lines.append(f"    exec {compiler} {base}{le} {fuse_ld} $args")

        lines.append("else")

        if cpp and kind == "linux":
            lines.append('    stdlib_flag=""')
            lines.append('    [ "$has_stdlib" = "false" ] && stdlib_flag="-stdlib=libc++"')
            lines.append(f'    exec {compiler} {base}{le} $stdlib_flag "$@"')
        else:
            lines.append(f'    exec {compiler} {base}{le} "$@"')

        lines.append("fi")

    print("\n".join(lines))


def main():
    parser = argparse.ArgumentParser(
        description="Generate a clang cross-compilation wrapper script"
    )
    parser.add_argument("target", help="3-component target (e.g. x86_64-linux-musl)")
    parser.add_argument("--sysroot", required=True, help="Path to sysroot/SDK")
    parser.add_argument("--cpp", action="store_true", help="Generate clang++ wrapper")
    args = parser.parse_args()

    generate(args.target, args.sysroot, args.cpp)


if __name__ == "__main__":
    main()
