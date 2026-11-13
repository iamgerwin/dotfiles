"""gh wrapper tests use a fake gh on PATH and throwaway repositories, never real tokens."""

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

    def run_gh(self, cwd, *args, env=None, setup=""):
        script = f'source "{FUNCTIONS}"; {setup} gh "$@"'
        return subprocess.run(
            ["zsh", "-f", "-c", script, "zsh", *args],
            cwd=cwd, env={**self.env, **(env or {})}, capture_output=True, text=True, check=True,
        )

    def gh(self, cwd, *args, env=None, setup=""):
        return self.run_gh(cwd, *args, env=env, setup=setup).stdout.strip()

    def personal(self, name="personal"):
        return self.repo(name, "git@github.com-iamgerwin:iamgerwin/repo.git")

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

    def test_account_without_token_falls_back_with_a_warning(self):
        path = self.repo("other", "git@github.com-other:someone/repo.git")
        setup = "GH_HOST_ACCOUNTS[github.com-other]=missing;"
        result = self.run_gh(path, "api", "user", setup=setup)
        self.assertEqual(result.stdout.strip(), "token=none args=api user")
        self.assertIn("no token for missing", result.stderr)

    def test_unmapped_remote_is_silent(self):
        path = self.repo("quiet", "git@gh-shakewell:shakewellagency/repo.git")
        self.assertEqual(self.run_gh(path, "api", "user").stderr, "")

    def test_explicit_repo_skips_the_mapping(self):
        path = self.personal()
        for args in (("-R", "other/x"), ("--repo", "other/x"), ("--repo=other/x",), ("-Rother/x",)):
            with self.subTest(args=args):
                self.assertEqual(self.gh(path, *args, "pr", "list"),
                                 f"token=none args={' '.join(args)} pr list")

    def test_gh_repo_skips_the_mapping(self):
        path = self.personal()
        self.assertEqual(self.gh(path, "pr", "list", env={"GH_REPO": "other/x"}),
                         "token=none args=pr list")

    def test_works_under_nounset(self):
        for name, remote, token in (("mapped", "git@github.com-iamgerwin:iamgerwin/repo.git", "token-iamgerwin"),
                                    ("unmapped", "git@gh-shakewell:shakewellagency/repo.git", "none")):
            with self.subTest(remote=name):
                path = self.repo(f"nounset-{name}", remote)
                self.assertEqual(self.gh(path, "api", "user", setup="setopt nounset;"),
                                 f"token={token} args=api user")

    def test_xtrace_does_not_print_the_token(self):
        path = self.personal()
        result = self.run_gh(path, "api", "user", setup="setopt xtrace;")
        self.assertEqual(result.stdout.strip(), "token=token-iamgerwin args=api user")
        self.assertNotIn("token-iamgerwin", result.stderr)

    def test_caller_options_are_restored(self):
        path = self.personal()
        script = f'source "{FUNCTIONS}"; setopt xtrace; gh api user >/dev/null 2>&1; [[ -o xtrace ]] && print on'
        result = subprocess.run(["zsh", "-f", "-c", script], cwd=path, env=self.env,
                                capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout.strip(), "on")

    def test_token_does_not_leak_into_the_shell(self):
        path = self.repo("leak", "git@github.com-iamgerwin:iamgerwin/repo.git")
        script = f'source "{FUNCTIONS}"; gh api user >/dev/null; print -r -- "${{GH_TOKEN:-unset}}"'
        result = subprocess.run(["zsh", "-f", "-c", script], cwd=path, env=self.env,
                                capture_output=True, text=True, check=True)
        self.assertEqual(result.stdout.strip(), "unset")


if __name__ == "__main__":
    unittest.main()
