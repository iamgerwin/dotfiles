---
name: quick-address-issue
description: Resolve a GitHub issue end to end as an open source contributor. Covers clone or fork, a feature branch off the base branch, granular conventional commits with tests, doc alignment, a reviewer-ready PR, and a closing comment on the issue. Use when asked to work on, fix, or address a GitHub issue link.
argument-hint: <issue-url> [base-branch]
disable-model-invocation: true
---

# Quick Address Issue

Work on the GitHub issue given in the arguments, acting as a careful open source
software engineer.

**Arguments:** `$ARGUMENTS`

- First argument: the issue URL or `owner/repo#number` (required). If it's missing, ask for it and stop.
- Second argument: the base branch (optional). Default: the repository's default branch.

Paths below (`scripts/`, `references/`, `assets/`) are relative to this skill's directory.

## 1. Understand the issue

1. Parse the reference: `scripts/parse-issue-url.sh "<issue-url>"` prints `OWNER`, `REPO`, `NUMBER`.
2. Read it: `gh issue view <NUMBER> --repo <OWNER>/<REPO> --json title,body,state,labels,comments`.
3. If the issue is **closed** or already has a linked PR or commit, check whether the work is
   done (`gh pr list --repo <OWNER>/<REPO> --state all --search "<NUMBER>"`, `git log --grep`).
   Report what you find and ask before doing duplicate work.

## 2. Account and workspace

1. Pick the GitHub account that matches `OWNER`. Profiles follow `gh-<company-name>`, and the
   default personal profile is `gh-iamgerwin` (`iamgerwin@live.com`). If it's unclear which
   profile applies, ask.
2. Make sure `gh auth status` shows that account active (`gh auth switch --user <login>`).
3. Clone into a scratch or workspace directory, never into `$HOME` directly:
   - With push access (`gh repo view <OWNER>/<REPO> --json viewerPermission`): `gh repo clone`.
   - Without it: `gh repo fork <OWNER>/<REPO> --clone`.
4. Set the commit identity **locally** for this clone (`git config user.email` / `user.name`), then
   verify it. Don't change the global git config.

## 3. Contribution rules

Read `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.github/pull_request_template.md`, and any lint or
test instructions, and follow them over the defaults in this skill.
If the project requires a CLA, DCO sign-off, or any other agreement, **stop and ask the user**.
Never accept an agreement on their behalf.

## 4. Branch

```bash
git switch <base> && git pull --ff-only
git switch -c <type>/<NUMBER>-<short-slug>   # e.g. feat/125-claude-code-latest
```

## 5. Impact analysis (before editing)

Search the whole repository for everything the change touches: code, scripts, configs, docs,
CHANGELOG, lock files. Example: `grep -rn "<term>" --exclude-dir=.git .`.
List the files you'll change, and why, before you start editing.

## 6. Implement with granular commits

Follow `references/commit-guidelines.md` for every commit. In short: one intent per commit, each
commit safe on its own, tests with the change, conventional messages that reference the issue,
and **no AI attribution** in commit messages.

## 7. Test

- Run the project's existing test and lint commands, and add tests for new behavior.
- If the project has no test harness, add a focused script test where reasonable, or record
  exact manual verification steps and their results for the PR.
- Re-run the impact search from step 5 to confirm no stale references remain.

## 8. When the issue can't be fully resolved

Create `docs/limitations/<NUMBER>-<short-description>.md` from `assets/limitation-template.md`,
commit it, and explain the blocker in the PR and in the issue comment.

## 9. Pull request

1. Push with `git push -u origin <branch>`. If HTTPS auth fails, run `gh auth setup-git`.
2. Check everything in `references/pr-checklist.md`.
3. Write the body to a temp file based on `assets/pr-body-template.md` (or the repository's own
   template), then run `gh pr create --base <base> --title "<conventional title>" --body-file <file>`.
   Always use `--body-file`: inline bodies get mangled by shell backticks and `$`.
4. No AI attribution in the PR body.

## 10. Comment on the issue

Write a short, friendly, professional comment based on `assets/issue-comment-template.md`, and post
it with `gh issue comment <NUMBER> --repo <OWNER>/<REPO> --body-file <file>`.

## 11. Report back

Give the user the PR URL, the list of commits, the tests run, and anything deferred or blocked.
