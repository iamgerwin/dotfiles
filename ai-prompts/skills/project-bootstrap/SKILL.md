---
name: project-bootstrap
description: Initialize new backend/frontend projects with opinionated defaults.
tags:
  - laravel
  - nextjs
  - bootstrap
  - setup
---

# Project Bootstrap Skill

## Purpose

Use this Skill when you need to quickly scaffold new projects with consistent configurations, best practices, and team conventions already built-in. This eliminates repetitive setup work and ensures all projects start with the same foundation.

## How this Skill works

This Skill provides:
- **Shell scripts** for automated project initialization (Laravel, Next.js)
- **Template files** for README and PR templates
- **Pre-configured settings** for linting, formatting, and CI/CD

### Scripts

| Script | Description |
|--------|-------------|
| `scripts/init-laravel.sh` | Initialize a new Laravel project with Pest, Pint, and standard structure |
| `scripts/init-nextjs.sh` | Initialize a new Next.js project with TypeScript, ESLint, and Tailwind |

### Templates

| Template | Description |
|----------|-------------|
| `templates/README.template.md` | Standard README structure for new projects |
| `templates/PR_TEMPLATE.template.md` | Pull request template with checklist |

### Requirements

- **Laravel**: PHP 8.2+, Composer, Node.js 18+
- **Next.js**: Node.js 18+, npm or yarn
- **General**: Git configured with user name/email

### Environment Variables

None required. Scripts will prompt for project-specific values.

## Example invocation

### Initialize a Laravel project

```bash
# From the skills directory
./scripts/init-laravel.sh my-laravel-app

# Or specify a path
./scripts/init-laravel.sh my-app ~/projects/
```

### Initialize a Next.js project

```bash
# From the skills directory
./scripts/init-nextjs.sh my-nextjs-app

# With TypeScript (default)
./scripts/init-nextjs.sh my-app --typescript
```

### Using with Claude

When working with Claude, you can reference this Skill:

> "Use the project-bootstrap Skill to scaffold a new Laravel API project called 'inventory-api' with Pest testing framework."

> "Bootstrap a new Next.js application using the project-bootstrap Skill. Include TypeScript and Tailwind CSS."

## Customization

To adapt these scripts for your team:

1. Edit the scripts in `scripts/` to match your conventions
2. Update templates in `templates/` with your project structure
3. Add additional scripts for other frameworks (Rails, Django, etc.)

## Related Skills

- `code-review-checklist` - Review standards for projects created with this Skill
