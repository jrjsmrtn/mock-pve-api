# Architecture Decision Records

This document provides an overview of key architectural decisions made during the development of the Mock PVE API Server. Each decision record explains the context, options considered, and rationale behind important design choices.

## Decision Process

Architecture Decision Records (ADRs) capture important architectural decisions along with their context and consequences. This helps current and future contributors understand why certain choices were made and provides a foundation for future architectural evolution.

### Decision States

- **Proposed**: Under consideration
- **Accepted**: Decision made and implemented
- **Deprecated**: No longer recommended but still supported
- **Superseded**: Replaced by a newer decision

## Current Architecture Decisions

### Core Technology Stack

#### [ADR-001: Elixir/OTP for Mock Server Implementation](../adr/001-elixir-otp-implementation.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Use Elixir/OTP with GenServer state management for the core mock server implementation.

**Key Points**:
- Excellent concurrency handling through the Actor model
- Built-in fault tolerance via OTP supervision trees
- Consistent state management with GenServer serialization
- Natural pattern matching for API request routing
- Low memory footprint with lightweight processes

**Trade-offs**: Learning curve for functional programming, specialized knowledge required

---

#### [ADR-002: Plug over Phoenix for HTTP Handling](../adr/002-plug-over-phoenix.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Use Plug directly with Cowboy rather than the full Phoenix framework.

**Key Points**:
- Minimal overhead for API-only service
- Faster startup time and lower memory usage
- Direct control over HTTP request/response handling
- Easier to reason about with simpler codebase

**Trade-offs**: Manual implementation of features that Phoenix provides

---

### State and Data Management

#### [ADR-003: In-Memory State Management](../adr/003-in-memory-state-management.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Use in-memory GenServer state rather than persistent storage.

**Key Points**:
- Zero external dependencies for deployment
- Fast response times for API operations
- Simple state reset between test runs
- Suitable for testing and development use cases

**Trade-offs**: State lost on container restart, limited to single-node deployment

---

#### [ADR-004: Capability Matrix for Version Compatibility](../adr/004-capability-matrix-version-compatibility.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Implement feature availability through a capability matrix system.

**Key Points**:
- Version-specific feature availability
- Clean separation between version logic and API handlers
- Extensible system for future PVE versions
- Proper error responses for unsupported features

**Trade-offs**: Additional complexity in endpoint handlers

---

### Deployment and Configuration

#### [ADR-005: Container-First Deployment Strategy](../adr/005-container-first-deployment.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Design for container deployment with Docker/Podman as primary distribution method.

**Key Points**:
- Consistent runtime environment across platforms
- Easy integration with CI/CD pipelines
- Simplified dependency management
- Scalable deployment options

**Trade-offs**: Container runtime overhead, more complex local development

---

#### [ADR-006: Environment Variable Configuration](../adr/006-environment-variable-configuration.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Use environment variables for runtime configuration with sensible defaults.

**Key Points**:
- Container-friendly configuration approach
- Easy integration with orchestration systems
- Runtime configuration without rebuilding images
- Clear separation between compile-time and runtime settings

**Trade-offs**: Configuration scattered across environment, validation complexity

---

### API Design and Coverage

#### [ADR-007: Comprehensive API Coverage Matrix](../adr/007-comprehensive-api-coverage-matrix.md)
**Status**: Accepted | **Date**: 2025-08-30

**Decision**: Implement a systematic API coverage tracking and validation system.

**Key Points**:
- Structured approach to endpoint implementation
- Clear visibility into coverage gaps
- Automated validation of implementation status
- Priority-based development roadmap

**Trade-offs**: Additional metadata maintenance overhead

---

### Historical Context

#### [ADR-013: Historical Context from pvex](../adr/013-historical-context-from-pvex.md)
**Status**: Accepted | **Date**: 2025-01-30

**Decision**: Extract and evolve the mock server functionality from the pvex project.

**Key Points**:
- Leverages proven mock server architecture
- Extends functionality for broader ecosystem use
- Maintains compatibility with existing pvex patterns
- Enables standalone distribution and maintenance

**Trade-offs**: Additional project maintenance overhead, coordination between projects

## Architecture Patterns

### Request Flow Architecture
```
HTTP Request → Plug Router → Handler Module → State GenServer → Response
```

1. **HTTP Layer**: Cowboy web server with Plug middleware
2. **Routing**: Pattern-matched routing to specific handlers
3. **Handlers**: Business logic for each API endpoint group
4. **State Layer**: Centralized GenServer for resource state
5. **Response**: JSON-formatted responses matching PVE API schema

### State Management Pattern
```elixir
# Centralized state in MockPveApi.State GenServer
%{
  version: "8.3",
  capabilities: %{sdn: true, backup_providers: true},
  nodes: %{"pve-node-1" => %{status: "online", ...}},
  vms: %{100 => %{name: "test-vm", status: "running", ...}},
  containers: %{200 => %{name: "test-ct", status: "running", ...}},
  pools: %{"production" => %{members: [...], ...}},
  storage: %{"local" => %{type: "dir", ...}}
}
```

### Version Compatibility Pattern
```elixir
# Feature availability through capability checking
case MockPveApi.Capabilities.supports?(version, :sdn_tech_preview) do
  true -> handle_sdn_request(conn, params)
  false -> send_not_implemented_error(conn, "SDN features require PVE 8.0+")
end
```

## Design Principles

### 1. Simplicity Over Features
Prioritize simple, maintainable solutions over complex feature completeness. The mock server should be easy to understand, modify, and extend.

### 2. Container-First Design
All architectural decisions consider container deployment as the primary use case, with local development as secondary.

### 3. Version Fidelity
Accurate simulation of PVE version differences is more important than implementing every possible endpoint.

### 4. Zero Dependencies
Minimize external runtime dependencies to ensure reliable deployment across different environments.

### 5. Fail-Safe Defaults
Default configuration should work out-of-the-box for the most common use cases without requiring configuration.

## Evolution and Future Decisions

### Planned Decisions
- **Authentication System Design**: How to implement optional authentication simulation
- **Multi-Node Clustering**: Whether to support multiple mock nodes in a single instance
- **Plugin Architecture**: Extensibility mechanism for custom endpoints
- **Performance Optimization**: Caching strategies and response optimization

### Decision Review Process
Architecture decisions should be reviewed when:
- Performance problems are identified
- New PVE versions introduce breaking changes
- Community feedback suggests alternative approaches
- Security vulnerabilities are discovered
- Maintenance burden becomes excessive

## Contributing to Architecture

When proposing significant architectural changes:

1. **Create an ADR**: Document the context, options, and reasoning
2. **Seek Feedback**: Discuss with maintainers and community
3. **Consider Impact**: Evaluate effects on existing users
4. **Plan Migration**: Define migration path for breaking changes
5. **Update Documentation**: Keep architecture docs current

---

*Architecture decisions are living documents. As the Mock PVE API Server evolves, these decisions may be revisited and updated to reflect new requirements and understanding.*