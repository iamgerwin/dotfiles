# CircleCI Best Practices

## Table of Contents
- [Official Documentation](#official-documentation)
- [Core Concepts](#core-concepts)
- [Project Structure Examples](#project-structure-examples)
- [Configuration Examples](#configuration-examples)
- [Best Practices](#best-practices)
- [Common Patterns](#common-patterns)
- [Do's and Don'ts](#dos-and-donts)
- [Additional Resources](#additional-resources)

## Official Documentation

- [CircleCI Documentation](https://circleci.com/docs/)
- [Configuration Reference](https://circleci.com/docs/configuration-reference/)
- [CircleCI Orbs](https://circleci.com/developer/orbs)
- [API Documentation](https://circleci.com/docs/api/v2/)
- [Best Practices Guide](https://circleci.com/docs/optimizations/)
- [Security Recommendations](https://circleci.com/docs/security-recommendations/)

## Core Concepts

### Pipeline Components
- **Pipeline**: The entire configuration for a project
- **Workflow**: A set of rules for running jobs
- **Job**: A collection of steps
- **Step**: An individual task (run, checkout, etc.)
- **Executor**: Environment where jobs run (Docker, machine, macOS)
- **Orb**: Reusable package of configuration

### Execution Environments
- **Docker**: Containerized environment
- **Machine**: Ubuntu/Linux VM
- **macOS**: macOS VM for iOS development
- **Windows**: Windows VM
- **GPU**: GPU-enabled compute

### Key Features
- **Workflows**: Orchestrate and schedule jobs
- **Parallelism**: Run jobs and tests in parallel
- **Caching**: Speed up builds with dependency and build caching
- **Artifacts**: Store and share files between jobs
- **Workspaces**: Share data between jobs in a workflow
- **Approval Jobs**: Manual approval gates

## Project Structure Examples

### Basic Project Structure
```
project/
├── .circleci/
│   ├── config.yml
│   └── continue_config.yml
├── src/
├── tests/
├── Dockerfile
├── docker-compose.yml
├── package.json
└── README.md
```

### Advanced Multi-Service Structure
```
microservices-project/
├── .circleci/
│   ├── config.yml
│   ├── orbs/
│   │   ├── custom-deploy.yml
│   │   └── security-scan.yml
│   ├── scripts/
│   │   ├── deploy.sh
│   │   ├── test.sh
│   │   └── security-check.sh
│   └── workflows/
│       ├── main.yml
│       ├── nightly.yml
│       └── release.yml
├── services/
│   ├── auth-service/
│   │   ├── src/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── package.json
│   ├── user-service/
│   │   ├── src/
│   │   ├── tests/
│   │   ├── Dockerfile
│   │   └── package.json
│   └── api-gateway/
├── infrastructure/
│   ├── terraform/
│   ├── kubernetes/
│   └── helm/
├── shared/
│   ├── utils/
│   ├── types/
│   └── configs/
└── scripts/
    ├── build-all.sh
    ├── test-all.sh
    └── deploy-all.sh
```

### Enterprise Configuration Structure
```
enterprise-ci-cd/
├── .circleci/
│   ├── config.yml
│   ├── orbs/
│   │   ├── company-security/
│   │   │   ├── @orb.yml
│   │   │   ├── commands/
│   │   │   ├── jobs/
│   │   │   └── executors/
│   │   ├── company-deploy/
│   │   └── company-notify/
│   ├── contexts/
│   │   ├── production.yml
│   │   ├── staging.yml
│   │   └── development.yml
│   ├── workflows/
│   │   ├── feature-branch.yml
│   │   ├── main-branch.yml
│   │   ├── release.yml
│   │   └── hotfix.yml
│   └── templates/
│       ├── test-template.yml
│       ├── build-template.yml
│       └── deploy-template.yml
├── environments/
│   ├── prod/
│   ├── staging/
│   └── dev/
└── monitoring/
    ├── dashboards/
    └── alerts/
```

## Configuration Examples

### Basic Configuration (.circleci/config.yml)
```yaml
version: 2.1

orbs:
  node: circleci/node@5.0.3
  docker: circleci/docker@2.2.0

executors:
  node-executor:
    docker:
      - image: cimg/node:18.17
    working_directory: ~/project

jobs:
  checkout-and-install:
    executor: node-executor
    steps:
      - checkout
      - restore_cache:
          keys:
            - v1-dependencies-{{ checksum "package-lock.json" }}
            - v1-dependencies-
      - run:
          name: Install dependencies
          command: npm ci
      - save_cache:
          paths:
            - node_modules
          key: v1-dependencies-{{ checksum "package-lock.json" }}
      - persist_to_workspace:
          root: ~/project
          paths:
            - .

  test:
    executor: node-executor
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Run tests
          command: npm test
      - run:
          name: Generate coverage
          command: npm run test:coverage
      - store_test_results:
          path: test-results
      - store_artifacts:
          path: coverage
          destination: coverage

  lint:
    executor: node-executor
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Run ESLint
          command: npm run lint
      - run:
          name: Run Prettier
          command: npm run format:check

  build:
    executor: node-executor
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Build application
          command: npm run build
      - persist_to_workspace:
          root: ~/project
          paths:
            - dist

  docker-build:
    executor: docker/docker
    steps:
      - attach_workspace:
          at: ~/project
      - setup_remote_docker:
          docker_layer_caching: true
      - docker/check
      - docker/build:
          image: myapp
          tag: << pipeline.git.revision >>
      - docker/push:
          image: myapp
          tag: << pipeline.git.revision >>

workflows:
  test-and-build:
    jobs:
      - checkout-and-install
      - test:
          requires:
            - checkout-and-install
      - lint:
          requires:
            - checkout-and-install
      - build:
          requires:
            - checkout-and-install
      - docker-build:
          requires:
            - test
            - lint
            - build
          filters:
            branches:
              only: main
```

### Advanced Multi-Environment Workflow
```yaml
version: 2.1

orbs:
  aws-cli: circleci/aws-cli@3.1.4
  kubernetes: circleci/kubernetes@1.3.1
  helm: circleci/helm@2.0.1
  slack: circleci/slack@4.10.1

parameters:
  deploy-environment:
    type: string
    default: ""
  run-integration-tests:
    type: boolean
    default: false

executors:
  node-executor:
    docker:
      - image: cimg/node:18.17
      - image: cimg/postgres:14.0
        environment:
          POSTGRES_USER: test
          POSTGRES_DB: testdb
          POSTGRES_PASSWORD: testpass
    working_directory: ~/project
    environment:
      DATABASE_URL: postgres://test:testpass@localhost:5432/testdb

  python-executor:
    docker:
      - image: cimg/python:3.9
    working_directory: ~/project

  deployment-executor:
    docker:
      - image: cimg/aws:2023.03
    working_directory: ~/project

jobs:
  setup:
    executor: node-executor
    steps:
      - checkout
      - restore_cache:
          keys:
            - v2-npm-deps-{{ checksum "package-lock.json" }}
            - v2-npm-deps-
      - run:
          name: Install Node dependencies
          command: npm ci
      - save_cache:
          paths:
            - node_modules
          key: v2-npm-deps-{{ checksum "package-lock.json" }}
      - persist_to_workspace:
          root: ~/project
          paths:
            - .

  unit-tests:
    executor: node-executor
    parallelism: 4
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Run unit tests
          command: |
            npm run test:unit -- --shard=$CIRCLE_NODE_INDEX/$CIRCLE_NODE_TOTAL
      - store_test_results:
          path: test-results/unit
      - store_artifacts:
          path: coverage/unit

  integration-tests:
    executor: node-executor
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Wait for database
          command: |
            for i in $(seq 1 30); do
              nc -z localhost 5432 && echo Success && exit 0
              echo -n .
              sleep 1
            done
            echo Failed waiting for Postgres && exit 1
      - run:
          name: Run database migrations
          command: npm run db:migrate
      - run:
          name: Run integration tests
          command: npm run test:integration
      - store_test_results:
          path: test-results/integration

  security-scan:
    executor: node-executor
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Audit npm dependencies
          command: npm audit --audit-level high
      - run:
          name: Run security linting
          command: npm run security:lint
      - run:
          name: Check for secrets
          command: |
            if git log --oneline -n 20 | grep -iE '(password|secret|key|token)'; then
              echo "Potential secrets found in recent commits"
              exit 1
            fi

  build-and-package:
    executor: node-executor
    steps:
      - attach_workspace:
          at: ~/project
      - run:
          name: Build application
          command: npm run build:production
      - run:
          name: Package application
          command: |
            tar -czf app-${CIRCLE_SHA1}.tar.gz dist package.json package-lock.json
      - store_artifacts:
          path: app-${CIRCLE_SHA1}.tar.gz
      - persist_to_workspace:
          root: ~/project
          paths:
            - dist
            - app-*.tar.gz

  docker-build-and-push:
    executor: docker/docker
    steps:
      - attach_workspace:
          at: ~/project
      - setup_remote_docker:
          docker_layer_caching: true
      - run:
          name: Build Docker image
          command: |
            docker build -t $CIRCLE_PROJECT_REPONAME:$CIRCLE_SHA1 .
            docker tag $CIRCLE_PROJECT_REPONAME:$CIRCLE_SHA1 $CIRCLE_PROJECT_REPONAME:latest
      - run:
          name: Push to registry
          command: |
            echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
            docker push $CIRCLE_PROJECT_REPONAME:$CIRCLE_SHA1
            docker push $CIRCLE_PROJECT_REPONAME:latest

  deploy-staging:
    executor: deployment-executor
    steps:
      - attach_workspace:
          at: ~/project
      - aws-cli/install
      - kubernetes/install-kubectl
      - helm/install-helm-client
      - run:
          name: Deploy to staging
          command: |
            aws eks update-kubeconfig --region us-east-1 --name staging-cluster
            helm upgrade --install myapp ./helm/myapp \
              --namespace staging \
              --set image.tag=$CIRCLE_SHA1 \
              --set environment=staging \
              --wait
      - slack/notify:
          event: pass
          custom: |
            {
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "✅ *Staging Deployment Successful*\n*Project:* $CIRCLE_PROJECT_REPONAME\n*Branch:* $CIRCLE_BRANCH\n*Commit:* $CIRCLE_SHA1"
                  }
                }
              ]
            }

  deploy-production:
    executor: deployment-executor
    steps:
      - attach_workspace:
          at: ~/project
      - aws-cli/install
      - kubernetes/install-kubectl
      - helm/install-helm-client
      - run:
          name: Deploy to production
          command: |
            aws eks update-kubeconfig --region us-east-1 --name production-cluster
            helm upgrade --install myapp ./helm/myapp \
              --namespace production \
              --set image.tag=$CIRCLE_SHA1 \
              --set environment=production \
              --wait
      - slack/notify:
          event: pass
          channel: '#deployments'
          custom: |
            {
              "blocks": [
                {
                  "type": "section",
                  "text": {
                    "type": "mrkdwn",
                    "text": "🚀 *Production Deployment Successful*\n*Project:* $CIRCLE_PROJECT_REPONAME\n*Version:* $CIRCLE_SHA1"
                  }
                }
              ]
            }

  approval-gate:
    executor: node-executor
    steps:
      - run: echo "Awaiting approval for production deployment"

workflows:
  feature-branch:
    when:
      and:
        - not:
            equal: [ main, << pipeline.git.branch >> ]
        - not:
            equal: [ develop, << pipeline.git.branch >> ]
    jobs:
      - setup
      - unit-tests:
          requires:
            - setup
      - security-scan:
          requires:
            - setup

  develop-branch:
    when:
      equal: [ develop, << pipeline.git.branch >> ]
    jobs:
      - setup
      - unit-tests:
          requires:
            - setup
      - integration-tests:
          requires:
            - setup
      - security-scan:
          requires:
            - setup
      - build-and-package:
          requires:
            - unit-tests
            - integration-tests
            - security-scan
      - docker-build-and-push:
          requires:
            - build-and-package
          context: docker-registry
      - deploy-staging:
          requires:
            - docker-build-and-push
          context:
            - aws-staging
            - slack-notifications

  main-branch:
    when:
      equal: [ main, << pipeline.git.branch >> ]
    jobs:
      - setup
      - unit-tests:
          requires:
            - setup
      - integration-tests:
          requires:
            - setup
      - security-scan:
          requires:
            - setup
      - build-and-package:
          requires:
            - unit-tests
            - integration-tests
            - security-scan
      - docker-build-and-push:
          requires:
            - build-and-package
          context: docker-registry
      - deploy-staging:
          requires:
            - docker-build-and-push
          context:
            - aws-staging
            - slack-notifications
      - approval-gate:
          type: approval
          requires:
            - deploy-staging
      - deploy-production:
          requires:
            - approval-gate
          context:
            - aws-production
            - slack-notifications

  nightly:
    triggers:
      - schedule:
          cron: "0 2 * * *"
          filters:
            branches:
              only: main
    jobs:
      - setup
      - integration-tests:
          requires:
            - setup
          context: nightly-testing
      - security-scan:
          requires:
            - setup
```

### Custom Orb Example
```yaml
# .circleci/orbs/custom-deploy.yml
version: 2.1

description: |
  Custom deployment orb for company infrastructure

executors:
  deploy-executor:
    docker:
      - image: cimg/aws:2023.03
    working_directory: ~/project

commands:
  install-dependencies:
    description: "Install deployment dependencies"
    steps:
      - run:
          name: Install kubectl
          command: |
            curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
            sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
      - run:
          name: Install Helm
          command: |
            curl https://get.helm.sh/helm-v3.12.0-linux-amd64.tar.gz | tar xz
            sudo mv linux-amd64/helm /usr/local/bin/

  setup-cluster-access:
    description: "Setup access to Kubernetes cluster"
    parameters:
      cluster-name:
        type: string
      region:
        type: string
        default: "us-east-1"
    steps:
      - run:
          name: Configure kubectl
          command: |
            aws eks update-kubeconfig \
              --region << parameters.region >> \
              --name << parameters.cluster-name >>

  deploy-helm-chart:
    description: "Deploy application using Helm"
    parameters:
      release-name:
        type: string
      chart-path:
        type: string
        default: "./helm/chart"
      namespace:
        type: string
        default: "default"
      values:
        type: string
        default: ""
    steps:
      - run:
          name: Deploy with Helm
          command: |
            helm upgrade --install << parameters.release-name >> << parameters.chart-path >> \
              --namespace << parameters.namespace >> \
              --create-namespace \
              << parameters.values >> \
              --wait

jobs:
  deploy:
    executor: deploy-executor
    parameters:
      environment:
        type: string
      cluster-name:
        type: string
      release-name:
        type: string
    steps:
      - checkout
      - install-dependencies
      - setup-cluster-access:
          cluster-name: << parameters.cluster-name >>
      - deploy-helm-chart:
          release-name: << parameters.release-name >>
          namespace: << parameters.environment >>
          values: |
            --set image.tag=$CIRCLE_SHA1
            --set environment=<< parameters.environment >>

examples:
  deploy-to-staging:
    description: Deploy application to staging environment
    usage:
      version: 2.1
      orbs:
        deploy: company/deploy@1.0.0
      workflows:
        deploy-staging:
          jobs:
            - deploy/deploy:
                environment: staging
                cluster-name: staging-cluster
                release-name: myapp
```

## Best Practices

### Performance Optimization
1. **Use Workspaces**: Share data between jobs efficiently
2. **Enable Caching**: Cache dependencies, builds, and Docker layers
3. **Parallelism**: Use parallelism for tests and builds
4. **Resource Classes**: Choose appropriate resource classes for jobs
5. **Docker Layer Caching**: Enable for Docker builds

### Security
1. **Context Management**: Use contexts for environment-specific secrets
2. **Environment Variables**: Use encrypted environment variables
3. **Image Security**: Scan container images for vulnerabilities
3. **Least Privilege**: Grant minimal required permissions
4. **Secret Rotation**: Regularly rotate secrets and tokens

### Configuration Management
1. **Orb Usage**: Use official orbs when possible
2. **Version Pinning**: Pin orb and image versions
3. **Configuration Validation**: Validate configurations before committing
4. **Modular Design**: Break complex workflows into smaller, reusable jobs
5. **Documentation**: Document custom orbs and complex workflows

### Monitoring and Debugging
1. **Structured Logging**: Use consistent logging formats
2. **Test Results**: Store test results and artifacts
3. **Notifications**: Set up appropriate notifications for failures
4. **Metrics Collection**: Collect build and deployment metrics
5. **SSH Debugging**: Use SSH access for debugging failed builds

## Common Patterns

### Matrix Builds
```yaml
version: 2.1

executors:
  node-executor:
    parameters:
      node-version:
        type: string
    docker:
      - image: cimg/node:<< parameters.node-version >>

jobs:
  test:
    parameters:
      node-version:
        type: string
    executor:
      name: node-executor
      node-version: << parameters.node-version >>
    steps:
      - checkout
      - run: npm ci
      - run: npm test

workflows:
  test-matrix:
    jobs:
      - test:
          matrix:
            parameters:
              node-version: ["14.21", "16.20", "18.17", "20.5"]
```

### Conditional Deployments
```yaml
jobs:
  deploy:
    executor: deployment-executor
    steps:
      - when:
          condition:
            equal: [ main, << pipeline.git.branch >> ]
          steps:
            - run: echo "Deploying to production"
            - run: ./scripts/deploy-production.sh
      - when:
          condition:
            equal: [ develop, << pipeline.git.branch >> ]
          steps:
            - run: echo "Deploying to staging"
            - run: ./scripts/deploy-staging.sh
      - unless:
          condition:
            or:
              - equal: [ main, << pipeline.git.branch >> ]
              - equal: [ develop, << pipeline.git.branch >> ]
          steps:
            - run: echo "Feature branch - no deployment"
```

### Blue-Green Deployment
```yaml
jobs:
  blue-green-deploy:
    executor: deployment-executor
    steps:
      - checkout
      - run:
          name: Deploy to green environment
          command: |
            helm upgrade --install myapp-green ./helm/myapp \
              --namespace production \
              --set service.selector.version=green \
              --set image.tag=$CIRCLE_SHA1 \
              --wait
      - run:
          name: Run health checks
          command: |
            ./scripts/health-check.sh https://green.myapp.com
      - run:
          name: Switch traffic to green
          command: |
            kubectl patch service myapp-service \
              -p '{"spec":{"selector":{"version":"green"}}}'
      - run:
          name: Cleanup blue environment
          command: |
            helm delete myapp-blue --namespace production || true
```

### Fan-out/Fan-in Pattern
```yaml
workflows:
  fan-out-fan-in:
    jobs:
      - setup
      
      # Fan-out: Multiple parallel jobs
      - unit-tests:
          requires: [setup]
      - integration-tests:
          requires: [setup]
      - security-scan:
          requires: [setup]
      - performance-tests:
          requires: [setup]
      
      # Fan-in: Single job depending on all parallel jobs
      - deploy:
          requires:
            - unit-tests
            - integration-tests
            - security-scan
            - performance-tests
```

## Do's and Don'ts

### Do's
✅ **Use workspaces** to share data between jobs efficiently
✅ **Enable caching** for dependencies and build artifacts
✅ **Pin versions** for orbs, images, and tools
✅ **Use contexts** for environment-specific configuration
✅ **Store test results** and artifacts for debugging
✅ **Set up proper notifications** for build failures
✅ **Use parallelism** to speed up tests and builds
✅ **Validate configurations** before merging
✅ **Monitor resource usage** and optimize accordingly
✅ **Document custom orbs** and complex configurations

### Don'ts
❌ **Don't hardcode secrets** in configuration files
❌ **Don't use latest tags** for production images
❌ **Don't ignore failed builds** or tests
❌ **Don't create overly complex** single jobs
❌ **Don't forget to clean up** resources after deployment
❌ **Don't skip security scans** and vulnerability checks
❌ **Don't use deprecated** features or orbs
❌ **Don't ignore build performance** and optimization
❌ **Don't commit sensitive data** to version control
❌ **Don't neglect monitoring** and alerting

## Additional Resources

### Official Resources
- [CircleCI Blog](https://circleci.com/blog/) - Latest updates and best practices
- [CircleCI Academy](https://academy.circleci.com/) - Training courses
- [CircleCI Orb Registry](https://circleci.com/developer/orbs) - Community orbs
- [CircleCI Discuss](https://discuss.circleci.com/) - Community forum

### Tools and Integrations
- [CircleCI CLI](https://circleci.com/docs/local-cli/) - Command-line tool
- [Config Validation](https://circleci.com/docs/config-validation/) - Validate configurations
- [VS Code Extension](https://marketplace.visualstudio.com/items?itemName=CircleCI.circleci) - IDE support
- [GitHub Integration](https://circleci.com/docs/github-integration/) - GitHub Apps

### Monitoring and Analytics
- [CircleCI Insights](https://circleci.com/docs/insights/) - Build analytics
- [Test Insights](https://circleci.com/docs/collect-test-data/) - Test performance data
- [Performance Plans](https://circleci.com/docs/performance-plan/) - Resource optimization

### Learning Resources
- [CircleCI Documentation](https://circleci.com/docs/) - Complete documentation
- [Configuration Cookbook](https://circleci.com/docs/configuration-cookbook/) - Configuration examples
- [Sample Projects](https://circleci.com/docs/sample-config/) - Example configurations
- [Migration Guides](https://circleci.com/docs/migration/) - Migration from other CI/CD systems

### Community Resources
- [CircleCI GitHub](https://github.com/CircleCI-Public) - Public repositories
- [Stack Overflow](https://stackoverflow.com/questions/tagged/circleci) - Q&A
- [Reddit r/devops](https://www.reddit.com/r/devops/) - DevOps community
- [CircleCI YouTube](https://www.youtube.com/c/CircleCI) - Video tutorials and webinars