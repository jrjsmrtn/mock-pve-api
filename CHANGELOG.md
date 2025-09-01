# Changelog

All notable changes to Mock PVE API will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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