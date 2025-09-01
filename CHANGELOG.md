# Changelog

All notable changes to Mock PVE API will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2024-12-01 (Enhanced API Coverage)

### Added - Phase 3: Enhanced API Coverage
- **VM/Container Lifecycle Operations**: Complete start, stop, restart, shutdown, migrate support
- **Backup & Restore System**: 
  - POST `/api2/json/nodes/:node/vzdump` - Create backups with realistic file simulation
  - GET `/api2/json/nodes/:node/storage/:storage/backup` - List backup files
  - Backup restore simulation with progress tracking
- **Task/Job Simulation**: 
  - GET `/api2/json/nodes/:node/tasks/:upid/status` - Real-time progress tracking
  - GET `/api2/json/nodes/:node/tasks/:upid/log` - Detailed task logs
  - Realistic task duration and progress simulation (60-second completion)
- **Authentication Endpoints**:
  - Enhanced POST `/api2/json/access/ticket` with stateful ticket management
  - POST `/api2/json/access/users/:userid/token/:tokenid` - API token creation
  - GET `/api2/json/access/users/:userid/token` - List user tokens
  - Token validation and expiration (2-hour ticket lifetime)
- **Permissions & ACL Simulation**:
  - GET `/api2/json/access/permissions` - User permissions lookup
  - PUT `/api2/json/access/acl` - Set access control permissions
  - GET `/api2/json/access/roles` - List available roles
  - Role-based privilege system with Administrator role
- **Metrics & Statistics Endpoints**:
  - GET `/api2/json/nodes/:node/rrd` - Node RRD data for graphs
  - GET `/api2/json/nodes/:node/rrddata` - Structured RRD data points
  - GET `/api2/json/nodes/:node/qemu/:vmid/rrd` - VM metrics
  - GET `/api2/json/nodes/:node/lxc/:vmid/rrd` - Container metrics
  - GET `/api2/json/nodes/:node/netstat` - Network interface statistics
  - GET `/api2/json/nodes/:node/report` - Comprehensive system report
  - GET `/api2/json/cluster/metrics/server/:id` - Cluster-wide metrics

### Enhanced Features
- **VM Operations**: 
  - POST `/api2/json/nodes/:node/qemu/:vmid/migrate` - Live migration
  - POST `/api2/json/nodes/:node/qemu/:vmid/snapshot` - Snapshot creation
  - POST `/api2/json/nodes/:node/qemu/:vmid/clone` - VM cloning
- **Container Operations**:
  - POST `/api2/json/nodes/:node/lxc/:vmid/migrate` - Container migration
- **Advanced Authentication**:
  - Stateful ticket storage with expiration
  - API token generation with privilege separation
  - CSRF token support for web interface compatibility

### Improved Infrastructure
- **State Management**: Enhanced GenServer with backup, migration, and auth state
- **Task System**: Realistic progress simulation with type-specific log generation
- **Metrics Simulation**: Time-series data generation for different timeframes
- **Security Model**: Role-based permissions with Administrator role privileges

## [0.2.0] - 2024-11-XX (Docker Hub Release)

### Added
- Docker Hub repository setup and automated publishing
- Multi-architecture builds (amd64, arm64)
- Semantic versioning tags and automated GitHub Actions
- Container security scanning and SBOM generation

## [0.1.0] - 2024-11-XX (Initial Release)

### Added
- Initial release of Mock PVE API Server
- Complete PVE version simulation support (7.0 through 9.0)
- Docker container support with multi-architecture builds
- Comprehensive API endpoint coverage for core PVE operations
- Stateful resource management for realistic testing scenarios
- Version-specific capability detection and feature availability
- Environment variable configuration for flexible deployment
- CI/CD integration examples for GitHub Actions and GitLab CI
- Multi-language usage examples (Python, JavaScript, Elixir)

### Core Features
- **Version Simulation**: Granular support for PVE 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, and 9.0
- **API Endpoints**: Version, nodes, cluster status, resources, VMs, containers, storage, pools
- **Advanced Features**: SDN management (8.0+), firewall, backup providers (8.2+), user management
- **State Management**: In-memory resource tracking with lifecycle operations
- **Containerization**: Production-ready Docker images with health checks
- **Configuration**: Environment-based configuration with sensible defaults

### Infrastructure
- **Docker Images**: Multi-stage builds for minimal production footprint
- **Docker Compose**: Pre-configured environments for different PVE versions
- **Health Checks**: Built-in health monitoring for container orchestration
- **Logging**: Configurable log levels with structured output
- **Error Simulation**: Optional error injection for resilience testing

## [0.1.0] - 2025-01-XX (Initial Planning)

### Added
- Project structure and initial codebase extraction from pvex
- Basic API endpoint implementations with realistic responses
- Version compatibility matrix and capability system
- Container infrastructure with Docker and Docker Compose
- Comprehensive documentation and usage examples

---

## Version Support Matrix

| Mock PVE API Version | PVE Versions Supported | Key Features |
|---------------------|----------------------|--------------|
| 0.1.0 | 7.0 - 9.0 | Core virtualization, containers, storage, SDN, firewall |

## Migration Guide

### From Embedded Mock (pvex)

If you're migrating from the embedded mock server in pvex:

1. **Replace embedded mock usage**:
   ```bash
   # Old: Start embedded mock in pvex tests
   # New: Start container
   docker run -d -p 8006:8006 jrjsmrtn/mock-pve-api:latest
   ```

2. **Update test configuration**:
   ```elixir
   # Old: Direct module calls
   MockPveServer.start_test_server(port: 8007, pve_version: "8.0")
   
   # New: Configure client to use container
   config = %Pvex.Config{host: "localhost", port: 8006}
   ```

3. **Update CI/CD pipelines**:
   ```yaml
   # Add service container instead of building mock server
   services:
     mock-pve:
       image: jrjsmrtn/mock-pve-api:latest
       ports:
         - 8006:8006
   ```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines and development setup instructions.