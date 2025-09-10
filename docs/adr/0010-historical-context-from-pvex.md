# ADR-0010: Historical Context from pvex Project

**Date:** 2025-08-30  
**Status:** Accepted and Documented  
**Deciders:** Development Team

## Context and Problem Statement

The Mock PVE API Server was originally developed as part of the pvex project (Proxmox VE API Client for Elixir) during Sprint G to enable infrastructure-independent testing. The embedded mock server proved so valuable that it warranted extraction as a standalone project to serve the broader Proxmox VE ecosystem. This ADR documents the historical context, achievements, and rationale for the extraction.

## Original Implementation Context (pvex Sprint G)

### **Problem Statement in pvex**
The pvex library supported two types of testing: unit tests with mocked HTTP calls and integration tests against real Proxmox VE instances. While this approach ensured both isolated testing and real-world validation, it created barriers for:
- Contributors without access to PVE infrastructure
- CI/CD pipelines in cloud environments
- Automated testing requiring consistent, predictable environments
- Version compatibility testing across PVE 7.x and 8.x series

### **Implementation Architecture**
```
pvex/test/support/mock_pve_server/
├── lib/
│   ├── mock_pve_server.ex           # Main application
│   ├── mock_pve_server/router.ex    # HTTP routing
│   ├── mock_pve_server/handlers/    # API endpoint handlers
│   └── mock_pve_server/state.ex     # Stateful resource management
├── responses/
│   ├── pve7/                        # PVE 7.x response fixtures  
│   └── pve8/                        # PVE 8.x response fixtures
├── mix.exs                          # Mock server dependencies
└── Dockerfile                       # Container definition
```

### **Sprint G Achievements (2025-08-30)**

**Validation Results:**
- ✅ **Mock Server Functionality**: 7/7 basic integration tests pass (100%)
- ✅ **Unit Test Infrastructure**: 135/135 core resource tests pass (100%)
- ✅ **API Coverage**: Version detection, nodes, storage, clusters, resource pools
- ✅ **Version Compatibility**: Granular PVE version support (7.0-8.3) with feature detection
- ✅ **CI/CD Ready**: No external infrastructure dependencies for core testing
- ✅ **Developer Productivity**: Fast feedback loops with infrastructure-independent testing

**Technical Achievements:**
- **Mock PVE Server**: Lightweight Elixir/Plug implementation with realistic API responses
- **State Management**: In-memory resource lifecycle tracking for testing scenarios  
- **Version Engine**: Capabilities-based feature availability (SDN 8.0+, notifications 8.1+, etc.)
- **Response Fixtures**: Version-specific JSON fixtures matching real PVE API schemas
- **Test Integration**: Seamless integration with existing ExUnit test suite
- **Container Support**: Ready for Podman/Docker deployment in CI environments

**Performance Metrics:**
- **Startup Time**: < 1 second for mock server initialization
- **Test Execution**: Core unit tests run in 3.2 seconds (135 tests)
- **Resource Usage**: Minimal memory footprint for CI/CD environments
- **API Response Time**: < 100ms for simulated API calls

## Decision to Extract as Standalone Project

### **Rationale for Extraction**
1. **Ecosystem Value**: The mock server proved valuable beyond Elixir/pvex ecosystem
2. **Language Agnostic**: Docker containerization enables use with any programming language
3. **Broader Adoption**: Standalone project can serve Python, JavaScript, Go, Ruby, and other PVE clients
4. **Focused Development**: Dedicated project allows specialized features for testing scenarios
5. **Community Contribution**: Enables broader Proxmox VE community to contribute and benefit

### **Extraction Strategy**
- **Module Renaming**: MockPveServer → MockPveApi for clarity and branding
- **Project Structure**: Complete Mix project with Hex.pm packaging capability
- **Documentation**: Comprehensive ADRs, C4 architecture model, and multi-language examples
- **Docker Hub Distribution**: Professional container images for easy adoption
- **Backward Compatibility**: Maintain embedded version in pvex during transition period

## Historical Achievements Carried Forward

### **Version Support Matrix**
The mock server implements granular version support proven in pvex:

**PVE 7.x Series**
- 7.0: Basic virtualization, containers, storage
- 7.1: + Ceph Octopus support
- 7.2: + Network improvements
- 7.3: + Ceph Pacific support  
- 7.4: + cgroupv1, pre-upgrade validation

**PVE 8.x Series**
- 8.0: SDN (tech preview), realm sync, resource mappings, cgroupv2
- 8.1: + Enhanced notifications (webhooks, filters)
- 8.2: + VMware import wizard, backup providers, auto-install
- 8.3: + OVA import improvements, kernel 6.11 opt-in

**PVE 9.x Series** (Future)
- 9.0: Enhanced SDN Fabric, HA Resource Affinity, LVM Snapshots, ZFS RAIDZ

### **Proven Test Infrastructure Patterns**
From pvex MockPveHelper module:
- Server lifecycle management (start/stop/reset)
- Version-specific configuration
- State management and test data setup
- Connection health checking with retries
- Test environment isolation

### **Battle-Tested API Coverage**
- **Core Operations**: VM/Container lifecycle, configuration, monitoring
- **Storage Management**: Local, NFS, CIFS, ZFS, Ceph operations
- **Cluster Operations**: Node management, resource enumeration
- **Resource Pools**: Pool management and member operations
- **User Management**: Users, roles, permissions (basic simulation)
- **Version-Specific Features**: SDN, notifications, backup providers with proper 501 responses

## Impact on pvex Project

### **Transition Plan**
1. **Phase 1**: Announce standalone mock-pve-api project
2. **Phase 2**: Update pvex documentation to reference external mock server
3. **Phase 3**: Add deprecation notices to embedded mock server
4. **Phase 4**: Migrate pvex CI/CD to use Docker Hub images
5. **Phase 5**: Remove embedded mock server in future pvex major version

### **Maintained Compatibility**
- pvex continues to work with embedded mock server during transition
- MockPveHelper utilities remain functional
- Existing test suites continue to pass without modification
- Optional migration to external mock server for improved performance

## Success Metrics from pvex

The mock server's success in pvex provides baseline metrics for standalone adoption:
- **Test Reliability**: 100% test pass rate across 135+ tests
- **Developer Productivity**: Eliminated need for PVE infrastructure in development
- **CI/CD Enablement**: Enabled infrastructure-independent continuous integration
- **Version Coverage**: Comprehensive support for PVE 7.0 through 8.3
- **Performance**: Sub-second startup, sub-100ms response times

## Links

* [Original] [pvex ADR-013: Mock Testing Strategy](https://github.com/jrjsmrtn/pvex/blob/main/docs/adr/013-mock-testing-strategy.md)
* [Relates to] [ADR-0003: Elixir/OTP Implementation Choice](0003-elixir-otp-implementation-choice.md)
* [Relates to] [ADR-0004: Plug Framework Selection](0004-plug-over-phoenix-minimal-framework.md)
* [Enables] Broader Proxmox VE ecosystem testing capabilities
* [Supports] Multi-language client library development and testing