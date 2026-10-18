#!/usr/bin/env python3
"""Check shell syntax, maintained documentation links, and release alignment."""

import argparse
from pathlib import Path
import re
import subprocess
from urllib.parse import unquote, urlsplit

from release import release_notes


ROOT = Path(__file__).resolve().parents[1]
MAINTAINED_DOCS = ("README.md", "CHANGELOG.md", "AGENTS.md", "learnings/dump.md")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--lint", action="store_true", help="also require ShellCheck")
    args = parser.parse_args()
    paths = subprocess.check_output(
        ["git", "ls-files", "--cached", "--others", "--exclude-standard", "-z"], cwd=ROOT
    ).decode().split("\0")
    bash_files = []
    for name in sorted(set(paths) - {""}):
        path = ROOT / name
        if not path.is_file() or path.is_symlink():
            continue
        if path.suffix == ".zsh" or name == ".zshrc":
            subprocess.run(["zsh", "-n", str(path)], check=True)
        elif path.suffix == ".sh" or path.read_bytes()[:100].split(b"\n")[0] in (
            b"#!/usr/bin/env bash", b"#!/bin/bash",
        ):
            subprocess.run(["/bin/bash", "-n", str(path)], check=True)
            bash_files.append(name)
    if args.lint:
        # Legacy scripts have style warnings. Gate errors repository-wide rather
        # than hiding them behind excludes or blocking on unrelated reformatting.
        subprocess.run(["shellcheck", "--severity=error", *bash_files], cwd=ROOT, check=True)
    for name in MAINTAINED_DOCS:
        path = ROOT / name
        content = path.read_text()
        if not content.startswith("# ") or not content.endswith("\n"):
            raise ValueError(f"{name}: requires a title and final newline")
        for target in re.findall(r"\[[^\]\n]+\]\(([^)\s]+)\)", content):
            url = urlsplit(target)
            if url.scheme or url.netloc or not url.path:
                continue
            if not (path.parent / unquote(url.path)).exists():
                raise ValueError(f"{name}: missing local link target {target}")
    release_notes(ROOT)
    print(f"Syntax checked {len(bash_files)} Bash scripts; maintained docs and release metadata aligned")


if __name__ == "__main__":
    main()
