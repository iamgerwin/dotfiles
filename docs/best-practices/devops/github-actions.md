# GitHub Actions Best Practices

## Overview

GitHub Actions is a continuous integration and continuous delivery (CI/CD) platform that allows you to automate your build, test, and deployment pipeline. You can create workflows that build and test every pull request to your repository, or deploy merged pull requests to production.

## When to Use GitHub Actions

GitHub Actions is ideal for:
- **Automated Testing**: Run tests on every push and pull request
- **Continuous Deployment**: Deploy to production automatically after merge
- **Code Quality Checks**: Lint, format, and analyze code automatically
- **Release Management**: Automate version tagging and release notes
- **Scheduled Tasks**: Run maintenance tasks on a schedule
- **Cross-platform Testing**: Test on multiple OS and runtime versions simultaneously

## Core Concepts

### Workflows
YAML files that define automated processes, stored in `.github/workflows/`

### Events
Triggers that start workflows (push, pull_request, schedule, workflow_dispatch)

### Jobs
Sets of steps that execute on the same runner

### Steps
Individual tasks that run commands or actions

### Actions
Reusable units of code that can be shared across workflows

### Runners
Servers that execute your workflows (GitHub-hosted or self-hosted)

## Project Structure

```
.github/
├── workflows/
│   ├── ci.yml              # Continuous Integration
│   ├── cd.yml              # Continuous Deployment
│   ├── release.yml         # Release automation
│   ├── security.yml        # Security scanning
│   └── scheduled.yml       # Scheduled tasks
├── actions/
│   └── custom-action/      # Custom reusable actions
├── dependabot.yml          # Dependency updates
└── CODEOWNERS             # Code ownership rules
```

## Basic Workflow Structure

```yaml
name: CI Pipeline

# Event triggers
on:
  push:
    branches: [ main, develop ]
    paths-ignore:
      - '**.md'
      - 'docs/**'
  pull_request:
    branches: [ main ]
    types: [opened, synchronize, reopened]
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:      # Manual trigger

# Environment variables
env:
  NODE_VERSION: '20.x'
  CACHE_KEY: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}

# Workflow permissions
permissions:
  contents: read
  issues: write
  pull-requests: write

# Jobs definition
jobs:
  test:
    name: Test Suite
    runs-on: ubuntu-latest
    timeout-minutes: 10

    strategy:
      matrix:
        node-version: [18.x, 20.x]
        os: [ubuntu-latest, windows-latest]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history for better analysis

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ matrix.node-version }}
          cache: 'npm'

      - name: Install dependencies
        run: npm ci

      - name: Run tests
        run: npm test -- --coverage

      - name: Upload coverage
        if: matrix.os == 'ubuntu-latest' && matrix.node-version == '20.x'
        uses: codecov/codecov-action@v3
        with:
          token: ${{ secrets.CODECOV_TOKEN }}
          fail_ci_if_error: true
```

## Security Best Practices

### 1. Secrets Management

```yaml
# Good: Using secrets
env:
  API_KEY: ${{ secrets.API_KEY }}
  DATABASE_URL: ${{ secrets.DATABASE_URL }}

# Bad: Hardcoded values
env:
  API_KEY: "sk-1234567890abcdef"  # Never do this!
```

### 2. Minimal Permissions

```yaml
# Good: Least privilege
permissions:
  contents: read
  pull-requests: write

# Bad: Excessive permissions
permissions: write-all
```

### 3. Pin Action Versions

```yaml
# Best: Use commit SHA
- uses: actions/checkout@8ade135a41bc03ea155e62e844d188df1ea18608  # v4.1.0

# Good: Use specific version
- uses: actions/checkout@v4.1.0

# Bad: Use latest
- uses: actions/checkout@main
```

### 4. Protect Against Script Injection

```yaml
# Bad: Direct interpolation (vulnerable to injection)
- run: |
    echo "Title: ${{ github.event.issue.title }}"

# Good: Use environment variable
- env:
    TITLE: ${{ github.event.issue.title }}
  run: |
    echo "Title: ${TITLE}"
```

### 5. Environment Protection Rules

```yaml
jobs:
  deploy:
    environment:
      name: production
      url: https://app.example.com
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to production
        # Requires approval for production environment
        run: ./deploy.sh
```

## Advanced Patterns

### Matrix Strategy

```yaml
strategy:
  matrix:
    include:
      - os: ubuntu-latest
        node: 18
        npm: 8
      - os: windows-latest
        node: 20
        npm: 10
    exclude:
      - os: windows-latest
        node: 18
  fail-fast: false  # Don't cancel all jobs if one fails
  max-parallel: 2    # Limit concurrent jobs
```

### Caching Dependencies

```yaml
# Node.js with npm
- name: Cache node modules
  uses: actions/cache@v3
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      ${{ runner.os }}-node-

# Python with pip
- name: Cache pip packages
  uses: actions/cache@v3
  with:
    path: ~/.cache/pip
    key: ${{ runner.os }}-pip-${{ hashFiles('**/requirements.txt') }}

# Docker layers
- name: Cache Docker layers
  uses: actions/cache@v3
  with:
    path: /tmp/.buildx-cache
    key: ${{ runner.os }}-buildx-${{ github.sha }}
    restore-keys: |
      ${{ runner.os }}-buildx-
```

### Conditional Execution

```yaml
steps:
  - name: Deploy to staging
    if: github.ref == 'refs/heads/staging'
    run: ./deploy-staging.sh

  - name: Deploy to production
    if: github.ref == 'refs/heads/main' && github.event_name == 'push'
    run: ./deploy-production.sh

  - name: Run expensive tests
    if: |
      github.event_name == 'schedule' ||
      contains(github.event.head_commit.message, '[full-test]')
    run: npm run test:e2e
```

### Reusable Workflows

```yaml
# .github/workflows/reusable-tests.yml
name: Reusable Test Workflow

on:
  workflow_call:
    inputs:
      node-version:
        required: true
        type: string
      environment:
        required: false
        type: string
        default: 'test'
    secrets:
      npm-token:
        required: true

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: ${{ inputs.node-version }}
      - run: npm ci
      - run: npm test

# .github/workflows/ci.yml
name: CI
on: [push]

jobs:
  call-reusable:
    uses: ./.github/workflows/reusable-tests.yml
    with:
      node-version: '20.x'
      environment: 'staging'
    secrets:
      npm-token: ${{ secrets.NPM_TOKEN }}
```

### Composite Actions

```yaml
# .github/actions/setup-project/action.yml
name: 'Setup Project'
description: 'Setup Node.js and install dependencies'

inputs:
  node-version:
    description: 'Node.js version'
    required: true
    default: '20.x'

runs:
  using: "composite"
  steps:
    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'

    - name: Install dependencies
      run: npm ci
      shell: bash

    - name: Build project
      run: npm run build
      shell: bash

# Usage in workflow
- uses: ./.github/actions/setup-project
  with:
    node-version: '20.x'
```

## Deployment Strategies

### Blue-Green Deployment

```yaml
name: Blue-Green Deployment

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Blue environment
        id: deploy-blue
        run: |
          ./deploy.sh blue
          echo "url=https://blue.example.com" >> $GITHUB_OUTPUT

      - name: Run smoke tests
        run: |
          ./test-deployment.sh ${{ steps.deploy-blue.outputs.url }}

      - name: Switch traffic to Blue
        if: success()
        run: |
          ./switch-traffic.sh blue

      - name: Cleanup Green environment
        if: success()
        run: |
          sleep 300  # Wait 5 minutes
          ./cleanup.sh green
```

### Canary Deployment

```yaml
name: Canary Deployment

on:
  push:
    branches: [main]

jobs:
  canary:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy canary (10% traffic)
        run: |
          ./deploy-canary.sh 10

      - name: Monitor metrics
        run: |
          sleep 600  # 10 minutes
          ./check-metrics.sh

      - name: Gradual rollout
        run: |
          for percent in 25 50 75 100; do
            ./deploy-canary.sh $percent
            sleep 300
            ./check-metrics.sh || exit 1
          done
```

## Performance Optimization

### 1. Parallel Jobs

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run lint

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm run build

  deploy:
    needs: [lint, test, build]  # Wait for all to complete
    runs-on: ubuntu-latest
    steps:
      - run: ./deploy.sh
```

### 2. Minimize Checkout

```yaml
# Shallow clone for faster checkout
- uses: actions/checkout@v4
  with:
    fetch-depth: 1  # Only latest commit

# Sparse checkout for monorepos
- uses: actions/checkout@v4
  with:
    sparse-checkout: |
      packages/app
      packages/shared
```

### 3. Smart Caching

```yaml
- name: Get cache key components
  id: cache-keys
  run: |
    echo "week=$(date +%U)" >> $GITHUB_OUTPUT
    echo "month=$(date +%m)" >> $GITHUB_OUTPUT

- uses: actions/cache@v3
  with:
    path: ~/.npm
    key: npm-${{ steps.cache-keys.outputs.week }}-${{ hashFiles('**/package-lock.json') }}
    restore-keys: |
      npm-${{ steps.cache-keys.outputs.week }}-
      npm-${{ steps.cache-keys.outputs.month }}-
      npm-
```

## Cost Optimization

### 1. Use Path Filters

```yaml
on:
  push:
    paths:
      - 'src/**'
      - 'package*.json'
      - '.github/workflows/**'
    paths-ignore:
      - '**.md'
      - 'docs/**'
```

### 2. Cancel Previous Runs

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

### 3. Conditional Heavy Tasks

```yaml
- name: Run E2E tests
  if: |
    github.event_name == 'push' &&
    github.ref == 'refs/heads/main'
  run: npm run test:e2e
```

### 4. Use Workflow Dispatch for Manual Tasks

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        description: 'Environment to deploy'
        required: true
        type: choice
        options:
          - staging
          - production
      debug:
        description: 'Enable debug mode'
        type: boolean
        default: false
```

## Monitoring and Debugging

### 1. Debug Logging

```yaml
# Enable debug logging for specific step
- name: Debug step
  run: ./script.sh
  env:
    ACTIONS_STEP_DEBUG: true

# Enable runner diagnostic logging
env:
  ACTIONS_RUNNER_DEBUG: true
```

### 2. Workflow Status Badge

```markdown
![CI Status](https://github.com/username/repo/workflows/CI/badge.svg)
![Coverage](https://codecov.io/gh/username/repo/branch/main/graph/badge.svg)
```

### 3. Job Summaries

```yaml
- name: Generate test report
  if: always()
  run: |
    echo "## Test Results :test_tube:" >> $GITHUB_STEP_SUMMARY
    echo "" >> $GITHUB_STEP_SUMMARY
    echo "| Test Suite | Status | Time |" >> $GITHUB_STEP_SUMMARY
    echo "|------------|--------|------|" >> $GITHUB_STEP_SUMMARY
    echo "| Unit | ✅ Passed | 45s |" >> $GITHUB_STEP_SUMMARY
    echo "| Integration | ✅ Passed | 2m 15s |" >> $GITHUB_STEP_SUMMARY
    echo "| E2E | ❌ Failed | 5m 32s |" >> $GITHUB_STEP_SUMMARY
```

### 4. Annotations

```yaml
- name: Annotate PR
  run: |
    echo "::warning file=app.js,line=10::Consider using const instead of let"
    echo "::error file=test.js,line=5::Missing semicolon"
    echo "::notice file=README.md::Documentation needs update"
```

## Common Pitfalls and Solutions

### 1. Secret Masking Issues

**Problem**: Secrets appearing in logs
```yaml
# Bad: Secret might leak in error messages
- run: curl -H "Authorization: Bearer ${{ secrets.TOKEN }}" $API_URL
```

**Solution**: Use masked output
```yaml
- name: API Call
  run: |
    echo "::add-mask::${{ secrets.TOKEN }}"
    curl -H "Authorization: Bearer ${{ secrets.TOKEN }}" $API_URL
```

### 2. Path Context Issues

**Problem**: Workflow can't find files
```yaml
# Issue: Working directory mismatch
- run: npm install
- run: cd frontend && npm build  # Dependencies not found
```

**Solution**: Use working-directory
```yaml
- name: Install and build
  working-directory: ./frontend
  run: |
    npm install
    npm run build
```

### 3. Timeout Issues

**Problem**: Jobs timing out
```yaml
# Default timeout is 6 hours
jobs:
  long-running:
    runs-on: ubuntu-latest
    timeout-minutes: 30  # Set appropriate timeout
```

### 4. Artifact Size Limits

**Problem**: Artifacts too large (>500MB warning, >2GB error)
```yaml
# Solution: Compress and filter artifacts
- name: Compress artifacts
  run: |
    tar -czf build.tar.gz \
      --exclude='node_modules' \
      --exclude='*.map' \
      build/

- uses: actions/upload-artifact@v3
  with:
    name: build-artifacts
    path: build.tar.gz
    retention-days: 3  # Reduce retention
```

## Testing Workflows Locally

Use `act` to test workflows locally:

```bash
# Install act
brew install act  # macOS
# or
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run workflow
act push  # Simulate push event
act -j test  # Run specific job
act -s GITHUB_TOKEN=$TOKEN  # Pass secrets

# With specific event
act pull_request -e event.json
```

## Useful Actions from Marketplace

### Code Quality
- `actions/setup-node` - Node.js environment
- `actions/setup-python` - Python environment
- `github/super-linter` - Multi-language linter
- `sonarsource/sonarcloud-github-action` - Code analysis

### Testing
- `cypress-io/github-action` - E2E testing
- `codecov/codecov-action` - Coverage reporting
- `dorny/test-reporter` - Test results

### Deployment
- `peaceiris/actions-gh-pages` - GitHub Pages deployment
- `docker/build-push-action` - Docker builds
- `aws-actions/configure-aws-credentials` - AWS deployment

### Utilities
- `actions/cache` - Dependency caching
- `actions/upload-artifact` - Artifact storage
- `peter-evans/create-pull-request` - Automated PRs
- `actions/github-script` - GitHub API automation

## Security Vulnerabilities

### 1. Command Injection
**Vulnerable**:
```yaml
- run: echo "Comment: ${{ github.event.comment.body }}"
```

**Secure**:
```yaml
- env:
    COMMENT: ${{ github.event.comment.body }}
  run: echo "Comment: ${COMMENT}"
```

### 2. Untrusted Input
**Vulnerable**:
```yaml
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.ref }}  # Could be malicious
```

**Secure**:
```yaml
- uses: actions/checkout@v4
  with:
    ref: ${{ github.event.pull_request.head.sha }}  # Use SHA instead
```

### 3. Fork Pull Request Secrets
```yaml
# Secrets not available to fork PRs by default
on:
  pull_request_target:  # Use carefully - has write access
    types: [opened, synchronize]

jobs:
  test:
    if: github.event.pull_request.head.repo.full_name == github.repository
    # Only run for PRs from the same repository
```

## Compliance and Governance

### 1. Required Workflows

```yaml
# .github/workflows/required-checks.yml
name: Required Checks

on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  compliance:
    runs-on: ubuntu-latest
    steps:
      - name: License check
        run: ./scripts/check-licenses.sh

      - name: Security scan
        run: ./scripts/security-scan.sh

      - name: Dependency audit
        run: npm audit --audit-level=moderate
```

### 2. Branch Protection

Configure in repository settings:
- Require status checks to pass
- Require branches to be up to date
- Require conversation resolution
- Include administrators

### 3. Audit Logging

```yaml
- name: Log deployment
  run: |
    echo "Deployment by: ${{ github.actor }}" >> deployment.log
    echo "Commit: ${{ github.sha }}" >> deployment.log
    echo "Time: $(date -u +%Y-%m-%dT%H:%M:%SZ)" >> deployment.log

- name: Send audit log
  run: |
    curl -X POST $AUDIT_WEBHOOK \
      -H "Content-Type: application/json" \
      -d "{
        \"event\": \"deployment\",
        \"actor\": \"${{ github.actor }}\",
        \"environment\": \"production\",
        \"commit\": \"${{ github.sha }}\"
      }"
```

## Migration from Other CI/CD Platforms

### From Jenkins
```yaml
# Jenkins Pipeline equivalent
name: CI Pipeline

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # Equivalent to Jenkins 'sh' step
      - name: Build
        run: |
          ./gradlew build

      # Equivalent to Jenkins 'archiveArtifacts'
      - uses: actions/upload-artifact@v3
        with:
          name: build-artifacts
          path: build/libs/*.jar

      # Equivalent to Jenkins 'junit'
      - name: Publish test results
        uses: dorny/test-reporter@v1
        with:
          name: JUnit Tests
          path: build/test-results/**/*.xml
          reporter: java-junit
```

### From GitLab CI
```yaml
# GitLab CI equivalent
name: Pipeline

on:
  push:
    branches: [main, develop]
  pull_request:

env:  # GitLab CI variables
  DEPLOY_ENV: production

jobs:
  # Equivalent to GitLab stages
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: npm test

  build:
    needs: test  # GitLab dependencies
    runs-on: ubuntu-latest
    # GitLab rules equivalent
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      - run: npm run build

  deploy:
    needs: build
    runs-on: ubuntu-latest
    environment: production  # GitLab environments
    steps:
      - run: ./deploy.sh
```

## Troubleshooting Guide

### Workflow Not Triggering
1. Check workflow file location (`.github/workflows/`)
2. Verify YAML syntax
3. Check branch protection rules
4. Ensure correct event triggers
5. Verify repository permissions

### Secrets Not Available
1. Check secret names (case-sensitive)
2. Verify environment secrets
3. Fork PRs don't have access to secrets
4. Organization secrets inheritance

### Cache Not Working
1. Check cache key uniqueness
2. Verify cache size (<10GB)
3. Cache scope (same branch/default branch)
4. Check restore-keys fallback

### Artifact Issues
1. Check artifact size limits
2. Verify retention settings
3. Download artifacts before expiry
4. Check artifact names for uniqueness

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Workflow Syntax Reference](https://docs.github.com/actions/reference/workflow-syntax-for-github-actions)
- [GitHub Actions Marketplace](https://github.com/marketplace/actions)
- [Security Hardening Guide](https://docs.github.com/actions/security-guides/security-hardening-for-github-actions)
- [Billing and Usage](https://docs.github.com/billing/managing-billing-for-github-actions)