# Skills

Reusable [Agent Skills](https://claude.com/docs/skills/overview) for Claude Code and other
skill-aware agents. Each skill is a self-contained folder that an agent loads on demand: first
only the name and description, then the `SKILL.md` body when the skill is used, and bundled
files only when the instructions point to them.

## Layout

```
skills/
├── README.md                    # This file (not synced)
└── <skill-name>/                # kebab-case, matches the frontmatter name
    ├── SKILL.md                 # REQUIRED: frontmatter + core instructions
    ├── scripts/                 # OPTIONAL: executable helpers (bash, python, ...)
    ├── references/              # OPTIONAL: docs loaded only when needed
    └── assets/                  # OPTIONAL: templates, boilerplate, config files
```

## Available skills

| Skill | Invoke | Purpose |
|-------|--------|---------|
| [`quick-address-issue`](quick-address-issue/SKILL.md) | `/quick-address-issue <issue-url> [base-branch]` | Resolve a GitHub issue end to end: branch, granular commits, tests, docs, PR, issue comment |
| [`code-review-checklist`](code-review-checklist/SKILL.md) | Ask Claude to use it | Backend (Laravel) and frontend (React) review checklists |
| [`project-bootstrap`](project-bootstrap/SKILL.md) | Ask Claude to use it | Scaffold Laravel or Next.js projects with opinionated defaults |

## Install

Skills are read from `~/.claude/skills/`. Sync them from this repo:

```bash
~/dotfiles/scripts/sync-skills.sh             # sync to ~/.claude/skills
~/dotfiles/scripts/sync-skills.sh --dry-run   # preview
~/dotfiles/scripts/sync-skills.sh --target DIR
```

Each skill folder is synced on its own. Skills you installed from other sources stay
untouched, and files removed from a skill here are removed from its synced copy.

## SKILL.md conventions

```markdown
---
name: my-skill                      # required, lowercase kebab-case, == folder name
description: What it does. Use when ...   # required, <= 1024 chars, say WHEN to use it
argument-hint: <required> [optional]      # optional, shown in / autocomplete
disable-model-invocation: true            # optional, manual /my-skill only
---

# My Skill

Concise, imperative instructions. Refer to bundled files by relative path,
e.g. `scripts/run.sh`, `references/guide.md`, `assets/template.md`.
```

Guidelines:

- **Description drives discovery.** State what the skill does *and* when to use it.
- **Keep `SKILL.md` lean** (well under 500 lines). Move long checklists and docs into
  `references/`, and templates into `assets/`.
- **Parameterize with `$ARGUMENTS`** instead of hardcoding links, branches, or paths.
- **Set `disable-model-invocation: true`** for skills with side effects (pushing, posting,
  deploying), so they only run when invoked explicitly.
- **Make scripts deterministic and executable**, and test them (see `tests/skills/`).
- **No secrets.** Read credentials from the environment or `gh auth`, never from files in the skill.

## Create a new skill

```bash
mkdir -p skills/my-skill/{scripts,references,assets}
$EDITOR skills/my-skill/SKILL.md
tests/skills/validate-skills.sh          # check layout and frontmatter
scripts/sync-skills.sh                   # install locally
```

Then add the skill to the table above and to the Claude Skills section of the root `README.md`.

## Tests

```bash
tests/skills/validate-skills.sh           # every skill: layout, frontmatter, referenced files
tests/skills/parse-issue-url.test.sh      # quick-address-issue helper script
```
