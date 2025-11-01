# Enhancement: update-all.sh should handle failing/broken Homebrew casks and clean up obsolete apps

## Summary

Running `scripts/update-all.sh` surfaces repeated Homebrew Cask failures. The script should handle these gracefully (retry/skip/uninstall as appropriate) and the Brewfile should be audited to remove/rename obsolete or flaky casks. This will make `update-all.sh` idempotent and reduce noisy failures during routine updates.

## Error Output

Observed during `brew upgrade --cask --greedy` within the script:

```
Error: Problems with multiple casks:
alt-tab: It seems the App source '/Applications/AltTab.app' is not there.
arc: It seems the App source '/Applications/Arc.app' is not there.
firefox@developer-edition: It seems the App source '/Applications/Firefox Developer Edition.app' is not there.
opera: It seems there is already an App at '/opt/homebrew/Caskroom/opera/118.0.5461.60/Opera.app'.
skype: Download failed on Cask 'skype' with message: Download failed: https://download.skype.com/s4l/download/mac/Skype-8.150.0.125.dmg
vivaldi: It seems the App source '/Applications/Vivaldi.app' is not there.
```

## Likely Causes

- App bundles were moved/removed from `/Applications` after install (common for AltTab, Arc, Vivaldi, Firefox Dev Edition).
- Stale/partial installs in `Caskroom` (e.g., Opera) causing conflicts.
- Upstream vendor download changed or rate-limited (Skype), or token changed.
- Outdated/renamed tokens in `Brewfile` (e.g., Canary channel uses `google-chrome-canary`, not `google-chrome@canary`).

## Proposed Enhancements

- Add a cask remediation step in `scripts/update-all.sh`:
  - On "App source ... is not there": attempt `brew reinstall --cask --force <cask>` once; if still failing, log and skip.
  - On "already an App at ...": attempt `brew uninstall --cask --force <cask>` followed by `brew install --cask <cask>`.
  - On download errors: retry once; on second failure, skip with a clear notice.
  - Provide a configurable ignore/remove list via env or config file (e.g., `.dotfiles-update.yml`).
- Audit and reconcile `Brewfile` cask tokens and intent:
  - Replace `google-chrome@canary` with `google-chrome-canary`.
  - Review whether both `logi-options+` and `logitech-options` are needed (the latter is deprecated).
  - Verify `firefox@developer-edition` token is current; if renamed, update accordingly.
  - Remove casks that are no longer needed or supported to avoid recurring failures.
- Optionally add `--no-quarantine` for casks known to trip Gatekeeper, behind a flag.

## Candidates To Review (remove/rename/skip)

- `alt-tab`, `arc`, `vivaldi`, `firefox@developer-edition` — re-check tokens and reinstall behavior.
- `opera` — clean uninstall/reinstall to fix Caskroom conflict.
- `skype` — transient vendor download failures; consider skipping by default.
- `google-chrome@canary` → `google-chrome-canary` (rename).
- `logitech-options` — likely removable in favor of `logi-options+`.

## New Additions

- `gemini-cli` — Google Gemini CLI for AI-powered development workflows (install via `brew install gemini-cli`).

## Acceptance Criteria

- `scripts/update-all.sh` completes without exiting non-zero due to cask issues.
- Problematic casks are retried once and then skipped with actionable messaging.
- A documented mechanism exists to ignore or auto-remove specific casks.
- `Brewfile` reflects current, installable tokens; obsolete entries are removed.

## Reproduction

1. On macOS with Homebrew, run: `scripts/update-all.sh --brew-only --verbose`.
2. Observe failures during `brew upgrade --cask --greedy`.

## Environment

- macOS: [please fill]
- Homebrew: `brew --version` [please fill]
- Brewfile path: `Brewfile`

## Notes

- Some comments in the Brewfile appear copy-pasted (e.g., `arc`, `zed`, `zen` descriptions). Consider tidying while auditing tokens.

---

If approved, I can open a PR to:

- Add a cask remediation function to `scripts/update-all.sh` with retry/skip/uninstall logic.
- Introduce an optional `.dotfiles-update.yml` for ignore/remove lists.
- Update `Brewfile` tokens and remove deprecated entries.

