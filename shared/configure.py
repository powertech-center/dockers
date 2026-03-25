#!/usr/bin/env python3
"""Configure script that processes Jinja2 templates."""

import argparse
import os
import sys
from pathlib import Path

from jinja2 import Environment, FileSystemLoader

DISTRO_PKG = {
    "alpine": "apk",
    "debian": "apt",
    "ubuntu": "apt",
}


def main():
    parser = argparse.ArgumentParser(description="Process Jinja2 templates")
    parser.add_argument("distro", choices=DISTRO_PKG.keys())
    parser.add_argument("image")
    args = parser.parse_args()

    root = Path(__file__).resolve().parent.parent
    template_path = root / args.image / "Dockerfile.template"
    output_path = root / ".cache" / args.distro / args.image

    if not template_path.exists():
        print(f"Error: {template_path} not found", file=sys.stderr)
        sys.exit(1)

    env = Environment(
        loader=FileSystemLoader(str(template_path.parent)),
        keep_trailing_newline=True,
    )
    template = env.get_template(template_path.name)
    content = template.render(
        distro=args.distro,
        pkg=DISTRO_PKG[args.distro],
    )

    if output_path.exists() and output_path.read_text() == content:
        return

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(content)


if __name__ == "__main__":
    main()
