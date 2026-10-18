"""Release validation tests use throwaway metadata, never GitHub or git tags."""

import importlib.util
from pathlib import Path
import tempfile
import unittest


SPEC = importlib.util.spec_from_file_location(
    "release", Path(__file__).resolve().parents[1] / "scripts/release.py"
)
RELEASE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(RELEASE)


class ReleaseTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.write("VERSION", "0.1.0\n")
        self.write("README.md", "# Dotfiles\n\n**Current version: 0.1.0**\n")
        self.write("CHANGELOG.md", "# Changelog\n\n## [Unreleased]\n\n"
                   "## [0.1.0] - 2026-10-18\n\n### Added\n- Touch ID\n\n"
                   "## [Initial Release]\n- Older notes\n")

    def write(self, name, value):
        (self.root / name).write_text(value)

    def test_release_notes_only_include_requested_version(self):
        self.assertEqual(
            RELEASE.release_notes(self.root, "v0.1.0"), "### Added\n- Touch ID\n"
        )

    def test_invalid_semver(self):
        for value in ("v0.1.0", "01.1.0", "0.1", "0.1.0-rc.1", "0.1.0+build", "1.0.00"):
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.write("VERSION", value)
                RELEASE.release_notes(self.root)

    def test_mismatched_tag(self):
        for tag in ("0.1.0", "v0.2.0", "v0.1.0; echo unsafe"):
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                RELEASE.release_notes(self.root, tag)

    def test_missing_or_invalid_changelog(self):
        for text in ("## [Unreleased]\n", "## [0.1.0] - 2026-10-18\n- Change\n",
                     "## [Unreleased]\n## [0.1.0] - 2026-02-30\n- Change\n",
                     "## [Unreleased]\n## [0.1.0] - 2026-10-18\n### Added\n"):
            with self.subTest(text=text), self.assertRaises(ValueError):
                self.write("CHANGELOG.md", text)
                RELEASE.release_notes(self.root)

    def test_stale_readme(self):
        self.write("README.md", "**Current version: 0.0.1**\n")
        with self.assertRaises(ValueError):
            RELEASE.release_notes(self.root)


if __name__ == "__main__":
    unittest.main()
