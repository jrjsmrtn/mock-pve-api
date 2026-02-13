# 2. Adopt Development Best Practices

Date: 2025-01-30

## Status

Accepted

## Context

The mock-pve-api project requires adherence to professional development practices that ensure code quality, maintainability, documentation clarity, and operational reliability. The project follows AI-Assisted Project Orchestration patterns that emphasize systematic development methodologies for testing infrastructure.

We need established practices for:
1. **Code Quality**: Ensuring reliable Proxmox VE API simulation functionality
2. **Testing Strategy**: Validating behavior against real PVE API requirements
3. **Version Management**: Clear progression from development to production-ready container images
4. **Documentation**: Multiple audiences from developers to DevOps engineers to end users
5. **Architecture Tracking**: Evolution of complex multi-version API simulation
6. **Change Management**: Controlled releases with clear history for container registry distribution

The project's unique characteristics as a testing infrastructure tool require specific considerations:
- Container-first deployment strategy with Docker Hub distribution
- Multi-version PVE API compatibility (7.x, 8.x, 9.x series)
- CI/CD integration patterns across multiple platforms
- Elixir/OTP technology stack with HTTP/HTTPS endpoint simulation
- Community-driven development with contributor onboarding needs

## Decision

We will adopt comprehensive development best practices covering testing, versioning, workflow, documentation, architecture management, and sprint-based development lifecycle tailored to the mock-pve-api project.

### Test-Driven Development (TDD)
**Approach**: Red-Green-Refactor cycle for API endpoint development
- **Red**: Write failing test for desired PVE API endpoint behavior
- **Green**: Implement minimal handler code to make endpoint test pass
- **Refactor**: Improve endpoint implementation while maintaining comprehensive test coverage

**Target**: >85% test coverage with emphasis on endpoint validation and version compatibility

### Semantic Versioning Strategy
**Initial Development**: 0.x.y on develop branch (current: 0.4.5)
- **0.1.0**: Initial Elixir/OTP Mock PVE API integration
- **0.2.0**: Basic endpoint functionality working
- **0.3.0**: API coverage matrix implementation
- **0.4.0**: Complete endpoint implementation (37/37 endpoints)
- **0.4.x**: SSL/TLS, testing, and quality improvements
- **0.5.x**: Docker Hub release and community distribution

**Production Releases**: Following semantic versioning for container registry
- **1.0.0**: Production-ready with >95% PVE API endpoint coverage and Docker Hub distribution
- **1.x.y**: Backward-compatible endpoint additions and bug fixes
- **2.0.0**: Breaking changes (if needed for major PVE API evolution)

### Git Workflow (Gitflow-based)
**Branch Strategy**:
- **main**: Production-ready releases only (container registry tags)
- **develop**: Integration branch for active development
- **feature/**: Individual feature development (endpoint implementation, SSL/TLS, etc.)
- **hotfix/**: Critical production fixes for container images
- **release/**: Preparation for Docker Hub releases

### Change Documentation (Keep a Changelog)
**Format**: Follow [keepachangelog.com](https://keepachangelog.com/) format
- **Added**: New PVE API endpoints, features, capabilities
- **Changed**: Changes in existing endpoint behavior or configuration
- **Deprecated**: Soon-to-be removed features or API versions
- **Removed**: Removed endpoints or deprecated PVE version support
- **Fixed**: Bug fixes in API simulation or container deployment
- **Security**: Security vulnerabilities in HTTPS implementation or container images

### Architecture as Code (C4 DSL)
**Approach**: Use C4 DSL for Mock PVE API architecture documentation and validation
- **System Context**: Mock PVE API Server in CI/CD and testing ecosystem
- **Container View**: Elixir/OTP application, HTTP/HTTPS endpoints, state management
- **Component View**: Router, handlers, capability matrix, fixture management
- **Code View**: Key abstractions for endpoint simulation and version compatibility

**Validation Process**:
```bash
# Validate C4 DSL files using Podman (preferred)
podman run --rm -v "$(pwd)/docs/architecture:/usr/local/structurizr" \
  structurizr/cli validate -workspace workspace.dsl

# Generate documentation
podman run --rm -p 8080:8080 \
  -v "$(pwd)/docs/architecture:/usr/local/structurizr" structurizr/lite
```

### Sprint-Based Development Lifecycle
**Approach**: Use Agile-inspired sprint methodology for systematic feature development
- **Sprint Duration**: 2-week sprints with clear API coverage deliverables
- **Sprint Planning**: Define sprint goals, endpoint implementation targets, and acceptance criteria
- **Daily Progress**: Track development progress and impediment identification
- **Sprint Review**: Demonstrate completed API endpoints and validate against PVE compatibility requirements
- **Sprint Retrospective**: Continuous improvement of endpoint development and testing process

### Documentation Framework (Diataxis)
**Four Documentation Types**:
1. **Tutorials** (Learning-oriented): Getting started guides for new users and contributors
2. **How-to Guides** (Problem-oriented): Specific integration task solutions (CI/CD, multi-version testing)
3. **Reference** (Information-oriented): Complete API endpoint documentation and configuration reference
4. **Explanation** (Understanding-oriented): Architecture decisions, PVE version compatibility, and design rationale

**Structure**:
```
docs/
├── tutorials/          # Learning-oriented (getting started, first tests)
├── howto/             # Problem-oriented (CI/CD integration, client setup)
├── reference/         # Information-oriented (API endpoints, environment variables)
├── explanation/       # Understanding-oriented (architecture, version compatibility)
└── adr/              # Architecture decisions
```

### Container-First Development
**Approach**: Podman-first, Docker-compatible containerization strategy
- **Development**: Volume mounts for live reload during endpoint development
- **Testing**: Container-based integration tests against running mock server
- **Distribution**: Multi-architecture builds (amd64, arm64) for Docker Hub
- **CI/CD**: Native container integration for GitHub Actions, GitLab CI, Jenkins
- **Security**: Rootless containers, vulnerability scanning, comprehensive SBOM generation

### Supply Chain Security & SBOM Generation
**Approach**: Comprehensive Software Bill of Materials (SBOM) generation for supply chain transparency
- **SBOM Formats**: Support for SPDX 2.3, CycloneDX 1.4, and custom Mix dependency formats
- **Dependency Tracking**: Complete Elixir/OTP dependency tree analysis with version pinning
- **Vulnerability Scanning**: Automated security scanning with Syft and Grype tools  
- **CI/CD Integration**: SBOM generation integrated into GitHub Actions release pipeline
- **Transparency**: Public SBOM availability for container images and releases
- **Compliance**: Meets enterprise and government supply chain security requirements

**SBOM Generation Workflow**:
```bash
# Generate comprehensive SBOMs
make sbom-generate          # Generate all SBOM formats
make sbom-spdx             # SPDX JSON format for compliance
make sbom-cyclonedx        # CycloneDX format for tooling integration
make vulnerability-scan    # Security vulnerability assessment
```

### Consistent Quality Gates
**Approach**: Escalating quality gate chain — fast local checks, thorough pre-push validation, comprehensive CI

**Local Development**:
- **`.editorconfig`**: Enforces consistent formatting (UTF-8, LF, 2-space indent for Elixir, tabs for Makefiles)
- **Lefthook**: Git hook manager replacing ad-hoc shell scripts
  - **Pre-commit** (parallel): `mix format --check-formatted`, `mix compile --warnings-as-errors`, `mix docs.coverage --check` (conditional on coverage.ex changes), `gitleaks protect --staged` (secret detection)
  - **Pre-push**: `mix test`
- **SPDX headers**: All source files carry `SPDX-FileCopyrightText` and `SPDX-License-Identifier` headers

**CI (GitHub Actions)**:
- Format check, compile with `--force --warnings-as-errors`, test with coverage, documentation generation
- Security audit with SBOM generation and vulnerability scanning
- Container build and multi-version integration tests

**Quality Gate Chain**:

| Check | Pre-commit | Pre-push | CI |
|-------|-----------|----------|-----|
| `mix format --check-formatted` | yes | - | yes |
| `mix compile --warnings-as-errors` | yes | - | yes (--force) |
| `mix docs.coverage --check` | conditional | - | - |
| `gitleaks protect --staged` | yes | - | - |
| `gitleaks detect` | - | - | yes |
| `mix test` | - | yes | yes (--cover) |
| `mix docs` | - | - | yes |
| Security audit / SBOM | - | - | yes |
| Container build + integration | - | - | yes |

### Erlef Aegis & OpenSSF Compliance
**Approach**: Align with the [EEF Security Working Group's Aegis initiative](https://security.erlef.org/aegis/) and [OpenSSF](https://openssf.org/) best practices to strengthen supply chain security and meet emerging regulations (EU CRA, NIST SSDF).

**Aegis alignment**:
- **SBOM generation**: SPDX and CycloneDX formats for all releases (see Supply Chain Security section above)
- **SPDX licence headers**: Machine-readable copyright and licence metadata on all source files
- **Secret detection**: [Gitleaks](https://github.com/gitleaks/gitleaks) scans staged changes at pre-commit and full history in CI
- **Vulnerability handling**: Automated scanning with Grype integrated into CI pipeline
- **Dependency tracking**: Complete Elixir/OTP dependency tree with version pinning via `mix.lock`
- **Account security**: Follow Hex.pm recommendations for maintainer authentication as they evolve

**OpenSSF Scorecard alignment**:
- **Branch protection**: Main branch protected; PRs required for merges
- **CI tests**: Automated test suite runs on every push and PR
- **Code review**: All PRs require review before merge
- **Dependency updates**: Pinned dependencies with regular update checks
- **Licence**: SPDX-compliant MIT licence with machine-readable headers
- **Security policy**: Vulnerability disclosure and security audit practices
- **Signed releases**: Target signed container images and package provenance as Aegis tooling matures

## Consequences

**Positive:**
- Code Quality: TDD ensures reliable PVE API endpoint functionality
- Clear Evolution: Semantic versioning provides predictable upgrade paths for container users
- Controlled Releases: Gitflow manages development complexity and Docker Hub publishing
- Change Transparency: Keep a Changelog format aids users and maintainers of container images
- Architecture Visibility: C4 DSL provides clear system understanding for contributors
- Comprehensive Documentation: Diataxis serves all user types effectively (developers, DevOps, end users)
- Professional Standards: Industry best practices increase adoption confidence and Docker Hub credibility
- Iterative Development: Sprint-based approach enables rapid feedback and course correction
- Container Quality: Systematic approach to container image security and distribution
- Supply Chain Security: SBOM generation provides transparency and vulnerability tracking for dependencies
- Consistent Quality Gates: Escalating pre-commit/pre-push/CI chain catches issues early without slowing development
- Regulatory Readiness: Aegis and OpenSSF alignment prepares the project for EU CRA and NIST SSDF requirements

**Negative:**
- Development Overhead: Additional process steps slow initial endpoint development
- Tool Dependencies: Requires familiarity with multiple tools and frameworks (Elixir, Podman, C4 DSL, lefthook)
- Maintenance Commitment: Documentation and architecture models need ongoing updates with PVE API evolution
- Sprint Overhead: Sprint ceremonies add time overhead to development process
- Evolving Standards: Aegis and OpenSSF recommendations are still maturing; practices may need revision as tooling stabilises

## Implementation Plan

### Phase 1: Core Practices (Completed)
- [x] Set up TDD workflow with comprehensive test suite (37/37 endpoints tested)
- [x] Initialize CHANGELOG.md with current state and version history
- [x] Configure gitflow branching in repository (main/develop strategy)
- [x] Create initial C4 DSL architecture model

### Phase 2: Documentation Framework (Completed)
- [x] Establish Diataxis documentation structure
- [x] Convert existing documentation to appropriate categories
- [x] Create comprehensive tutorial and reference content
- [x] Set up C4 DSL validation in development workflow

### Phase 3: Process Integration (In Progress)
- [x] Integrate practices into development workflow
- [x] Document contribution guidelines
- [x] Set up automated validation where possible
- [ ] Train team on adopted practices (community onboarding)

### Phase 4: Container Excellence (In Progress)
- [x] Implement SSL/TLS support for HTTPS endpoints
- [x] Add SBOM generation for supply chain security
- [ ] Complete Docker Hub release automation
- [ ] Implement multi-architecture container builds

### Phase 5: Quality Gates & Compliance (In Progress)
- [x] Add `.editorconfig` for consistent editor formatting
- [x] Replace ad-hoc pre-commit hook with lefthook (pre-commit + pre-push)
- [x] Add SPDX copyright/licence headers to all source files
- [x] Modernise GitHub Actions workflow (actions/cache@v4, upload-artifact@v4, `--force` compile)
- [x] Add gitleaks secret detection (pre-commit via lefthook, CI via gitleaks-action)
- [ ] Evaluate OpenSSF Scorecard and address findings
- [ ] Adopt Hex.pm account security recommendations as Aegis tooling matures
- [ ] Add signed container image provenance

## Validation Criteria

These practices will be validated through:
1. **Test Coverage**: Maintain >85% test coverage through TDD ✓ (Current: 36/52 tests passing)
2. **Version Compliance**: Semantic versioning followed in all releases ✓ (Current: v0.4.5)
3. **Git History**: Clean, meaningful commit history following gitflow ✓
4. **Change Documentation**: All releases documented in changelog ✓
5. **Architecture Currency**: C4 DSL models updated with implementation changes ✓
6. **Documentation Completeness**: All four Diataxis types populated and maintained ✓
7. **Container Quality**: Successful Docker Hub distribution with security scanning ⏳
8. **Supply Chain Security**: SBOM generation for all releases with vulnerability assessment ✓
9. **Quality Gates**: Pre-commit and pre-push hooks enforced via lefthook; CI pipeline green ✓
10. **SPDX Compliance**: All source files carry machine-readable licence headers ✓
11. **OpenSSF Scorecard**: Target score improvement as checks are addressed ⏳

## Related Decisions

- ADR-0001: Record architecture decisions (establishes documentation process)
- ADR-0003: Elixir/OTP implementation choice (will follow these established practices)
- Future ADRs: Container deployment, API coverage strategy, version compatibility matrix