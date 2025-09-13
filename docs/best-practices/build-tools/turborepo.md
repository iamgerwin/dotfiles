# Turborepo Best Practices

## Overview

Turborepo is a high-performance build system for JavaScript and TypeScript monorepos. It provides intelligent caching, parallel execution, and incremental builds to dramatically improve build times and developer productivity in large-scale projects.

## Key Concepts

### Monorepo Structure
A monorepo contains multiple packages/applications in a single repository, enabling code sharing and atomic changes across projects.

### Pipeline
Defines the task dependency graph and execution order for your monorepo's build process.

### Caching
Turborepo caches task outputs and skips re-execution when inputs haven't changed, significantly reducing build times.

### Remote Caching
Share cache artifacts across team members and CI/CD environments for maximum efficiency.

## Best Practices

### 1. Repository Structure

#### Recommended Layout
```
monorepo/
├── apps/
│   ├── web/
│   │   ├── package.json
│   │   └── src/
│   ├── mobile/
│   │   ├── package.json
│   │   └── src/
│   └── api/
│       ├── package.json
│       └── src/
├── packages/
│   ├── ui/
│   │   ├── package.json
│   │   └── src/
│   ├── config/
│   │   ├── package.json
│   │   └── src/
│   └── utils/
│       ├── package.json
│       └── src/
├── turbo.json
├── package.json
└── pnpm-workspace.yaml
```

#### Package Naming Conventions
```json
// apps/web/package.json
{
  "name": "@company/web",
  "version": "1.0.0"
}

// packages/ui/package.json
{
  "name": "@company/ui",
  "version": "1.0.0"
}
```

### 2. Pipeline Configuration

#### Optimal turbo.json Setup
```json
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**", ".next/**"],
      "env": ["NODE_ENV", "API_URL"]
    },
    "test": {
      "dependsOn": ["build"],
      "inputs": ["src/**", "test/**"],
      "outputs": ["coverage/**"],
      "cache": true
    },
    "lint": {
      "inputs": ["**/*.ts", "**/*.tsx", "**/*.js", "**/*.jsx"],
      "cache": true
    },
    "dev": {
      "cache": false,
      "persistent": true
    },
    "typecheck": {
      "dependsOn": ["^build"],
      "outputs": ["tsconfig.tsbuildinfo"]
    }
  },
  "globalEnv": ["CI", "NODE_ENV"],
  "globalDependencies": ["tsconfig.json", ".eslintrc.js"]
}
```

#### Task Dependencies
```json
{
  "pipeline": {
    "deploy": {
      "dependsOn": ["build", "test", "lint"],
      "cache": false
    },
    "publish": {
      "dependsOn": ["^build", "test"],
      "cache": false
    }
  }
}
```

### 3. Caching Strategies

#### Input Hash Configuration
```json
{
  "pipeline": {
    "build": {
      "inputs": [
        "src/**",
        "package.json",
        "tsconfig.json",
        "!**/*.test.ts",
        "!**/*.spec.ts"
      ],
      "outputs": ["dist/**"],
      "env": ["NODE_ENV"]
    }
  }
}
```

#### Environment Variables
```json
{
  "pipeline": {
    "build": {
      "env": ["API_KEY", "DATABASE_URL"],
      "passThroughEnv": ["AWS_*", "VERCEL_*"]
    }
  }
}
```

#### Cache Optimization
```bash
# Local cache configuration
turbo run build --cache-dir=".turbo"

# Remote cache setup
turbo login
turbo link

# Force cache refresh
turbo run build --force

# Analyze cache hits
turbo run build --dry-run
```

### 4. Performance Optimization

#### Parallel Execution
```json
{
  "pipeline": {
    "test": {
      "dependsOn": [],
      "outputs": [],
      "inputs": ["src/**", "test/**"]
    },
    "lint": {
      "dependsOn": [],
      "outputs": []
    }
  }
}
```

#### Incremental Builds
```bash
# Only build affected packages
turbo run build --filter=...[origin/main]

# Build specific package and dependencies
turbo run build --filter=@company/web...

# Build dependents of a package
turbo run build --filter=...@company/ui
```

#### Memory Management
```bash
# Increase Node memory for large projects
NODE_OPTIONS="--max-old-space-size=8192" turbo run build

# Limit concurrency for resource-constrained environments
turbo run build --concurrency=2
```

### 5. Development Workflow

#### Local Development
```json
// package.json scripts
{
  "scripts": {
    "dev": "turbo run dev",
    "build": "turbo run build",
    "test": "turbo run test",
    "lint": "turbo run lint",
    "clean": "turbo run clean && rm -rf node_modules"
  }
}
```

#### Watch Mode Configuration
```json
{
  "pipeline": {
    "dev": {
      "cache": false,
      "persistent": true,
      "dependsOn": ["^build"]
    },
    "build:watch": {
      "cache": false,
      "persistent": true,
      "outputs": ["dist/**"]
    }
  }
}
```

#### Hot Module Replacement
```javascript
// Configure HMR for development
module.exports = {
  watchOptions: {
    ignored: /node_modules/,
    aggregateTimeout: 300,
    poll: 1000
  },
  devServer: {
    hot: true,
    liveReload: true
  }
};
```

### 6. CI/CD Integration

#### GitHub Actions Setup
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 2

      - uses: pnpm/action-setup@v2
        with:
          version: 8

      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'pnpm'

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Setup Turbo Remote Cache
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ secrets.TURBO_TEAM }}
        run: |
          turbo link

      - name: Build and Test
        run: turbo run build test lint --cache-dir=.turbo
        env:
          TURBO_TOKEN: ${{ secrets.TURBO_TOKEN }}
          TURBO_TEAM: ${{ secrets.TURBO_TEAM }}
```

#### Docker Integration
```dockerfile
# Multi-stage build with Turborepo
FROM node:18-alpine AS builder
WORKDIR /app
RUN npm install -g turbo
COPY . .
RUN turbo prune --scope=@company/api --docker

FROM node:18-alpine AS installer
WORKDIR /app
COPY --from=builder /app/out/json/ .
COPY --from=builder /app/out/pnpm-lock.yaml ./pnpm-lock.yaml
RUN corepack enable
RUN pnpm install --frozen-lockfile

FROM node:18-alpine AS sourcer
WORKDIR /app
COPY --from=installer /app/ .
COPY --from=builder /app/out/full/ .
RUN pnpm turbo run build --filter=@company/api

FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=sourcer /app/ .
EXPOSE 3000
CMD ["node", "apps/api/dist/index.js"]
```

### 7. Team Collaboration

#### Remote Caching Setup
```bash
# Configure Vercel Remote Cache
npx turbo login
npx turbo link

# Self-hosted cache server
TURBO_REMOTE_CACHE_URL=https://cache.company.com
TURBO_TOKEN=your-token
TURBO_TEAM=your-team
```

#### Branch Protection
```json
// .turborepo/config.json
{
  "teamId": "team_xxx",
  "apiUrl": "https://api.vercel.com",
  "experimentalUI": true,
  "cacheDir": ".turbo",
  "daemon": true
}
```

### 8. Package Management

#### Workspace Dependencies
```json
// packages/ui/package.json
{
  "name": "@company/ui",
  "dependencies": {
    "@company/utils": "workspace:*",
    "react": "^18.0.0"
  },
  "devDependencies": {
    "@company/config": "workspace:*"
  }
}
```

#### Version Management
```bash
# Update dependencies across workspace
pnpm update -r

# Add dependency to specific workspace
pnpm add lodash --filter @company/web

# Run command in specific package
pnpm --filter @company/api run dev
```

## Common Patterns

### Shared Configuration
```javascript
// packages/config/eslint/index.js
module.exports = {
  extends: ['next', 'turbo', 'prettier'],
  rules: {
    '@next/next/no-html-link-for-pages': 'off',
  },
  parserOptions: {
    babelOptions: {
      presets: [require.resolve('next/babel')],
    },
  },
};

// apps/web/.eslintrc.js
module.exports = {
  root: true,
  extends: ['@company/config/eslint'],
};
```

### Environment Management
```bash
# .env.local
DATABASE_URL=postgresql://localhost/mydb
REDIS_URL=redis://localhost:6379

# turbo.json
{
  "globalEnv": ["DATABASE_URL", "REDIS_URL"],
  "pipeline": {
    "build": {
      "env": ["NODE_ENV", "NEXT_PUBLIC_*"]
    }
  }
}
```

### Testing Strategy
```json
{
  "pipeline": {
    "test": {
      "outputs": ["coverage/**"],
      "dependsOn": ["^build"]
    },
    "test:unit": {
      "outputs": [],
      "inputs": ["src/**", "test/unit/**"]
    },
    "test:integration": {
      "outputs": [],
      "inputs": ["src/**", "test/integration/**"],
      "dependsOn": ["build"]
    },
    "test:e2e": {
      "outputs": [],
      "dependsOn": ["build"],
      "cache": false
    }
  }
}
```

## Troubleshooting

### Cache Issues
```bash
# Clear all caches
turbo run build --force

# Clear specific package cache
turbo run build --filter=@company/web --force

# Debug cache misses
turbo run build --dry-run=json > dry-run.json

# Verify cache configuration
turbo run build --summarize
```

### Dependency Problems
```bash
# Analyze dependencies
turbo run build --graph

# Check for circular dependencies
turbo run build --dry-run

# Rebuild dependency graph
rm -rf node_modules pnpm-lock.yaml
pnpm install
```

### Performance Issues
```bash
# Profile build performance
turbo run build --profile

# Analyze build times
turbo run build --summarize > summary.json

# Limit concurrency
turbo run build --concurrency=1
```

## Migration Guide

### From Lerna
```bash
# Install Turborepo
pnpm add turbo -D -w

# Create turbo.json
cat > turbo.json << EOF
{
  "$schema": "https://turbo.build/schema.json",
  "pipeline": {
    "build": {
      "dependsOn": ["^build"],
      "outputs": ["dist/**"]
    }
  }
}
EOF

# Update package.json scripts
npm pkg set scripts.build="turbo run build"
```

### From Nx
```javascript
// Map Nx targets to Turbo pipeline
const nxConfig = require('./nx.json');
const turboConfig = {
  pipeline: {}
};

Object.entries(nxConfig.targetDefaults).forEach(([target, config]) => {
  turboConfig.pipeline[target] = {
    dependsOn: config.dependsOn || [],
    outputs: config.outputs || [],
    cache: config.cache !== false
  };
});
```

## Advanced Configuration

### Custom Task Runners
```javascript
// turbo.config.js
module.exports = {
  extends: ['//'],
  pipeline: {
    deploy: {
      dependsOn: ['build', 'test'],
      outputs: [],
      cache: false,
      env: ['DEPLOY_KEY', 'DEPLOY_URL']
    }
  }
};
```

### Conditional Execution
```bash
# Run only if files changed
turbo run test --filter='...[origin/main]' --dry-run

# Skip unchanged packages
turbo run build --continue
```

### Generator Templates
```javascript
// turbo/generators/config.ts
import type { PlopTypes } from '@turbo/gen';

export default function generator(plop: PlopTypes.NodePlopAPI): void {
  plop.setGenerator('package', {
    description: 'Create a new package',
    prompts: [
      {
        type: 'input',
        name: 'name',
        message: 'Package name?',
      },
    ],
    actions: [
      {
        type: 'addMany',
        destination: '{{turbo.paths.root}}/packages/{{name}}',
        templateFiles: 'templates/package/**/*',
        base: 'templates/package',
      },
    ],
  });
}
```

## Resources

- [Official Documentation](https://turbo.build/repo/docs)
- [Turborepo Examples](https://github.com/vercel/turbo/tree/main/examples)
- [Migration Guides](https://turbo.build/repo/docs/guides/migrate-from-lerna)
- [API Reference](https://turbo.build/repo/docs/reference/configuration)
- [Remote Caching](https://turbo.build/repo/docs/core-concepts/remote-caching)