#!/usr/bin/env python3
"""Check a local image against README.md and maintain its warning files."""

import argparse
import errno
import re
import subprocess
import sys
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DISTROS = ("alpine", "debian", "ubuntu")
REGISTRY = "ghcr.io/powertech-center"


def displayed_size(size):
    if size < 1_000_000_000:
        value = (Decimal(size) / 1_000_000).quantize(Decimal("1"), rounding=ROUND_HALF_UP)
        return f"{value} MB"
    value = (Decimal(size) / 1_000_000_000).quantize(Decimal("0.1"), rounding=ROUND_HALF_UP)
    return f"{value} GB"


def expected_size(distro, image):
    readme = (ROOT / "README.md").read_text(encoding="utf-8")
    for line in readme.splitlines():
        cells = [cell.strip() for cell in line.split("|")]
        if len(cells) >= 6 and re.search(rf"\[{re.escape(image)}\]\(#{re.escape(image)}\)", cells[1]):
            value = cells[2 + DISTROS.index(distro)]
            if not re.fullmatch(r"\d+(?:\.\d+)? (MB|GB)", value):
                raise ValueError(f"Invalid README size for {distro}/{image}: {value}")
            return value
    raise ValueError(f"README size missing for {distro}/{image}")


def check_size(distro, image):
    reference = f"{REGISTRY}/{distro}/{image}:latest"
    result = subprocess.run(
        ["docker", "image", "inspect", reference, "--format", "{{.Size}}"],
        check=True, capture_output=True, text=True,
    )
    size = int(result.stdout.strip())
    actual = displayed_size(size)
    expected = expected_size(distro, image)
    warning = ROOT / ".warnings" / f"{distro}-{image}-size.txt"
    print(f"Size {reference}: {actual}; README: {expected}")
    if actual != expected:
        message = (
            f"WARNING: Image size differs from README.md\n"
            f"Image: {reference}\nREADME: {expected}\nActual: {actual} ({size} bytes)\n"
        )
        while True:
            warning.parent.mkdir(exist_ok=True)
            try:
                warning.write_text(message, encoding="utf-8")
                break
            except FileNotFoundError:
                # A parallel check may have removed the still-empty directory.
                continue
    else:
        try:
            warning.unlink()
        except FileNotFoundError:
            return
        # Other parallel checks may still have warnings in this directory.
        try:
            warning.parent.rmdir()
        except OSError as exc:
            if exc.errno not in (errno.ENOENT, errno.ENOTEMPTY, errno.EEXIST):
                raise


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("distro", choices=DISTROS)
    parser.add_argument("image")
    args = parser.parse_args()
    if not re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", args.image):
        parser.error("image must contain lowercase letters, digits and single hyphens")
    check_size(args.distro, args.image)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print(f"ERROR: {exc}", file=sys.stderr)
        if isinstance(exc, subprocess.CalledProcessError) and exc.stderr:
            print(exc.stderr.strip(), file=sys.stderr)
        sys.exit(1)
