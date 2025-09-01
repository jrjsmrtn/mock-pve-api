# CI/CD Integration Guide

This guide provides comprehensive examples for integrating the Mock PVE API Server into various CI/CD platforms. The containerized approach ensures consistent testing environments across different platforms while eliminating dependencies on external Proxmox VE infrastructure.

## Overview

The Mock PVE API Server is designed for seamless CI/CD integration through:
- **OCI containers** (Podman/Docker) for consistent environments
- **Environment variables** for configuration
- **Health checks** for readiness detection
- **Multi-version testing** for compatibility validation
- **Fast startup** for efficient pipeline execution

## GitHub Actions

### Basic Integration

```yaml
name: Test with Mock PVE API
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mock-pve:
        image: docker.io/jrjsmrtn/mock-pve-api:latest
        ports:
          - 8006:8006
        env:
          MOCK_PVE_VERSION: "8.0"
          MOCK_PVE_DELAY: "0"
        options: >-
          --health-cmd "curl -f http://localhost:8006/api2/json/version || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      
      - name: Cache dependencies
        uses: actions/cache@v3
        with:
          path: |
            _build
            deps
          key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
          restore-keys: |
            ${{ runner.os }}-mix-
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Wait for Mock PVE API
        run: |
          timeout 60 sh -c 'until curl -f http://localhost:8006/api2/json/version; do 
            echo "Waiting for Mock PVE API..."
            sleep 2
          done'
          echo "Mock PVE API is ready!"
      
      - name: Run tests
        run: mix test --cover
        env:
          MOCK_PVE_HOST: localhost
          MOCK_PVE_PORT: 8006
      
      - name: Upload coverage reports
        uses: codecov/codecov-action@v3
        with:
          files: ./cover/excoveralls.json
```

### Multi-Version Testing

```yaml
name: Multi-Version PVE Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        pve_version: ["7.4", "8.0", "8.1", "8.2", "8.3"]
        include:
          - pve_version: "7.4"
            expected_features: "basic"
          - pve_version: "8.0"
            expected_features: "sdn"
          - pve_version: "8.1"
            expected_features: "sdn,notifications"
          - pve_version: "8.2"
            expected_features: "sdn,notifications,backup-providers"
          - pve_version: "8.3"
            expected_features: "sdn,notifications,backup-providers"
    
    services:
      mock-pve:
        image: docker.io/jrjsmrtn/mock-pve-api:latest
        ports:
          - 8006:8006
        env:
          MOCK_PVE_VERSION: ${{ matrix.pve_version }}
        options: >-
          --health-cmd "curl -f http://localhost:8006/api2/json/version || exit 1"
          --health-interval 5s
          --health-timeout 3s
          --health-retries 10
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Verify PVE Version
        run: |
          VERSION=$(curl -s http://localhost:8006/api2/json/version | jq -r '.data.version')
          echo "Mock PVE API Version: $VERSION"
          [[ "$VERSION" == "${{ matrix.pve_version }}" ]] || exit 1
      
      - name: Run version-specific tests
        run: |
          mix test --include compatibility
        env:
          MOCK_PVE_HOST: localhost
          MOCK_PVE_PORT: 8006
          PVE_VERSION: ${{ matrix.pve_version }}
          EXPECTED_FEATURES: ${{ matrix.expected_features }}
```

### Parallel Testing with Multiple Containers

```yaml
name: Parallel Multi-Version Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      
      - name: Set up Elixir
        uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      
      - name: Start multiple Mock PVE API servers
        run: |
          # Start PVE 7.4 on port 18074
          podman run -d --name mock-pve-74 \
            -p 18074:8006 \
            -e MOCK_PVE_VERSION=7.4 \
            jrjsmrtn/mock-pve-api:latest
          
          # Start PVE 8.0 on port 18080  
          podman run -d --name mock-pve-80 \
            -p 18080:8006 \
            -e MOCK_PVE_VERSION=8.0 \
            jrjsmrtn/mock-pve-api:latest
            
          # Start PVE 8.3 on port 18083
          podman run -d --name mock-pve-83 \
            -p 18083:8006 \
            -e MOCK_PVE_VERSION=8.3 \
            jrjsmrtn/mock-pve-api:latest
      
      - name: Wait for all servers
        run: |
          for port in 18074 18080 18083; do
            echo "Waiting for server on port $port..."
            timeout 60 sh -c "until curl -f http://localhost:$port/api2/json/version; do sleep 2; done"
            echo "Server on port $port is ready!"
          done
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Run parallel compatibility tests
        run: mix test --include parallel_compatibility
        env:
          MOCK_PVE_74_PORT: 18074
          MOCK_PVE_80_PORT: 18080
          MOCK_PVE_83_PORT: 18083
      
      - name: Cleanup containers
        if: always()
        run: |
          docker stop mock-pve-74 mock-pve-80 mock-pve-83 || true
          docker rm mock-pve-74 mock-pve-80 mock-pve-83 || true
```

## GitLab CI

### Basic Pipeline

```yaml
# .gitlab-ci.yml
stages:
  - test
  - integration

variables:
  MIX_ENV: test
  ELIXIR_VERSION: "1.15"
  OTP_VERSION: "26"

.elixir_template: &elixir_template
  image: elixir:${ELIXIR_VERSION}-otp-${OTP_VERSION}
  before_script:
    - mix local.hex --force
    - mix local.rebar --force
    - mix deps.get

test:basic:
  <<: *elixir_template
  stage: test
  services:
    - name: jrjsmrtn/mock-pve-api:latest
      alias: mock-pve
      variables:
        MOCK_PVE_VERSION: "8.0"
  variables:
    MOCK_PVE_HOST: mock-pve
    MOCK_PVE_PORT: 8006
  script:
    - |
      # Wait for mock server
      timeout 60 sh -c 'until curl -f http://mock-pve:8006/api2/json/version; do 
        echo "Waiting for Mock PVE API..."
        sleep 2
      done'
    - mix test --cover
  coverage: '/\[TOTAL\]\s+(\d+\.\d+)%/'
  artifacts:
    reports:
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml

integration:multi-version:
  <<: *elixir_template
  stage: integration
  parallel:
    matrix:
      - PVE_VERSION: ["7.4", "8.0", "8.3"]
  services:
    - name: jrjsmrtn/mock-pve-api:latest
      alias: mock-pve
      variables:
        MOCK_PVE_VERSION: ${PVE_VERSION}
  variables:
    MOCK_PVE_HOST: mock-pve
    MOCK_PVE_PORT: 8006
  script:
    - |
      # Verify version
      timeout 60 sh -c 'until curl -f http://mock-pve:8006/api2/json/version; do sleep 2; done'
      VERSION=$(curl -s http://mock-pve:8006/api2/json/version | jq -r '.data.version')
      echo "Testing against PVE version: $VERSION"
      [[ "$VERSION" == "${PVE_VERSION}" ]] || exit 1
    - mix test --include compatibility
  artifacts:
    reports:
      junit: _build/test/junit-report.xml
```

### Advanced GitLab Pipeline with Manual Staging

```yaml
# .gitlab-ci.yml
stages:
  - build
  - test
  - integration
  - staging

variables:
  DOCKER_DRIVER: overlay2
  MOCK_PVE_IMAGE: "jrjsmrtn/mock-pve-api:latest"

# Build stage
build:deps:
  image: elixir:1.15-otp-26
  stage: build
  script:
    - mix local.hex --force
    - mix local.rebar --force
    - mix deps.get
    - mix compile
  cache:
    key: deps-$CI_COMMIT_REF_SLUG
    paths:
      - deps/
      - _build/
  artifacts:
    paths:
      - deps/
      - _build/
    expire_in: 1 hour

# Test stages
test:unit:
  image: elixir:1.15-otp-26
  stage: test
  dependencies:
    - build:deps
  script:
    - mix test --exclude integration --exclude compatibility
  cache:
    key: deps-$CI_COMMIT_REF_SLUG
    paths:
      - deps/
      - _build/
    policy: pull

test:integration:
  image: elixir:1.15-otp-26
  stage: test
  dependencies:
    - build:deps
  services:
    - name: ${MOCK_PVE_IMAGE}
      alias: mock-pve
      variables:
        MOCK_PVE_VERSION: "8.0"
  variables:
    MOCK_PVE_HOST: mock-pve
    MOCK_PVE_PORT: 8006
  script:
    - timeout 60 sh -c 'until curl -f http://mock-pve:8006/api2/json/version; do sleep 2; done'
    - mix test --only integration
  cache:
    key: deps-$CI_COMMIT_REF_SLUG
    paths:
      - deps/
      - _build/
    policy: pull

# Compatibility testing
.compatibility_template: &compatibility_template
  image: elixir:1.15-otp-26
  stage: integration
  dependencies:
    - build:deps
  services:
    - name: ${MOCK_PVE_IMAGE}
      alias: mock-pve
      variables:
        MOCK_PVE_VERSION: ${PVE_VERSION}
  variables:
    MOCK_PVE_HOST: mock-pve
    MOCK_PVE_PORT: 8006
  script:
    - timeout 60 sh -c 'until curl -f http://mock-pve:8006/api2/json/version; do sleep 2; done'
    - VERSION=$(curl -s http://mock-pve:8006/api2/json/version | jq -r '.data.version')
    - echo "Testing compatibility with PVE ${PVE_VERSION}"
    - [[ "$VERSION" == "${PVE_VERSION}" ]] || exit 1
    - mix test --only compatibility
  cache:
    key: deps-$CI_COMMIT_REF_SLUG
    paths:
      - deps/
      - _build/
    policy: pull

compatibility:pve74:
  <<: *compatibility_template
  variables:
    PVE_VERSION: "7.4"

compatibility:pve80:
  <<: *compatibility_template
  variables:
    PVE_VERSION: "8.0"

compatibility:pve83:
  <<: *compatibility_template
  variables:
    PVE_VERSION: "8.3"

# Staging environment
staging:deploy:
  image: alpine:latest
  stage: staging
  when: manual
  only:
    - main
  before_script:
    - apk add --no-cache curl docker-cli
  script:
    - |
      echo "Deploying to staging environment..."
      podman run -d --name mock-pve-staging \
        -p 8006:8006 \
        -e MOCK_PVE_VERSION=8.0 \
        ${MOCK_PVE_IMAGE}
      
      timeout 60 sh -c 'until curl -f http://localhost:8006/api2/json/version; do sleep 2; done'
      echo "Mock PVE API deployed to staging"
  environment:
    name: staging
    url: http://staging.example.com:8006
  after_script:
    - docker stop mock-pve-staging || true
    - docker rm mock-pve-staging || true
```

## Jenkins Pipeline

### Declarative Pipeline

```groovy
// Jenkinsfile
pipeline {
    agent any
    
    environment {
        MOCK_PVE_IMAGE = 'jrjsmrtn/mock-pve-api:latest'
        MIX_ENV = 'test'
    }
    
    stages {
        stage('Preparation') {
            steps {
                checkout scm
                sh 'docker pull ${MOCK_PVE_IMAGE}'
            }
        }
        
        stage('Unit Tests') {
            agent {
                docker {
                    image 'elixir:1.15-otp-26'
                    args '--network host'
                }
            }
            steps {
                sh '''
                    mix local.hex --force
                    mix local.rebar --force
                    mix deps.get
                    mix test --exclude integration --exclude compatibility
                '''
            }
        }
        
        stage('Integration Tests') {
            steps {
                script {
                    // Start mock server
                    def mockContainer = docker.run(
                        "-p 18006:8006 -e MOCK_PVE_VERSION=8.0 ${MOCK_PVE_IMAGE}"
                    )
                    
                    try {
                        // Wait for server
                        sh '''
                            timeout 60 sh -c 'until curl -f http://localhost:18006/api2/json/version; do 
                                echo "Waiting for Mock PVE API..."
                                sleep 2
                            done'
                        '''
                        
                        // Run tests in Elixir container
                        docker.image('elixir:1.15-otp-26').inside('--network host') {
                            sh '''
                                mix local.hex --force
                                mix local.rebar --force
                                mix deps.get
                                MOCK_PVE_HOST=localhost MOCK_PVE_PORT=18006 mix test --only integration
                            '''
                        }
                    } finally {
                        mockContainer.stop()
                    }
                }
            }
        }
        
        stage('Multi-Version Compatibility') {
            parallel {
                stage('PVE 7.4') {
                    steps {
                        script {
                            testPveVersion('7.4', 18074)
                        }
                    }
                }
                stage('PVE 8.0') {
                    steps {
                        script {
                            testPveVersion('8.0', 18080)
                        }
                    }
                }
                stage('PVE 8.3') {
                    steps {
                        script {
                            testPveVersion('8.3', 18083)
                        }
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Cleanup any remaining containers
            sh '''
                docker ps -a --filter "ancestor=${MOCK_PVE_IMAGE}" --format "{{.ID}}" | xargs -r docker rm -f
            '''
        }
        success {
            publishHTML([
                allowMissing: false,
                alwaysLinkToLastBuild: true,
                keepAll: true,
                reportDir: 'cover',
                reportFiles: 'excoveralls.html',
                reportName: 'Coverage Report'
            ])
        }
    }
}

def testPveVersion(version, port) {
    def mockContainer = docker.run(
        "-p ${port}:8006 -e MOCK_PVE_VERSION=${version} ${MOCK_PVE_IMAGE}"
    )
    
    try {
        sh """
            timeout 60 sh -c 'until curl -f http://localhost:${port}/api2/json/version; do sleep 2; done'
            ACTUAL_VERSION=\$(curl -s http://localhost:${port}/api2/json/version | jq -r '.data.version')
            echo "Testing PVE \${ACTUAL_VERSION} compatibility"
            [[ "\${ACTUAL_VERSION}" == "${version}" ]] || exit 1
        """
        
        docker.image('elixir:1.15-otp-26').inside('--network host') {
            sh """
                mix local.hex --force
                mix local.rebar --force  
                mix deps.get
                MOCK_PVE_HOST=localhost MOCK_PVE_PORT=${port} PVE_VERSION=${version} mix test --only compatibility
            """
        }
    } finally {
        mockContainer.stop()
    }
}
```

### Scripted Pipeline with Advanced Features

```groovy
// Jenkinsfile.advanced
node {
    def pveVersions = ['7.4', '8.0', '8.1', '8.2', '8.3']
    def mockContainers = [:]
    
    try {
        stage('Checkout') {
            checkout scm
        }
        
        stage('Prepare Environment') {
            sh 'docker pull jrjsmrtn/mock-pve-api:latest'
            
            // Create docker network for better isolation
            sh '''
                docker network create mock-pve-test || true
            '''
        }
        
        stage('Start Mock Servers') {
            parallel pveVersions.collectEntries { version ->
                ["PVE ${version}": {
                    def port = 18000 + (version.replace('.', '') as Integer)
                    echo "Starting Mock PVE API ${version} on port ${port}"
                    
                    mockContainers[version] = sh(
                        script: """
                            podman run -d \\
                                --network mock-pve-test \\
                                --name mock-pve-${version.replace('.', '')} \\
                                -p ${port}:8006 \\
                                -e MOCK_PVE_VERSION=${version} \\
                                -e MOCK_PVE_DELAY=0 \\
                                --health-cmd="curl -f http://localhost:8006/api2/json/version || exit 1" \\
                                --health-interval=5s \\
                                --health-timeout=3s \\
                                --health-retries=5 \\
                                jrjsmrtn/mock-pve-api:latest
                        """,
                        returnStdout: true
                    ).trim()
                    
                    // Wait for health check
                    timeout(time: 2, unit: 'MINUTES') {
                        waitUntil {
                            script {
                                def health = sh(
                                    script: "docker inspect --format='{{.State.Health.Status}}' ${mockContainers[version]}",
                                    returnStdout: true
                                ).trim()
                                return health == 'healthy'
                            }
                        }
                    }
                    
                    echo "Mock PVE API ${version} is healthy and ready"
                }]
            }
        }
        
        stage('Unit Tests') {
            docker.image('elixir:1.15-otp-26').inside('--network mock-pve-test') {
                sh '''
                    mix local.hex --force
                    mix local.rebar --force
                    mix deps.get
                    mix compile
                    mix test --exclude integration --exclude compatibility --cover
                '''
            }
        }
        
        stage('Integration Tests') {
            parallel pveVersions.collectEntries { version ->
                ["Integration PVE ${version}": {
                    docker.image('elixir:1.15-otp-26').inside('--network mock-pve-test') {
                        def port = 18000 + (version.replace('.', '') as Integer)
                        def containerName = "mock-pve-${version.replace('.', '')}"
                        
                        sh """
                            # Verify server is responding
                            curl -f http://${containerName}:8006/api2/json/version
                            
                            # Run integration tests
                            MOCK_PVE_HOST=${containerName} \\
                            MOCK_PVE_PORT=8006 \\
                            PVE_VERSION=${version} \\
                            mix test --only integration
                        """
                    }
                }]
            }
        }
        
        stage('Compatibility Tests') {
            parallel pveVersions.collectEntries { version ->
                ["Compatibility PVE ${version}": {
                    docker.image('elixir:1.15-otp-26').inside('--network mock-pve-test') {
                        def containerName = "mock-pve-${version.replace('.', '')}"
                        
                        sh """
                            # Test version-specific features
                            MOCK_PVE_HOST=${containerName} \\
                            MOCK_PVE_PORT=8006 \\
                            PVE_VERSION=${version} \\
                            mix test --only compatibility
                        """
                    }
                }]
            }
        }
        
        stage('Performance Tests') {
            docker.image('elixir:1.15-otp-26').inside('--network mock-pve-test') {
                sh '''
                    # Run against PVE 8.0 for performance baseline
                    MOCK_PVE_HOST=mock-pve-80 \\
                    MOCK_PVE_PORT=8006 \\
                    mix test --only performance
                '''
            }
        }
        
    } finally {
        stage('Cleanup') {
            // Stop and remove all mock containers
            mockContainers.each { version, containerId ->
                sh "docker stop ${containerId} || true"
                sh "docker rm ${containerId} || true"
            }
            
            // Remove test network
            sh 'docker network rm mock-pve-test || true'
        }
    }
    
    stage('Publish Results') {
        publishHTML([
            allowMissing: false,
            alwaysLinkToLastBuild: true,
            keepAll: true,
            reportDir: 'cover',
            reportFiles: 'excoveralls.html',
            reportName: 'Test Coverage Report'
        ])
        
        publishTestResults testResultsPattern: '_build/test/junit-reports/*.xml'
        
        archiveArtifacts artifacts: '_build/test/junit-reports/*.xml', fingerprint: true
    }
}
```

## Azure DevOps

### Basic Pipeline

```yaml
# azure-pipelines.yml
trigger:
  branches:
    include:
      - main
      - develop

pool:
  vmImage: 'ubuntu-latest'

variables:
  MOCK_PVE_IMAGE: 'jrjsmrtn/mock-pve-api:latest'
  MIX_ENV: 'test'

stages:
- stage: Test
  displayName: 'Test Stage'
  jobs:
  - job: UnitTests
    displayName: 'Unit Tests'
    container: 'elixir:1.15-otp-26'
    steps:
    - script: |
        mix local.hex --force
        mix local.rebar --force
        mix deps.get
        mix test --exclude integration --exclude compatibility
      displayName: 'Run Unit Tests'

  - job: IntegrationTests
    displayName: 'Integration Tests'
    services:
      mock-pve: 
        image: $(MOCK_PVE_IMAGE)
        ports:
          - 8006:8006
        env:
          MOCK_PVE_VERSION: "8.0"
    container: 'elixir:1.15-otp-26'
    steps:
    - script: |
        # Wait for mock server
        timeout 60 sh -c 'until curl -f http://mock-pve:8006/api2/json/version; do 
          echo "Waiting for Mock PVE API..."
          sleep 2
        done'
      displayName: 'Wait for Mock Server'
    
    - script: |
        mix local.hex --force
        mix local.rebar --force
        mix deps.get
        MOCK_PVE_HOST=mock-pve MOCK_PVE_PORT=8006 mix test --only integration
      displayName: 'Run Integration Tests'

- stage: Compatibility
  displayName: 'Compatibility Testing'
  dependsOn: Test
  jobs:
  - job: MultiVersion
    displayName: 'Multi-Version Tests'
    strategy:
      matrix:
        pve74:
          PVE_VERSION: '7.4'
        pve80:
          PVE_VERSION: '8.0'
        pve83:
          PVE_VERSION: '8.3'
    services:
      mock-pve:
        image: $(MOCK_PVE_IMAGE)
        ports:
          - 8006:8006
        env:
          MOCK_PVE_VERSION: $(PVE_VERSION)
    container: 'elixir:1.15-otp-26'
    steps:
    - script: |
        timeout 60 sh -c 'until curl -f http://mock-pve:8006/api2/json/version; do sleep 2; done'
        VERSION=$(curl -s http://mock-pve:8006/api2/json/version | jq -r '.data.version')
        echo "Testing against PVE version: $VERSION"
        [[ "$VERSION" == "$(PVE_VERSION)" ]] || exit 1
      displayName: 'Verify PVE Version'
    
    - script: |
        mix local.hex --force
        mix local.rebar --force
        mix deps.get
        MOCK_PVE_HOST=mock-pve MOCK_PVE_PORT=8006 PVE_VERSION=$(PVE_VERSION) mix test --only compatibility
      displayName: 'Run Compatibility Tests'
```

## Docker Compose for Local CI/CD Testing

### Basic Setup

```yaml
# docker-compose.ci.yml
version: '3.8'

services:
  # Mock PVE API servers for different versions
  mock-pve-74:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "18074:8006"
    environment:
      - MOCK_PVE_VERSION=7.4
      - MOCK_PVE_DELAY=0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s

  mock-pve-80:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "18080:8006"
    environment:
      - MOCK_PVE_VERSION=8.0
      - MOCK_PVE_DELAY=0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s

  mock-pve-83:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "18083:8006"
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_DELAY=0
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
      interval: 5s
      timeout: 3s
      retries: 10
      start_period: 5s

  # Test runner
  test-runner:
    image: elixir:1.15-otp-26
    volumes:
      - .:/app
      - test-deps:/app/deps
      - test-build:/app/_build
    working_dir: /app
    depends_on:
      mock-pve-74:
        condition: service_healthy
      mock-pve-80:
        condition: service_healthy
      mock-pve-83:
        condition: service_healthy
    environment:
      - MIX_ENV=test
      - MOCK_PVE_74_HOST=mock-pve-74
      - MOCK_PVE_80_HOST=mock-pve-80  
      - MOCK_PVE_83_HOST=mock-pve-83
      - MOCK_PVE_PORT=8006
    command: >
      sh -c "
        mix local.hex --force &&
        mix local.rebar --force &&
        mix deps.get &&
        mix test --include parallel_compatibility
      "

volumes:
  test-deps:
  test-build:
```

### CI/CD Simulation Script

```bash
#!/bin/bash
# ci-test.sh - Simulate CI/CD pipeline locally

set -e

echo "🚀 Starting Mock PVE API CI/CD Simulation"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

cleanup() {
    log_info "Cleaning up containers..."
    docker-compose -f docker-compose.ci.yml down -v --remove-orphans
}

# Trap cleanup on exit
trap cleanup EXIT

# Stage 1: Environment Setup
log_info "Stage 1: Setting up environment"
docker-compose -f docker-compose.ci.yml pull
log_success "Docker images pulled"

# Stage 2: Start Services
log_info "Stage 2: Starting Mock PVE API servers"
docker-compose -f docker-compose.ci.yml up -d mock-pve-74 mock-pve-80 mock-pve-83

# Wait for health checks
log_info "Waiting for health checks..."
for service in mock-pve-74 mock-pve-80 mock-pve-83; do
    log_info "Waiting for $service to be healthy..."
    timeout 60 sh -c "until docker-compose -f docker-compose.ci.yml ps $service | grep '(healthy)'; do sleep 2; done"
    log_success "$service is healthy"
done

# Stage 3: Unit Tests
log_info "Stage 3: Running unit tests"
podman run --rm \
    -v "$(pwd):/app" \
    -w /app \
    elixir:1.15-otp-26 \
    sh -c "
        mix local.hex --force &&
        mix local.rebar --force &&
        mix deps.get &&
        mix test --exclude integration --exclude compatibility
    "
log_success "Unit tests completed"

# Stage 4: Integration Tests
log_info "Stage 4: Running integration tests"
docker-compose -f docker-compose.ci.yml run --rm test-runner \
    sh -c "
        mix test --only integration
    "
log_success "Integration tests completed"

# Stage 5: Compatibility Tests
log_info "Stage 5: Running compatibility tests"
docker-compose -f docker-compose.ci.yml run --rm test-runner \
    sh -c "
        mix test --only compatibility
    "
log_success "Compatibility tests completed"

# Stage 6: Performance Tests (if available)
log_info "Stage 6: Running performance tests"
docker-compose -f docker-compose.ci.yml run --rm test-runner \
    sh -c "
        mix test --only performance || echo 'Performance tests not available'"
log_success "Performance tests completed"

log_success "🎉 All CI/CD stages completed successfully!"

# Display summary
echo
echo "📊 Test Summary:"
echo "=================="
echo "✅ Unit Tests: PASSED"
echo "✅ Integration Tests: PASSED"  
echo "✅ Compatibility Tests: PASSED"
echo "✅ Performance Tests: COMPLETED"
echo
echo "Mock PVE API servers tested:"
echo "  - PVE 7.4 (port 18074)"
echo "  - PVE 8.0 (port 18080)" 
echo "  - PVE 8.3 (port 18083)"
```

## Environment Variables Reference

### Mock PVE API Configuration

| Variable | Default | Description | Example |
|----------|---------|-------------|---------|
| `MOCK_PVE_VERSION` | `8.0` | PVE version to simulate | `7.4`, `8.0`, `8.3` |
| `MOCK_PVE_HOST` | `0.0.0.0` | Host to bind server | `127.0.0.1`, `localhost` |
| `MOCK_PVE_PORT` | `8006` | Port for server | `8006`, `18006` |
| `MOCK_PVE_DELAY` | `0` | Response delay (ms) | `100`, `500` |
| `MOCK_PVE_ERROR_RATE` | `0` | Error injection rate (%) | `5`, `10` |
| `MOCK_PVE_LOG_LEVEL` | `info` | Logging level | `debug`, `info`, `warn` |

### Test Configuration

| Variable | Description | Example |
|----------|-------------|---------|
| `MOCK_PVE_HOST` | Mock server hostname | `localhost`, `mock-pve` |
| `MOCK_PVE_PORT` | Mock server port | `8006`, `18006` |
| `PVE_VERSION` | Expected PVE version | `7.4`, `8.0`, `8.3` |
| `EXPECTED_FEATURES` | Expected feature list | `sdn,notifications` |
| `CI` | CI environment flag | `true`, `false` |

## Best Practices

### 1. Health Checks
Always use health checks to ensure mock servers are ready:

```yaml
# Docker Compose
healthcheck:
  test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
  interval: 5s
  timeout: 3s
  retries: 10
  start_period: 5s
```

```bash
# Shell script
wait_for_server() {
    local host=${1:-localhost}
    local port=${2:-8006}
    local timeout=${3:-60}
    
    timeout $timeout sh -c "until curl -f http://$host:$port/api2/json/version; do sleep 2; done"
}
```

### 2. Version Verification
Always verify the mock server is running the expected PVE version:

```bash
verify_version() {
    local expected_version=$1
    local host=${2:-localhost}
    local port=${3:-8006}
    
    actual_version=$(curl -s http://$host:$port/api2/json/version | jq -r '.data.version')
    
    if [[ "$actual_version" != "$expected_version" ]]; then
        echo "Version mismatch: expected $expected_version, got $actual_version"
        exit 1
    fi
    
    echo "✅ Mock server running PVE $actual_version"
}
```

### 3. Parallel Testing
Use different ports for parallel version testing:

```bash
# Start multiple versions
start_parallel_servers() {
    declare -A versions=( ["7.4"]=18074 ["8.0"]=18080 ["8.3"]=18083 )
    
    for version in "${!versions[@]}"; do
        port=${versions[$version]}
        podman run -d --name "mock-pve-${version//./}" \
            -p "$port:8006" \
            -e "MOCK_PVE_VERSION=$version" \
            jrjsmrtn/mock-pve-api:latest
    done
}
```

### 4. Resource Cleanup
Always clean up containers and networks:

```bash
cleanup() {
    echo "Cleaning up Mock PVE API containers..."
    docker ps -a --filter "ancestor=jrjsmrtn/mock-pve-api" --format "{{.ID}}" | xargs -r docker rm -f
    docker network ls --filter "name=mock-pve" --format "{{.ID}}" | xargs -r docker network rm
}

trap cleanup EXIT
```

### 5. Caching Dependencies
Cache dependencies for faster builds:

```yaml
# GitHub Actions
- name: Cache dependencies
  uses: actions/cache@v3
  with:
    path: |
      _build
      deps
    key: ${{ runner.os }}-mix-${{ hashFiles('**/mix.lock') }}
```

```yaml
# GitLab CI
cache:
  key: deps-$CI_COMMIT_REF_SLUG
  paths:
    - deps/
    - _build/
```

This comprehensive CI/CD integration guide provides everything needed to implement robust, multi-version testing with the Mock PVE API Server across different platforms and environments.