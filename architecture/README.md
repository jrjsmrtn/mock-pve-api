# Mock PVE API - Architecture Documentation

This directory contains the C4 architecture model for the Mock PVE API Server, providing comprehensive documentation of the system's structure, components, and interactions.

## Architecture Overview

The Mock PVE API Server is designed as a lightweight, containerized application that simulates the Proxmox VE REST API for testing and development purposes. The architecture follows the C4 model approach with clear separation of concerns and well-defined component boundaries.

## Architecture Levels

### Level 1: System Context
Shows how the Mock PVE API Server fits into the broader ecosystem, including:
- **Developers**: Using the mock server for local development and testing
- **CI/CD Systems**: Integrating the mock server for automated testing pipelines  
- **PVE Client Libraries**: Various language implementations that consume the API
- **Container Runtime**: Podman/Docker/K8s infrastructure hosting the server
- **OCI Registry**: Container registry providing OCI images

### Level 2: Containers
The system is composed of three main containers:
- **Web Server**: HTTP request handling and routing (Plug/Cowboy)
- **State Manager**: In-memory resource state management (GenServer/ETS)
- **Capability Engine**: Version-specific feature detection and validation

### Level 3: Components
Each container is further decomposed into focused components:

#### Web Server Components
- **HTTP Router**: Routes API requests to appropriate handlers
- **API Handlers**: Specialized handlers for different endpoint categories
- **Middleware Stack**: Cross-cutting concerns (logging, parsing, CORS)

#### State Manager Components  
- **State GenServer**: Serializes all state modifications
- **ETS Store**: Fast concurrent read access to resource state
- **Resource Modeler**: Models PVE resources (VMs, containers, storage, etc.)
- **State Validator**: Ensures state consistency and validation

#### Capability Engine Components
- **Version Matrix**: Maps features to specific PVE versions
- **Feature Detector**: Checks feature availability for configured version
- **Error Generator**: Creates appropriate HTTP error responses

### Level 4: Code
Implementation details are documented in the source code with comprehensive module documentation, typespecs, and inline comments.

## Key Architectural Decisions

The architecture is based on several key decisions documented in our ADRs:

1. **[ADR-0003](../docs/adr/0003-elixir-otp-implementation-choice.md)**: Elixir/OTP for concurrent request handling and fault tolerance
2. **[ADR-0004](../docs/adr/0004-plug-over-phoenix-minimal-framework.md)**: Plug over Phoenix for minimal footprint
3. **[ADR-0005](../docs/adr/0005-in-memory-state-management.md)**: In-memory state management for simplicity and performance
4. **[ADR-0006](../docs/adr/0006-capability-matrix-version-compatibility.md)**: Capability matrix for version compatibility
5. **[ADR-0007](../docs/adr/0007-container-first-deployment.md)**: Container-first deployment strategy
6. **[ADR-0008](../docs/adr/0008-environment-variable-configuration.md)**: Environment variable configuration

## Core Architectural Principles

### 1. Container-Native Design
- **Zero external dependencies**: No databases or external services required
- **Configuration via environment variables**: Perfect for containerized deployments
- **Health checks built-in**: Container orchestration support
- **Multi-architecture**: amd64 and arm64 support

### 2. Performance-Focused
- **In-memory state**: Sub-millisecond response times
- **Concurrent request handling**: Elixir Actor model for scalability
- **ETS for fast reads**: Concurrent read access without contention
- **Minimal resource footprint**: ~20-50MB memory usage

### 3. Version Accuracy
- **Capability matrix**: Explicit mapping of features to PVE versions
- **Appropriate error responses**: 501 Not Implemented for unsupported features
- **Realistic state modeling**: Accurate simulation of PVE resource relationships
- **Version-specific behaviors**: Different responses based on configured version

### 4. Developer Experience
- **Single command startup**: `podman run -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest`
- **Multiple language examples**: Python, JavaScript, Elixir client examples
- **Comprehensive documentation**: Usage guides, API references, troubleshooting
- **CI/CD integration**: Native support for all major CI platforms

## Request Flow Architecture

### Typical API Request Flow
1. **Client Request**: HTTP request arrives at the router
2. **Middleware Processing**: Logging, parsing, and validation
3. **Route Matching**: Route to appropriate API handler
4. **Capability Check**: Verify feature availability for PVE version
5. **State Query**: Retrieve or update resource state via GenServer
6. **Response Generation**: Create JSON response matching PVE API schema
7. **Client Response**: Return HTTP response to client

### State Management Flow  
1. **State Modification**: Handler requests state change via GenServer
2. **Validation**: State validator ensures consistency and constraints
3. **Resource Modeling**: Create/update structured resource representations
4. **ETS Storage**: Persist state changes to ETS tables
5. **Confirmation**: Confirm successful state update to handler

### Version Compatibility Flow
1. **Feature Request**: Client requests version-specific feature
2. **Capability Lookup**: Check feature availability in version matrix
3. **Version Validation**: Verify current version supports requested feature
4. **Error Generation**: Create appropriate error response if unsupported
5. **Feature Execution**: Process request if feature is supported

## Deployment Architecture

### Development Deployment
- **Single container**: All components in one container instance
- **Local Docker**: Docker Desktop or Podman on developer machine
- **Debug configuration**: Enhanced logging and state inspection
- **Volume mounting**: Source code mounted for development

### CI/CD Deployment
- **Service container**: Mock server runs as CI service
- **Test container**: Separate container for running tests
- **Resource limits**: Constrained CPU and memory allocation
- **Health checks**: Ensure service readiness before tests

### Production Testing Deployment
- **Kubernetes pods**: Multi-replica deployment for load testing
- **Load balancer**: Kubernetes service for request distribution
- **Resource quotas**: Defined CPU/memory limits and requests
- **Horizontal scaling**: Multiple pod replicas for capacity

## Data Architecture

### Resource State Model
```
State {
  version: "8.3"
  nodes: Map<NodeID, NodeData>
  vms: Map<VMID, VMData>  
  containers: Map<CTID, ContainerData>
  storage: Map<StorageID, StorageData>
  pools: Map<PoolID, PoolData>
  users: Map<UserID, UserData>
}
```

### Capability Matrix Structure
```
Capabilities {
  "7.0": [:basic_virtualization, :containers, :storage_basic]
  "8.0": [...previous, :sdn_tech_preview, :realm_sync]
  "8.2": [...previous, :backup_providers, :vmware_import]
  "9.0": [...previous, :sdn_fabrics, :ha_affinity]
}
```

## Visualization and Validation

### View the Architecture
To visualize the complete architecture model:

```bash
# Validate the C4 model
make arch-validate

# Start interactive visualization
make arch-viz
# Then open http://localhost:8080
```

### Manual Commands
```bash
# Validate C4 DSL syntax
podman run --rm -v $(pwd)/architecture:/usr/local/structurizr \
  structurizr/cli validate -w workspace.dsl

# Interactive visualization
podman run -p 8080:8080 -v $(pwd)/architecture:/usr/local/structurizr \
  structurizr/lite
```

### Available Views
- **System Context**: High-level system relationships
- **Container View**: Internal container structure
- **Component Views**: Detailed component breakdown for each container
- **Deployment Views**: Different deployment scenarios
- **Dynamic Views**: Request and state update flows

## Architecture Evolution

### Current State (v0.1.0)
- Core API simulation with basic endpoints
- In-memory state management
- Version compatibility system
- Container-ready deployment

### Planned Evolution (v0.2.0 - v1.0.0)
- **Enhanced API Coverage**: More PVE endpoints and operations
- **State Persistence**: Optional SQLite backend for state
- **WebSocket Support**: Real-time console/event simulation
- **Plugin Architecture**: Extensible endpoint and behavior system
- **Performance Optimization**: Caching and connection pooling
- **Observability**: Metrics, tracing, and monitoring integration

### Future Considerations
- **Multi-instance State Sharing**: Redis-backed shared state
- **Event Streaming**: Kafka/NATS for event simulation
- **GraphQL Interface**: Alternative API interface
- **gRPC Support**: High-performance protocol option

## Contributing to Architecture

### Architecture Changes
1. **Propose changes** via ADR (Architecture Decision Record)
2. **Update C4 model** to reflect structural changes
3. **Validate model** using Structurizr CLI
4. **Review impact** on existing components and interfaces
5. **Document migration path** for breaking changes

### Architecture Reviews
- All significant architectural changes require design review
- C4 model must be updated for structural changes
- ADRs required for major technology or pattern decisions
- Performance impact assessment for architectural changes

## Links and References

- **C4 Model**: https://c4model.com/
- **Structurizr**: https://structurizr.com/
- **Elixir/OTP**: https://elixir-lang.org/
- **Proxmox VE API**: https://pve.proxmox.com/pve-docs/api-viewer/
- **Container Architecture**: https://12factor.net/

---

This architecture documentation is maintained alongside the codebase and should be updated whenever significant structural changes are made to the system.