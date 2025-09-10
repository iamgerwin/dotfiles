# Git Best Practices

## Overview
Git is the distributed version control system that powers modern software development. These best practices ensure clean history, effective collaboration, and maintainable repositories.

## Repository Setup

### Initial Configuration
```bash
# Global user configuration
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"

# Editor configuration
git config --global core.editor "vim"
git config --global merge.tool "vimdiff"

# Line ending configuration
git config --global core.autocrlf input  # Unix/Mac
git config --global core.autocrlf true   # Windows

# Default branch name
git config --global init.defaultBranch main

# Enable helpful features
git config --global rerere.enabled true
git config --global column.ui auto
git config --global branch.sort -committerdate
git config --global fetch.prune true
git config --global diff.colorMoved zebra
git config --global pull.rebase true
```

### .gitignore Best Practices
```gitignore
# Environment files
.env
.env.local
.env.*.local
*.env

# IDE files
.vscode/
.idea/
*.swp
*.swo
.DS_Store
Thumbs.db

# Dependencies
node_modules/
vendor/
bower_components/

# Build outputs
dist/
build/
out/
*.log
*.pid

# Test coverage
coverage/
*.lcov
.nyc_output/

# Temporary files
*.tmp
*.temp
*.cache
.sass-cache/

# Security
*.pem
*.key
*.crt
*.p12
secrets/
```

### .gitattributes Configuration
```gitattributes
# Auto detect text files and normalize line endings
* text=auto

# Source code
*.php text diff=php
*.js text
*.css text
*.html text diff=html
*.md text diff=markdown

# Binary files
*.jpg binary
*.png binary
*.gif binary
*.ico binary
*.pdf binary

# Exclude files from releases
.gitattributes export-ignore
.gitignore export-ignore
.github/ export-ignore
tests/ export-ignore
docs/ export-ignore
```

## Branching Strategies

### Git Flow
```bash
# Main branches
main        # Production-ready code
develop     # Integration branch

# Supporting branches
feature/*   # New features
release/*   # Release preparation
hotfix/*    # Emergency fixes

# Feature branch workflow
git checkout -b feature/user-authentication develop
# Work on feature
git checkout develop
git merge --no-ff feature/user-authentication
git branch -d feature/user-authentication

# Release workflow
git checkout -b release/1.2.0 develop
# Prepare release
git checkout main
git merge --no-ff release/1.2.0
git tag -a v1.2.0 -m "Version 1.2.0"
git checkout develop
git merge --no-ff release/1.2.0
```

### GitHub Flow
```bash
# Simple branch workflow
main        # Always deployable

# Feature workflow
git checkout -b feature-name
# Make changes
git push origin feature-name
# Create pull request
# Review and merge
```

### GitLab Flow
```bash
# Environment branches
main        # Latest code
pre-production  # Staging
production  # Production

# Feature workflow with environments
git checkout -b feature-name main
# Develop feature
git push origin feature-name
# Merge to main
git checkout pre-production
git merge main
# Test in staging
git checkout production
git merge pre-production
```

## Commit Best Practices

### Commit Message Format
```bash
# Conventional Commits
<type>(<scope>): <subject>

<body>

<footer>

# Types
feat: New feature
fix: Bug fix
docs: Documentation changes
style: Code style changes (formatting, etc)
refactor: Code refactoring
perf: Performance improvements
test: Test additions or corrections
build: Build system changes
ci: CI configuration changes
chore: Maintenance tasks

# Examples
feat(auth): add OAuth2 integration

Implemented Google and GitHub OAuth2 providers
with automatic user profile synchronization.

Closes #123

fix(api): prevent race condition in payment processing

Added mutex lock to ensure atomic transactions
during concurrent payment requests.

Fixes #456
```

### Atomic Commits
```bash
# Bad - mixing changes
git add .
git commit -m "Fix bug and add new feature"

# Good - separate concerns
git add src/auth.js
git commit -m "fix(auth): resolve token expiration issue"

git add src/feature.js tests/feature.test.js
git commit -m "feat(dashboard): add real-time analytics widget"
```

### Interactive Staging
```bash
# Stage specific hunks
git add -p file.js

# Stage with intent
git add -N new-file.js
git add -p new-file.js

# Review changes before committing
git diff --staged
git commit -v
```

## Working with History

### Rewriting History Safely
```bash
# Interactive rebase for last 3 commits
git rebase -i HEAD~3

# Fixup commits
git commit --fixup=abc123
git rebase -i --autosquash main

# Amend last commit
git commit --amend --no-edit

# Split a commit
git rebase -i HEAD~2
# Mark commit as 'edit'
git reset HEAD^
git add file1.js
git commit -m "First logical change"
git add file2.js
git commit -m "Second logical change"
git rebase --continue
```

### Cleaning Up Branches
```bash
# Delete merged branches
git branch --merged | grep -v "\*\|main\|develop" | xargs -n 1 git branch -d

# Delete remote tracking branches
git remote prune origin

# Clean up old branches
git for-each-ref --format='%(refname:short) %(committerdate)' refs/heads/ | \
  awk '$2 < "'$(date -d '3 months ago' '+%Y-%m-%d')'"' | \
  cut -d' ' -f1 | xargs git branch -D
```

## Merging and Rebasing

### Merge Strategies
```bash
# Fast-forward merge (linear history)
git merge --ff-only feature-branch

# No fast-forward (preserve branch history)
git merge --no-ff feature-branch

# Squash merge (single commit)
git merge --squash feature-branch
git commit -m "feat: add complete feature"

# Three-way merge with custom message
git merge feature-branch -m "Merge feature: user authentication"
```

### Rebase Best Practices
```bash
# Rebase feature branch on main
git checkout feature-branch
git rebase main

# Interactive rebase to clean history
git rebase -i main

# Preserve merge commits
git rebase --preserve-merges main

# Abort rebase if needed
git rebase --abort

# Continue after resolving conflicts
git add .
git rebase --continue
```

## Collaboration

### Pull Request Workflow
```bash
# Keep branch updated
git checkout feature-branch
git fetch origin
git rebase origin/main

# Push changes
git push origin feature-branch

# Force push after rebase (carefully!)
git push --force-with-lease origin feature-branch

# Update PR after review
git commit --fixup HEAD
git rebase -i --autosquash origin/main
git push --force-with-lease
```

### Code Review Practices
```bash
# Fetch PR for local review
git fetch origin pull/123/head:pr-123
git checkout pr-123

# Review changes
git diff main...pr-123
git log main..pr-123

# Suggest changes
git checkout -b pr-123-suggestions pr-123
# Make changes
git push origin pr-123-suggestions
```

## Advanced Techniques

### Stashing
```bash
# Save current work
git stash save "WIP: feature implementation"

# List stashes
git stash list

# Apply specific stash
git stash apply stash@{2}

# Pop latest stash
git stash pop

# Create branch from stash
git stash branch feature-from-stash

# Stash including untracked files
git stash --include-untracked
```

### Cherry-Picking
```bash
# Apply specific commit
git cherry-pick abc123

# Cherry-pick range
git cherry-pick abc123..def456

# Cherry-pick without committing
git cherry-pick -n abc123

# Continue after conflict
git cherry-pick --continue
```

### Bisecting
```bash
# Start bisect
git bisect start
git bisect bad HEAD
git bisect good v1.0.0

# Automated bisect
git bisect run npm test

# Manual bisect
git bisect good  # Current commit is good
git bisect bad   # Current commit is bad

# End bisect
git bisect reset
```

## Hooks

### Client-Side Hooks
```bash
#!/bin/sh
# .git/hooks/pre-commit
# Check for debugging statements

FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '\.(js|php|py)$')

for FILE in $FILES; do
    if grep -E '(console\.(log|debug)|var_dump|dd\(|debugger)' "$FILE"; then
        echo "Error: Debugging statement found in $FILE"
        exit 1
    fi
done

# Run tests
npm test || exit 1

# Check code style
npm run lint || exit 1
```

### Commit Message Hook
```bash
#!/bin/sh
# .git/hooks/commit-msg
# Validate commit message format

commit_regex='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\(.+\))?: .{1,50}'

if ! grep -qE "$commit_regex" "$1"; then
    echo "Invalid commit message format!"
    echo "Format: <type>(<scope>): <subject>"
    exit 1
fi
```

## Security

### Sensitive Data Protection
```bash
# Remove sensitive file from history
git filter-branch --force --index-filter \
  'git rm --cached --ignore-unmatch path/to/sensitive-file' \
  --prune-empty --tag-name-filter cat -- --all

# Using BFG Repo-Cleaner (faster alternative)
bfg --delete-files sensitive-file.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive

# Scan for secrets
git secrets --install
git secrets --scan
```

### Signing Commits
```bash
# Configure GPG signing
git config --global user.signingkey YOUR_GPG_KEY
git config --global commit.gpgsign true

# Sign individual commit
git commit -S -m "Signed commit"

# Verify signatures
git log --show-signature
git verify-commit HEAD
```

## Performance

### Large File Storage (LFS)
```bash
# Install and initialize LFS
git lfs install

# Track large files
git lfs track "*.psd"
git lfs track "*.zip"
git add .gitattributes

# View tracked files
git lfs ls-files

# Migrate existing files
git lfs migrate import --include="*.psd" --everything
```

### Optimizing Repository
```bash
# Garbage collection
git gc --aggressive --prune=now

# Repack repository
git repack -a -d -f --depth=250 --window=250

# Clean unnecessary files
git clean -fdx

# Shallow clone for CI/CD
git clone --depth 1 --branch main https://github.com/user/repo.git
```

## Troubleshooting

### Common Fixes
```bash
# Fix detached HEAD
git checkout main

# Undo last commit (keep changes)
git reset --soft HEAD~1

# Undo last commit (discard changes)
git reset --hard HEAD~1

# Recover deleted branch
git reflog
git checkout -b recovered-branch abc123

# Fix wrong commit author
git commit --amend --author="Name <email@example.com>"

# Remove untracked files
git clean -fd
```

### Conflict Resolution
```bash
# View conflict markers
git diff --name-only --diff-filter=U

# Use specific version
git checkout --ours file.js  # Keep current branch version
git checkout --theirs file.js  # Keep incoming version

# Manual merge tool
git mergetool

# Abort merge
git merge --abort
```

## Aliases

### Useful Git Aliases
```bash
# ~/.gitconfig
[alias]
    # Shortcuts
    co = checkout
    br = branch
    ci = commit
    st = status
    
    # Pretty log
    lg = log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    
    # Show last commit
    last = log -1 HEAD
    
    # Unstage files
    unstage = reset HEAD --
    
    # Amend commit
    amend = commit --amend --no-edit
    
    # List branches by date
    recent = for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'
    
    # Show changed files
    changed = diff --name-only
    
    # Interactive rebase
    ri = rebase -i
    
    # Prune and fetch
    pf = !git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -D
```

## Best Practices Summary

1. **Write Clear Commit Messages**: Use conventional commits format
2. **Keep Commits Atomic**: One logical change per commit
3. **Branch Strategically**: Use appropriate branching model for your team
4. **Review Before Pushing**: Always review changes before pushing
5. **Keep History Clean**: Use interactive rebase to maintain clean history
6. **Never Force Push to Shared Branches**: Use --force-with-lease instead
7. **Use .gitignore**: Exclude unnecessary files from tracking
8. **Sign Important Commits**: Use GPG signing for releases
9. **Regular Maintenance**: Perform regular gc and prune operations
10. **Document Workflows**: Maintain clear documentation of team Git workflows

## Conclusion

Git is a powerful tool that requires discipline and good practices to use effectively. Following these best practices ensures a clean, maintainable repository history and smooth collaboration within teams.