# Laravel GitHub Actions Best Practices

## Overview
GitHub Actions provides powerful CI/CD automation for Laravel applications. These best practices ensure reliable deployments, comprehensive testing, and efficient workflows.

## Workflow Structure

### Basic Laravel CI/CD Workflow
```yaml
# .github/workflows/laravel.yml
name: Laravel CI/CD

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  schedule:
    - cron: '0 0 * * 1' # Weekly security scan

env:
  PHP_VERSION: '8.2'
  NODE_VERSION: '18'
  COMPOSER_VERSION: '2'

jobs:
  test:
    runs-on: ubuntu-latest
    
    strategy:
      matrix:
        php: [8.1, 8.2, 8.3]
        laravel: [9.*, 10.*]
        dependency-version: [prefer-lowest, prefer-stable]
        include:
          - laravel: 10.*
            testbench: 8.*
          - laravel: 9.*
            testbench: 7.*
    
    name: P${{ matrix.php }} - L${{ matrix.laravel }} - ${{ matrix.dependency-version }}
    
    services:
      mysql:
        image: mysql:8.0
        env:
          MYSQL_ROOT_PASSWORD: password
          MYSQL_DATABASE: testing
        ports:
          - 3306:3306
        options: --health-cmd="mysqladmin ping" --health-interval=10s --health-timeout=5s --health-retries=3
      
      redis:
        image: redis:7
        ports:
          - 6379:6379
        options: --health-cmd="redis-cli ping" --health-interval=10s --health-timeout=5s --health-retries=3
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: ${{ matrix.php }}
          extensions: mbstring, dom, fileinfo, mysql, redis, opcache
          coverage: xdebug
          tools: composer:v2
      
      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: vendor
          key: ${{ runner.os }}-composer-${{ hashFiles('**/composer.lock') }}
          restore-keys: |
            ${{ runner.os }}-composer-
      
      - name: Install dependencies
        run: |
          composer require "laravel/framework:${{ matrix.laravel }}" "orchestra/testbench:${{ matrix.testbench }}" --no-interaction --no-update
          composer update --${{ matrix.dependency-version }} --prefer-dist --no-interaction
      
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: ${{ env.NODE_VERSION }}
          cache: 'npm'
      
      - name: Install NPM dependencies
        run: npm ci
      
      - name: Build assets
        run: npm run build
      
      - name: Generate key
        run: php artisan key:generate
      
      - name: Directory Permissions
        run: chmod -R 777 storage bootstrap/cache
      
      - name: Run tests
        env:
          DB_CONNECTION: mysql
          DB_HOST: 127.0.0.1
          DB_PORT: 3306
          DB_DATABASE: testing
          DB_USERNAME: root
          DB_PASSWORD: password
          REDIS_HOST: 127.0.0.1
          REDIS_PORT: 6379
        run: |
          php artisan migrate --force
          php artisan db:seed --force
          vendor/bin/phpunit --coverage-clover coverage.xml
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
        with:
          file: ./coverage.xml
          flags: tests
          name: Laravel Test Coverage
```

## Testing Strategies

### Parallel Testing
```yaml
name: Parallel Tests

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        test-suite: [unit, feature, browser]
        parallel: [1, 2, 3, 4]
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup environment
        run: |
          cp .env.testing .env
          php artisan key:generate
      
      - name: Run parallel tests
        run: |
          php artisan test --parallel --processes=4 --testsuite=${{ matrix.test-suite }}
```

### Browser Testing with Dusk
```yaml
name: Laravel Dusk Tests

jobs:
  dusk:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          extensions: mbstring, dom, fileinfo, mysql
      
      - name: Install Chrome Driver
        run: |
          php artisan dusk:chrome-driver --detect
          chmod -R 0755 vendor/laravel/dusk/bin/
      
      - name: Start Chrome Driver
        run: |
          vendor/laravel/dusk/bin/chromedriver-linux &
          sleep 5
      
      - name: Run Laravel Server
        run: |
          php artisan serve --no-reload &
          sleep 5
      
      - name: Run Dusk Tests
        env:
          APP_URL: http://127.0.0.1:8000
        run: |
          php artisan dusk
      
      - name: Upload Screenshots
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: dusk-screenshots
          path: tests/Browser/screenshots
      
      - name: Upload Console Logs
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: dusk-console
          path: tests/Browser/console
```

## Code Quality

### Static Analysis and Linting
```yaml
name: Code Quality

jobs:
  static-analysis:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
          tools: phpstan, psalm, phpcs, php-cs-fixer
      
      - name: Run PHPStan
        run: phpstan analyse --error-format=github
      
      - name: Run Psalm
        run: psalm --output-format=github
      
      - name: Run PHP CS Fixer
        run: php-cs-fixer fix --dry-run --diff --verbose
      
      - name: Run Larastan
        run: vendor/bin/phpstan analyse --configuration=phpstan.neon
      
      - name: Run Pint
        run: vendor/bin/pint --test
```

### Security Scanning
```yaml
name: Security Scan

jobs:
  security:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run Security Checker
        uses: symfonycorp/security-checker-action@v4
      
      - name: Run Snyk Security Scan
        uses: snyk/actions/php@master
        env:
          SNYK_TOKEN: ${{ secrets.SNYK_TOKEN }}
      
      - name: Run Trivy Scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'
      
      - name: Upload Trivy results
        uses: github/codeql-action/upload-sarif@v2
        with:
          sarif_file: 'trivy-results.sarif'
```

## Deployment Workflows

### Production Deployment
```yaml
name: Deploy to Production

on:
  push:
    tags:
      - 'v*'

jobs:
  deploy:
    runs-on: ubuntu-latest
    environment: production
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.2'
      
      - name: Build application
        run: |
          composer install --optimize-autoloader --no-dev
          npm ci --production
          npm run build
          php artisan config:cache
          php artisan route:cache
          php artisan view:cache
      
      - name: Create deployment artifact
        run: |
          tar -czf deploy.tar.gz \
            --exclude=.git \
            --exclude=.github \
            --exclude=node_modules \
            --exclude=tests \
            --exclude=.env \
            .
      
      - name: Deploy to server
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.PRODUCTION_HOST }}
          username: ${{ secrets.PRODUCTION_USER }}
          key: ${{ secrets.PRODUCTION_SSH_KEY }}
          script: |
            cd /var/www/html
            php artisan down --retry=60
            git pull origin main
            composer install --optimize-autoloader --no-dev
            php artisan migrate --force
            php artisan config:cache
            php artisan route:cache
            php artisan view:cache
            php artisan queue:restart
            php artisan up
```

### Zero-Downtime Deployment
```yaml
name: Zero-Downtime Deploy

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Deploy with Envoy
        run: |
          composer global require laravel/envoy
          ~/.composer/vendor/bin/envoy run deploy \
            --server=production \
            --branch=${{ github.ref_name }} \
            --commit=${{ github.sha }}
```

## Docker Integration

### Build and Push Docker Image
```yaml
name: Docker Build

jobs:
  docker:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v2
      
      - name: Login to DockerHub
        uses: docker/login-action@v2
        with:
          username: ${{ secrets.DOCKER_USERNAME }}
          password: ${{ secrets.DOCKER_PASSWORD }}
      
      - name: Build and push
        uses: docker/build-push-action@v4
        with:
          context: .
          push: true
          tags: |
            ${{ secrets.DOCKER_USERNAME }}/laravel-app:latest
            ${{ secrets.DOCKER_USERNAME }}/laravel-app:${{ github.sha }}
          cache-from: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/laravel-app:buildcache
          cache-to: type=registry,ref=${{ secrets.DOCKER_USERNAME }}/laravel-app:buildcache,mode=max
          build-args: |
            PHP_VERSION=8.2
            NODE_VERSION=18
```

## Performance Optimization

### Caching Strategies
```yaml
name: Optimized Build

jobs:
  build:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Cache Composer dependencies
        uses: actions/cache@v3
        with:
          path: vendor
          key: composer-${{ runner.os }}-${{ hashFiles('**/composer.lock') }}
          restore-keys: |
            composer-${{ runner.os }}-
      
      - name: Cache NPM dependencies
        uses: actions/cache@v3
        with:
          path: ~/.npm
          key: npm-${{ runner.os }}-${{ hashFiles('**/package-lock.json') }}
          restore-keys: |
            npm-${{ runner.os }}-
      
      - name: Cache Laravel
        uses: actions/cache@v3
        with:
          path: |
            bootstrap/cache
            storage/framework/cache
          key: laravel-cache-${{ runner.os }}-${{ github.sha }}
          restore-keys: |
            laravel-cache-${{ runner.os }}-
      
      - name: Cache built assets
        uses: actions/cache@v3
        with:
          path: public/build
          key: assets-${{ runner.os }}-${{ hashFiles('resources/**') }}
          restore-keys: |
            assets-${{ runner.os }}-
```

## Database Management

### Migration and Seeding
```yaml
name: Database Operations

jobs:
  database:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Backup production database
        if: github.ref == 'refs/heads/main'
        run: |
          mysqldump -h ${{ secrets.DB_HOST }} \
            -u ${{ secrets.DB_USER }} \
            -p${{ secrets.DB_PASSWORD }} \
            ${{ secrets.DB_NAME }} > backup.sql
      
      - name: Upload backup
        uses: actions/upload-artifact@v3
        with:
          name: database-backup-${{ github.run_id }}
          path: backup.sql
          retention-days: 30
      
      - name: Run migrations
        run: |
          php artisan migrate --force
          php artisan db:seed --class=ProductionSeeder --force
```

## Queue and Schedule Management

### Queue Worker Deployment
```yaml
name: Queue Worker

jobs:
  queue:
    runs-on: ubuntu-latest
    
    steps:
      - name: Deploy queue workers
        uses: appleboy/ssh-action@v0.1.5
        with:
          host: ${{ secrets.WORKER_HOST }}
          username: ${{ secrets.WORKER_USER }}
          key: ${{ secrets.WORKER_SSH_KEY }}
          script: |
            cd /var/www/html
            php artisan queue:restart
            supervisorctl reread
            supervisorctl update
            supervisorctl restart laravel-worker:*
```

### Scheduled Tasks
```yaml
name: Laravel Schedule

on:
  schedule:
    - cron: '* * * * *' # Every minute

jobs:
  schedule:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Run scheduler
        run: php artisan schedule:run
        env:
          APP_ENV: production
          DB_CONNECTION: ${{ secrets.DB_CONNECTION }}
          DB_HOST: ${{ secrets.DB_HOST }}
```

## Monitoring and Notifications

### Slack Notifications
```yaml
name: Deployment Notifications

jobs:
  notify:
    runs-on: ubuntu-latest
    
    steps:
      - name: Notify Slack on Success
        if: success()
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_CHANNEL: deployments
          SLACK_COLOR: good
          SLACK_MESSAGE: 'Deployment successful for ${{ github.repository }}'
          SLACK_TITLE: Deployment Success
          SLACK_USERNAME: GitHub Actions
      
      - name: Notify Slack on Failure
        if: failure()
        uses: rtCamp/action-slack-notify@v2
        env:
          SLACK_WEBHOOK: ${{ secrets.SLACK_WEBHOOK }}
          SLACK_CHANNEL: deployments
          SLACK_COLOR: danger
          SLACK_MESSAGE: 'Deployment failed for ${{ github.repository }}'
          SLACK_TITLE: Deployment Failed
          SLACK_USERNAME: GitHub Actions
```

## Environment Management

### Multi-Environment Setup
```yaml
name: Environment Deploy

on:
  push:
    branches:
      - main
      - staging
      - develop

jobs:
  deploy:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Set environment
        id: environment
        run: |
          if [[ "${{ github.ref }}" == "refs/heads/main" ]]; then
            echo "env=production" >> $GITHUB_OUTPUT
          elif [[ "${{ github.ref }}" == "refs/heads/staging" ]]; then
            echo "env=staging" >> $GITHUB_OUTPUT
          else
            echo "env=development" >> $GITHUB_OUTPUT
          fi
      
      - name: Deploy to ${{ steps.environment.outputs.env }}
        uses: ./.github/actions/deploy
        with:
          environment: ${{ steps.environment.outputs.env }}
          host: ${{ secrets[format('{0}_HOST', steps.environment.outputs.env)] }}
          user: ${{ secrets[format('{0}_USER', steps.environment.outputs.env)] }}
```

## Custom Actions

### Reusable Laravel Setup
```yaml
# .github/actions/laravel-setup/action.yml
name: 'Laravel Setup'
description: 'Setup Laravel environment'

inputs:
  php-version:
    description: 'PHP version'
    required: false
    default: '8.2'
  node-version:
    description: 'Node version'
    required: false
    default: '18'

runs:
  using: 'composite'
  steps:
    - name: Setup PHP
      uses: shivammathur/setup-php@v2
      with:
        php-version: ${{ inputs.php-version }}
        extensions: mbstring, dom, fileinfo, mysql, redis
        coverage: xdebug
    
    - name: Setup Node
      uses: actions/setup-node@v4
      with:
        node-version: ${{ inputs.node-version }}
        cache: 'npm'
    
    - name: Install dependencies
      shell: bash
      run: |
        composer install --optimize-autoloader
        npm ci
        npm run build
    
    - name: Setup Laravel
      shell: bash
      run: |
        cp .env.example .env
        php artisan key:generate
        php artisan config:cache
```

## Best Practices Summary

1. **Matrix Testing**: Test against multiple PHP and Laravel versions
2. **Service Containers**: Use Docker containers for databases and Redis
3. **Caching**: Cache dependencies and build artifacts
4. **Parallel Testing**: Run tests in parallel for faster feedback
5. **Security Scanning**: Regular security checks for dependencies
6. **Environment Separation**: Different workflows for different environments
7. **Zero-Downtime Deployments**: Use rolling deployments or blue-green strategies
8. **Artifact Storage**: Store build artifacts and test results
9. **Monitoring**: Implement comprehensive monitoring and notifications
10. **Reusable Workflows**: Create custom actions for common tasks

## Conclusion

GitHub Actions provides powerful automation for Laravel applications. Following these best practices ensures reliable CI/CD pipelines, comprehensive testing, and smooth deployments.