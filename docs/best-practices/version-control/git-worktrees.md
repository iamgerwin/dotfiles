# Git Worktrees Best Practices

## Overview

Git worktrees allow you to have multiple branches checked out simultaneously in separate directories, enabling parallel development without the overhead of multiple clones.

## When to Use Worktrees

### Ideal Use Cases
- **Hotfix While Feature Development**: Fix production bugs without disrupting feature work
- **Code Review**: Review PRs while maintaining your current work state
- **Parallel Feature Development**: Work on multiple features simultaneously
- **Testing**: Test different versions without switching branches
- **Long-Running Operations**: Run builds/tests in one worktree while coding in another

### When NOT to Use
- Small, quick changes (branch switching is faster)
- Limited disk space environments
- Projects with large binary files
- When submodules are heavily used (complexity increases)

## Core Commands

### Basic Operations
```bash
# Add a new worktree
git worktree add ../project-feature feature-branch

# Add worktree for new branch
git worktree add -b new-feature ../project-new-feature origin/main

# Add detached worktree (for testing specific commits)
git worktree add --detach ../project-test HEAD~3

# List all worktrees
git worktree list

# Remove a worktree
git worktree remove ../project-feature

# Prune stale worktrees
git worktree prune
```

## Project Structure

### Recommended Layout
```
workspace/
├── main/                 # Main repository (primary worktree)
│   ├── .git/            # Git directory
│   └── src/
├── feature-auth/        # Feature worktree
│   └── src/
├── hotfix-security/     # Hotfix worktree
│   └── src/
└── release-v2.0/        # Release worktree
    └── src/
```

### Naming Conventions
```bash
# Pattern: <project>-<type>-<description>
myapp-feature-authentication
myapp-hotfix-security-patch
myapp-release-v2.0
myapp-experiment-new-framework
```

## Workflow Patterns

### Feature Development Workflow
```bash
# 1. Create feature worktree
git worktree add -b feature/user-auth ../myapp-feature-auth origin/main

# 2. Work in the feature worktree
cd ../myapp-feature-auth
# ... development work ...

# 3. Push changes
git push -u origin feature/user-auth

# 4. After merge, cleanup
cd ../myapp-main
git worktree remove ../myapp-feature-auth
git branch -d feature/user-auth
```

### Hotfix Workflow
```bash
# 1. Create hotfix from production
git worktree add -b hotfix/critical ../myapp-hotfix origin/production

# 2. Fix and test
cd ../myapp-hotfix
# ... fix and test ...

# 3. Push and deploy
git push -u origin hotfix/critical

# 4. Cleanup after deployment
git worktree remove ../myapp-hotfix
```

### Code Review Workflow
```bash
# 1. Create review worktree
git fetch origin pull/123/head:pr-123
git worktree add ../myapp-review-pr123 pr-123

# 2. Review and test
cd ../myapp-review-pr123
# ... review code, run tests ...

# 3. Cleanup
git worktree remove ../myapp-review-pr123
git branch -d pr-123
```

## Performance Optimization

### Shared Repository Objects
```bash
# Worktrees share the same object database
# This saves disk space and network bandwidth

# Optimize repository (benefits all worktrees)
git gc --aggressive
git repack -Ad
```

### Sparse Checkout with Worktrees
```bash
# Enable sparse checkout for large repos
git worktree add --sparse ../myapp-frontend feature/ui

cd ../myapp-frontend
git sparse-checkout init --cone
git sparse-checkout set frontend/
```

## Integration with Tools

### IDE Configuration
```bash
# VSCode - Open different worktrees in separate windows
code ../myapp-main
code ../myapp-feature

# IntelliJ - Each worktree as separate project
idea ../myapp-main
idea ../myapp-feature
```

### Build Tool Configuration
```makefile
# Makefile for building across worktrees
build-all:
	@for dir in ../myapp-*; do \
		echo "Building $$dir"; \
		make -C $$dir build; \
	done
```

### CI/CD Integration
```yaml
# GitHub Actions - Test multiple branches
jobs:
  test-worktrees:
    strategy:
      matrix:
        branch: [main, develop, staging]
    steps:
      - uses: actions/checkout@v3
      - run: |
          git worktree add ../test-${{ matrix.branch }} origin/${{ matrix.branch }}
          cd ../test-${{ matrix.branch }}
          npm test
```

## Advanced Techniques

### Locked Worktrees
```bash
# Lock worktree to prevent accidental removal
git worktree lock ../myapp-production

# Unlock when needed
git worktree unlock ../myapp-production
```

### Moving Worktrees
```bash
# Move worktree to different location
git worktree move ../myapp-feature /new/path/myapp-feature
```

### Repair Corrupted Worktrees
```bash
# Repair worktree references
git worktree repair

# Repair from main repository
cd main-repo
git worktree repair ../broken-worktree
```

## Security Considerations

### Sensitive Data
```bash
# Don't share worktrees between users
# Each worktree maintains its own:
# - Index
# - HEAD
# - Working directory state

# Use separate worktrees for different security contexts
git worktree add ../myapp-public public-branch
git worktree add ../myapp-internal internal-branch
```

### File Permissions
```bash
# Ensure proper permissions
chmod -R 700 ../myapp-sensitive-worktree

# Verify no hardlinks exist across worktrees
find . -type f -links +1
```

## Troubleshooting

### Common Issues and Solutions

#### Worktree Already Exists
```bash
# Error: fatal: '...' already exists
# Solution: Remove or use different path
git worktree remove ../existing-path
# OR
git worktree add ../new-path branch-name
```

#### Stale Worktree References
```bash
# Clean up missing worktrees
git worktree prune -v

# Force removal of problematic worktree
git worktree remove --force ../problematic-worktree
```

#### Branch Already Checked Out
```bash
# Error: branch is already checked out at...
# Solution: Use different branch or remove existing worktree
git worktree list  # Find where branch is checked out
git worktree remove <path>
```

## Best Practices Summary

### Do's ✅
- Use descriptive worktree directory names
- Clean up worktrees after merging branches
- Run `git worktree prune` periodically
- Use worktrees for parallel development
- Lock production/critical worktrees
- Document worktree conventions in team README
- Use sparse checkout for large repositories
- Automate worktree creation for common workflows

### Don'ts ❌
- Don't nest worktrees inside each other
- Don't share worktrees between users
- Don't use worktrees with submodules (unless necessary)
- Don't forget to push changes before removing worktrees
- Don't modify the .git file in worktrees
- Don't use worktrees on network drives (performance)
- Don't create too many worktrees (cognitive overhead)
- Don't mix worktree content with main repository

## Automation Scripts

### Worktree Manager Script
```bash
#!/bin/bash
# wt-manager.sh - Worktree management helper

case "$1" in
  feature)
    git worktree add -b "feature/$2" "../${PWD##*/}-feature-$2" origin/main
    ;;
  hotfix)
    git worktree add -b "hotfix/$2" "../${PWD##*/}-hotfix-$2" origin/production
    ;;
  review)
    git fetch origin "pull/$2/head:pr-$2"
    git worktree add "../${PWD##*/}-review-pr$2" "pr-$2"
    ;;
  clean)
    git worktree prune
    git branch --merged | grep -v main | xargs -r git branch -d
    ;;
  *)
    echo "Usage: wt-manager.sh {feature|hotfix|review|clean} [name]"
    ;;
esac
```

### Cleanup Cron Job
```bash
# Add to crontab for automatic cleanup
0 2 * * * cd /path/to/repo && git worktree prune && git gc --auto
```

## References

- [Git Worktree Documentation](https://git-scm.com/docs/git-worktree)
- [Git Worktree Tutorial](https://github.blog/2015-07-29-git-worktree/)
- [Advanced Git Worktree Patterns](https://stackoverflow.com/questions/31935776/what-would-i-use-git-worktree-for)