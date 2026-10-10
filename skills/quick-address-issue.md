---
name: quick-address-issue
description: Streamlined workflow for addressing GitHub issues with granular commits and comprehensive documentation
author: iamgerwin
version: 1.0.0
---

# Quick Address Issue Skill

A reusable workflow template for efficiently addressing GitHub issues following software engineering best practices with granular commits, proper testing, and documentation alignment.

## Parameters

- `ISSUE_URL` - GitHub issue link (required) - e.g., https://github.com/iamgerwin/dotfiles/issues/125
- `REPO_PATH` - Local repository path (optional) - defaults to /tmp/dotfiles
- `MAIN_BRANCH` - Main branch name (optional) - defaults to main

## Workflow Overview

```
Setup → Preparation → Implementation → Testing → Documentation → PR & Feedback
```

## Step-by-Step Instructions

### 1. Initial Checks

**Purpose:** Verify repository state and understand contribution requirements

- ☐ Clone or fork the repository if needed
- ☐ Review contributing guidelines (CONTRIBUTING.md, .github/CONTRIBUTING.md)
- ☐ Agree on any contribution agreements or CoCs
- ☐ Verify GitHub CLI access with correct account (gh-iamgerwin for personal)
- ☐ Confirm git config matches intended account (iamgerwin@live.com for personal)

### 2. Branch Setup

**Purpose:** Create isolated feature branch for changes

```bash
cd ${REPO_PATH}
git checkout ${MAIN_BRANCH}
git pull origin ${MAIN_BRANCH}
git checkout -b feat/$(echo ${ISSUE_URL} | grep -oE '[0-9]+')[-short-description]
```

- Branch naming: `feat/<issue-number>-<short-description>`
- Branch from ${MAIN_BRANCH}, not from older branches

### 3. Understand the Issue

**Purpose:** Fully comprehend what needs to be addressed

- Read the issue description carefully
- Review linked references and documentation
- Check for related issues or PRs
- Identify all affected files and components
- Note any edge cases or special considerations

### 4. Implementation

**Purpose:** Make changes following granular commit guidelines

#### Commit Best Practices

- ☐ **One intent per commit** - Single change theme; no mixed refactor + feature + bugfix
- ☐ **Independently safe** - Build passes, no broken state, no half-finished logic
- ☐ **Small, reviewable diff** - Avoid mega commits; split by responsibility
- ☐ **Layer-separated commits** - Schema → backend → UI → tests (don't mix unless necessary)
- ☐ **Pure refactors isolated** - No behavior changes in refactor commits
- ☐ **Formatting/lint isolated** - Never bundled with logic changes
- ☐ **Tests with changes** - Committed with the change or immediately after (not later)
- ☐ **Reverts are clean** - Reverting won't break others; avoid hidden dependencies
- ☐ **No secrets/artifacts** - No tokens, console spam, or temporary files
- ☐ **Conventional messages** - Imperative verb + scope/ID + outcome
  - Example: `fix(auth): enforce approval guard on update`
  - Include issue reference: `Fixes #123` or `References #125`
- ☐ **Guard commits** - For risky changes use feature flag, fallback path, or config toggle

### 5. Testing

**Purpose:** Ensure changes work as intended and don't break other functionality

- ☐ Execute manual tests if UI changes
- ☐ Run unit/feature tests if applicable
- ☐ Verify no breaking changes to other functionality
- ☐ Test edge cases and error scenarios
- ☐ Check for security implications
- ☐ Evaluate performance impact

### 6. Documentation Alignment

**Purpose:** Keep docs synchronized with code changes

**Always check if impacted:**
- README.md
- Contributing guidelines
- Relevant feature-specific documentation
- Installation guides
- Configuration examples
- API/Command documentation
- Limitation files (docs/limitations/)

**Update all files that reference changed functionality**

### 7. Code Quality Checks

**Purpose:** Ensure changes align with repository practices

- ☐ Follow existing code style and patterns
- ☐ Non-destructive changes (can rollback without issues)
- ☐ No breaking changes (or clearly documented)
- ☐ Remove any AI attribution from commits (no 🤖 markers)

### 8. Create Pull Request

**Purpose:** Submit changes for review with clear context

**PR Description Checklist:**

- ☐ Purpose is clear (why this change exists)
- ☐ Scope is defined (what's included/excluded)
- ☐ Changes summarized in plain language
- ☐ No unrelated changes included
- ☐ Tests added or executed (manual or automated)
- ☐ Edge cases considered
- ☐ No breaking changes (or clearly documented)
- ☐ Security implications reviewed
- ☐ Performance impact considered
- ☐ Docs updated (if applicable)
- ☐ Key files/logic highlighted for reviewers
- ☐ Ticket/issue linked
- ☐ Ready for review (not WIP)

### 9. Issue Feedback

**Purpose:** Communicate progress to issue stakeholders

- Comment on the GitHub issue with:
  - Summary of what was done
  - PR link with clear reference
  - Any relevant implementation details
  - Professional and enthusiastic tone as community collaborator

## Example Usage

```bash
# Set parameters
ISSUE_URL="https://github.com/iamgerwin/dotfiles/issues/125"
REPO_PATH="/tmp/dotfiles"
MAIN_BRANCH="main"

# Create branch
cd $REPO_PATH
git checkout $MAIN_BRANCH
git checkout -b feat/125-update-claude-code-latest

# Make changes, commit, push
git push -u origin feat/125-update-claude-code-latest

# Create PR via gh
gh pr create --repo iamgerwin/dotfiles \
  --title "Your PR Title" \
  --body "Your detailed PR description"

# Comment on issue
gh issue comment 125 --repo iamgerwin/dotfiles \
  --body "Summary of work completed..."
```

## Key Principles

1. **Granular Commits** - Each commit should be independently reviewable and safe
2. **Documentation First** - Update docs alongside code changes
3. **Clarity Over Speed** - Well-structured PRs are easier to review
4. **Quality Assurance** - Test thoroughly before submitting
5. **Respectful Communication** - Professional engagement with maintainers

## Related Resources

- [Claude Code Documentation](https://claude.com/claude-code)
- [Git Best Practices](https://git-scm.com/docs)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [GitHub CLI Reference](https://cli.github.com/manual)

## Version History

- **v1.0.0** (2026-10-11) - Initial skill creation for GitHub issue addressing workflow
