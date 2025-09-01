# PVE API Coverage Matrix

This document provides a comprehensive overview of Proxmox VE API endpoint coverage in the mock-pve-api server. Based on analysis of the pvex project (97.8% API coverage across 305+ endpoints), this matrix tracks implementation status, version compatibility, and development priorities.

## Coverage Overview

The mock-pve-api server implements a structured approach to PVE API coverage with systematic tracking of endpoint implementation status across all supported PVE versions (7.0 - 9.0).

### Coverage Statistics

| Category | Total Endpoints | Implemented | Partial | Planned | Coverage % |
|----------|----------------|-------------|---------|---------|------------|
| **Version** | 1 | 1 | 0 | 0 | 100% |
| **Cluster** | 6 | 2 | 0 | 4 | 33% |
| **Nodes** | 4 | 3 | 0 | 1 | 75% |
| **Virtual Machines** | 5 | 3 | 2 | 0 | 100% |
| **LXC Containers** | 3 | 2 | 1 | 0 | 100% |
| **Storage** | 3 | 2 | 1 | 0 | 100% |
| **Access Control** | 4 | 1 | 0 | 3 | 25% |
| **Resource Pools** | 2 | 1 | 0 | 1 | 50% |
| **TOTAL** | **28** | **15** | **4** | **9** | **68%** |

## Status Legend

- ✅ **:implemented** - Fully implemented with comprehensive functionality
- 🟡 **:partial** - Core functionality available, some advanced features missing  
- 🔄 **:in_progress** - Currently being developed
- 📋 **:planned** - Planned for implementation
- ❌ **:not_supported** - Not supported/not planned
- 🔴 **:pve8_only** - Available in PVE 8.x+ only
- 🟠 **:pve9_only** - Available in PVE 9.x+ only

## Priority Levels

- **Critical**: Essential endpoints required for basic PVE client functionality
- **High**: Important endpoints for common operations
- **Medium**: Useful endpoints for advanced features  
- **Low**: Optional endpoints for specialized use cases

---

## Version Information

### `/api2/json/version` ✅

**Status**: :implemented | **Priority**: Critical | **Since**: PVE 6.0

Get PVE version information and server details.

**Methods**: GET  
**Parameters**: None  
**Handler**: `MockPveApi.Handlers.Version`  
**Test Coverage**: ✅

**Response Schema**:
```json
{
  "data": {
    "version": "8.3",
    "release": "8.3", 
    "repoid": "f123456d",
    "keyboard": "en-us"
  }
}
```

---

## Cluster Management

### `/api2/json/cluster/status` ✅

**Status**: :implemented | **Priority**: Critical | **Since**: PVE 6.0

Get cluster status and node information.

**Methods**: GET  
**Parameters**: None  
**Handler**: `MockPveApi.Handlers.Cluster`  
**Test Coverage**: ✅

### `/api2/json/cluster/resources` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

Get cluster resource overview (VMs, containers, storage).

**Methods**: GET  
**Parameters**:
- `type` (optional): Filter by resource type (`vm`, `storage`, `node`, `sdn`)

**Handler**: `MockPveApi.Handlers.Cluster`  
**Test Coverage**: ✅

### `/api2/json/cluster/config/join` 📋

**Status**: :planned | **Priority**: Medium | **Since**: PVE 6.0

Join node to existing cluster.

**Methods**: POST  
**Parameters**:
- `hostname` (required): Cluster hostname
- `nodeid` (optional): Node ID
- `votes` (optional): Number of votes (default: 1)

**Notes**: Cluster management operations planned for Phase 4

### `/api2/json/cluster/sdn/zones` ✅ 🔴

**Status**: :implemented | **Priority**: Medium | **Since**: PVE 8.0

Software Defined Networking zone management.

**Methods**: GET, POST  
**Capabilities Required**: `:sdn_tech_preview`  
**Handler**: `MockPveApi.Handlers.SDN`  
**Test Coverage**: ✅

**Notes**: SDN features available in PVE 8.0+ only

### `/api2/json/cluster/sdn/zones/{zone}` 📋 🔴

**Status**: :planned | **Priority**: Medium | **Since**: PVE 8.0

Individual SDN zone operations.

**Methods**: GET, PUT, DELETE  
**Parameters**:
- `zone` (required): Zone identifier

**Capabilities Required**: `:sdn_tech_preview`  
**Notes**: Individual zone CRUD operations planned

### `/api2/json/cluster/backup-info/providers` 🔴

**Status**: :pve8_only | **Priority**: Medium | **Since**: PVE 8.2

List available backup providers.

**Methods**: GET  
**Capabilities Required**: `:backup_providers`  
**Notes**: Backup provider plugins introduced in PVE 8.2

### `/api2/json/cluster/ha/affinity` 🟠

**Status**: :pve9_only | **Priority**: Medium | **Since**: PVE 9.0

HA resource affinity rules management.

**Methods**: GET, POST  
**Capabilities Required**: `:ha_resource_affinity`  
**Notes**: HA affinity rules new in PVE 9.0

---

## Node Management

### `/api2/json/nodes` ✅

**Status**: :implemented | **Priority**: Critical | **Since**: PVE 6.0

List all cluster nodes with status.

**Methods**: GET  
**Handler**: `MockPveApi.Handlers.Nodes`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/status` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

Node status and control operations.

**Methods**: GET, POST  
**Parameters**:
- `node` (required): Node name
- `command` (optional): Control command (`reboot`, `shutdown`)

**Handler**: `MockPveApi.Handlers.Nodes`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/version` ✅

**Status**: :implemented | **Priority**: Medium | **Since**: PVE 6.0

Node-specific version information.

**Methods**: GET  
**Parameters**:
- `node` (required): Node name

**Handler**: `MockPveApi.Handlers.Nodes`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/time` 📋

**Status**: :planned | **Priority**: Low | **Since**: PVE 6.0

Node time configuration.

**Methods**: GET, PUT  
**Parameters**:
- `node` (required): Node name

**Notes**: Time management operations planned

---

## Virtual Machine Management

### `/api2/json/nodes/{node}/qemu` ✅

**Status**: :implemented | **Priority**: Critical | **Since**: PVE 6.0

List and create virtual machines on node.

**Methods**: GET, POST  
**Parameters**:
- `node` (required): Node name
- `full` (optional): Full VM information (default: false)

**Handler**: `MockPveApi.Handlers.VMs`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/qemu/{vmid}` 🟡

**Status**: :partial | **Priority**: Critical | **Since**: PVE 6.0

Individual VM configuration and management.

**Methods**: GET, PUT, DELETE  
**Parameters**:
- `node` (required): Node name
- `vmid` (required): VM ID

**Handler**: `MockPveApi.Handlers.VMs`  
**Test Coverage**: ✅  
**Notes**: Core VM operations implemented, advanced config partial

### `/api2/json/nodes/{node}/qemu/{vmid}/status/current` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

Current VM status and statistics.

**Methods**: GET  
**Parameters**:
- `node` (required): Node name
- `vmid` (required): VM ID

**Handler**: `MockPveApi.Handlers.VMs`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/qemu/{vmid}/status/{command}` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

VM control operations (start, stop, reset, etc.).

**Methods**: POST  
**Parameters**:
- `node` (required): Node name
- `vmid` (required): VM ID
- `command` (required): Control command (`start`, `stop`, `reset`, `shutdown`, `suspend`, `resume`)

**Handler**: `MockPveApi.Handlers.VMs`  
**Test Coverage**: ✅  
**Notes**: VM lifecycle operations fully supported

### `/api2/json/nodes/{node}/qemu/{vmid}/clone` 📋

**Status**: :planned | **Priority**: High | **Since**: PVE 6.0

Clone virtual machine.

**Methods**: POST  
**Parameters**:
- `node` (required): Node name
- `vmid` (required): Source VM ID
- `newid` (required): New VM ID

**Notes**: VM cloning operations planned for Phase 4

---

## LXC Container Management

### `/api2/json/nodes/{node}/lxc` ✅

**Status**: :implemented | **Priority**: Critical | **Since**: PVE 6.0

List and create LXC containers on node.

**Methods**: GET, POST  
**Parameters**:
- `node` (required): Node name

**Handler**: `MockPveApi.Handlers.Containers`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/lxc/{vmid}` 🟡

**Status**: :partial | **Priority**: Critical | **Since**: PVE 6.0

Individual LXC container configuration.

**Methods**: GET, PUT, DELETE  
**Parameters**:
- `node` (required): Node name
- `vmid` (required): Container ID

**Handler**: `MockPveApi.Handlers.Containers`  
**Test Coverage**: ✅  
**Notes**: Core container operations implemented

### `/api2/json/nodes/{node}/lxc/{vmid}/status/current` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

Current container status and statistics.

**Methods**: GET  
**Parameters**:
- `node` (required): Node name
- `vmid` (required): Container ID

**Handler**: `MockPveApi.Handlers.Containers`  
**Test Coverage**: ✅

---

## Storage Management

### `/api2/json/nodes/{node}/storage` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

List storage configured for node.

**Methods**: GET  
**Parameters**:
- `node` (required): Node name
- `content` (optional): Filter by content type (`images`, `backup`, `vztmpl`)

**Handler**: `MockPveApi.Handlers.Storage`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/storage/{storage}/status` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

Storage status and capacity information.

**Methods**: GET  
**Parameters**:
- `node` (required): Node name
- `storage` (required): Storage ID

**Handler**: `MockPveApi.Handlers.Storage`  
**Test Coverage**: ✅

### `/api2/json/nodes/{node}/storage/{storage}/content` 🟡

**Status**: :partial | **Priority**: Medium | **Since**: PVE 6.0

Storage content management (images, backups, templates).

**Methods**: GET, POST  
**Parameters**:
- `node` (required): Node name
- `storage` (required): Storage ID

**Handler**: `MockPveApi.Handlers.Storage`  
**Test Coverage**: ✅  
**Notes**: Content listing implemented, content creation partial

---

## Access Control & User Management

### `/api2/json/access/users` ✅

**Status**: :implemented | **Priority**: High | **Since**: PVE 6.0

User account management.

**Methods**: GET, POST  
**Handler**: `MockPveApi.Handlers.Access`  
**Test Coverage**: ✅

### `/api2/json/access/users/{userid}` 📋

**Status**: :planned | **Priority**: Medium | **Since**: PVE 6.0

Individual user account operations.

**Methods**: GET, PUT, DELETE  
**Parameters**:
- `userid` (required): User ID

**Notes**: Individual user CRUD operations planned

### `/api2/json/access/ticket` 📋

**Status**: :planned | **Priority**: High | **Since**: PVE 6.0

Authentication ticket creation.

**Methods**: POST  
**Parameters**:
- `username` (required): Username
- `password` (required): Password
- `realm` (optional): Authentication realm (default: "pam")

**Response Schema**:
```json
{
  "data": {
    "ticket": "string",
    "CSRFPreventionToken": "string"
  }
}
```

**Notes**: Authentication system planned for Phase 4

### `/api2/json/access/groups` 📋

**Status**: :planned | **Priority**: Medium | **Since**: PVE 6.0

User group management.

**Methods**: GET, POST  
**Notes**: Group management planned

---

## Resource Pool Management

### `/api2/json/pools` ✅

**Status**: :implemented | **Priority**: Medium | **Since**: PVE 6.0

Resource pool management.

**Methods**: GET, POST  
**Handler**: `MockPveApi.Handlers.Pools`  
**Test Coverage**: ✅

### `/api2/json/pools/{poolid}` 📋

**Status**: :planned | **Priority**: Medium | **Since**: PVE 6.0

Individual pool operations.

**Methods**: GET, PUT, DELETE  
**Parameters**:
- `poolid` (required): Pool ID

**Notes**: Individual pool CRUD operations planned

---

## Coverage API Endpoints

The mock-pve-api server exposes internal coverage information through special API endpoints:

### `/api2/json/_coverage/stats`

Get overall coverage statistics including totals and percentages by implementation status.

### `/api2/json/_coverage/categories`

Get coverage breakdown by API category with implementation percentages.

### `/api2/json/_coverage/missing`

Get list of critical priority endpoints that are not yet implemented.

---

## Development Roadmap

### Phase 4: Enhanced API Coverage (v0.4.0)

**High Priority Endpoints**:
- Authentication system (`/api2/json/access/ticket`)
- VM cloning operations
- Individual user/group management
- Pool CRUD operations

**Medium Priority Endpoints**:
- Cluster join operations
- Individual SDN zone management
- Time configuration endpoints

### Phase 5: Advanced Features (v0.5.0)

**Version-Specific Endpoints**:
- Backup provider management (PVE 8.2+)
- HA affinity rules (PVE 9.0+)
- Enhanced SDN features

### Coverage Goals

- **v0.4.0**: Target 85% coverage of critical/high priority endpoints
- **v0.5.0**: Target 95% coverage including version-specific features
- **v1.0.0**: Complete API compatibility with 305+ endpoints from pvex analysis

---

## Testing & Validation

### Coverage Testing Strategy

- **Endpoint Discovery**: Automated tests verify all endpoints in coverage matrix
- **Status Validation**: Tests confirm implementation status matches actual handlers
- **Version Compatibility**: Tests validate version-specific endpoint availability
- **Error Responses**: Tests confirm appropriate error codes and messages

### Validation Commands

```bash
# Check coverage validation
curl http://localhost:8006/api2/json/_coverage/stats

# Validate critical endpoints
curl http://localhost:8006/api2/json/_coverage/missing

# Test version compatibility
MOCK_PVE_VERSION=7.4 make test-integration
MOCK_PVE_VERSION=8.3 make test-integration
```

---

*This coverage matrix is automatically maintained based on the `MockPveApi.Coverage` module and reflects the current implementation status as of v0.3.1.*