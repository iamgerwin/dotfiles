# Pull Request Checklist

Verify each item before running `gh pr create`. If one can't be satisfied, say so
explicitly in the PR body instead of leaving it out.

- [ ] **Purpose is clear**: why this change exists.
- [ ] **Scope is defined**: what's included and what's intentionally excluded.
- [ ] **Changes summarized in plain language**: no need to read the diff to understand them.
- [ ] **No unrelated changes**: the diff contains only what the issue needs.
- [ ] **Tests added or executed**: automated, or manual steps with their results.
- [ ] **Edge cases considered**: list the ones checked.
- [ ] **No breaking changes**, or each one clearly documented with a migration path.
- [ ] **Security implications reviewed**: input handling, secrets, permissions, destructive operations.
- [ ] **Performance impact considered**: or stated as negligible, with a reason.
- [ ] **Docs updated**: README, guides, CHANGELOG, where applicable.
- [ ] **Key files highlighted**: point reviewers to where the real logic lives.
- [ ] **Issue linked**: `Closes #<n>` (same repo) or `Closes <owner>/<repo>#<n>` (cross-repo).
- [ ] **Ready for review**: not a draft or WIP, unless the user asked for a draft.
- [ ] **No AI attribution** in the PR body.

## Before opening

- Re-read the full diff: `git diff <base>...HEAD`
- Confirm the commit authors: `git log --format='%h %an <%ae> %s' <base>..HEAD`
- Respect the repository's own PR template (`.github/pull_request_template.md`) if it has one.
  Fill in its sections; use `assets/pr-body-template.md` only to cover what it lacks.
