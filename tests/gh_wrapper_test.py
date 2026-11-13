"""gh wrapper tests use a fake gh on PATH and throwaway repositories, never real tokens."""

from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
FUNCTIONS = ROOT / "functions.zsh"
CUSTOM = ROOT / "custom.zsh"
# Tests own their mapping, so they do not depend on what custom.zsh ships.
MAP = "GH_HOST_ACCOUNTS[github.com-iamgerwin]=iamgerwin;"
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

    def zsh(self, cwd, script, *args, env=None):
        return subprocess.run(
            ["zsh", "-f", "-c", script, "zsh", *args],
            cwd=cwd, env={**self.env, **(env or {})}, capture_output=True, text=True,
        )

    def run_gh(self, cwd, *args, env=None, setup=""):
        return self.zsh(cwd, f'source "{FUNCTIONS}"; {MAP} {setup} gh "$@"', *args, env=env)

    def gh(self, cwd, *args, env=None, setup=""):
        result = self.run_gh(cwd, *args, env=env, setup=setup)
        self.assertEqual(result.returncode, 0, result.stderr)
        return result.stdout.strip()

    def personal(self, name="personal"):
        return self.repo(name, "git@github.com-iamgerwin:iamgerwin/repo.git")

    def test_mapped_alias_uses_its_account(self):
        for i, remote in enumerate(("git@github.com-iamgerwin:iamgerwin/repo.git",
                                    "ssh://git@github.com-iamgerwin/iamgerwin/repo.git",
                                    "git@GitHub.com-IamGerwin:iamgerwin/repo.git")):
            with self.subTest(remote=remote):
                path = self.repo(f"mapped-{i}", remote)
                self.assertEqual(self.gh(path, "pr", "list"), "token=token-iamgerwin args=pr list")

    def test_unmapped_remote_uses_active_account(self):
        path = self.repo("work", "git@gh-shakewell:shakewellagency/repo.git")
        self.assertEqual(self.gh(path, "pr", "list"), "token=none args=pr list")

    def test_outside_a_repository_uses_active_account(self):
        self.assertEqual(self.gh(self.root, "api", "user"), "token=none args=api user")

    def test_explicit_token_wins(self):
        path = self.personal()
        self.assertEqual(self.gh(path, "api", "user", env={"GH_TOKEN": "mine"}),
                         "token=mine args=api user")

    def test_account_without_token_fails_closed(self):
        path = self.repo("other", "git@github.com-other:someone/repo.git")
        result = self.run_gh(path, "pr", "create", setup="GH_HOST_ACCOUNTS[github.com-other]=missing;")
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
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

    def test_flag_values_and_positionals_keep_the_mapping(self):
        path = self.personal()
        for args in (("issue", "comment", "5", "--body", "--repo"),
                     ("pr", "create", "--title", "-Rebase cleanup"),
                     ("api", "user", "--jq", "--repo"),
                     ("api", "-f", "q=-Rx", "graphql"),
                     ("api", "--", "-R")):
            with self.subTest(args=args):
                self.assertEqual(self.gh(path, *args), f"token=token-iamgerwin args={' '.join(args)}")

    def test_gh_repo_skips_the_mapping(self):
        path = self.personal()
        self.assertEqual(self.gh(path, "pr", "list", env={"GH_REPO": "other/x"}),
                         "token=none args=pr list")

    def test_missing_or_scalar_map_falls_back_without_crashing(self):
        path = self.personal()
        for setup in ("unset GH_HOST_ACCOUNTS;", "unset GH_HOST_ACCOUNTS; GH_HOST_ACCOUNTS=scalar;"):
            with self.subTest(setup=setup):
                self.assertEqual(self.gh(path, "api", "user", setup=setup), "token=none args=api user")

    def test_empty_map_by_default(self):
        path = self.personal()
        result = self.zsh(path, f'source "{FUNCTIONS}"; gh api user')
        self.assertEqual(result.stdout.strip(), "token=none args=api user")

    def test_custom_zsh_mapping_applies_after_functions(self):
        path = self.personal()
        result = self.zsh(path, f'source "{FUNCTIONS}"; source "{CUSTOM}"; gh api user')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "token=token-iamgerwin args=api user")

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
        result = self.zsh(path, f'source "{FUNCTIONS}"; {MAP} setopt xtrace; '
                                'gh api user >/dev/null 2>&1; [[ -o xtrace ]] && print on')
        self.assertEqual(result.stdout.strip(), "on")

    def test_token_does_not_leak_into_the_shell(self):
        path = self.personal()
        result = self.zsh(path, f'source "{FUNCTIONS}"; {MAP} gh api user >/dev/null; '
                                'print -r -- "${GH_TOKEN:-unset}"')
        self.assertEqual(result.stdout.strip(), "unset")


if __name__ == "__main__":
    unittest.main()
