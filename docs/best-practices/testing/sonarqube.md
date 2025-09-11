# SonarQube Best Practices

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

- [SonarQube Documentation](https://docs.sonarqube.org/latest/)
- [SonarQube Installation Guide](https://docs.sonarqube.org/latest/setup/)
- [SonarQube Project Configuration](https://docs.sonarqube.org/latest/project-administration/)
- [SonarQube Quality Gates](https://docs.sonarqube.org/latest/user-guide/quality-gates/)
- [SonarQube Security Rules](https://docs.sonarqube.org/latest/user-guide/security-rules/)
- [SonarScanner Documentation](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/)

## Core Concepts

### Code Quality Dimensions
- **Bugs**: Code that is demonstrably wrong or highly likely to yield unexpected behavior
- **Vulnerabilities**: Security-related issues that are potentially exploitable by hackers
- **Code Smells**: Maintainability-related issues that make code harder to understand and change
- **Coverage**: Percentage of code covered by tests
- **Duplications**: Duplicated blocks of code that should be refactored

### Quality Gate
- **Quality Gate**: Set of Boolean conditions based on measure thresholds
- **Conditions**: Individual rules within a quality gate
- **Overall Code Status**: Pass/Fail status based on quality gate evaluation

### Analysis Types
- **Main Branch Analysis**: Analysis of the main development branch
- **Pull Request Analysis**: Analysis of changes in pull/merge requests
- **Branch Analysis**: Analysis of feature branches
- **Baseline Analysis**: Historical analysis for comparison

### Metrics and Measures
- **Reliability**: Bugs, Reliability Rating
- **Security**: Vulnerabilities, Security Hotspots, Security Rating
- **Maintainability**: Code Smells, Technical Debt, Maintainability Rating
- **Coverage**: Line Coverage, Branch Coverage, Condition Coverage
- **Duplications**: Duplicated Lines, Duplicated Files, Duplicated Blocks

## Project Structure Examples

### Basic SonarQube Integration Structure
```
project/
├── src/
│   ├── main/
│   │   └── java/
│   └── test/
│       └── java/
├── sonar-project.properties
├── .sonarcloud.properties
├── build.gradle / pom.xml / package.json
├── Jenkinsfile
├── .github/
│   └── workflows/
│       └── sonarqube.yml
└── quality-profiles/
    ├── java-profile.xml
    ├── javascript-profile.xml
    └── python-profile.xml
```

### Multi-Module Project Structure
```
enterprise-project/
├── backend/
│   ├── auth-service/
│   │   ├── src/
│   │   ├── pom.xml
│   │   └── sonar-project.properties
│   ├── user-service/
│   │   ├── src/
│   │   ├── pom.xml
│   │   └── sonar-project.properties
│   └── common/
├── frontend/
│   ├── web-app/
│   │   ├── src/
│   │   ├── package.json
│   │   └── sonar-project.properties
│   └── mobile-app/
├── infrastructure/
│   ├── terraform/
│   └── kubernetes/
├── sonar-project.properties (root)
├── quality-gates/
│   ├── backend-gate.json
│   ├── frontend-gate.json
│   └── default-gate.json
├── quality-profiles/
│   ├── java-backend.xml
│   ├── javascript-frontend.xml
│   └── typescript-frontend.xml
└── scripts/
    ├── analyze.sh
    ├── setup-quality-gates.sh
    └── export-profiles.sh
```

### SonarQube Server Setup Structure
```
sonarqube-setup/
├── docker/
│   ├── docker-compose.yml
│   ├── sonarqube/
│   │   ├── Dockerfile
│   │   └── plugins/
│   ├── postgresql/
│   │   └── init.sql
│   └── nginx/
│       └── nginx.conf
├── kubernetes/
│   ├── namespace.yaml
│   ├── postgres/
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   ├── sonarqube/
│   │   ├── deployment.yaml
│   │   ├── service.yaml
│   │   └── ingress.yaml
│   └── monitoring/
│       ├── servicemonitor.yaml
│       └── grafana-dashboard.json
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
├── backup/
│   ├── backup-script.sh
│   └── restore-script.sh
├── monitoring/
│   ├── prometheus-rules.yaml
│   └── alerting-rules.yaml
└── scripts/
    ├── setup.sh
    ├── backup.sh
    └── migrate.sh
```

## Configuration Examples

### Basic Project Configuration (sonar-project.properties)
```properties
# Required metadata
sonar.projectKey=my-project
sonar.projectName=My Application
sonar.projectVersion=1.0.0

# Source code configuration
sonar.sources=src/main/java,src/main/javascript
sonar.tests=src/test/java,src/test/javascript
sonar.java.binaries=target/classes
sonar.java.test.binaries=target/test-classes
sonar.java.libraries=target/dependency/*.jar

# Language-specific settings
sonar.java.source=11
sonar.java.target=11
sonar.javascript.lcov.reportPaths=coverage/lcov.info
sonar.typescript.lcov.reportPaths=coverage/lcov.info

# Coverage settings
sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
sonar.junit.reportPaths=target/surefire-reports
sonar.surefire.reportPaths=target/surefire-reports

# Exclusions
sonar.exclusions=**/*Test.java,**/*.spec.js,**/node_modules/**,**/dist/**
sonar.test.exclusions=**/node_modules/**
sonar.coverage.exclusions=**/*Test.java,**/*IT.java,**/config/**,**/dto/**

# Quality gate
sonar.qualitygate.wait=true
sonar.qualitygate.timeout=300

# Additional settings
sonar.sourceEncoding=UTF-8
sonar.scm.provider=git
```

### Multi-Language Project Configuration
```properties
# Project metadata
sonar.projectKey=fullstack-app
sonar.projectName=Full Stack Application
sonar.projectVersion=${BUILD_NUMBER}

# Module definitions
sonar.modules=backend,frontend,mobile

# Backend module (Java/Spring Boot)
backend.sonar.projectName=Backend Services
backend.sonar.sources=src/main/java
backend.sonar.tests=src/test/java
backend.sonar.java.binaries=target/classes
backend.sonar.java.test.binaries=target/test-classes
backend.sonar.java.libraries=target/dependency/*.jar
backend.sonar.coverage.jacoco.xmlReportPaths=target/site/jacoco/jacoco.xml
backend.sonar.exclusions=**/config/**,**/dto/**,**/entity/**

# Frontend module (React/TypeScript)
frontend.sonar.projectName=Web Frontend
frontend.sonar.sources=src
frontend.sonar.tests=src
frontend.sonar.test.inclusions=**/*.test.ts,**/*.test.tsx,**/*.spec.ts,**/*.spec.tsx
frontend.sonar.typescript.lcov.reportPaths=coverage/lcov.info
frontend.sonar.javascript.lcov.reportPaths=coverage/lcov.info
frontend.sonar.exclusions=**/node_modules/**,**/build/**,**/dist/**,**/*.d.ts

# Mobile module (React Native)
mobile.sonar.projectName=Mobile App
mobile.sonar.sources=src
mobile.sonar.tests=__tests__
mobile.sonar.javascript.lcov.reportPaths=coverage/lcov.info
mobile.sonar.exclusions=**/node_modules/**,**/android/**,**/ios/**
```

### Docker Compose Setup
```yaml
# docker-compose.yml
version: '3.8'

services:
  postgresql:
    image: postgres:13
    environment:
      POSTGRES_USER: sonar
      POSTGRES_PASSWORD: sonar
      POSTGRES_DB: sonarqube
    volumes:
      - postgresql_data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - sonarqube

  sonarqube:
    image: sonarqube:9.9-community
    depends_on:
      - postgresql
    environment:
      SONAR_JDBC_URL: jdbc:postgresql://postgresql:5432/sonarqube
      SONAR_JDBC_USERNAME: sonar
      SONAR_JDBC_PASSWORD: sonar
      SONAR_ES_BOOTSTRAP_CHECKS_DISABLE: true
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs
      - ./plugins:/opt/sonarqube/extensions/plugins
    ports:
      - "9000:9000"
    networks:
      - sonarqube
    ulimits:
      nofile:
        soft: 65536
        hard: 65536
    sysctls:
      vm.max_map_count: 524288

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - sonarqube
    networks:
      - sonarqube

volumes:
  postgresql_data:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:

networks:
  sonarqube:
    driver: bridge
```

### GitHub Actions Integration
```yaml
# .github/workflows/sonarqube.yml
name: SonarQube Analysis

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]
  schedule:
    - cron: '0 2 * * *'  # Daily at 2 AM

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_USER: test
          POSTGRES_PASSWORD: test
          POSTGRES_DB: testdb
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
    - uses: actions/checkout@v3
      with:
        fetch-depth: 0  # Full history for better blame information
    
    - name: Set up JDK 11
      uses: actions/setup-java@v3
      with:
        java-version: '11'
        distribution: 'temurin'
    
    - name: Set up Node.js
      uses: actions/setup-node@v3
      with:
        node-version: '16'
        cache: 'npm'
    
    - name: Cache SonarQube packages
      uses: actions/cache@v3
      with:
        path: ~/.sonar/cache
        key: ${{ runner.os }}-sonar
        restore-keys: ${{ runner.os }}-sonar
    
    - name: Cache Maven packages
      uses: actions/cache@v3
      with:
        path: ~/.m2
        key: ${{ runner.os }}-m2-${{ hashFiles('**/pom.xml') }}
        restore-keys: ${{ runner.os }}-m2
    
    - name: Install dependencies
      run: |
        mvn clean compile
        npm install
    
    - name: Run backend tests
      run: mvn test jacoco:report
      env:
        DATABASE_URL: jdbc:postgresql://localhost:5432/testdb
        DATABASE_USERNAME: test
        DATABASE_PASSWORD: test
    
    - name: Run frontend tests
      run: npm test -- --coverage --watchAll=false
    
    - name: Run SonarQube Scan
      uses: sonarqube-quality-gate-action@master
      with:
        scanMetadataReportFile: target/sonar/report-task.txt
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
        SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}
    
    - name: SonarQube Analysis
      run: |
        mvn sonar:sonar \
          -Dsonar.projectKey=${{ github.repository_owner }}_${{ github.event.repository.name }} \
          -Dsonar.organization=${{ github.repository_owner }} \
          -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
          -Dsonar.token=${{ secrets.SONAR_TOKEN }} \
          -Dsonar.pullrequest.key=${{ github.event.number }} \
          -Dsonar.pullrequest.branch=${{ github.head_ref }} \
          -Dsonar.pullrequest.base=${{ github.base_ref }}
      if: github.event_name == 'pull_request'
    
    - name: SonarQube Analysis (Main Branch)
      run: |
        mvn sonar:sonar \
          -Dsonar.projectKey=${{ github.repository_owner }}_${{ github.event.repository.name }} \
          -Dsonar.organization=${{ github.repository_owner }} \
          -Dsonar.host.url=${{ secrets.SONAR_HOST_URL }} \
          -Dsonar.token=${{ secrets.SONAR_TOKEN }}
      if: github.ref == 'refs/heads/main'
```

### Jenkins Pipeline Integration
```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        SONAR_TOKEN = credentials('sonar-token')
        SONAR_HOST_URL = 'https://sonarqube.example.com'
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        
        stage('Build') {
            parallel {
                stage('Backend') {
                    steps {
                        dir('backend') {
                            sh 'mvn clean compile'
                        }
                    }
                }
                stage('Frontend') {
                    steps {
                        dir('frontend') {
                            sh 'npm install'
                            sh 'npm run build'
                        }
                    }
                }
            }
        }
        
        stage('Test') {
            parallel {
                stage('Backend Tests') {
                    steps {
                        dir('backend') {
                            sh 'mvn test jacoco:report'
                        }
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: '**/target/surefire-reports/TEST-*.xml'
                            publishCoverage adapters: [
                                jacocoAdapter('**/target/site/jacoco/jacoco.xml')
                            ]
                        }
                    }
                }
                stage('Frontend Tests') {
                    steps {
                        dir('frontend') {
                            sh 'npm test -- --coverage --watchAll=false'
                        }
                    }
                    post {
                        always {
                            publishTestResults testResultsPattern: '**/test-results.xml'
                            publishCoverage adapters: [
                                istanbulCoberturaAdapter('**/coverage/cobertura-coverage.xml')
                            ]
                        }
                    }
                }
            }
        }
        
        stage('SonarQube Analysis') {
            environment {
                scannerHome = tool 'SonarQubeScanner'
            }
            steps {
                withSonarQubeEnv('SonarQube') {
                    script {
                        if (env.CHANGE_ID) {
                            // Pull Request Analysis
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.pullrequest.key=${env.CHANGE_ID} \
                                -Dsonar.pullrequest.branch=${env.CHANGE_BRANCH} \
                                -Dsonar.pullrequest.base=${env.CHANGE_TARGET}
                            """
                        } else {
                            // Branch Analysis
                            sh """
                                ${scannerHome}/bin/sonar-scanner \
                                -Dsonar.branch.name=${env.BRANCH_NAME}
                            """
                        }
                    }
                }
            }
        }
        
        stage('Quality Gate') {
            steps {
                timeout(time: 10, unit: 'MINUTES') {
                    waitForQualityGate abortPipeline: true
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
        failure {
            emailext (
                subject: "SonarQube Analysis Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "SonarQube analysis failed for ${env.JOB_NAME} build ${env.BUILD_NUMBER}. Check the console output for details.",
                to: "${env.CHANGE_AUTHOR_EMAIL}"
            )
        }
        success {
            script {
                if (env.CHANGE_ID) {
                    pullRequest.comment("✅ SonarQube analysis passed! Quality gate conditions met.")
                }
            }
        }
    }
}
```

### Quality Gate Configuration
```json
{
  "name": "Production Quality Gate",
  "conditions": [
    {
      "metric": "new_reliability_rating",
      "op": "GT",
      "error": "1"
    },
    {
      "metric": "new_security_rating", 
      "op": "GT",
      "error": "1"
    },
    {
      "metric": "new_maintainability_rating",
      "op": "GT", 
      "error": "1"
    },
    {
      "metric": "new_coverage",
      "op": "LT",
      "error": "80"
    },
    {
      "metric": "new_duplicated_lines_density",
      "op": "GT",
      "error": "3"
    },
    {
      "metric": "new_security_hotspots_reviewed",
      "op": "LT",
      "error": "100"
    }
  ]
}
```

## Best Practices

### Project Configuration
1. **Consistent Project Keys**: Use meaningful, consistent project key naming conventions
2. **Module Organization**: Organize multi-module projects with clear module boundaries
3. **Exclusion Patterns**: Define appropriate exclusions for generated code and test utilities
4. **Source Encoding**: Always specify source encoding (UTF-8)
5. **Baseline Configuration**: Set up appropriate baselines for legacy projects

### Quality Gates
1. **Incremental Approach**: Focus on "new code" conditions for legacy projects
2. **Realistic Thresholds**: Set achievable but meaningful thresholds
3. **Coverage Requirements**: Define appropriate coverage requirements per project type
4. **Security Focus**: Include security-related conditions
5. **Regular Review**: Periodically review and adjust quality gate conditions

### Analysis Strategy
1. **Branch Strategy**: Implement analysis for main branches and pull requests
2. **Failure Handling**: Configure builds to fail on quality gate failures
3. **Performance Monitoring**: Monitor analysis time and optimize as needed
4. **Historical Tracking**: Maintain historical data for trend analysis
5. **Integration Testing**: Include integration test coverage in analysis

### Security and Compliance
1. **Security Rules**: Enable and configure security-related rules
2. **Compliance Profiles**: Use compliance-specific quality profiles (OWASP, CWE)
3. **Secret Detection**: Configure rules to detect hardcoded secrets
4. **Vulnerability Tracking**: Track and remediate security vulnerabilities
5. **Regular Updates**: Keep SonarQube and rules database updated

## Common Patterns

### Multi-Environment Setup
```bash
#!/bin/bash
# analyze.sh - Multi-environment analysis script

ENVIRONMENT=${1:-development}
PROJECT_VERSION=${2:-$(git describe --tags --always)}

case $ENVIRONMENT in
  "development")
    SONAR_HOST="https://sonar-dev.company.com"
    QUALITY_GATE="Development Gate"
    ;;
  "staging") 
    SONAR_HOST="https://sonar-staging.company.com"
    QUALITY_GATE="Staging Gate"
    ;;
  "production")
    SONAR_HOST="https://sonar.company.com"
    QUALITY_GATE="Production Gate"
    ;;
esac

# Run analysis with environment-specific settings
sonar-scanner \
  -Dsonar.host.url=$SONAR_HOST \
  -Dsonar.projectVersion=$PROJECT_VERSION \
  -Dsonar.qualitygate=$QUALITY_GATE \
  -Dsonar.environment=$ENVIRONMENT
```

### Custom Rule Configuration
```xml
<!-- quality-profile.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<profile>
    <name>Company Java Standards</name>
    <language>java</language>
    <rules>
        <!-- Critical bugs -->
        <rule>
            <repositoryKey>java</repositoryKey>
            <key>S2259</key>
            <priority>BLOCKER</priority>
        </rule>
        
        <!-- Security vulnerabilities -->
        <rule>
            <repositoryKey>java</repositoryKey>
            <key>S2083</key>
            <priority>BLOCKER</priority>
        </rule>
        
        <!-- Code smells -->
        <rule>
            <repositoryKey>java</repositoryKey>
            <key>S1104</key>
            <priority>MAJOR</priority>
        </rule>
        
        <!-- Custom rules -->
        <rule>
            <repositoryKey>company-rules</repositoryKey>
            <key>avoid-system-out</key>
            <priority>MINOR</priority>
            <parameters>
                <parameter>
                    <key>message</key>
                    <value>Use logging framework instead of System.out</value>
                </parameter>
            </parameters>
        </rule>
    </rules>
</profile>
```

### Automated Quality Gate Setup
```python
# setup-quality-gates.py
import requests
import json

class SonarQubeManager:
    def __init__(self, base_url, token):
        self.base_url = base_url
        self.headers = {
            'Authorization': f'Bearer {token}',
            'Content-Type': 'application/json'
        }
    
    def create_quality_gate(self, name, conditions):
        # Create quality gate
        response = requests.post(
            f'{self.base_url}/api/qualitygates/create',
            headers=self.headers,
            data={'name': name}
        )
        
        if response.status_code == 200:
            gate_id = response.json()['id']
            
            # Add conditions
            for condition in conditions:
                self.add_condition(gate_id, condition)
            
            return gate_id
        else:
            raise Exception(f'Failed to create quality gate: {response.text}')
    
    def add_condition(self, gate_id, condition):
        response = requests.post(
            f'{self.base_url}/api/qualitygates/create_condition',
            headers=self.headers,
            data={
                'gateId': gate_id,
                'metric': condition['metric'],
                'op': condition['op'],
                'error': condition['error']
            }
        )
        
        if response.status_code != 200:
            raise Exception(f'Failed to add condition: {response.text}')

# Usage
sonar = SonarQubeManager('https://sonar.company.com', 'your-token')

production_conditions = [
    {'metric': 'new_reliability_rating', 'op': 'GT', 'error': '1'},
    {'metric': 'new_security_rating', 'op': 'GT', 'error': '1'},
    {'metric': 'new_maintainability_rating', 'op': 'GT', 'error': '1'},
    {'metric': 'new_coverage', 'op': 'LT', 'error': '80'},
    {'metric': 'new_duplicated_lines_density', 'op': 'GT', 'error': '3'}
]

gate_id = sonar.create_quality_gate('Production Gate', production_conditions)
print(f'Created quality gate with ID: {gate_id}')
```

## Do's and Don'ts

### Do's
✅ **Set up quality gates** with appropriate thresholds
✅ **Use incremental analysis** for better performance
✅ **Configure proper exclusions** for generated code
✅ **Integrate with CI/CD pipelines** for automated analysis  
✅ **Monitor and track metrics** over time
✅ **Review and act on findings** regularly
✅ **Use pull request analysis** for early feedback
✅ **Configure appropriate quality profiles** for your technology stack
✅ **Set up notifications** for quality gate failures
✅ **Document coding standards** and rules

### Don'ts
❌ **Don't ignore quality gate failures** in CI/CD
❌ **Don't set unrealistic coverage** requirements
❌ **Don't analyze generated or vendor code**
❌ **Don't use default admin passwords** in production
❌ **Don't skip security rule configuration**
❌ **Don't ignore technical debt** accumulation
❌ **Don't run analysis too frequently** (impacts performance)
❌ **Don't forget to update** SonarQube and plugins regularly
❌ **Don't ignore false positives** - configure suppressions properly
❌ **Don't analyze the same code** multiple times unnecessarily

## Additional Resources

### Official Tools and Plugins
- [SonarLint](https://www.sonarlint.org/) - IDE extensions for real-time analysis
- [SonarScanner CLI](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner/) - Command-line scanner
- [SonarScanner for Maven](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-maven/) - Maven integration
- [SonarScanner for Gradle](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-gradle/) - Gradle integration
- [SonarScanner for Jenkins](https://docs.sonarqube.org/latest/analysis/scan/sonarscanner-for-jenkins/) - Jenkins plugin

### Language Support
- [Java Analysis](https://docs.sonarqube.org/latest/analysis/languages/java/) - Java-specific configuration
- [JavaScript/TypeScript Analysis](https://docs.sonarqube.org/latest/analysis/languages/javascript/) - JS/TS analysis
- [Python Analysis](https://docs.sonarqube.org/latest/analysis/languages/python/) - Python analysis
- [C# Analysis](https://docs.sonarqube.org/latest/analysis/languages/csharp/) - C# and VB.NET
- [C/C++ Analysis](https://docs.sonarqube.org/latest/analysis/languages/cfamily/) - C/C++ analysis

### Community Resources
- [SonarSource Community](https://community.sonarsource.com/) - Official community forum
- [SonarQube Rules](https://rules.sonarsource.com/) - Complete rules documentation
- [GitHub SonarSource](https://github.com/SonarSource) - Official repositories
- [Stack Overflow](https://stackoverflow.com/questions/tagged/sonarqube) - Q&A platform

### Learning Resources
- [SonarQube Documentation](https://docs.sonarqube.org/latest/) - Complete documentation
- [Clean Code School](https://www.sonarsource.com/learn/clean-code/) - Clean code principles
- [SonarSource Blog](https://blog.sonarsource.com/) - Latest news and insights
- [Webinars and Events](https://www.sonarsource.com/events/) - Training and events

### Third-Party Integrations
- [SonarQube Prometheus Exporter](https://github.com/dmeiners88/sonarqube-prometheus-exporter) - Metrics for Prometheus
- [SonarQube Quality Gate Plugin](https://plugins.jenkins.io/sonar-quality-gates/) - Jenkins integration
- [GitHub SonarCloud Action](https://github.com/SonarSource/sonarcloud-github-action) - GitHub Actions