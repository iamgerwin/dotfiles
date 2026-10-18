"""Mocked Bash behavior tests: never authenticate or update real packages."""

import os
from pathlib import Path
import pty
import subprocess
import tempfile
import threading
import unittest


ROOT = Path(__file__).resolve().parents[1]
BASH = os.environ.get("BASH_UNDER_TEST", "/bin/bash")
SCRIPT = ROOT / "scripts/update-all.sh"

# Install a safety net BEFORE sourcing. Even a regression in the source guard
# must not reach a developer's real package managers, sudo, or home directory.
SANDBOX = r'''
for test_command in sudo mo brew npm pip3 gem rustup composer cargo-install-update go nvim tmux softwareupdate; do
    eval "$test_command() { printf 'UNEXPECTED: $test_command\\n' >> \"\$CALL_LOG\"; return 99; }"
    export -f "$test_command"
done
'''

MOCKS = r'''
uname() { printf '%s\n' "${TEST_OS:-Darwin}"; }
brew() { printf 'brew %s\n' "$*" >> "$CALL_LOG"; }
sudo() {
    printf 'sudo %s\n' "$*" >> "$CALL_LOG"
    case "$*" in
        '-n -v') return "${CACHE_STATUS:-1}" ;;
        '-v') printf 'native Touch ID/password prompt\n' >&2; return "${AUTH_STATUS:-0}" ;;
        *) return 99 ;;
    esac
}
mo() {
    printf 'mo %s\n' "$*" >> "$CALL_LOG"
    [[ "${MO_STATUS:-0}" == 0 ]] || return "$MO_STATUS"
    [[ "${ENABLE_TOUCHID:-true}" != true ]] || touch "$AUTH_STATE"
}
touchid_configured() { [[ -f "$AUTH_STATE" ]]; }
update_homebrew() { brew update; }
'''
OTHER_UPDATES = (
    "update_npm", "update_pip", "update_gems", "update_composer", "update_rust",
    "update_go", "update_ai_tools", "update_oh_my_zsh", "update_tmux_plugins",
    "update_neovim_plugins", "update_macos",
)
MOCKS += "\n".join(
    f'{name}() {{ printf "{name}\\n" >> "$CALL_LOG"; }}' for name in OTHER_UPDATES
) + "\n"


class UpdateAllTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.log = Path(self.temp.name) / "calls"
        self.log.touch()
        self.state = Path(self.temp.name) / "enabled"

    def run_shell(self, body, *, mocks=True, terminal=False, args=(), **env):
        environment = os.environ.copy()
        environment.pop("CI", None)
        environment.update(
            CALL_LOG=str(self.log), AUTH_STATE=str(self.state), SCRIPT=str(SCRIPT),
            HOME=self.temp.name,
        )
        environment.update(env)
        program = SANDBOX + 'source "$SCRIPT" "$@"\n' + (MOCKS if mocks else "") + body
        command = [BASH, "-c", program, "update-all-test", *args]
        if terminal:
            # Exercise the real -t gate without any real sudo or Mole process.
            master, slave = pty.openpty()
            output = []

            def drain_terminal():
                try:
                    while True:
                        chunk = os.read(master, 65536)
                        if not chunk:
                            break
                        output.append(chunk)
                except OSError:  # PTYs report EOF as EIO on some platforms.
                    pass

            reader = threading.Thread(target=drain_terminal, daemon=True)
            reader.start()
            try:
                result = subprocess.run(
                    command, env=environment, stdin=slave, stdout=slave,
                    stderr=subprocess.PIPE, text=True, timeout=10,
                )
            finally:
                os.close(slave)
                reader.join(timeout=3)
                os.close(master)
            result.stdout = b"".join(output).decode(errors="replace")
            return result
        return subprocess.run(
            command, env=environment, capture_output=True, text=True, timeout=10
        )

    def calls(self):
        return self.log.read_text().splitlines()

    def assert_ok(self, result):
        self.assertEqual(result.returncode, 0, result.stdout or result.stderr)

    def test_source_does_not_run_updates(self):
        result = self.run_shell('echo "sourced"', mocks=False)
        self.assert_ok(result)
        self.assertEqual(result.stdout, "sourced\n")
        self.assertEqual(self.calls(), [])

    def test_help_and_unknown_options(self):
        result = self.run_shell("", args=("--help",))
        self.assert_ok(result)
        self.assertIn("--setup-touchid", result.stdout)
        self.assertIn("--no-auth", result.stdout)
        self.assertNotEqual(self.run_shell("", args=("--unknown",)).returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_foreground_auth_before_homebrew(self):
        result = self.run_shell('main', terminal=True)
        self.assert_ok(result)
        self.assertEqual(self.calls(), ["sudo -n -v", "sudo -v", "brew update", *OTHER_UPDATES])
        self.assertIn("native Touch ID/password prompt", result.stderr)

    def test_cached_credentials_skip_prompt(self):
        self.assert_ok(self.run_shell("prepare_update_auth", terminal=True, CACHE_STATUS="0"))
        self.assertEqual(self.calls(), ["sudo -n -v"])

    def test_auth_failure_stops_main_before_updates(self):
        self.assertNotEqual(
            self.run_shell("main", terminal=True, AUTH_STATUS="1").returncode, 0
        )
        self.assertEqual(self.calls(), ["sudo -n -v", "sudo -v"])

    def test_password_works_without_touchid_setup(self):
        result = self.run_shell("prepare_update_auth", terminal=True)
        self.assert_ok(result)
        self.assertEqual(self.calls(), ["sudo -n -v", "sudo -v"])
        self.assertFalse(self.state.exists())  # No implicit mo/PAM modification.

    def test_redirected_runs_skip_auth(self):
        self.assert_ok(self.run_shell("prepare_update_auth"))
        self.assertEqual(self.calls(), [])

    def test_ci_even_with_terminal_skips_auth(self):
        self.assert_ok(self.run_shell("prepare_update_auth", terminal=True, CI="true"))
        self.assertEqual(self.calls(), [])

    def test_linux_skips_auth(self):
        self.assert_ok(self.run_shell("prepare_update_auth", terminal=True, TEST_OS="Linux"))
        self.assertEqual(self.calls(), [])

    def test_no_auth_and_manager_isolation(self):
        for flag in ("--no-auth", "--npm-only", "--pip-only", "--ai-tools-only"):
            with self.subTest(flag=flag):
                self.assert_ok(self.run_shell("prepare_update_auth", terminal=True, args=(flag,)))
        self.assertEqual(self.calls(), [])

    def test_missing_brew_or_sudo_skips_auth(self):
        for missing in ("brew", "sudo"):
            result = self.run_shell(
                f'command_exists() {{ [[ "$1" != {missing} ]]; }}; prepare_update_auth',
                terminal=True,
            )
            self.assert_ok(result)
        self.assertEqual(self.calls(), [])

    def test_setup_runs_mole_only_and_is_idempotent(self):
        self.assert_ok(self.run_shell("main", terminal=True, args=("--setup-touchid",)))
        self.assertTrue(self.state.exists())
        self.assert_ok(self.run_shell("main", terminal=True, args=("--setup-touchid",)))
        self.assertEqual(self.calls(), ["mo touchid enable"])

    def test_setup_checks_postcondition(self):
        result = self.run_shell("setup_touchid", terminal=True, ENABLE_TOUCHID="false")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), ["mo touchid enable"])

    def test_cancelled_setup_reports_failure(self):
        result = self.run_shell("setup_touchid", terminal=True, MO_STATUS="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse(self.state.exists())

    def test_setup_missing_mole(self):
        result = self.run_shell(
            'command_exists() { [[ "$1" != mo ]]; }; setup_touchid', terminal=True
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_setup_requires_mac_interactive_non_ci(self):
        for terminal, env in ((False, {}), (True, {"TEST_OS": "Linux"}), (True, {"CI": "true"})):
            with self.subTest(terminal=terminal, env=env):
                self.assertNotEqual(
                    self.run_shell("setup_touchid", terminal=terminal, **env).returncode, 0
                )
        self.assertEqual(self.calls(), [])

    def test_active_pam_rules(self):
        sudo_file = Path(self.temp.name) / "sudo"
        local_file = Path(self.temp.name) / "sudo_local"
        cases = (
            ("auth include sudo_local\n", "auth sufficient pam_tid.so\n", True),
            ("auth sufficient /usr/lib/pam/pam_tid.so\n", "", True),
            ("# auth sufficient pam_tid.so\n", "", False),
            ("auth include sudo_local\n", "#auth sufficient pam_tid.so\n", False),
            ("# auth include sudo_local\n", "auth sufficient pam_tid.so\n", False),
            ("auth include sudo_local\n", "auth sufficient pam_tidXso\n", False),
            ("auth required pam_opendirectory.so\n", "auth sufficient pam_tid.so\n", False),
        )
        for sudo_policy, local_policy, enabled in cases:
            with self.subTest(sudo=sudo_policy, local=local_policy):
                sudo_file.write_text(sudo_policy)
                local_file.write_text(local_policy)
                result = self.run_shell(
                    'touchid_configured "$SUDO_FILE" "$LOCAL_FILE"', mocks=False,
                    SUDO_FILE=str(sudo_file), LOCAL_FILE=str(local_file),
                )
                self.assertEqual(result.returncode == 0, enabled, result.stderr)
        sudo_file.unlink()
        local_file.unlink()
        result = self.run_shell(
            'touchid_configured "$SUDO_FILE" "$LOCAL_FILE"', mocks=False,
            SUDO_FILE=str(sudo_file), LOCAL_FILE=str(local_file),
        )
        self.assertEqual(result.returncode, 1)

    def test_manager_flags_preserve_selection(self):
        for flag, selected in (("--brew-only", "BREW"), ("--npm-only", "NPM"),
                               ("--pip-only", "PIP"), ("--ai-tools-only", "AI_TOOLS")):
            result = self.run_shell(
                'for name in BREW NPM PIP GEM COMPOSER RUST GO AI_TOOLS OH_MY_ZSH TMUX NEOVIM MACOS; do '
                'var="UPDATE_$name"; [[ "${!var}" != true ]] || echo "$name"; done',
                args=(flag,),
            )
            self.assert_ok(result)
            self.assertEqual(result.stdout.strip(), selected)

    def test_cask_ignore_comments_whitespace_and_filtering(self):
        ignore = Path(self.temp.name) / "ignore"
        ignore.write_text("# comment\n\n  arc  # broken\nopera\n")
        result = self.run_shell(
            'load_cask_ignore_list >/dev/null; '
            'get_outdated_casks() { printf "arc\\nopera\\nfirefox\\n"; }; '
            'get_cask_upgrade_list', CASK_IGNORE_FILE=str(ignore),
        )
        self.assert_ok(result)
        self.assertEqual(result.stdout.strip(), "firefox")

    def test_empty_cask_ignore_list(self):
        result = self.run_shell('is_cask_ignored firefox', CASK_IGNORE_FILE=str(self.log))
        self.assertEqual(result.returncode, 1)

    def test_timeout_preserves_command_failure(self):
        result = self.run_shell('run_with_timeout 2 "exit 7"')
        self.assertEqual(result.returncode, 7)


if __name__ == "__main__":
    unittest.main()
