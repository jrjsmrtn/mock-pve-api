# Changelog

All notable changes to Mock PVE API will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.4.6] - 2025-09-11 (Foundation ADR Sequence & Supply Chain Security)

### Added
- **Foundation ADR Sequence Implementation**: AI-Assisted Project Orchestration pattern language
  - **ADR-0001: Record Architecture Decisions** - Systematic documentation approach following adr-tools format
  - **ADR-0002: Adopt Development Best Practices** - Comprehensive practices including TDD, semantic versioning, Gitflow, C4 DSL, Diataxis documentation framework, sprint-based development, and container-first approach
  - **ADR-0003: Elixir/OTP Implementation Choice** - Technology stack decision with comprehensive analysis and rationale
  - **ADR Directory README** - Complete ADR process documentation with foundation sequence explanation
- **Supply Chain Security & SBOM Best Practices**:
  - **SBOM Generation Integration** - Added comprehensive Software Bill of Materials generation to development best practices
  - **Multi-Format SBOM Support** - SPDX 2.3, CycloneDX 1.4, and custom Mix dependency formats documented in ADR-0002
  - **Supply Chain Security Standards** - Enhanced quality standards with enterprise compliance requirements
  - **SBOM Workflow Documentation** - Complete workflow commands and vulnerability assessment integration

### Changed
- **ADR Structure**: Systematically renumbered existing ADRs from 001-007, 013 to new Foundation sequence 0004-0010
- **Documentation References**: Updated all cross-references across project documentation for new ADR numbering
- **Architecture Documentation**: Enhanced C4 model system description with Foundation ADR Sequence context
- **Development Roadmap**: Added Phase 4.6 completion with comprehensive Foundation ADR and supply chain security achievements
- **Quality Standards**: Enhanced container standards and added dedicated Supply Chain Security section

### Fixed
- **ADR Cross-References**: Updated all internal links and references across CHANGELOG.md, README.md, architecture documentation, and explanation content
- **ADR Content Numbering**: Corrected internal ADR numbering to match new file naming convention

## [0.4.4] - 2025-09-01 (Diátaxis Documentation Reorganization)

### Added
- **Complete Diátaxis Documentation Structure**: Reorganized all documentation following industry-standard Diátaxis framework
  - **Tutorials**: Learning-oriented guides (getting-started.md, your-first-test.md, understanding-versions.md)
  - **How-To Guides**: Problem-solving guides (client-integration.md, multi-version-testing.md, container-deployment.md, setup-ci-cd.md, migrate-from-pvex.md)
  - **Reference**: Information-oriented documentation (api-endpoints.md, environment-variables.md, client-examples.md, api-coverage.md)
  - **Explanation**: Understanding-oriented content (architecture-decisions.md, version-compatibility.md, state-management.md)
- **New Tutorial Content**: Created comprehensive tutorials for new users
- **Enhanced How-To Guides**: Practical guides for common tasks and integration scenarios
- **Comprehensive Reference Material**: Complete API and configuration documentation
- **Conceptual Explanations**: Deep-dive explanations of architecture and design decisions

### Changed
- **Documentation Structure**: Complete reorganization from flat structure to Diátaxis quadrants
- **Navigation**: Updated all internal links and cross-references for new structure
- **Examples Organization**: Simplified and cleaned up examples directory structure
- **README.md**: Updated to reflect new documentation organization with clear categories

### Fixed
- **Documentation Links**: Fixed all broken internal documentation links after reorganization
- **ADR Numbering**: Resolved duplicate ADR-005 numbers by renaming API coverage matrix to ADR-0009
- **Relative Paths**: Corrected all relative path calculations for new directory structure

### Removed
- **Obsolete Directories**: Cleaned up old docs/guides/ directory and empty subdirectories
- **Broken Links**: Eliminated all references to non-existent documentation files

## [0.4.3] - 2025-09-01 (Container Runtime Configuration & Testing Validation)

### Fixed
- **Runtime Configuration**: Added `config/runtime.exs` for proper environment variable handling in containers
  - Fixed PVE version selection from `MOCK_PVE_VERSION` environment variable
  - Resolved compile-time vs runtime configuration issues in production builds
  - Environment variables now properly read at container startup time
- **Production Dependencies**: Made Finch HTTP client a production dependency
  - Fixed container startup failures with missing Finch dependency
  - Ensures proper HTTP client availability for all environments
- **Version Handler**: Corrected application name reference in version endpoint
  - Fixed hardcoded `:mock_pve_server` to proper `:mock_pve_api` reference
  - Enables proper version simulation across different PVE versions

### Validated
- **Container Testing**: Comprehensive Podman container validation
  - Multi-version support (PVE 7.4, 8.3, 9.0) working correctly
  - Network isolation and cluster simulation tested
  - Cross-container API authentication and communication verified
- **API Endpoints**: All 37 endpoints systematically tested and verified working
  - Authentication system (tickets, cookies) fully functional
  - Version-specific capability detection working properly
  - Cluster operations and resource management tested

### Infrastructure
- **Container Builds**: Fixed production container builds with proper dependencies
- **Multi-Architecture**: Validated ARM64 builds and Intel compatibility requirements
- **Development Workflow**: Enhanced testing procedures for container deployments

## [0.4.2] - 2025-01-31 (Code Quality & Warning Cleanup)

### Fixed
- **Compiler Warnings**: Eliminated all 20+ unused variables and function ordering issues
- **Code Quality**: Applied Elixir best practices throughout codebase
- **Pattern Matching**: Fixed GenServer recursive call issues with proper pattern matching

## [0.4.1] - 2025-01-31 (100% API Coverage Milestone)

### Added
- **Complete API Implementation**: Achieved 100% coverage with all 37 endpoints functional
- **Authentication System**: Full cookie-based authentication with proper PVE ticket handling
- **Enhanced CRUD Operations**: Complete resource management for VMs, containers, users, pools

## [0.4.0] - 2025-01-31 (Phase 4: Enhanced API Implementation)

### Added
- **VM/Container Operations**: Complete lifecycle management including cloning
- **User/Group Management**: Full CRUD operations for access control
- **Enhanced Storage**: Content management with POST endpoints for ISOs/templates/backups
- **Cluster Configuration**: Join operations and node management endpoints
- **HA & Backup Features**: Version-specific features (PVE 8.2+ backup providers, 9.0+ HA affinity)

## [0.3.2] - 2025-01-30 (Comprehensive API Coverage Matrix)

### Added - Phase 3.2: API Coverage Matrix System
- **Complete API Coverage Matrix**: Based on pvex analysis (305+ endpoints, 97.8% coverage)
  - `MockPveApi.Coverage` module with 28+ initial endpoints across 8 categories
  - Structured endpoint information with methods, parameters, response schemas
  - Implementation status tracking: :implemented, :partial, :planned, :not_supported, :pve8_only, :pve9_only
  - Priority levels: critical, high, medium, low for development planning
- **Coverage-Aware Router**: Enhanced request handling with intelligent error responses
  - Version-specific endpoint filtering (PVE 8+, PVE 9+ features)
  - Method validation with proper HTTP 405 responses
  - Detailed error messages with coverage information
  - Coverage status checking plug with appropriate 501 responses
- **Coverage API Endpoints**: Internal coverage monitoring via REST API
  - GET `/api2/json/_coverage/stats` - Overall coverage statistics (68% current)
  - GET `/api2/json/_coverage/categories` - Per-category implementation status
  - GET `/api2/json/_coverage/missing` - Critical endpoints not yet implemented
- **Architecture Documentation**:
  - ADR-0009: Comprehensive API Coverage Matrix architecture decision
  - Complete API coverage reference document (850+ lines)
  - Per-endpoint documentation with parameters, examples, version compatibility
- **Test Infrastructure**:
  - Comprehensive coverage matrix validation suite
  - Endpoint schema validation and consistency checks
  - Version compatibility testing across PVE 7.x-9.x
  - Coverage statistics and development metrics

### Enhanced Infrastructure
- **Documentation System**: 
  - Status legend with 7 implementation states
  - Development roadmap with Phase 4-7 planning
  - Coverage goals: 85% (v0.4.0), 95% (v0.5.0), 100% (v1.0.0)
- **Error Handling**: 
  - Structured error responses with coverage_info metadata
  - Version-specific error messages for unsupported features
  - Handler validation for implemented endpoints

### Development Impact
- **Current Coverage**: 68% (19/28 endpoints implemented/partial)
- **Critical Endpoints**: All implemented (version, nodes, VMs, containers)
- **Next Phase Planning**: Clear roadmap for Phase 4 authentication and CRUD operations
- **pvex Compatibility**: Coverage matrix follows pvex project structure and organization

## [0.3.1] - 2025-01-29 (HTTP Client Migration)

### Changed - Phase 3.1: HTTP Client Modernization
- **HTTP Client Migration**: Migrated from HTTPoison to Finch HTTP client
  - Updated `test/support/test_helper.ex` to use Finch for HTTP requests
  - Updated all Elixir examples in `examples/elixir/` to use Finch
  - Added Finch to application supervision tree for reliable HTTP client management
  - Maintained complete API compatibility during migration
- **Dependency Updates**: 
  - Added `{:finch, "~> 0.18", only: [:dev, :test]}` to mix.exs dependencies
  - Removed dependency on HTTPoison for test and example code
- **Documentation Updates**: Updated code examples to reflect Finch usage patterns

### Infrastructure
- **HTTP Client Architecture**: Modern, connection-pooling HTTP client for better performance
- **Supervision Tree**: Finch integrated into application supervision for reliability
- **Testing**: All HTTP-based tests migrated to use Finch client

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