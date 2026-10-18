# Living engineering lessons

Read this before making changes. Add concrete lessons as they are discovered,
link their regression tests, and revise entries when the behavior changes.
README owns usage and release instructions; CHANGELOG owns user-visible history.

## Authentication must stay on the foreground terminal

- **Symptom:** Homebrew cask updates wait for credentials inside captured output
  or time out without a visible prompt.
- **Cause:** Authentication starts inside background or redirected commands.
- **Prevention:** Validate sudo before Homebrew updates in an interactive macOS
  terminal. Let macOS PAM offer Touch ID and password fallback; keep Homebrew
  unprivileged. CI and redirected runs skip upfront authentication. Never collect
  passwords in shell variables, disable password fallback, or change PAM silently.
- **Evidence:** `tests/update_all_test.py` covers authentication order, cached
  credentials, failure, isolation flags, noninteractive runs, and CI.

## Touch ID setup is opt-in and idempotent

- **Symptom:** Repeating setup can turn off working Touch ID.
- **Cause:** `mo touchid` is a toggle, and commented PAM examples are not active
  configuration. A sudo_local rule is ineffective without its sudo include.
- **Prevention:** Check active rules and the include before invoking Mole's explicit
  `mo touchid enable`, not its bare toggle. Use `update-all --setup-touchid` only
  from a terminal; verify setup afterward. Mole
  owns privileged configuration and its password prompt; update-all writes no PAM
  files. Password fallback and hardware availability remain macOS responsibilities.
- **Evidence:** `tests/update_all_test.py` tests active, commented, missing, and
  legacy policies; setup success, cancellation, missing Mole, and repeated setup.

## Compatibility and release evidence must be reproducible

- **Symptom:** A check passes on a developer's modern Bash but fails on a Mac.
- **Cause:** macOS ships Bash 3.2, and GNU-only tools differ from BSD tools.
- **Prevention:** Run the same check runner on Linux and macOS using `/bin/bash`.
  Add mocked regressions rather than running real installers in CI. Record the
  physical Touch ID verification separately; hosted runners have no sensor.
- **Evidence:** `.github/workflows/ci.yml` and `scripts/check.sh`. Release checks
  validate VERSION, changelog notes, and main ancestry before creating `vX.Y.Z`.
- **Merge gate:** A workflow alone does not block merging. Keep GitHub branch
  protection check names aligned with CI job names; README records the live
  requirements. Repository settings survive code rollback and need separate changes.

## Terminal tests must drain their output

- **Symptom:** A mocked full update hangs even though all commands finish quickly.
- **Cause:** An unread pseudo-terminal fills its small output buffer and blocks
  the foreground process, particularly on macOS.
- **Prevention:** Drain PTY output concurrently and close/reap terminal resources.
- **Evidence:** The full-main authentication-order regression in
  `tests/update_all_test.py` exercises this test harness on both CI platforms.
