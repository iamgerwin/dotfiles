"""gh wrapper tests use a fake gh on PATH and throwaway repositories, never real tokens."""

import os
from pathlib import Path
import subprocess
import tempfile
import unittest


FUNCTIONS = Path(__file__).resolve().parents[1] / "functions.zsh"
FAKE_GH = """#!/bin/sh
if [ "$1" = auth ] && [ "$2" = token ]; then
    [ "$4" = missing ] && exit 1
    echo "token-$4"
    exit 0
fi
echo "token=${GH_TOKEN:-none} args=$*"
"""


class GhWrapperTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        bin_dir = self.root / "bin"
        bin_dir.mkdir()
        gh = bin_dir / "gh"
        gh.write_text(FAKE_GH)
        gh.chmod(0o755)
        self.env = {"PATH": f"{bin_dir}:/usr/bin:/bin", "HOME": str(self.root)}

    def repo(self, name, remote=None):
        path = self.root / name
        path.mkdir()
        subprocess.run(["git", "init", "-q", str(path)], check=True)
        if remote:
            subprocess.run(["git", "-C", str(path), "remote", "add", "origin", remote], check=True)
        return path

    def gh(self, cwd, *args, env=None, setup=""):
        script = f'source "{FUNCTIONS}"; {setup} gh "$@"'
        result = subprocess.run(
            ["zsh", "-f", "-c", script, "zsh", *args],
            cwd=cwd, env={**self.env, **(env or {})}, capture_output=True, text=True, check=True,
        )
        return result.stdout.strip()

    def test_mapped_alias_uses_its_account(self):
        for remote in ("git@github.com-iamgerwin:iamgerwin/repo.git",
                       "ssh://git@github.com-iamgerwin/iamgerwin/repo.git"):
            with self.subTest(remote=remote):
                path = self.repo(remote.replace("/", "_").replace(":", "_"), remote)
                self.assertEqual(self.gh(path, "pr", "list"), "token=token-iamgerwin args=pr list")

    def test_unmapped_remote_uses_active_account(self):
        path = self.repo("work", "git@gh-shakewell:shakewellagency/repo.git")
        self.assertEqual(self.gh(path, "pr", "list"), "token=none args=pr list")

    def test_outside_a_repository_uses_active_account(self):
        self.assertEqual(self.gh(self.root, "api", "user"), "token=none args=api user")

    def test_explicit_token_wins(self):
        path = self.repo("personal", "git@github.com-iamgerwin:iamgerwin/repo.git")
        self.assertEqual(self.gh(path, "api", "user", env={"GH_TOKEN": "mine"}),
                         "token=mine args=api user")

    def test_account_without_token_falls_back(self):
        path = self.repo("other", "git@github.com-other:someone/repo.git")
        setup = "GH_HOST_ACCOUNTS[github.com-other]=missing;"
        self.assertEqual(self.gh(path, "api", "user", setup=setup), "token=none args=api user")

    def test_token_does_not_leak_into_the_shell(self):
        path = self.repo("leak", "git@github.com-iamgerwin:iamgerwin/repo.git")
        script = f'source "{FUNCTIONS}"; gh api user >/dev/null; print -r -- "${{GH_TOKEN:-unset}}"'
        result = subprocess.run(["zsh", "-f", "-c", script], cwd=path, env=self.env,
                                capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout.strip(), "unset")


if __name__ == "__main__":
    unittest.main()
