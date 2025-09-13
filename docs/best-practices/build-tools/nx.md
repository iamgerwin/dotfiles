# Nx Best Practices

## Overview

Nx is a powerful, extensible build system with first-class monorepo support and excellent developer tools. It provides computation caching, code generation, dependency graph visualization, and enforced module boundaries, making it ideal for enterprise-scale applications.

## Key Concepts

### Workspace
The entire monorepo containing multiple projects (apps and libraries) managed by Nx.

### Projects
Individual applications or libraries within the workspace, each with its own configuration and dependencies.

### Executors
Pre-packaged scripts that perform tasks like building, testing, and serving applications.

### Generators
Code scaffolding tools that create or modify code following best practices and conventions.

### Affected Commands
Commands that analyze code changes and run tasks only on affected projects, optimizing CI/CD pipelines.

### Module Boundaries
Rules that enforce architectural constraints and prevent unwanted dependencies between projects.

## Best Practices

### 1. Workspace Organization

#### Project Structure
```
workspace/
├── apps/
│   ├── web-app/
│   │   ├── src/
│   │   ├── project.json
│   │   └── tsconfig.json
│   ├── mobile-app/
│   │   ├── src/
│   │   └── project.json
│   └── api/
│       ├── src/
│       └── project.json
├── libs/
│   ├── shared/
│   │   ├── ui/
│   │   ├── utils/
│   │   └── data-access/
│   ├── feature/
│   │   ├── auth/
│   │   ├── dashboard/
│   │   └── settings/
│   └── domain/
│       ├── user/
│       └── product/
├── tools/
│   ├── generators/
│   └── executors/
├── nx.json
├── workspace.json
└── tsconfig.base.json
```

#### Library Types
```typescript
// Feature libraries - smart components with business logic
// libs/feature/auth/src/lib/login/login.component.ts

// UI libraries - presentational components
// libs/shared/ui/src/lib/button/button.component.ts

// Data-access libraries - state management and API calls
// libs/shared/data-access/src/lib/api/api.service.ts

// Utility libraries - pure functions and helpers
// libs/shared/utils/src/lib/format/format.ts

// Domain libraries - business entities and logic
// libs/domain/user/src/lib/user.model.ts
```

### 2. Configuration Management

#### nx.json Configuration
```json
{
  "$schema": "./node_modules/nx/schemas/nx-schema.json",
  "affected": {
    "defaultBase": "main"
  },
  "tasksRunnerOptions": {
    "default": {
      "runner": "nx/tasks-runners/default",
      "options": {
        "cacheableOperations": ["build", "test", "lint", "e2e"],
        "parallel": 3,
        "cacheDirectory": ".nx/cache"
      }
    }
  },
  "targetDefaults": {
    "build": {
      "dependsOn": ["^build"],
      "inputs": ["production", "^production"],
      "cache": true
    },
    "test": {
      "inputs": ["default", "^production", "{workspaceRoot}/jest.preset.js"],
      "cache": true
    },
    "lint": {
      "inputs": ["default", "{workspaceRoot}/.eslintrc.json"],
      "cache": true
    }
  },
  "namedInputs": {
    "production": [
      "default",
      "!{projectRoot}/**/*.spec.ts",
      "!{projectRoot}/**/*.test.ts",
      "!{projectRoot}/tsconfig.spec.json",
      "!{projectRoot}/jest.config.ts"
    ],
    "default": ["{projectRoot}/**/*", "sharedGlobals"],
    "sharedGlobals": []
  },
  "generators": {
    "@nx/react": {
      "application": {
        "style": "scss",
        "linter": "eslint",
        "bundler": "webpack"
      },
      "component": {
        "style": "scss"
      },
      "library": {
        "style": "scss",
        "linter": "eslint"
      }
    }
  }
}
```

#### Project Configuration
```json
// apps/web-app/project.json
{
  "$schema": "../../node_modules/nx/schemas/project-schema.json",
  "sourceRoot": "apps/web-app/src",
  "projectType": "application",
  "targets": {
    "build": {
      "executor": "@nx/webpack:webpack",
      "outputs": ["{options.outputPath}"],
      "options": {
        "outputPath": "dist/apps/web-app",
        "index": "apps/web-app/src/index.html",
        "main": "apps/web-app/src/main.tsx",
        "polyfills": "apps/web-app/src/polyfills.ts",
        "tsConfig": "apps/web-app/tsconfig.app.json",
        "assets": ["apps/web-app/src/favicon.ico", "apps/web-app/src/assets"],
        "styles": ["apps/web-app/src/styles.scss"],
        "scripts": []
      },
      "configurations": {
        "production": {
          "fileReplacements": [
            {
              "replace": "apps/web-app/src/environments/environment.ts",
              "with": "apps/web-app/src/environments/environment.prod.ts"
            }
          ],
          "optimization": true,
          "outputHashing": "all",
          "sourceMap": false,
          "extractCss": true,
          "namedChunks": false,
          "vendorChunk": false,
          "buildOptimizer": true
        }
      }
    },
    "serve": {
      "executor": "@nx/webpack:dev-server",
      "options": {
        "buildTarget": "web-app:build",
        "port": 4200
      },
      "configurations": {
        "production": {
          "buildTarget": "web-app:build:production"
        }
      }
    }
  },
  "tags": ["scope:web", "type:app"]
}
```

### 3. Module Boundaries

#### Enforcing Constraints
```json
// .eslintrc.json
{
  "overrides": [
    {
      "files": ["*.ts", "*.tsx"],
      "rules": {
        "@nx/enforce-module-boundaries": [
          "error",
          {
            "enforceBuildableLibDependency": true,
            "allow": [],
            "depConstraints": [
              {
                "sourceTag": "scope:web",
                "onlyDependOnLibsWithTags": ["scope:web", "scope:shared"]
              },
              {
                "sourceTag": "scope:api",
                "onlyDependOnLibsWithTags": ["scope:api", "scope:shared"]
              },
              {
                "sourceTag": "type:feature",
                "onlyDependOnLibsWithTags": [
                  "type:feature",
                  "type:ui",
                  "type:data-access",
                  "type:util"
                ]
              },
              {
                "sourceTag": "type:ui",
                "onlyDependOnLibsWithTags": ["type:ui", "type:util"]
              },
              {
                "sourceTag": "type:data-access",
                "onlyDependOnLibsWithTags": ["type:data-access", "type:util"]
              }
            ]
          }
        ]
      }
    }
  ]
}
```

#### Library Tags
```json
// libs/feature/auth/project.json
{
  "tags": ["scope:shared", "type:feature"]
}

// libs/shared/ui/project.json
{
  "tags": ["scope:shared", "type:ui"]
}

// libs/domain/user/project.json
{
  "tags": ["scope:shared", "type:domain"]
}
```

### 4. Code Generation

#### Custom Generators
```typescript
// tools/generators/feature/index.ts
import { Tree, formatFiles, installPackagesTask } from '@nx/devkit';
import { libraryGenerator } from '@nx/react';

export default async function (tree: Tree, schema: any) {
  await libraryGenerator(tree, {
    name: schema.name,
    directory: `libs/feature/${schema.name}`,
    style: 'scss',
    skipTsConfig: false,
    skipFormat: false,
    tags: `scope:shared,type:feature`,
    unitTestRunner: 'jest',
    linter: 'eslint',
  });

  // Add custom files
  const libraryRoot = `libs/feature/${schema.name}`;

  // Create feature component
  tree.write(
    `${libraryRoot}/src/lib/${schema.name}.tsx`,
    `import React from 'react';

export interface ${capitalize(schema.name)}Props {}

export function ${capitalize(schema.name)}(props: ${capitalize(schema.name)}Props) {
  return (
    <div>
      <h1>Welcome to ${schema.name}!</h1>
    </div>
  );
}

export default ${capitalize(schema.name)};`
  );

  await formatFiles(tree);
  return () => {
    installPackagesTask(tree);
  };
}

function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1);
}
```

#### Generator Configuration
```json
// tools/generators/feature/schema.json
{
  "$schema": "http://json-schema.org/schema",
  "cli": "nx",
  "id": "feature",
  "type": "object",
  "properties": {
    "name": {
      "type": "string",
      "description": "Feature name",
      "$default": {
        "$source": "argv",
        "index": 0
      }
    },
    "routing": {
      "type": "boolean",
      "description": "Add routing setup",
      "default": true
    }
  },
  "required": ["name"]
}
```

### 5. Testing Strategies

#### Unit Testing Configuration
```typescript
// jest.preset.js
const nxPreset = require('@nx/jest/preset').default;

module.exports = {
  ...nxPreset,
  coverageReporters: ['html', 'text', 'lcov'],
  collectCoverageFrom: [
    'src/**/*.{js,jsx,ts,tsx}',
    '!src/**/*.stories.{js,jsx,ts,tsx}',
    '!src/**/*.spec.{js,jsx,ts,tsx}',
    '!src/index.ts',
  ],
};

// libs/feature/auth/jest.config.ts
export default {
  displayName: 'feature-auth',
  preset: '../../../jest.preset.js',
  transform: {
    '^.+\\.[tj]sx?$': ['@swc/jest', { jsc: { transform: { react: { runtime: 'automatic' } } } }],
  },
  moduleFileExtensions: ['ts', 'tsx', 'js', 'jsx'],
  coverageDirectory: '../../../coverage/libs/feature/auth',
  setupFilesAfterEnv: ['<rootDir>/src/test-setup.ts'],
};
```

#### E2E Testing
```typescript
// apps/web-app-e2e/src/e2e/app.cy.ts
describe('web-app', () => {
  beforeEach(() => cy.visit('/'));

  it('should display welcome message', () => {
    cy.contains('Welcome');
  });

  it('should navigate to dashboard', () => {
    cy.get('[data-testid="nav-dashboard"]').click();
    cy.url().should('include', '/dashboard');
  });
});

// E2E project configuration
{
  "targets": {
    "e2e": {
      "executor": "@nx/cypress:cypress",
      "options": {
        "cypressConfig": "apps/web-app-e2e/cypress.config.ts",
        "devServerTarget": "web-app:serve",
        "testingType": "e2e"
      }
    }
  }
}
```

### 6. CI/CD Optimization

#### Affected Commands
```bash
# Run tests only for affected projects
nx affected:test --base=main --head=HEAD

# Build affected applications
nx affected:build --base=main --parallel=3

# Lint affected projects
nx affected:lint --base=main

# Run e2e tests for affected apps
nx affected:e2e --base=main
```

#### GitHub Actions Workflow
```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  main:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0

      - uses: nrwl/nx-set-shas@v3

      - uses: actions/setup-node@v3
        with:
          node-version: 18
          cache: 'npm'

      - run: npm ci

      - run: npx nx-cloud start-ci-run --stop-agents-after="build"

      - run: npx nx affected --target=lint --parallel=3
      - run: npx nx affected --target=test --parallel=3 --ci --coverage
      - run: npx nx affected --target=build --parallel=3

      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          directory: ./coverage
```

#### Distributed Task Execution
```yaml
# .nx/workflows/ci.yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:

jobs:
  agents:
    name: Nx Cloud - Agents
    uses: nrwl/ci/.github/workflows/nx-cloud-agents.yml@v0.13.0
    with:
      number-of-agents: 3

  main:
    name: Nx Cloud - Main Job
    uses: nrwl/ci/.github/workflows/nx-cloud-main.yml@v0.13.0
    with:
      main-branch-name: main
      number-of-agents: 3
      init-commands: |
        npx nx-cloud start-ci-run --stop-agents-after="build" --agent-count=3
      parallel-commands: |
        npx nx-cloud record -- npx nx format:check
      parallel-commands-on-agents: |
        npx nx affected --target=lint --parallel=3
        npx nx affected --target=test --parallel=3 --ci --coverage
        npx nx affected --target=build --parallel=3
```

### 7. Performance Optimization

#### Computation Caching
```json
// nx.json
{
  "tasksRunnerOptions": {
    "default": {
      "runner": "@nrwl/nx-cloud",
      "options": {
        "cacheableOperations": ["build", "test", "lint", "e2e"],
        "accessToken": "your-nx-cloud-token",
        "parallel": 3,
        "cacheDirectory": ".nx/cache",
        "useDaemonProcess": true
      }
    }
  }
}
```

#### Build Optimization
```javascript
// webpack.config.js
const { composePlugins, withNx } = require('@nx/webpack');
const { withReact } = require('@nx/react');

module.exports = composePlugins(
  withNx(),
  withReact(),
  (config, { options, context }) => {
    // Optimization for production builds
    if (options.mode === 'production') {
      config.optimization = {
        ...config.optimization,
        splitChunks: {
          chunks: 'all',
          cacheGroups: {
            vendor: {
              test: /[\\/]node_modules[\\/]/,
              name: 'vendors',
              priority: 10
            },
            common: {
              minChunks: 2,
              priority: 5,
              reuseExistingChunk: true
            }
          }
        },
        runtimeChunk: 'single',
        moduleIds: 'deterministic'
      };
    }

    return config;
  }
);
```

### 8. Development Workflow

#### Local Development
```bash
# Start development server
nx serve web-app

# Run tests in watch mode
nx test feature-auth --watch

# Generate new library
nx g @nx/react:library ui-components --directory=libs/shared

# Generate component
nx g @nx/react:component button --project=shared-ui-components

# Run multiple targets
nx run-many --target=test --projects=feature-auth,feature-dashboard

# Interactive mode
nx serve --project=web-app --configuration=development
```

#### Debugging
```json
// .vscode/launch.json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Nx Build",
      "program": "${workspaceFolder}/node_modules/.bin/nx",
      "args": ["build", "web-app", "--verbose"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    },
    {
      "type": "node",
      "request": "launch",
      "name": "Debug Jest Tests",
      "program": "${workspaceFolder}/node_modules/.bin/nx",
      "args": ["test", "feature-auth", "--runInBand"],
      "console": "integratedTerminal",
      "internalConsoleOptions": "neverOpen"
    }
  ]
}
```

## Advanced Features

### Custom Executors
```typescript
// tools/executors/deploy/impl.ts
import { ExecutorContext } from '@nx/devkit';
import { execSync } from 'child_process';

export interface DeployExecutorOptions {
  buildTarget: string;
  environment: 'staging' | 'production';
}

export default async function deployExecutor(
  options: DeployExecutorOptions,
  context: ExecutorContext
): Promise<{ success: boolean }> {
  console.log('Starting deployment...');

  // Build the project
  execSync(`nx run ${options.buildTarget}`, { stdio: 'inherit' });

  // Deploy based on environment
  const deployCommand = options.environment === 'production'
    ? 'npm run deploy:prod'
    : 'npm run deploy:staging';

  try {
    execSync(deployCommand, { stdio: 'inherit' });
    return { success: true };
  } catch (error) {
    console.error('Deployment failed:', error);
    return { success: false };
  }
}
```

### Dependency Graph Analysis
```bash
# Visualize project dependencies
nx graph

# Export dependency graph
nx graph --file=output.json

# Show affected projects
nx print-affected --base=main

# Analyze circular dependencies
nx lint --fix
```

### Incremental Builds
```typescript
// libs/buildable/project.json
{
  "targets": {
    "build": {
      "executor": "@nx/js:tsc",
      "outputs": ["{options.outputPath}"],
      "options": {
        "outputPath": "dist/libs/buildable",
        "main": "libs/buildable/src/index.ts",
        "tsConfig": "libs/buildable/tsconfig.lib.json",
        "buildableProjectDepsInPackageJsonType": "dependencies",
        "updateBuildableProjectDepsInPackageJson": true
      }
    }
  }
}
```

## Migration Strategies

### From Create React App
```bash
# Create Nx workspace
npx create-nx-workspace@latest myworkspace --preset=react

# Move existing code
mv src/* apps/webapp/src/
mv public/* apps/webapp/public/

# Update imports
nx g @nx/workspace:move --project=webapp --destination=apps/webapp

# Add Nx cloud
nx g @nrwl/nx-cloud:init
```

### From Angular CLI
```bash
# Add Nx to existing Angular project
npx nx@latest init

# Convert to Nx workspace
nx g @nx/angular:ng-add

# Generate libraries from existing code
nx g @nx/angular:library feature-core --directory=libs
```

## Troubleshooting

### Cache Issues
```bash
# Clear local cache
nx reset

# Clear cloud cache
nx-cloud clear-cache

# Disable cache temporarily
nx build web-app --skip-nx-cache

# Debug cache hits/misses
NX_VERBOSE_LOGGING=true nx build web-app
```

### Performance Issues
```bash
# Profile build performance
nx build web-app --profile

# Analyze bundle size
nx build web-app --statsJson
npx webpack-bundle-analyzer dist/apps/web-app/stats.json

# Optimize memory usage
NODE_OPTIONS="--max-old-space-size=8192" nx build web-app
```

### Dependency Issues
```bash
# Check for circular dependencies
nx lint

# Update dependencies
nx migrate latest
nx migrate --run-migrations

# Fix module resolution
nx g @nx/workspace:fix-configuration
```

## Resources

- [Official Documentation](https://nx.dev)
- [Nx Cloud](https://nx.app)
- [Nx Plugins Registry](https://nx.dev/plugin-registry)
- [Nx Examples](https://github.com/nrwl/nx-examples)
- [Enterprise Support](https://nx.app/enterprise)
- [Community Plugins](https://nx.dev/community)