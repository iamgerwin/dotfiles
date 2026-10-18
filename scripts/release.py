#!/usr/bin/env python3
"""Validate release metadata and extract notes without creating a tag/release."""

import argparse
from datetime import date
from pathlib import Path
import re


ROOT = Path(__file__).resolve().parents[1]
# Stable releases only; GitHub tags use a v prefix, VERSION does not.
SEMVER = re.compile(r"(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)")


def release_notes(root, tag=None):
    version = (root / "VERSION").read_text().strip()
    if not SEMVER.fullmatch(version):
        raise ValueError("VERSION must be a stable SemVer X.Y.Z (no leading zeros)")
    if tag is not None and tag != f"v{version}":
        raise ValueError(f"release tag must match VERSION: v{version}")
    changelog = (root / "CHANGELOG.md").read_text()
    if "## [Unreleased]" not in changelog:
        raise ValueError("CHANGELOG.md must retain an Unreleased section")
    entries = re.findall(
        rf"^## \[{re.escape(version)}\] - (\d{{4}}-\d{{2}}-\d{{2}})\n(.*?)(?=^## |\Z)",
        changelog, re.MULTILINE | re.DOTALL,
    )
    if len(entries) != 1:
        raise ValueError(f"CHANGELOG.md must have exactly one dated [{version}] entry")
    release_date, notes = entries[0]
    date.fromisoformat(release_date)
    if not re.search(r"^- \S", notes, re.MULTILINE):
        raise ValueError("release notes must contain at least one change")
    if f"**Current version: {version}**" not in (root / "README.md").read_text():
        raise ValueError("README current version must match VERSION")
    return notes.strip() + "\n"


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--tag", help="expected vX.Y.Z tag")
    parser.add_argument("--notes", type=Path, help="write validated release notes")
    args = parser.parse_args()
    try:
        notes = release_notes(ROOT, args.tag)
    except (ValueError, OSError) as error:
        parser.exit(1, f"Release validation failed: {error}\n")
    if args.notes:
        args.notes.write_text(notes)
    print("Release metadata is aligned")


if __name__ == "__main__":
    main()
