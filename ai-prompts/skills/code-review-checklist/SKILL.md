---
name: code-review-checklist
description: Comprehensive code review checklists for backend and frontend code.
tags:
  - code-review
  - quality
  - best-practices
  - laravel
  - react
---

# Code Review Checklist Skill

## Purpose

Use this Skill to ensure consistent, thorough code reviews across your team. These checklists help reviewers catch common issues, enforce best practices, and maintain code quality standards.

## How this Skill works

This Skill provides:
- **Markdown checklists** for different contexts (backend, frontend)
- **Category-based organization** for efficient reviews
- **Customizable templates** to match team conventions

### Templates

| Template | Description |
|----------|-------------|
| `templates/backend-checklist.md` | Checklist for Laravel/PHP backend code |
| `templates/frontend-checklist.md` | Checklist for React/TypeScript frontend code |

### Categories Covered

**Backend Checklist**:
- Code Quality & Standards
- Security Considerations
- Database & Performance
- Error Handling
- Testing Coverage
- Documentation

**Frontend Checklist**:
- Component Architecture
- TypeScript & Type Safety
- Performance & Optimization
- Accessibility (a11y)
- State Management
- Testing

## Example invocation

### Using checklists in reviews

Copy the relevant checklist content when reviewing a PR:

```bash
# Copy backend checklist to clipboard
cat ai-prompts/skills/code-review-checklist/templates/backend-checklist.md | pbcopy

# Or for frontend
cat ai-prompts/skills/code-review-checklist/templates/frontend-checklist.md | pbcopy
```

### Using with Claude

When working with Claude for code reviews:

> "Use the code-review-checklist Skill to review this Laravel controller. Focus on security and performance considerations."

> "Apply the frontend checklist from code-review-checklist Skill to review this React component."

## Customization

To adapt these checklists for your team:

1. Edit templates in `templates/` to add team-specific checks
2. Create additional checklists for other technologies (e.g., `api-checklist.md`)
3. Remove checks that don't apply to your projects

## Related Skills

- `project-bootstrap` - Set up projects that align with these review standards
