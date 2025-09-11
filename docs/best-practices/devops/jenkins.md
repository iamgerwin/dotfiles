# Jenkins Best Practices

## Official Documentation
- **Main Documentation**: https://www.jenkins.io/doc/
- **Pipeline Documentation**: https://www.jenkins.io/doc/book/pipeline/
- **Plugin Index**: https://plugins.jenkins.io/
- **Community**: https://community.jenkins.io/

## Core Concepts

### Architecture
```
Jenkins Master
├── Web UI
├── Job Configuration
├── Build Scheduling
├── Agent Management
└── Plugin Management

Jenkins Agents
├── Build Execution
├── Workspace Management
└── Tool Installation
```

## Project Structure
```
jenkins/
├── Jenkinsfile
├── jenkins-config/
│   ├── casc.yaml           # Configuration as Code
│   ├── plugins.txt         # Plugin list
│   └── shared-libraries/   # Shared pipeline libraries
├── docker/
│   ├── master/
│   │   └── Dockerfile
│   └── agent/
│       └── Dockerfile
├── scripts/
│   ├── setup.sh
│   └── backup.sh
└── pipelines/
    ├── build/
    ├── test/
    └── deploy/
```

## Declarative Pipeline

### 1. Basic Pipeline Structure
```groovy
// Jenkinsfile
pipeline {
    agent any
    
    options {
        buildDiscarder(logRotator(numToKeepStr: '10'))
        timestamps()
        timeout(time: 1, unit: 'HOURS')
        disableConcurrentBuilds()
        skipDefaultCheckout()
    }
    
    environment {
        APP_NAME = 'myapp'
        APP_ENV = "${env.BRANCH_NAME == 'main' ? 'production' : 'staging'}"
        DOCKER_REGISTRY = 'registry.example.com'
        DOCKER_CREDENTIALS = credentials('docker-registry-creds')
        SLACK_WEBHOOK = credentials('slack-webhook')
    }
    
    parameters {
        string(name: 'VERSION', defaultValue: '1.0.0', description: 'Version to build')
        choice(name: 'ENVIRONMENT', choices: ['dev', 'staging', 'production'], description: 'Deployment environment')
        booleanParam(name: 'RUN_TESTS', defaultValue: true, description: 'Run tests?')
        text(name: 'RELEASE_NOTES', defaultValue: '', description: 'Release notes')
    }
    
    triggers {
        pollSCM('H/5 * * * *')
        cron('H 2 * * 1-5')
        upstream(upstreamProjects: 'upstream-job', threshold: hudson.model.Result.SUCCESS)
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.GIT_COMMIT_SHORT = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
                    env.GIT_BRANCH = sh(returnStdout: true, script: "git branch -r --contains ${env.GIT_COMMIT}").trim()
                }
            }
        }
        
        stage('Build') {
            steps {
                sh 'echo "Building ${APP_NAME} version ${VERSION}"'
                sh './gradlew clean build'
                stash includes: 'build/**', name: 'build-artifacts'
            }
        }
        
        stage('Test') {
            when {
                expression { params.RUN_TESTS == true }
            }
            parallel {
                stage('Unit Tests') {
                    steps {
                        sh './gradlew test'
                        junit 'build/test-results/**/*.xml'
                    }
                }
                stage('Integration Tests') {
                    steps {
                        sh './gradlew integrationTest'
                        junit 'build/test-results/**/*.xml'
                    }
                }
                stage('Code Quality') {
                    steps {
                        sh './gradlew sonarqube'
                        recordIssues(
                            enabledForFailure: true,
                            tools: [
                                java(),
                                checkStyle(pattern: 'build/reports/checkstyle/*.xml'),
                                spotBugs(pattern: 'build/reports/spotbugs/*.xml')
                            ]
                        )
                    }
                }
            }
        }
        
        stage('Security Scan') {
            steps {
                sh 'trivy scan --severity HIGH,CRITICAL .'
                dependencyCheck additionalArguments: '--scan ./', odcInstallation: 'dependency-check'
                publishHTML([
                    allowMissing: false,
                    alwaysLinkToLastBuild: true,
                    keepAll: true,
                    reportDir: 'build/reports',
                    reportFiles: 'dependency-check-report.html',
                    reportName: 'Dependency Check Report'
                ])
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    docker.withRegistry("https://${DOCKER_REGISTRY}", 'docker-credentials') {
                        def app = docker.build("${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}-${env.GIT_COMMIT_SHORT}")
                        app.push()
                        app.push('latest')
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                branch 'main'
            }
            steps {
                script {
                    def deployEnv = params.ENVIRONMENT
                    
                    if (deployEnv == 'production') {
                        input message: 'Deploy to production?', ok: 'Deploy'
                    }
                    
                    withCredentials([file(credentialsId: 'kubeconfig', variable: 'KUBECONFIG')]) {
                        sh """
                            kubectl set image deployment/${APP_NAME} \
                                ${APP_NAME}=${DOCKER_REGISTRY}/${APP_NAME}:${VERSION}-${env.GIT_COMMIT_SHORT} \
                                -n ${deployEnv}
                            kubectl rollout status deployment/${APP_NAME} -n ${deployEnv}
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
            archiveArtifacts artifacts: 'build/libs/**/*.jar', fingerprint: true, allowEmptyArchive: true
        }
        success {
            slackSend(
                color: 'good',
                message: "Build Successful: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
        }
        failure {
            slackSend(
                color: 'danger',
                message: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
            emailext(
                subject: "Build Failed: ${env.JOB_NAME} - ${env.BUILD_NUMBER}",
                body: "Build failed. Check console output at ${env.BUILD_URL}",
                to: 'team@example.com'
            )
        }
        unstable {
            slackSend(
                color: 'warning',
                message: "Build Unstable: ${env.JOB_NAME} - ${env.BUILD_NUMBER} (<${env.BUILD_URL}|Open>)"
            )
        }
    }
}
```

## Scripted Pipeline

### 1. Advanced Scripted Pipeline
```groovy
// Jenkinsfile (Scripted)
node {
    def app
    def dockerImage
    
    try {
        stage('Preparation') {
            // Clean workspace
            deleteDir()
            
            // Checkout code
            checkout scm
            
            // Load pipeline configuration
            def config = readYaml file: 'pipeline-config.yaml'
            env.APP_NAME = config.app.name
            env.VERSION = config.app.version
        }
        
        stage('Build') {
            // Use specific agent
            node('build-agent') {
                sh 'mvn clean package'
                stash includes: 'target/*.jar', name: 'app-jar'
            }
        }
        
        stage('Parallel Testing') {
            parallel(
                'Unit Tests': {
                    node('test-agent') {
                        unstash 'app-jar'
                        sh 'mvn test'
                        junit 'target/surefire-reports/*.xml'
                    }
                },
                'Performance Tests': {
                    node('performance-agent') {
                        unstash 'app-jar'
                        sh 'jmeter -n -t test.jmx -l results.jtl'
                        perfReport sourceDataFiles: 'results.jtl'
                    }
                },
                'Security Scan': {
                    node('security-agent') {
                        sh 'dependency-check.sh --scan .'
                    }
                }
            )
        }
        
        stage('Build Docker Image') {
            dockerImage = docker.build("${env.APP_NAME}:${env.VERSION}")
        }
        
        stage('Push to Registry') {
            docker.withRegistry('https://registry.example.com', 'docker-creds') {
                dockerImage.push()
                dockerImage.push('latest')
            }
        }
        
        stage('Deploy') {
            milestone(1)
            
            if (env.BRANCH_NAME == 'main') {
                timeout(time: 1, unit: 'HOURS') {
                    input message: 'Deploy to production?', ok: 'Deploy'
                }
                
                milestone(2)
                
                withCredentials([
                    string(credentialsId: 'aws-access-key', variable: 'AWS_ACCESS_KEY_ID'),
                    string(credentialsId: 'aws-secret-key', variable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    sh '''
                        aws ecs update-service \
                            --cluster production \
                            --service ${APP_NAME} \
                            --force-new-deployment
                    '''
                }
            }
        }
        
        currentBuild.result = 'SUCCESS'
    } catch (Exception e) {
        currentBuild.result = 'FAILURE'
        throw e
    } finally {
        // Notifications
        def status = currentBuild.result ?: 'SUCCESS'
        notifyBuild(status)
    }
}

def notifyBuild(String buildStatus) {
    def colorMap = [
        'SUCCESS': 'good',
        'FAILURE': 'danger',
        'UNSTABLE': 'warning'
    ]
    
    slackSend(
        color: colorMap[buildStatus],
        message: "${buildStatus}: Job '${env.JOB_NAME} [${env.BUILD_NUMBER}]' (${env.BUILD_URL})"
    )
}
```

## Shared Libraries

### 1. Library Structure
```
// vars/standardPipeline.groovy
def call(Map config) {
    pipeline {
        agent any
        
        stages {
            stage('Checkout') {
                steps {
                    checkout scm
                }
            }
            
            stage('Build') {
                steps {
                    script {
                        buildApp(config)
                    }
                }
            }
            
            stage('Test') {
                steps {
                    script {
                        testApp(config)
                    }
                }
            }
            
            stage('Deploy') {
                steps {
                    script {
                        deployApp(config)
                    }
                }
            }
        }
        
        post {
            always {
                notifyBuild(currentBuild.result)
            }
        }
    }
}

// src/com/example/jenkins/BuildUtils.groovy
package com.example.jenkins

class BuildUtils implements Serializable {
    def steps
    
    BuildUtils(steps) {
        this.steps = steps
    }
    
    def buildDocker(String imageName, String tag) {
        steps.sh "docker build -t ${imageName}:${tag} ."
        steps.sh "docker push ${imageName}:${tag}"
    }
    
    def runTests(String testCommand) {
        try {
            steps.sh testCommand
        } catch (Exception e) {
            steps.error "Tests failed: ${e.message}"
        }
    }
}
```

### 2. Using Shared Library
```groovy
@Library('jenkins-shared-library@main') _

standardPipeline {
    appName = 'myapp'
    buildTool = 'maven'
    deployEnvironment = 'production'
}
```

## Configuration as Code (JCasC)

### 1. Jenkins Configuration
```yaml
# jenkins-config/casc.yaml
jenkins:
  systemMessage: "Jenkins - Managed by Configuration as Code"
  numExecutors: 2
  mode: NORMAL
  
  securityRealm:
    ldap:
      configurations:
        - server: ldap.example.com
          rootDN: dc=example,dc=com
          userSearchBase: ou=users
          userSearch: uid={0}
          groupSearchBase: ou=groups
  
  authorizationStrategy:
    roleBased:
      roles:
        global:
          - name: "admin"
            permissions:
              - "Overall/Administer"
            assignments:
              - "admin-group"
          - name: "developer"
            permissions:
              - "Overall/Read"
              - "Job/Build"
              - "Job/Cancel"
            assignments:
              - "dev-group"
  
  clouds:
    - kubernetes:
        name: "kubernetes"
        serverUrl: "https://kubernetes.default"
        namespace: "jenkins"
        jenkinsUrl: "http://jenkins:8080"
        templates:
          - name: "maven"
            label: "maven"
            containers:
              - name: "maven"
                image: "maven:3.8-openjdk-11"
                command: "sleep"
                args: "99999"
          - name: "docker"
            label: "docker"
            containers:
              - name: "docker"
                image: "docker:dind"
                privileged: true

credentials:
  system:
    domainCredentials:
      - credentials:
          - usernamePassword:
              id: "github-credentials"
              username: "${GITHUB_USER}"
              password: "${GITHUB_TOKEN}"
              description: "GitHub credentials"
          - string:
              id: "slack-token"
              secret: "${SLACK_TOKEN}"
              description: "Slack token"
          - file:
              id: "kubeconfig"
              fileName: "kubeconfig"
              secretBytes: "${KUBECONFIG_BASE64}"

unclassified:
  location:
    url: "https://jenkins.example.com/"
  
  gitHubPluginConfig:
    configs:
      - credentialsId: "github-credentials"
        name: "GitHub"
  
  slackNotifier:
    teamDomain: "example"
    tokenCredentialId: "slack-token"
    room: "#ci-cd"

jobs:
  - script: >
      pipelineJob('seed-job') {
        definition {
          cps {
            script('''
              pipeline {
                agent any
                stages {
                  stage('Seed Jobs') {
                    steps {
                      jobDsl targets: 'jobs/**/*.groovy'
                    }
                  }
                }
              }
            ''')
          }
        }
      }
```

## Job DSL

### 1. Creating Jobs Programmatically
```groovy
// jobs/application-jobs.groovy
def environments = ['dev', 'staging', 'production']
def applications = ['frontend', 'backend', 'api']

applications.each { app ->
    environments.each { env ->
        pipelineJob("${app}-${env}") {
            description("Deploy ${app} to ${env}")
            
            parameters {
                stringParam('VERSION', 'latest', 'Version to deploy')
                booleanParam('DRY_RUN', false, 'Perform dry run')
            }
            
            triggers {
                if (env == 'dev') {
                    scm('H/5 * * * *')
                }
            }
            
            definition {
                cpsScm {
                    scm {
                        git {
                            remote {
                                url("https://github.com/example/${app}.git")
                                credentials('github-credentials')
                            }
                            branch('*/main')
                        }
                    }
                    scriptPath('Jenkinsfile')
                }
            }
            
            properties {
                buildDiscarder {
                    strategy {
                        logRotator {
                            daysToKeepStr('30')
                            numToKeepStr('10')
                            artifactDaysToKeepStr('7')
                            artifactNumToKeepStr('5')
                        }
                    }
                }
            }
        }
    }
}

// Create a multibranch pipeline
multibranchPipelineJob('app-multibranch') {
    branchSources {
        github {
            id('github')
            scanCredentialsId('github-credentials')
            repoOwner('example')
            repository('app')
        }
    }
    
    orphanedItemStrategy {
        discardOldItems {
            numToKeep(10)
        }
    }
    
    triggers {
        periodic(5)
    }
}

// Create a folder
folder('infrastructure') {
    description('Infrastructure related jobs')
}

// Create a view
listView('Deploy Jobs') {
    jobs {
        regex('.*-deploy')
    }
    columns {
        status()
        weather()
        name()
        lastSuccess()
        lastFailure()
        lastDuration()
        buildButton()
    }
}
```

## Docker Setup

### 1. Jenkins Master Dockerfile
```dockerfile
# docker/master/Dockerfile
FROM jenkins/jenkins:lts

USER root

# Install additional tools
RUN apt-get update && apt-get install -y \
    docker.io \
    kubectl \
    helm \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install AWS CLI
RUN pip3 install awscli

# Install plugins
COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN jenkins-plugin-cli --plugins < /usr/share/jenkins/ref/plugins.txt

# Copy configuration
COPY casc.yaml /var/jenkins_home/casc.yaml
ENV CASC_JENKINS_CONFIG=/var/jenkins_home/casc.yaml

USER jenkins
```

### 2. Docker Compose
```yaml
# docker-compose.yml
version: '3.8'

services:
  jenkins:
    build: ./docker/master
    container_name: jenkins
    restart: unless-stopped
    ports:
      - "8080:8080"
      - "50000:50000"
    volumes:
      - jenkins_home:/var/jenkins_home
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - JENKINS_OPTS=--prefix=/jenkins
      - JAVA_OPTS=-Djenkins.install.runSetupWizard=false
    networks:
      - jenkins

  jenkins-agent:
    build: ./docker/agent
    container_name: jenkins-agent
    restart: unless-stopped
    environment:
      - JENKINS_URL=http://jenkins:8080
      - JENKINS_SECRET=${JENKINS_SECRET}
      - JENKINS_AGENT_NAME=docker-agent
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    networks:
      - jenkins

volumes:
  jenkins_home:

networks:
  jenkins:
    driver: bridge
```

## Pipeline Templates

### 1. Node.js Application
```groovy
// pipelines/nodejs-pipeline.groovy
pipeline {
    agent {
        docker {
            image 'node:16-alpine'
            args '-v /var/run/docker.sock:/var/run/docker.sock'
        }
    }
    
    stages {
        stage('Install Dependencies') {
            steps {
                sh 'npm ci'
                sh 'npm audit fix --audit-level=moderate'
            }
        }
        
        stage('Lint') {
            steps {
                sh 'npm run lint'
            }
        }
        
        stage('Test') {
            steps {
                sh 'npm test -- --coverage'
                publishHTML([
                    reportDir: 'coverage',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
        
        stage('Build') {
            steps {
                sh 'npm run build'
                archiveArtifacts artifacts: 'dist/**', fingerprint: true
            }
        }
        
        stage('Security Scan') {
            steps {
                sh 'npm audit --json > npm-audit.json'
                sh 'npx snyk test --json > snyk-report.json || true'
            }
        }
    }
}
```

### 2. Python Application
```groovy
// pipelines/python-pipeline.groovy
pipeline {
    agent any
    
    stages {
        stage('Setup Python Environment') {
            steps {
                sh '''
                    python3 -m venv venv
                    . venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    pip install -r requirements-dev.txt
                '''
            }
        }
        
        stage('Lint') {
            steps {
                sh '''
                    . venv/bin/activate
                    flake8 src/
                    black --check src/
                    mypy src/
                '''
            }
        }
        
        stage('Test') {
            steps {
                sh '''
                    . venv/bin/activate
                    pytest tests/ \
                        --junitxml=test-results/junit.xml \
                        --cov=src \
                        --cov-report=html \
                        --cov-report=term
                '''
                junit 'test-results/junit.xml'
                publishHTML([
                    reportDir: 'htmlcov',
                    reportFiles: 'index.html',
                    reportName: 'Coverage Report'
                ])
            }
        }
        
        stage('Security Scan') {
            steps {
                sh '''
                    . venv/bin/activate
                    safety check --json > safety-report.json
                    bandit -r src/ -f json -o bandit-report.json
                '''
            }
        }
    }
}
```

## Monitoring and Maintenance

### 1. Groovy Script for Maintenance
```groovy
// scripts/maintenance.groovy
import jenkins.model.*
import hudson.model.*

def jenkins = Jenkins.getInstance()

// Clean up old builds
jenkins.getAllItems(Job.class).each { job ->
    job.getBuilds().each { build ->
        if (build.getTimeInMillis() < System.currentTimeMillis() - 30L * 24 * 60 * 60 * 1000) {
            println "Deleting old build: ${build}"
            build.delete()
        }
    }
}

// Disable jobs that haven't run in 60 days
jenkins.getAllItems(Job.class).each { job ->
    def lastBuild = job.getLastBuild()
    if (lastBuild && lastBuild.getTimeInMillis() < System.currentTimeMillis() - 60L * 24 * 60 * 60 * 1000) {
        println "Disabling inactive job: ${job.name}"
        job.disable()
    }
}

// Clean workspace
jenkins.getAllItems(Job.class).each { job ->
    if (job.hasProperty('customWorkspace')) {
        def workspace = job.getCustomWorkspace()
        if (workspace && workspace.exists()) {
            println "Cleaning workspace for ${job.name}"
            workspace.deleteRecursive()
        }
    }
}
```

### 2. Backup Script
```bash
#!/bin/bash
# scripts/backup.sh

JENKINS_HOME="/var/jenkins_home"
BACKUP_DIR="/backup/jenkins"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="jenkins_backup_${DATE}.tar.gz"

# Create backup directory
mkdir -p ${BACKUP_DIR}

# Stop Jenkins (optional for consistency)
# systemctl stop jenkins

# Create backup
tar -czf ${BACKUP_DIR}/${BACKUP_FILE} \
    --exclude='${JENKINS_HOME}/workspace' \
    --exclude='${JENKINS_HOME}/logs' \
    --exclude='${JENKINS_HOME}/.cache' \
    ${JENKINS_HOME}

# Start Jenkins if stopped
# systemctl start jenkins

# Upload to S3 (optional)
aws s3 cp ${BACKUP_DIR}/${BACKUP_FILE} s3://backup-bucket/jenkins/

# Clean old backups (keep last 7)
ls -t ${BACKUP_DIR}/jenkins_backup_*.tar.gz | tail -n +8 | xargs rm -f

echo "Backup completed: ${BACKUP_FILE}"
```

## Best Practices Summary

### Do's ✅
- Use Pipeline as Code (Jenkinsfile)
- Implement Configuration as Code (JCasC)
- Use shared libraries for reusable code
- Set up proper authentication and authorization
- Use credentials management properly
- Implement proper build rotation
- Use agents for scalability
- Version control all configurations
- Implement proper monitoring
- Regular backups

### Don'ts ❌
- Don't hardcode credentials
- Don't run builds on master node
- Don't ignore security updates
- Don't use outdated plugins
- Don't skip test stages
- Don't use shell scripts for complex logic
- Don't ignore build failures
- Don't keep unlimited build history
- Don't use freestyle jobs for complex workflows
- Don't expose Jenkins without authentication

## Additional Resources
- **Blue Ocean UI**: https://www.jenkins.io/projects/blueocean/
- **Jenkins X**: https://jenkins-x.io/
- **Jenkins Kubernetes Plugin**: https://plugins.jenkins.io/kubernetes/
- **Jenkins Configuration as Code Plugin**: https://plugins.jenkins.io/configuration-as-code/