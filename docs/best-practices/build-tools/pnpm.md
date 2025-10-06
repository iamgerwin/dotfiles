# PNPM Best Practices

## Official Documentation
- **PNPM Documentation**: https://pnpm.io
- **PNPM CLI**: https://pnpm.io/cli/add
- **Workspaces**: https://pnpm.io/workspaces
- **Configuration**: https://pnpm.io/npmrc
- **Motivation**: https://pnpm.io/motivation

## Overview

PNPM (Performant NPM) is a fast, disk space-efficient package manager for JavaScript. Unlike npm and Yarn, PNPM uses a content-addressable storage system where packages are stored in a global store and linked to projects via hard links and symlinks. This approach drastically reduces disk usage and installation time while maintaining strict dependency management.

PNPM creates a non-flat node_modules structure that prevents packages from accessing undeclared dependencies, making it more reliable and secure than traditional package managers.

## Pros & Cons

### Advantages
- **Disk space efficiency** - Packages stored once globally, linked to projects
- **Faster installations** - Incremental installs reuse cached packages
- **Strict dependency resolution** - Prevents phantom dependencies
- **Monorepo support** - Built-in workspace management
- **Deterministic installs** - Lockfile ensures consistency
- **Minimal overhead** - Lightweight compared to Yarn
- **Compatible with npm** - Drop-in replacement for npm
- **Better security** - Isolated dependency trees
- **Side-effects cache** - Speeds up repeated installations
- **Built-in scripts** - Recursive execution across workspaces

### Disadvantages
- **Learning curve** - Different node_modules structure
- **Compatibility issues** - Some packages expect flat node_modules
- **Symlink limitations** - Challenges on Windows (pre-v7)
- **Tool support** - Not all tools handle symlinks properly
- **Debugging complexity** - Non-flat structure harder to inspect
- **Migration effort** - Requires testing when switching from npm/Yarn
- **Smaller ecosystem** - Fewer resources compared to npm/Yarn
- **Build tool integration** - Some bundlers need configuration

## Best Use Cases

### Ideal Scenarios
- **Monorepo architectures** - Multiple packages in one repository
- **Large projects** - Many dependencies benefit from space savings
- **CI/CD pipelines** - Faster installation speeds up builds
- **Docker builds** - Reduced layer sizes and build times
- **Team environments** - Consistent dependency resolution
- **Disk space constrained** - Shared hosting or limited storage
- **Enterprise projects** - Strict dependency management required
- **Active development** - Frequent dependency updates
- **Multiple projects** - Shared dependencies across projects

### When Not to Use
- **Legacy codebases** - Heavy reliance on flat node_modules
- **Incompatible tooling** - Build tools that don't support symlinks
- **Simple prototypes** - Overhead not justified for small projects
- **Windows pre-v7** - Symlink issues on older Windows versions
- **Restricted environments** - Systems that don't allow symlinks
- **Strict compatibility needs** - When npm is mandated

## Project Structure

```
project/
├── packages/
│   ├── app/
│   │   ├── package.json
│   │   └── src/
│   ├── lib-a/
│   │   ├── package.json
│   │   └── src/
│   └── lib-b/
│       ├── package.json
│       └── src/
├── .npmrc                    # PNPM configuration
├── package.json              # Root package.json
├── pnpm-lock.yaml           # Lockfile
└── pnpm-workspace.yaml      # Workspace configuration
```

## Core Best Practices

### 1. Workspace Configuration

```yaml
# pnpm-workspace.yaml
packages:
  - 'packages/*'
  - 'apps/*'
  - '!**/test/**'
```

```json
// Root package.json
{
  "name": "my-monorepo",
  "private": true,
  "scripts": {
    "build": "pnpm -r --filter='./packages/*' build",
    "test": "pnpm -r test",
    "dev": "pnpm -r --parallel dev"
  },
  "devDependencies": {
    "typescript": "^5.0.0"
  }
}
```

### 2. PNPM Configuration

```ini
# .npmrc
# Strict peer dependencies
strict-peer-dependencies=true

# Auto install peers
auto-install-peers=true

# Shamefully hoist (use sparingly)
# shamefully-hoist=false

# Store directory
store-dir=~/.pnpm-store

# Lockfile settings
lockfile=true
prefer-frozen-lockfile=true

# Node linker (v8+)
node-linker=isolated

# Public hoist pattern
public-hoist-pattern[]='*eslint*'
public-hoist-pattern[]='*prettier*'

# Registry
registry=https://registry.npmjs.org/

# Logging
loglevel=info
```

### 3. Installation Commands

```bash
# Install all dependencies
pnpm install

# Install production dependencies only
pnpm install --prod

# Install from frozen lockfile (CI)
pnpm install --frozen-lockfile

# Install with no lockfile update
pnpm install --prefer-frozen-lockfile

# Add package
pnpm add <package>

# Add dev dependency
pnpm add -D <package>

# Add to specific workspace
pnpm add <package> --filter <workspace>

# Add to all workspaces
pnpm add <package> -w

# Update package
pnpm update <package>

# Update all packages
pnpm update

# Remove package
pnpm remove <package>

# Remove from specific workspace
pnpm remove <package> --filter <workspace>
```

### 4. Workspace Management

```bash
# Run script in all workspaces
pnpm -r run build

# Run script in specific workspace
pnpm --filter <workspace> run build

# Run in parallel
pnpm -r --parallel run dev

# Run with dependencies
pnpm --filter <workspace>... run build

# Run in topological order
pnpm -r --workspace-concurrency=1 run build

# List workspaces
pnpm -r list

# Execute command in each workspace
pnpm -r exec rm -rf dist
```

### 5. Package.json Scripts

```json
{
  "scripts": {
    "dev": "pnpm -r --parallel run dev",
    "build": "pnpm -r run build",
    "test": "pnpm -r run test",
    "lint": "pnpm -r run lint",
    "clean": "pnpm -r exec rm -rf dist node_modules",
    "type-check": "pnpm -r run type-check",
    "format": "prettier --write \"**/*.{ts,tsx,md}\"",
    "prepare": "husky install"
  }
}
```

### 6. Dependency Management

```json
// packages/app/package.json
{
  "name": "@monorepo/app",
  "dependencies": {
    "@monorepo/lib-a": "workspace:*",
    "@monorepo/lib-b": "workspace:^1.0.0",
    "react": "^18.0.0"
  },
  "peerDependencies": {
    "react": ">=17.0.0"
  }
}
```

```bash
# Link workspace packages
pnpm install

# Update workspace dependencies
pnpm update --filter @monorepo/app

# Check for outdated
pnpm outdated

# Audit dependencies
pnpm audit

# Fix vulnerabilities
pnpm audit --fix
```

### 7. Filtering and Selection

```bash
# Filter by package name
pnpm --filter "@monorepo/app" build

# Filter by pattern
pnpm --filter "@monorepo/*" build

# Filter by path
pnpm --filter "./packages/app" build

# Include dependencies
pnpm --filter "@monorepo/app..." build

# Include dependents
pnpm --filter "...@monorepo/lib-a" build

# Changed packages (with git)
pnpm --filter "...[origin/main]" build

# Multiple filters
pnpm --filter "@monorepo/app" --filter "@monorepo/lib-a" build
```

## Architecture Patterns

### 1. Monorepo Structure

```
monorepo/
├── apps/
│   ├── web/              # Next.js app
│   └── api/              # Express API
├── packages/
│   ├── ui/               # Shared UI components
│   ├── utils/            # Shared utilities
│   └── config/           # Shared configuration
├── tools/
│   └── scripts/          # Build scripts
├── .npmrc
├── package.json
├── pnpm-lock.yaml
└── pnpm-workspace.yaml
```

### 2. Dependency Hoisting Strategy

```ini
# .npmrc
# Hoist patterns for tools
public-hoist-pattern[]='*types*'
public-hoist-pattern[]='*eslint*'
public-hoist-pattern[]='*prettier*'
public-hoist-pattern[]='@swc/*'

# Shamefully hoist problematic packages only
shamefully-hoist=false
```

### 3. Caching Strategy

```bash
# Use PNPM store for caching
export PNPM_HOME="$HOME/.pnpm-store"

# Prune store periodically
pnpm store prune

# Check store status
pnpm store status

# Verify store integrity
pnpm store verify
```

### 4. CI/CD Integration

```yaml
# .github/workflows/ci.yml
name: CI

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Build
        run: pnpm build

      - name: Test
        run: pnpm test

      - name: Lint
        run: pnpm lint
```

## Security Considerations

### 1. Lockfile Integrity

```bash
# Always commit pnpm-lock.yaml
git add pnpm-lock.yaml

# Verify lockfile integrity
pnpm install --frozen-lockfile

# Update lockfile only when needed
pnpm install --lockfile-only
```

### 2. Dependency Auditing

```bash
# Audit dependencies
pnpm audit

# Audit and fix
pnpm audit --fix

# Audit production only
pnpm audit --prod

# Generate audit report
pnpm audit --json > audit-report.json
```

### 3. Package Verification

```ini
# .npmrc
# Verify package checksums
verify-store-integrity=true

# Strict SSL
strict-ssl=true

# Ignore scripts during install (security)
ignore-scripts=false

# Engine strict
engine-strict=true
```

### 4. Private Package Security

```json
{
  "publishConfig": {
    "access": "restricted"
  }
}
```

```ini
# .npmrc
# Use scoped registry for private packages
@mycompany:registry=https://npm.pkg.github.com/
//npm.pkg.github.com/:_authToken=${NPM_TOKEN}
```

## Common Vulnerabilities

### 1. Phantom Dependencies

**Vulnerability:** Packages accessing dependencies not declared in package.json

**Risk:** Works in development but breaks in production or other environments

**Mitigation:**
```json
// package.json - explicitly declare all dependencies
{
  "dependencies": {
    "lodash": "^4.17.21",
    "axios": "^1.4.0"
  }
}
```

PNPM prevents this by default with its strict node_modules structure.

### 2. Dependency Confusion

**Vulnerability:** Malicious packages with same name as private packages

**Risk:** Installing malicious code instead of private package

**Mitigation:**
```ini
# .npmrc
# Use scoped packages
@mycompany:registry=https://npm.pkg.github.com/

# Verify packages
verify-store-integrity=true
```

### 3. Supply Chain Attacks

**Vulnerability:** Compromised dependencies

**Risk:** Malicious code execution

**Mitigation:**
```bash
# Regular audits
pnpm audit

# Review lockfile changes
git diff pnpm-lock.yaml

# Use exact versions for critical deps
{
  "dependencies": {
    "critical-package": "1.2.3"
  }
}
```

### 4. Outdated Dependencies

**Vulnerability:** Using packages with known vulnerabilities

**Risk:** Security exploits

**Mitigation:**
```bash
# Check for outdated packages
pnpm outdated

# Update with care
pnpm update

# Automated updates (with testing)
# Use Dependabot or Renovate
```

### 5. Malicious Scripts

**Vulnerability:** postinstall scripts executing malicious code

**Risk:** System compromise

**Mitigation:**
```ini
# .npmrc
# Disable scripts during install
ignore-scripts=true

# Or allowlist specific packages
ignored-scripts[]="*"
!ignored-scripts[]="package-with-safe-script"
```

## Performance Optimization

### 1. Store Management

```bash
# Prune unused packages
pnpm store prune

# Add to periodic maintenance script
#!/bin/bash
pnpm store prune
pnpm install --frozen-lockfile

# Configure store location
# .npmrc
store-dir=/path/to/fast/disk/.pnpm-store
```

### 2. Parallel Execution

```bash
# Build packages in parallel
pnpm -r --parallel run build

# Limit concurrency
pnpm -r --workspace-concurrency=4 run build

# Parallel development
pnpm -r --parallel run dev
```

### 3. Selective Installation

```bash
# Install only needed workspaces
pnpm install --filter <workspace>...

# Skip optional dependencies
pnpm install --no-optional

# Production only
pnpm install --prod --frozen-lockfile
```

### 4. Cache Optimization

```yaml
# GitHub Actions cache
- uses: actions/setup-node@v3
  with:
    node-version: '18'
    cache: 'pnpm'

# Or manual cache
- name: Get pnpm store directory
  id: pnpm-cache
  run: echo "dir=$(pnpm store path)" >> $GITHUB_OUTPUT

- uses: actions/cache@v3
  with:
    path: ${{ steps.pnpm-cache.outputs.dir }}
    key: ${{ runner.os }}-pnpm-store-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: |
      ${{ runner.os }}-pnpm-store-
```

### 5. Network Optimization

```ini
# .npmrc
# Increase network timeout
network-timeout=60000

# Concurrent downloads
network-concurrency=16

# Fetch retries
fetch-retries=3
```

## Testing Approach

### 1. Workspace Testing

```bash
# Test all workspaces
pnpm -r test

# Test specific workspace
pnpm --filter @monorepo/app test

# Test with coverage
pnpm -r test -- --coverage

# Test changed packages
pnpm --filter "...[origin/main]" test
```

### 2. Integration Testing

```json
// package.json
{
  "scripts": {
    "test:integration": "pnpm -r --workspace-concurrency=1 test:integration",
    "test:e2e": "pnpm --filter @monorepo/e2e test"
  }
}
```

### 3. Pre-commit Hooks

```json
// package.json
{
  "scripts": {
    "prepare": "husky install"
  },
  "devDependencies": {
    "husky": "^8.0.0",
    "lint-staged": "^13.0.0"
  }
}
```

```bash
# .husky/pre-commit
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

pnpm lint-staged
pnpm -r run type-check
```

## Error Handling

### 1. Installation Errors

```bash
# Clear cache and retry
pnpm store prune
rm -rf node_modules
rm pnpm-lock.yaml
pnpm install

# Force reinstall
pnpm install --force

# Debug installation
pnpm install --loglevel=debug
```

### 2. Peer Dependency Conflicts

```ini
# .npmrc
# Auto install peers
auto-install-peers=true

# Or resolve manually
strict-peer-dependencies=false
```

### 3. Workspace Resolution Issues

```bash
# Check workspace configuration
pnpm -r list

# Verify links
pnpm -r exec pwd

# Rebuild workspace links
rm -rf node_modules
pnpm install
```

### 4. Lockfile Conflicts

```bash
# Resolve lockfile conflicts
pnpm install --no-frozen-lockfile

# Or use main branch lockfile
git checkout main -- pnpm-lock.yaml
pnpm install
```

## Common Pitfalls & Mitigation

### 1. Flat node_modules Assumption

**Problem:** Code assumes flat node_modules structure

**Mitigation:**
```ini
# .npmrc
# Use shamefully-hoist only if absolutely necessary
shamefully-hoist=false

# Or hoist specific packages
public-hoist-pattern[]='problematic-package'
```

### 2. Incorrect Workspace Protocols

**Problem:** Not using workspace: protocol for local packages

**Mitigation:**
```json
// Wrong
{
  "dependencies": {
    "@monorepo/lib": "^1.0.0"
  }
}

// Correct
{
  "dependencies": {
    "@monorepo/lib": "workspace:*"
  }
}
```

### 3. Missing .npmrc in Workspaces

**Problem:** Configuration not inherited by all packages

**Mitigation:**
```bash
# Keep .npmrc at repository root
# Avoid per-package .npmrc files
```

### 4. Lockfile Out of Sync

**Problem:** Dependencies installed without updating lockfile

**Mitigation:**
```bash
# Always use pnpm commands
pnpm add <package>

# Not npm or yarn
npm install <package>  # Don't do this
```

### 5. Store Bloat

**Problem:** Store grows indefinitely

**Mitigation:**
```bash
# Add to periodic maintenance
pnpm store prune

# Scheduled job
0 0 * * 0 cd /project && pnpm store prune
```

### 6. Windows Symlink Issues

**Problem:** Symlinks not working on Windows

**Mitigation:**
```bash
# Use PNPM 7+ which uses junctions
pnpm@latest

# Or enable Developer Mode on Windows 10+
```

### 7. Build Tool Compatibility

**Problem:** Bundlers not following symlinks

**Mitigation:**
```javascript
// webpack.config.js
module.exports = {
  resolve: {
    symlinks: true
  }
};

// vite.config.js
export default {
  resolve: {
    preserveSymlinks: false
  }
};
```

## Best Practice Summary

### Development Checklist

- [ ] Use pnpm-workspace.yaml for monorepos
- [ ] Configure .npmrc for project settings
- [ ] Use workspace: protocol for local packages
- [ ] Commit pnpm-lock.yaml to version control
- [ ] Run pnpm install --frozen-lockfile in CI
- [ ] Use --filter for selective operations
- [ ] Leverage parallel execution where possible
- [ ] Configure public-hoist-pattern for tools only
- [ ] Avoid shamefully-hoist unless necessary
- [ ] Use exact versions for critical dependencies
- [ ] Regular pnpm audit for security
- [ ] Prune store periodically
- [ ] Document workspace structure
- [ ] Use consistent Node.js versions
- [ ] Configure engine-strict in package.json
- [ ] Set up pre-commit hooks
- [ ] Use --loglevel for debugging
- [ ] Test workspace dependencies locally
- [ ] Keep PNPM version consistent across team
- [ ] Use pnpm dlx for one-off commands

### CI/CD Checklist

- [ ] Cache PNPM store in CI pipeline
- [ ] Use --frozen-lockfile flag
- [ ] Set up pnpm/action-setup in GitHub Actions
- [ ] Configure PNPM version in CI
- [ ] Run pnpm audit in pipeline
- [ ] Test on same OS as production
- [ ] Verify lockfile integrity
- [ ] Use production dependencies only when building
- [ ] Set appropriate timeouts
- [ ] Configure retries for network issues
- [ ] Monitor build cache hit rates
- [ ] Parallelize independent workspace builds
- [ ] Fail fast on test failures
- [ ] Generate and store test reports
- [ ] Tag builds with workspace versions

### Security Checklist

- [ ] Enable strict-peer-dependencies
- [ ] Use verify-store-integrity
- [ ] Regular dependency audits
- [ ] Review lockfile changes in PRs
- [ ] Use scoped packages for private code
- [ ] Configure private registry correctly
- [ ] Protect NPM_TOKEN in CI
- [ ] Enable two-factor authentication
- [ ] Review postinstall scripts
- [ ] Use exact versions for security-critical deps
- [ ] Set up automated security scanning
- [ ] Configure content trust
- [ ] Use HTTPS registries only
- [ ] Implement package allowlists
- [ ] Monitor for supply chain attacks

## Conclusion

PNPM represents a significant evolution in JavaScript package management, addressing fundamental inefficiencies in npm and Yarn through its innovative content-addressable storage system. The combination of disk space savings, faster installations, and strict dependency management makes it an excellent choice for modern JavaScript projects, particularly monorepos.

The key to success with PNPM lies in embracing its non-flat node_modules structure and leveraging its powerful workspace features. While there may be an initial learning curve and occasional compatibility challenges, the benefits in terms of performance, reliability, and disk usage far outweigh the costs for most projects.

When migrating to PNPM, start by understanding your project's dependency structure, identify packages that might rely on hoisting, and configure .npmrc appropriately. Test thoroughly, especially if you have complex build tooling. For new projects, PNPM should be the default choice given its superior performance and security characteristics.

The future of JavaScript package management is moving toward stricter, more efficient systems, and PNPM is leading this charge. By adopting PNPM and following the best practices outlined in this guide, teams can build more reliable, faster, and more maintainable JavaScript applications while significantly reducing infrastructure costs related to disk usage and build times.
