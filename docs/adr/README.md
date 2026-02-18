# Architecture Decision Records

This directory contains Architecture Decision Records (ADRs) for the Mock PVE API project, documenting significant architectural decisions made during development.

## Foundation ADR Sequence

The project follows the **AI-Assisted Project Orchestration** pattern language, starting with three foundation ADRs that establish systematic development practices:

### ADR-0001: Record Architecture Decisions
**[0001-record-architecture-decisions.md](0001-record-architecture-decisions.md)**
- **Status**: Accepted
- **Purpose**: Establishes systematic tracking of architectural decisions
- **Impact**: Enables effective team communication and AI-assisted development context

### ADR-0002: Adopt Development Best Practices  
**[0002-adopt-development-best-practices.md](0002-adopt-development-best-practices.md)**
- **Status**: Accepted
- **Purpose**: Comprehensive development practices for testing infrastructure
- **Key Practices**: TDD, Semantic Versioning, Gitflow, Keep a Changelog, C4 DSL, Diátaxis Documentation, Sprint-based Development, Container-first approach

### ADR-0003: Elixir/OTP Implementation Choice
**[0003-elixir-otp-implementation-choice.md](0003-elixir-otp-implementation-choice.md)**
- **Status**: Accepted
- **Purpose**: Technology stack decision for concurrent HTTP API simulation
- **Rationale**: Actor model, fault tolerance, development velocity, container deployment characteristics

## Implementation ADRs

The following ADRs document specific implementation decisions for the Mock PVE API Server:

### ADR-0004: Plug over Phoenix for Minimal Framework Footprint
**[0004-plug-over-phoenix-minimal-framework.md](0004-plug-over-phoenix-minimal-framework.md)**
- **Status**: Accepted
- **Purpose**: HTTP framework choice balancing functionality and resource usage
- **Decision**: Plug middleware over full Phoenix framework for container optimization

### ADR-0005: In-Memory State Management Strategy
**[0005-in-memory-state-management.md](0005-in-memory-state-management.md)**
- **Status**: Accepted  
- **Purpose**: State persistence approach for realistic API simulation
- **Decision**: GenServer-based in-memory state for simplicity and performance

### ADR-0006: Capability Matrix for Version Compatibility
**[0006-capability-matrix-version-compatibility.md](0006-capability-matrix-version-compatibility.md)**
- **Status**: Accepted
- **Purpose**: Multi-version PVE API compatibility strategy
- **Decision**: Capability-based feature detection across PVE 7.x, 8.x, 9.x series

### ADR-0007: Container-First Deployment Strategy
**[0007-container-first-deployment.md](0007-container-first-deployment.md)**
- **Status**: Accepted
- **Purpose**: Distribution and deployment approach for testing infrastructure
- **Decision**: OCI registry distribution with Podman-first, Docker-compatible containers

### ADR-0008: Environment Variable Configuration Strategy
**[0008-environment-variable-configuration.md](0008-environment-variable-configuration.md)**
- **Status**: Accepted
- **Purpose**: Runtime configuration approach for container deployments
- **Decision**: Environment variable-based configuration with runtime evaluation

### ADR-0009: Comprehensive API Coverage Matrix
**[0009-comprehensive-api-coverage-matrix.md](0009-comprehensive-api-coverage-matrix.md)**
- **Status**: Implemented
- **Purpose**: Systematic tracking of PVE API endpoint implementation
- **Achievement**: 37/37 endpoints (100% coverage) with systematic documentation

### ADR-0010: Historical Context from pvex Project
**[0010-historical-context-from-pvex.md](0010-historical-context-from-pvex.md)**
- **Status**: Accepted and Documented
- **Purpose**: Document extraction rationale and achievements from original pvex project
- **Context**: Sprint G achievements, validation results, extraction strategy

## ADR Process

### Creating New ADRs
1. Use `adr new "Decision Title"` or create manually using foundation templates
2. Follow the established format: Status, Context, Decision, Consequences
3. Number sequentially starting from ADR-0011
4. Review during architecture discussions and sprint planning

### ADR Lifecycle
- **Proposed**: Under consideration
- **Accepted**: Approved and implemented
- **Deprecated**: Superseded by newer decisions  
- **Superseded**: Replaced by specific newer ADR

### Decision Criteria
- **Significant Impact**: Affects system architecture, technology choices, or development process
- **Hard to Reverse**: Decisions that are costly or difficult to change later
- **Team Alignment**: Decisions requiring team-wide understanding and agreement
- **API Simulation Fidelity**: Decisions affecting accuracy of Proxmox VE API behavior
- **Container Deployment**: Decisions affecting deployment, scalability, or CI/CD integration

## Architecture Evolution

The ADRs document the evolution of the Mock PVE API Server from initial extraction through production-ready container distribution:

1. **Foundation (ADR 0001-0003)**: Established systematic development practices
2. **Implementation (ADR 0004-0006)**: Core technology and architecture decisions  
3. **Deployment (ADR 0007-0008)**: Production deployment and configuration strategies
4. **Completeness (ADR 0009-0010)**: API coverage achievement and project context

## Links

- [ADR Tools](https://github.com/npryce/adr-tools) - Command line tools for ADRs
- [AI-Assisted Project Orchestration](https://github.com/user/ai-assisted-project-orchestration) - Pattern language source
- [Documenting Architecture Decisions](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions) - Original ADR concept
- [C4 Model](https://c4model.com/) - Architecture documentation approach used in ADR-0002

---

*Architecture Decision Records enable systematic documentation of architectural choices and provide essential context for AI-assisted development and team collaboration.*