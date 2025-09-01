# CLAUDE.md - mock-pve-api: Mock Proxmox VE API Server

## **Project Overview**

**mock-pve-api** is a lightweight, containerized Mock Proxmox VE API Server designed for testing and development. It simulates the Proxmox Virtual Environment REST API across versions 7.x, 8.x, and 9.x, enabling developers to test PVE client libraries and automation tools without requiring actual Proxmox VE infrastructure. This project is essential for CI/CD pipelines, integration testing, and local development environments.

**Domain Focus:**
- PVE API simulation and mocking
- Multi-version compatibility testing
- Stateful resource lifecycle simulation
- CI/CD pipeline integration
- Cross-language client library testing
- Development environment provisioning

**Current Status:** 0.3.2 (Comprehensive API Coverage Matrix)
**Supported PVE Versions:** 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, 9.0
**Target Elixir Version:** 1.15+
**Target OTP Version:** 26+
**Distribution:** OCI Registry (docker.io/jrjsmrtn/mock-pve-api)
**Containerization:** Podman-first, Docker-compatible approach

## **Development Commands**

### **Core Development**
```bash
# Environment setup
mix deps.get              # Install dependencies
mix compile               # Compile project

# Development workflow
iex -S mix                # Interactive development shell
mix run --no-halt         # Start mock server locally
MIX_ENV=dev mix run --no-halt  # Development mode with debug logging

# Testing
mix test                  # Run test suite
mix test --cover          # Run tests with coverage
mix format                # Format code
mix credo                 # Static analysis (when added)
mix dialyzer              # Type checking (when added)
mix docs                  # Generate documentation

# Release building
MIX_ENV=prod mix release  # Build production release
mix hex.build             # Build hex package (future)
```

### **Container Development**
```bash
# Container Management (Podman preferred, Docker compatible)
make container-build      # Build production container image
make container-build-dev  # Build development container  
make container-run        # Run container on port 8006
make container-run-dev    # Run development container with volume mounts

# Legacy Docker aliases (backward compatibility)
make docker-build         # Alias for container-build
make docker-run           # Alias for container-run

# Manual container commands (Podman recommended)
podman build -f containers/Containerfile -t mock-pve-api:latest .
podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest

# Multi-version testing
make container-run-versions  # Run PVE 7.4, 8.0, 8.3, 9.0 simultaneously

# Compose deployment (Podman Compose preferred)
podman-compose up -d         # Uses podman-compose.yml
docker-compose up -d         # Legacy compatibility via symlink
# Architecture validation (using Podman)
make arch-validate                   # Validate C4 architecture model
make arch-viz                        # Interactive visualization

# Manual architecture commands
podman run --rm -v $(pwd)/architecture:/usr/local/structurizr \
  structurizr/cli validate -w workspace.dsl
# Testing and validation
make test                      # Run unit tests
make test-integration          # Integration tests against container
make test-examples             # Test all language examples
make validate                  # Complete validation pipeline

```

### **Testing & Validation**
```bash
# Test with different clients
python examples/python/test_client.py      # Python client test
node examples/javascript/test-client.js    # JavaScript client test
elixir examples/elixir/test_client.exs    # Elixir client test

# API endpoint testing
curl http://localhost:8006/api2/json/version
curl http://localhost:8006/api2/json/nodes
curl http://localhost:8006/api2/json/cluster/status

# Health check
curl -f http://localhost:8006/api2/json/version || echo "Server not healthy"
```

## **Architecture Overview**

### **Core Design Principles**
1. **Version Fidelity**: Accurate simulation of PVE API responses across all supported versions
2. **Stateful Simulation**: In-memory state management for realistic resource lifecycles
3. **Zero Dependencies**: No external infrastructure required for operation
4. **Container-First**: Designed for container deployment and orchestration
5. **Language Agnostic**: Works with any HTTP client or PVE library
6. **Podman-First Containerization**: Secure, rootless container approach with Docker compatibility

### **Containerization Philosophy**
**Approach**: Podman-first, Docker-compatible
- **Primary Runtime**: Podman for enhanced security, rootless operation, and systemd integration
- **Compatibility**: Full Docker compatibility maintained through OCI compliance
- **Security**: Rootless containers by default, no privileged daemon required
- **Registry**: Uses `docker.io/` prefix for universal registry access
- **Development**: Volume mounts and live reload support for both runtimes
- **CI/CD**: Native support in GitHub Actions, GitLab CI, Jenkins with both runtimes

### **Application Structure**
```elixir
MockPveApi                        # Main application module
├── MockPveApi.Application        # OTP Application supervisor
├── MockPveApi.Router             # HTTP request routing (Plug)
├── MockPveApi.State              # GenServer for state management
├── MockPveApi.Capabilities       # Version-specific feature matrix
├── MockPveApi.Fixtures           # Response fixtures and templates
└── MockPveApi.Handlers           # API endpoint handlers
    ├── Version                   # /api2/json/version
    ├── Nodes                     # /api2/json/nodes/*
    ├── Cluster                   # /api2/json/cluster/*
    ├── Storage                   # /api2/json/nodes/{node}/storage/*
    ├── Pools                     # /api2/json/pools/*
    └── Access                    # /api2/json/access/*
```

### **State Management Strategy**
- **In-Memory State**: GenServer-based state for fast access
- **Resource Tracking**: VMs, containers, storage, pools maintained in state
- **Lifecycle Simulation**: Create, modify, delete operations update state
- **Isolation**: Each container instance maintains independent state
- **Reset Capability**: State can be reset for test isolation

### **Version Compatibility System**
```elixir
# Capability-based feature detection
MockPveApi.Capabilities.supports?(version, :sdn_tech_preview)  # true for 8.0+
MockPveApi.Capabilities.supports?(version, :backup_providers)   # true for 8.2+
MockPveApi.Capabilities.supports?(version, :ha_affinity)        # true for 9.0+

# Automatic version-appropriate responses
# Returns 501 Not Implemented for unsupported features
```

### **Key Architectural Decisions**
- **ADR-001**: Elixir/OTP for reliable concurrent request handling
- **ADR-002**: Plug over Phoenix for minimal footprint
- **ADR-003**: In-memory state over persistence for simplicity
- **ADR-004**: Capability matrix for version-specific features
- **ADR-005**: Container-first deployment strategy
- **ADR-006**: Environment variable configuration for flexibility

## **API Coverage**

### **Core Endpoints (All Versions)**
- ✅ `/api2/json/version` - Version information
- ✅ `/api2/json/nodes` - Node listing and status
- ✅ `/api2/json/cluster/status` - Cluster status
- ✅ `/api2/json/cluster/resources` - Resource overview
- ✅ `/api2/json/nodes/{node}/qemu` - Virtual machines
- ✅ `/api2/json/nodes/{node}/lxc` - LXC containers
- ✅ `/api2/json/nodes/{node}/storage` - Storage management
- ✅ `/api2/json/pools` - Resource pools
- ✅ `/api2/json/access/users` - User management

### **Version-Specific Endpoints**
- ✅ `/api2/json/cluster/sdn/*` - SDN management (8.0+)
- ✅ `/api2/json/cluster/firewall/*` - Firewall rules
- ✅ `/api2/json/cluster/backup-info/providers` - Backup providers (8.2+)
- ✅ `/api2/json/cluster/notifications/*` - Notifications (8.1+)
- ✅ `/api2/json/nodes/{node}/hardware/*` - Hardware detection

### **Response Characteristics**
- JSON format matching PVE API schema
- Appropriate HTTP status codes
- Error responses for unsupported operations
- Realistic data values and relationships

## **Configuration**

### **Environment Variables**
```bash
# Core configuration
MOCK_PVE_VERSION=8.3          # PVE version to simulate (7.0-9.0)
MOCK_PVE_PORT=8006            # Server port
MOCK_PVE_HOST=0.0.0.0         # Bind address

# Feature toggles
MOCK_PVE_ENABLE_SDN=true      # Enable SDN endpoints (8.0+ only)
MOCK_PVE_ENABLE_FIREWALL=true # Enable firewall endpoints
MOCK_PVE_ENABLE_BACKUP_PROVIDERS=true # Enable backup providers (8.2+)

# Simulation options
MOCK_PVE_DELAY=0              # Response delay in milliseconds
MOCK_PVE_ERROR_RATE=0         # Error injection rate (0-100)
MOCK_PVE_LOG_LEVEL=info       # Logging level (debug|info|warn|error)

# Advanced options (planned)
MOCK_PVE_PERSISTENCE=none     # Persistence mode (none|memory|sqlite)
MOCK_PVE_INIT_STATE=default   # Initial state preset
MOCK_PVE_MAX_RESOURCES=1000   # Maximum simulated resources
```

## **Development Roadmap**

### **Phase 1: Foundation (v0.1.0)** ✅
- [x] Extract and refactor from pvex project
- [x] Standalone Mix project structure
- [x] Docker containerization
- [x] Basic CI/CD pipeline
- [x] Multi-language examples
- [x] Comprehensive documentation

### **Phase 2: Docker Hub Release (v0.2.0)** 🚧
- [ ] Docker Hub repository setup
- [ ] Automated multi-arch builds (amd64, arm64)
- [ ] Semantic versioning tags
- [ ] GitHub Actions for automated publishing
- [ ] Container security scanning
- [ ] SBOM generation

### **Phase 3: Enhanced API Coverage (v0.3.0)** ✅
- [x] VM/Container lifecycle operations (start, stop, migrate)
- [x] Backup and restore endpoints
- [x] Task/job simulation with progress
- [x] Authentication endpoints (tickets, tokens)
- [x] Permissions and ACL simulation
- [x] Metrics and statistics endpoints

### **Phase 3.1: HTTP Client Migration (v0.3.1)** ✅
- [x] Migrate from HTTPoison to Finch HTTP client
- [x] Update test helper to use Finch
- [x] Update all Elixir examples to use Finch
- [x] Add Finch to application supervision tree
- [x] Maintain API compatibility during migration

### **Phase 3.2: API Coverage Matrix (v0.3.2)** ✅
- [x] Research pvex project API coverage (305+ endpoints, 97.8% coverage)
- [x] Design comprehensive coverage matrix data structure
- [x] Implement MockPveApi.Coverage module with 28+ endpoints
- [x] Add coverage-aware router with intelligent error responses
- [x] Create ADR-005 for coverage matrix architecture
- [x] Generate comprehensive API coverage documentation
- [x] Add coverage validation and statistics functions
- [x] Implement coverage API endpoints (/api2/json/_coverage/*)
- [x] Create comprehensive test suite for coverage matrix

### **Phase 4: Enhanced API Implementation (v0.4.0)**
- [ ] Authentication system (tickets, tokens, realms)
- [ ] VM/Container cloning operations  
- [ ] Individual user/group/pool CRUD operations
- [ ] Cluster join and configuration endpoints
- [ ] Enhanced storage content management
- [ ] Task/job progress simulation improvements
- [ ] Individual SDN zone/vnet operations (PVE 8.0+)
- [ ] Backup provider management (PVE 8.2+)
- [ ] Target: 85% coverage of critical/high priority endpoints

### **Phase 5: Advanced Features (v0.5.0)**
- [ ] WebSocket support for console/VNC simulation
- [ ] Event streaming simulation
- [ ] Configurable response fixtures
- [ ] State persistence options (SQLite)
- [ ] State import/export for test scenarios
- [ ] Performance metrics collection
- [ ] HA affinity rules (PVE 9.0+)
- [ ] Target: 95% coverage including version-specific features

### **Phase 6: Testing Framework (v0.6.0)**
- [ ] Test helper library for common scenarios
- [ ] Chaos engineering features (random failures)
- [ ] Network condition simulation (latency, timeouts)
- [ ] Load testing capabilities
- [ ] Compatibility test suite
- [ ] Integration with popular testing frameworks

### **Phase 7: Community & Ecosystem (v1.0.0)**
- [ ] Hex.pm package publication
- [ ] Plugin system for custom endpoints
- [ ] OpenAPI specification generation
- [ ] Proxmox community integration
- [ ] Contribution from PVE client library maintainers
- [ ] Official Proxmox recognition (stretch goal)

## **Quality Standards**

### **Code Quality**
- **Format**: Enforced via `mix format` and `.formatter.exs`
- **Documentation**: Module and function documentation required
- **Type Specs**: Comprehensive typespecs for public functions
- **Testing**: Minimum 80% test coverage for new features
- **Reviews**: All PRs require review before merge

### **Container Standards**
- **Size**: Alpine-based images under 50MB
- **Security**: Regular vulnerability scanning
- **Health**: Health check endpoints required
- **Signals**: Graceful shutdown handling
- **Logging**: Structured JSON logging to stdout

### **API Compatibility**
- **Schema Validation**: Responses match PVE API documentation
- **Version Accuracy**: Version-specific behavior properly simulated
- **Error Codes**: Appropriate HTTP status codes and error messages
- **Backwards Compatibility**: Maintain compatibility within major versions

## **Usage Examples**

### **CI/CD Integration**
```yaml
# GitHub Actions
services:
  mock-pve:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - 8006:8006
    env:
      MOCK_PVE_VERSION: "8.3"

# GitLab CI
services:
  - name: docker.io/jrjsmrtn/mock-pve-api:latest
    alias: mock-pve
    variables:
      MOCK_PVE_VERSION: "8.3"
```

### **Local Development**
```bash
# Quick start for development (Podman recommended)
podman run -d --name mock-pve \
  --userns=keep-id \
  -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Docker compatibility (legacy)
docker run -d --name mock-pve \
  -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  jrjsmrtn/mock-pve-api:latest

# Test your client
export PVE_HOST=localhost
export PVE_PORT=8006
python your_pve_client.py
```

### **Multi-Version Testing**
```bash
# Test against multiple PVE versions
for version in 7.4 8.0 8.3 9.0; do
  docker run -d --name pve-$version \
    -p $((8000 + ${version%%.*})):8006 \
    -e MOCK_PVE_VERSION=$version \
    jrjsmrtn/mock-pve-api:latest
done
```

## **Contributing**

### **Development Setup**
```bash
git clone https://github.com/jrjsmrtn/mock-pve-api.git
cd mock-pve-api
mix deps.get
mix test
mix run --no-halt
```

### **Adding New Endpoints**
1. Research real PVE API behavior
2. Add handler in `lib/mock_pve_api/handlers/`
3. Update router in `lib/mock_pve_api/router.ex`
4. Add capability check if version-specific
5. Write comprehensive tests
6. Update documentation

### **Submitting Changes**
1. Fork the repository
2. Create feature branch
3. Write tests for new functionality
4. Ensure all tests pass
5. Submit PR with clear description

## **Project Goals**

### **Short Term (3 months)**
- Achieve 1000+ Docker Hub pulls
- Support 90% of common PVE API endpoints
- Integrate with 3+ PVE client libraries
- Establish CI/CD best practices

### **Medium Term (6 months)**
- Become the standard for PVE API testing
- Achieve 5000+ Docker Hub pulls
- Support all major PVE API endpoints
- Build active contributor community

### **Long Term (12 months)**
- Official recognition from Proxmox community
- Integration into PVE client library test suites
- 10,000+ Docker Hub pulls
- Comprehensive plugin ecosystem
- Reference implementation for PVE API behavior

## **Success Metrics**

- **Adoption**: Docker Hub pulls, GitHub stars, forks
- **Quality**: Test coverage, bug reports, response time
- **Community**: Contributors, issues, discussions
- **Impact**: Client libraries using mock-pve-api
- **Recognition**: Mentions in PVE documentation/forums

## **Related Projects**

- **pvex**: Comprehensive Elixir client for Proxmox VE (origin project)
- **proxmoxer**: Python wrapper for Proxmox REST API
- **proxmox-api-go**: Go client for Proxmox VE API
- **node-proxmox**: Node.js client for Proxmox API

---

*This configuration establishes mock-pve-api as the definitive mock server for Proxmox VE API testing, enabling infrastructure-independent development and testing across the entire PVE ecosystem.*