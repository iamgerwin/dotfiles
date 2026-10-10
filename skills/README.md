# AI Skills Directory

This folder contains reusable AI skills and workflows designed to optimize agentic AI development practices for software engineering tasks. These skills provide structured templates, checklists, and best practices for common development workflows.

## Overview

Skills in this directory follow [Claude's skill framework](https://claude.com/docs/skills/overview) and are designed to be:

- **Parameterized** - Accept variables for flexibility across different contexts
- **Comprehensive** - Include detailed checklists and procedures
- **Best-practice focused** - Align with industry standards and the repository's conventions
- **Reusable** - Can be invoked repeatedly across different projects and issues

## Available Skills

### 1. quick-address-issue

**File:** `quick-address-issue.md`

**Purpose:** Streamlined workflow for addressing GitHub issues with granular commits and comprehensive documentation

**Parameters:**
- `ISSUE_URL` - GitHub issue link (required)
- `REPO_PATH` - Local repository path (optional, defaults to /tmp/dotfiles)
- `MAIN_BRANCH` - Main branch name (optional, defaults to main)

**When to use:**
- Working on any GitHub issue
- Need structured approach to feature implementation
- Want to ensure proper documentation alignment
- Building PRs with granular commits

**Key features:**
- Initial setup and repository verification
- Granular commit guidelines with detailed checklist
- Testing strategy and validation
- Documentation alignment procedures
- PR creation best practices
- Issue feedback template

**Example invocation:**
```
/quick-address-issue ISSUE_URL=https://github.com/iamgerwin/dotfiles/issues/125
```

## Skill Structure

Each skill file follows this structure:

```markdown
---
name: skill-name
description: Brief description
author: iamgerwin
version: 1.0.0
---

# Skill Title

## Parameters
- Parameter descriptions

## Workflow Overview
- Visual or text overview

## Step-by-Step Instructions
- Numbered steps with checklists

## Example Usage
- Concrete examples

## Key Principles
- Important concepts

## Related Resources
- Links to relevant documentation
```

## How to Use These Skills

### Option 1: Direct Invocation
```bash
# In Claude Code or via Claude API
/quick-address-issue ISSUE_URL=https://github.com/iamgerwin/dotfiles/issues/125
```

### Option 2: Manual Reference
Simply read the skill file for detailed procedures and checklists when working on tasks.

### Option 3: Skill Integration
These skills can be registered with Claude Code and called automatically based on context.

## Creating New Skills

When creating new skills:

1. **Use consistent format** - Follow the template above
2. **Add parameters** - Make skills reusable across contexts
3. **Include checklists** - Provide actionable guidance
4. **Document examples** - Show real-world usage
5. **Update this README** - List new skills here

### Naming Convention

- **File name:** `kebab-case-skill-name.md`
- **Skill name (metadata):** `kebab-case-skill-name`
- **Folder organization:** One skill per file

## Best Practices

1. **Parametrize everything** - Use variables for values that change
2. **Make checklists explicit** - Use ☐ for unchecked items
3. **Include examples** - Real examples are more useful than abstract instructions
4. **Reference external docs** - Link to authoritative sources
5. **Version your skills** - Track changes in the metadata

## Related Documentation

- [Claude Skills Overview](https://claude.com/docs/skills/overview)
- [Repository Contributing Guidelines](../CONTRIBUTING.md)
- [Development Best Practices](../docs/ai-tools/INSTALLATION.md)

## Maintenance

Skills should be reviewed and updated when:
- Repository practices change
- New tools or workflows are introduced
- Feedback suggests improvements
- New edge cases are discovered

**Last Updated:** 2026-10-11
