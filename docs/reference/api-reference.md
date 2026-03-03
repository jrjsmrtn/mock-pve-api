# Mock PVE API Reference

Complete reference for all supported endpoints in the Mock PVE API Server.
This document is the single source of truth for API documentation, automatically
generated from the `MockPveApi.Coverage` module.

> **Note**: This document is auto-generated. Do not edit manually.
> Run `mix docs.coverage` to regenerate after modifying endpoint definitions.

## Base Information

| Property | Value |
|----------|-------|
| **Base URL** | `http://localhost:8006/api2/json` |
| **HTTPS URL** | `https://localhost:8006/api2/json` (when SSL enabled) |
| **Authentication** | Optional (mock server accepts all requests) |
| **Content Type** | `application/json` |
| **Supported PVE Versions** | 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, 9.0 |


## Quick Start

```bash
# Start the mock server
podman run -d -p 8006:8006 -e MOCK_PVE_VERSION=8.3 ghcr.io/jrjsmrtn/mock-pve-api:latest

# Test the connection
curl http://localhost:8006/api2/json/version

# List nodes
curl http://localhost:8006/api2/json/nodes

# List VMs on a node
curl http://localhost:8006/api2/json/nodes/pve-node-1/qemu
```

---


## Coverage Overview

The mock-pve-api server provides comprehensive coverage of the Proxmox VE API
with systematic tracking across all supported versions (7.0 - 9.0).

| Category | Total | Implemented | Coverage |
|----------|-------|-------------|----------|
| Version | 1 | 1 | 100.0% |
| Cluster | 55 | 55 | 100.0% |
| Nodes | 45 | 45 | 100.0% |
| Virtual Machines | 55 | 55 | 100.0% |
| LXC Containers | 25 | 25 | 100.0% |
| Storage | 12 | 12 | 100.0% |
| Access Control | 17 | 17 | 100.0% |
| Resource Pools | 2 | 2 | 100.0% |
| SDN | 13 | 13 | 100.0% |
| Monitoring | 16 | 16 | 100.0% |
| Backup | 9 | 9 | 100.0% |
| Hardware | 9 | 9 | 100.0% |
| Firewall | 41 | 41 | 100.0% |
| Notifications | 16 | 16 | 100.0% |
| **TOTAL** | **316** | **316** | **100.0%** |


## Status Legend

| Icon | Status | Description |
|------|--------|-------------|
| ✅ | Implemented | Fully functional with complete response simulation |
| 📋 | Planned | Cataloged but not yet implemented |
| 🔴 | PVE 8.0+ | Feature requires PVE 8.0 or later |
| 🟠 | PVE 9.0+ | Feature requires PVE 9.0 or later |

## Priority Levels

- **Critical**: Essential endpoints for basic client functionality
- **High**: Important endpoints for common operations
- **Medium**: Useful endpoints for advanced features
- **Low**: Optional endpoints for specialized use cases

---


## Version Information

### `/version` ✅

Get PVE version information and server details

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "version": "8.3",
    "keyboard": "en-us",
    "release": "8.3-1",
    "repoid": "abcd1234"
  }
}
```

**Notes**: Foundation endpoint required for client compatibility


---


## Cluster Management

### `/cluster` ✅

Top-level cluster index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme` ✅

ACME module index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/account` ✅

ACME account management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/account/{name}` ✅

Get, update, or delete a specific ACME account

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Account name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/challenge-schema` ✅

ACME challenge schema types

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/directories` ✅

Known ACME directory endpoints

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/meta` ✅ 🔴

ACME directory metadata

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/plugins` ✅

ACME plugin management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/plugins/{id}` ✅

Get, update, or delete a specific ACME plugin

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `id` | string | Yes | Plugin ID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/acme/tos` ✅

ACME terms of service URL

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/backup-info` ✅

Backup info index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/backup-info/providers` ✅ 🔴

List available backup providers

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 8.2 |

**Example Response**:
```json
{
  "data": [
    {
      "enabled": 1,
      "name": "Proxmox Backup Server",
      "provider": "pbs"
    }
  ]
}
```

**Notes**: Backup provider plugins introduced in PVE 8.2


### `/cluster/backup-providers` ✅ 🔴

List backup providers (alternate path)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 8.2 |

**Example Response**:
```json
{
  "data": []
}
```

**Notes**: Inline handler in router; alternate path for backup provider listing


### `/cluster/bulk-action` ✅ 🟠

Bulk action index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/bulk-action/guest` ✅ 🟠

Bulk action guest overview

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/bulk-action/guest/migrate` ✅ 🟠

Bulk migrate guests

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/bulk-action/guest/shutdown` ✅ 🟠

Bulk shutdown guests

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/bulk-action/guest/start` ✅ 🟠

Bulk start guests

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/bulk-action/guest/suspend` ✅ 🟠

Bulk suspend guests

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ceph` ✅

Ceph module index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ceph/flags` ✅

Ceph global flags

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ceph/metadata` ✅

Ceph cluster metadata

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ceph/status` ✅

Ceph cluster status

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/config` ✅

Cluster configuration management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "version": 1,
    "cluster_name": "mock-cluster"
  }
}
```

**Notes**: Cluster configuration implemented


### `/cluster/config/join` ✅

Join node to existing cluster

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `hostname` | string | Yes | Cluster hostname | - |
| `nodeid` | integer | No | Node ID | - |
| `votes` | integer | No | Number of votes | - |

**Example Response**:
```json
{
  "data": "UPID:pve-node-1:00012348:00000000:clusterjoin::user@pam:"
}
```

**Notes**: Cluster management operations implemented


### `/cluster/config/nodes` ✅

List cluster nodes configuration

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "name": "pve-node-1",
      "nodeid": 1,
      "votes": 1
    }
  ]
}
```

**Notes**: Cluster nodes listing implemented


### `/cluster/config/nodes/{node}` ✅

Remove node from cluster

| Property | Value |
|----------|-------|
| **Methods** | POST, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": null
}
```

**Notes**: Node removal from cluster implemented


### `/cluster/firewall` ✅

Cluster firewall index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha` ✅

HA module index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/affinity` ✅ 🟠

HA resource affinity rules management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 9.0 |

**Example Response**:
```json
{
  "data": [
    {
      "name": "affinity-rule-1",
      "type": "group",
      "nodes": "pve-node-1,pve-node-2"
    }
  ]
}
```

**Notes**: HA affinity rules new in PVE 9.0


### `/cluster/ha/affinity/{rule}` ✅ 🟠

Individual HA affinity rule operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 9.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `rule` | string | Yes | Affinity rule ID | - |

**Example Response**:
```json
{
  "data": {}
}
```

**Notes**: HA affinity rules new in PVE 9.0


### `/cluster/ha/groups` ✅

HA group management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/ha/groups/{group}` ✅

Individual HA group operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `group` | string | Yes | HA group name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/manager_status` ✅

HA manager status

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/resources` ✅

HA resource management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/ha/resources/{sid}` ✅

Individual HA resource operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `sid` | string | Yes | HA resource SID (e.g. vm:100) | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/resources/{sid}/migrate` ✅

Migrate HA resource to different node

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/resources/{sid}/relocate` ✅

Relocate HA resource to different node

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/status` ✅

HA status index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/ha/status/current` ✅

Current HA manager and resource status

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/jobs` ✅

Scheduled jobs index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.1 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/jobs/realm-sync` ✅

List realm sync jobs

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.1 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/jobs/realm-sync/{id}` ✅

Realm sync job CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 7.1 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/jobs/schedule-analyze` ✅

Analyze scheduled job timing

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.1 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/log` ✅

Recent cluster log entries

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/mapping` ✅

Hardware mapping index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/metrics/export` ✅

Export cluster metrics

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/nextid` ✅

Get next free VMID

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |


### `/cluster/options` ✅

Cluster-wide datacenter options

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/replication` ✅

Replication job management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/replication/{id}` ✅

Individual replication job operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/resources` ✅

Get cluster resource overview (VMs, containers, storage)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `type` | string | No | Filter by resource type | `vm`, `storage`, `node`, `sdn` |

**Example Response**:
```json
{
  "data": [
    {
      "cpu": 0.15,
      "id": "node/pve-node-1",
      "node": "pve-node-1",
      "status": "online",
      "type": "node",
      "mem": 2147483648,
      "maxcpu": 8,
      "maxmem": 8589934592
    },
    {
      "id": "qemu/100",
      "name": "test-vm",
      "node": "pve-node-1",
      "status": "running",
      "type": "qemu",
      "vmid": 100
    }
  ]
}
```


### `/cluster/sdn/vnets/{vnet}/ips` ✅ 🔴

Create, update and delete vnet IPs

| Property | Value |
|----------|-------|
| **Methods** | POST, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/status` ✅

Get cluster status and node information

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "name": "mock-cluster",
      "type": "cluster",
      "nodes": 3,
      "quorate": 1
    },
    {
      "id": "node/pve-node-1",
      "name": "pve-node-1",
      "status": "online",
      "type": "node"
    }
  ]
}
```


### `/cluster/tasks` ✅

List cluster-wide tasks

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {}
}
```


---


## Node Management

### `/nodes` ✅

List all cluster nodes with status

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "cpu": 0.15,
      "node": "pve-node-1",
      "status": "online",
      "mem": 2147483648,
      "uptime": 86400,
      "maxcpu": 8,
      "maxmem": 8589934592
    }
  ]
}
```


### `/nodes/{node}` ✅

Node index — lists available sub-resources

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/apt/update` ✅

APT package update management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/apt/versions` ✅

Get package version information

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/ceph/osd` ✅

Ceph OSD management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/ceph/pools` ✅

Ceph pool management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/ceph/status` ✅

Ceph status on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/certificates/acme/certificate` ✅

ACME certificate management

| Property | Value |
|----------|-------|
| **Methods** | POST, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/certificates/info` ✅

Get node TLS certificate info

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/config` ✅

Node configuration options

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/disks/initgpt` ✅

Initialize disk with GPT

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/disks/list` ✅

List local disks

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/disks/lvm` ✅

LVM management on node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/disks/lvmthin` ✅

LVM thin pool management on node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/disks/smart` ✅

Get SMART health data for disks

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/disks/zfs` ✅

ZFS pool management on node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/dns` ✅

Node DNS configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/execute` ✅

Execute a command on a node (API call, not shell)

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/hosts` ✅

Node /etc/hosts management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/journal` ✅

Read systemd journal

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/migrateall` ✅

Migrate all VMs and containers to another node

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/network` ✅

List available network interfaces

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/network/{iface}` ✅

Individual network interface management

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `iface` | string | Yes | Interface name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/replication` ✅

List replication jobs for node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 5.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/replication/{id}` ✅

Get replication job status on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 5.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/replication/{id}/log` ✅

Get replication job log on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 5.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/replication/{id}/schedule_now` ✅

Schedule replication job immediately

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 5.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/replication/{id}/status` ✅

Get replication job detailed status on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 5.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/scan` ✅

List available scan types

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/scan/{type}` ✅

Scan for resources of a specific type

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/services/{service}/reload` ✅

Reload a system service

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/services/{service}/restart` ✅

Restart a system service

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/services/{service}/start` ✅

Start a system service

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/services/{service}/stop` ✅

Stop a system service

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/startall` ✅

Start all VMs and containers on node

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/status` ✅

Node status and control operations

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `command` | string | No | Control command | `reboot`, `shutdown` |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/stopall` ✅

Stop all VMs and containers on node

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/subscription` ✅

Node subscription information

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/syslog` ✅

Read system log (syslog)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/tasks` ✅

List tasks on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/tasks/{upid}` ✅

Stop a running task

| Property | Value |
|----------|-------|
| **Methods** | GET, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `upid` | string | Yes | Task UPID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/tasks/{upid}/log` ✅

Get task log by UPID

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `upid` | string | Yes | Task UPID | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/tasks/{upid}/status` ✅

Get task status by UPID

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `upid` | string | Yes | Task UPID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/time` ✅

Node time configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": {
    "localtime": 1702828800,
    "time": "2024-12-17T12:00:00Z",
    "timezone": "UTC"
  }
}
```

**Notes**: Node time configuration and timezone management


### `/nodes/{node}/version` ✅

Node-specific version information

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": {}
}
```


---


## Virtual Machine Management

### `/nodes/{node}/qemu` ✅

List and create virtual machines on node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `full` | boolean | No | Full VM information | - |

**Example Response**:
```json
{
  "data": [
    {
      "cpu": 0.25,
      "name": "test-vm",
      "status": "running",
      "mem": 1073741824,
      "maxcpu": 2,
      "maxmem": 2147483648,
      "vmid": 100
    }
  ]
}
```


### `/nodes/{node}/qemu/{vmid}` ✅

Individual VM configuration and management

| Property | Value |
|----------|-------|
| **Methods** | GET, DELETE |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```

**Notes**: Complete VM configuration and management with comprehensive status info


### `/nodes/{node}/qemu/{vmid}/agent` ✅

QEMU guest agent info and commands

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/exec` ✅

Execute command in guest

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/exec-status` ✅

Get agent exec command exit code and output

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/file-read` ✅

Read file from guest via agent

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/file-write` ✅

Write file to guest via agent

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/fsfreeze-freeze` ✅

Freeze guest filesystems

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/fsfreeze-status` ✅

Get filesystem freeze status

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/fsfreeze-thaw` ✅

Thaw guest filesystems

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/fstrim` ✅

Trim guest filesystems

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-fsinfo` ✅

Get guest filesystem info

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-host-name` ✅

Get guest hostname

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-memory-block-info` ✅

Get guest memory block info

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-memory-blocks` ✅

Get guest memory blocks

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-osinfo` ✅

Get guest OS information

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-time` ✅

Get guest time

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-timezone` ✅

Get guest timezone

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-users` ✅

List logged-in guest users

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/get-vcpus` ✅

Get guest vCPU info

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/info` ✅

Get QEMU guest agent info

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/network-get-interfaces` ✅

Get guest network interfaces

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/ping` ✅

Ping QEMU guest agent

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/set-user-password` ✅

Set guest user password

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/shutdown` ✅

Shutdown guest via agent

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/suspend-disk` ✅

Suspend guest to disk

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/suspend-hybrid` ✅

Hybrid guest suspend

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/agent/suspend-ram` ✅

Suspend guest to RAM

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/clone` ✅

Clone virtual machine

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Source VM ID | - |
| `newid` | integer | Yes | New VM ID | - |

**Example Response**:
```json
{
  "data": "UPID:pve-node-1:00012346:00000000:qmclone:100:user@pam:"
}
```

**Notes**: VM cloning operations implemented


### `/nodes/{node}/qemu/{vmid}/cloudinit` ✅

Cloud-init configuration get/update

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/cloudinit/dump` ✅

Get cloud-init configuration dump

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/config` ✅

VM configuration (get current or update)

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/feature` ✅

Check VM feature availability

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/migrate` ✅

Migrate VM to another node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/monitor` ✅

Send QEMU monitor command

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/move_disk` ✅

Move VM disk to different storage

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/mtunnel` ✅

Create migration tunnel for VM

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/mtunnelwebsocket` ✅

Migration tunnel WebSocket for VM

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/pending` ✅

Get pending VM configuration changes

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/remote_migrate` ✅

Migrate VM to remote cluster

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/resize` ✅

Resize VM disk

| Property | Value |
|----------|-------|
| **Methods** | PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/sendkey` ✅

Send key event to VM

| Property | Value |
|----------|-------|
| **Methods** | PUT |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/snapshot` ✅

List snapshots / create snapshot

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```

**Notes**: Full snapshot CRUD with state management


### `/nodes/{node}/qemu/{vmid}/snapshot/{snapname}` ✅

Get snapshot info / delete snapshot

| Property | Value |
|----------|-------|
| **Methods** | GET, DELETE |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |
| `snapname` | string | Yes | Snapshot name | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/config` ✅

Get or update snapshot configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |
| `snapname` | string | Yes | Snapshot name | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback` ✅

Rollback VM to snapshot

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |
| `snapname` | string | Yes | Snapshot name | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/spiceproxy` ✅

Create SPICE proxy for VM

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/status` ✅

VM status index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/status/current` ✅

Current VM status and statistics

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/status/{command}` ✅

VM control operations (start, stop, reset, etc.)

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |
| `command` | string | Yes | Control command | `start`, `stop`, `reset`, `shutdown`, `suspend`, `resume` |

**Example Response**:
```json
{
  "data": "UPID:pve-node-1:00012345:00000000:qmstart:100:user@pam:"
}
```

**Notes**: VM lifecycle operations fully supported


### `/nodes/{node}/qemu/{vmid}/template` ✅

Convert VM to template

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/termproxy` ✅

Create terminal proxy for VM

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/unlink` ✅

Unlink/delete disk images

| Property | Value |
|----------|-------|
| **Methods** | PUT |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/vncproxy` ✅

Create VNC proxy for VM

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/vncwebsocket` ✅

VNC WebSocket endpoint for VM

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


---


## LXC Container Management

### `/nodes/{node}/lxc` ✅

List and create LXC containers on node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": [
    {
      "cpu": 0.1,
      "name": "test-container",
      "status": "running",
      "mem": 536870912,
      "maxcpu": 1,
      "maxmem": 1073741824,
      "vmid": 200
    }
  ]
}
```


### `/nodes/{node}/lxc/{vmid}` ✅

Individual LXC container configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, DELETE |
| **Priority** | Critical |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```

**Notes**: Complete container configuration and management with comprehensive status info


### `/nodes/{node}/lxc/{vmid}/clone` ✅

Clone LXC container

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Source Container ID | - |
| `newid` | integer | Yes | New Container ID | - |

**Example Response**:
```json
{
  "data": "UPID:pve-node-1:00012347:00000000:vzclone:200:user@pam:"
}
```

**Notes**: Container cloning operations implemented


### `/nodes/{node}/lxc/{vmid}/config` ✅

Container configuration (get current or update)

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/feature` ✅

Check container feature availability

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/interfaces` ✅

Get container network interfaces

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/migrate` ✅ 🟠

Migrate container to another node

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 9.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/move_volume` ✅

Move container volume to different storage

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/mtunnel` ✅

Create migration tunnel for container

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/mtunnelwebsocket` ✅

Migration tunnel WebSocket for container

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/pending` ✅

Get pending container configuration changes

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/remote_migrate` ✅

Migrate container to remote cluster

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/resize` ✅

Resize container disk

| Property | Value |
|----------|-------|
| **Methods** | PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/snapshot` ✅

List snapshots / create snapshot

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```

**Notes**: Full snapshot CRUD with state management


### `/nodes/{node}/lxc/{vmid}/snapshot/{snapname}` ✅

Get snapshot info / delete snapshot

| Property | Value |
|----------|-------|
| **Methods** | GET, DELETE |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |
| `snapname` | string | Yes | Snapshot name | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/config` ✅

Get or update snapshot configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |
| `snapname` | string | Yes | Snapshot name | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/rollback` ✅

Rollback container to snapshot

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |
| `snapname` | string | Yes | Snapshot name | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/spiceproxy` ✅

Create SPICE proxy for container

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/status` ✅

Container status index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/status/current` ✅

Current container status and statistics

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/status/{action}` ✅

Container control operations (start, stop, shutdown, etc.)

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |
| `action` | string | Yes | Control action | `start`, `stop`, `shutdown`, `reboot`, `suspend`, `resume` |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```

**Notes**: Container lifecycle operations


### `/nodes/{node}/lxc/{vmid}/template` ✅

Convert container to template

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/termproxy` ✅

Create terminal proxy for container

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/vncproxy` ✅

Create VNC proxy for container

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/vncwebsocket` ✅

VNC WebSocket endpoint for container

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 4.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


---


## Storage Management

### `/nodes/{node}/storage` ✅

List storage configured for node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `content` | string | No | Filter by content type | `images`, `backup`, `vztmpl` |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/backup` ✅

List backup files in storage

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `storage` | string | Yes | Storage ID | - |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/content` ✅

Storage content management (images, backups, templates)

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `storage` | string | Yes | Storage ID | - |

**Example Response**:
```json
{
  "data": [
    {
      "size": 658505728,
      "format": "iso",
      "content": "iso",
      "volid": "local:iso/debian-12.iso"
    }
  ]
}
```

**Notes**: Content listing implemented, content creation partial


### `/nodes/{node}/storage/{storage}/content/{volume}` ✅

Individual storage volume operations

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `storage` | string | Yes | Storage ID | - |
| `volume` | string | Yes | Volume identifier | - |

**Example Response**:
```json
{
  "data": [
    {
      "size": 658505728,
      "format": "iso",
      "content": "iso",
      "volid": "local:iso/debian-12.iso"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/file-restore/download` ✅

Download files from a backup

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/file-restore/list` ✅

List files in a backup for single-file restore

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/import` ✅ 🔴

Import content into storage (e.g., VMware import)

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 8.2 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `storage` | string | Yes | Storage ID | - |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```

**Notes**: Inline handler in router; VMware import introduced in PVE 8.2


### `/nodes/{node}/storage/{storage}/prunebackups` ✅

Prune old backups

| Property | Value |
|----------|-------|
| **Methods** | GET, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/status` ✅

Storage status and capacity information

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `storage` | string | Yes | Storage ID | - |

**Example Response**:
```json
{
  "data": {
    "active": 1,
    "total": 107374182400,
    "type": "dir",
    "used": 21474836480,
    "storage": "local"
  }
}
```


### `/nodes/{node}/storage/{storage}/upload` ✅

Upload content to storage

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `storage` | string | Yes | Storage ID | - |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/storage` ✅

Storage definition management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/storage/{storage}` ✅

Individual storage definition CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `storage` | string | Yes | Storage ID | - |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


---


## Access Control & User Management

### `/access/acl` ✅

Access control list management

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/access/domains` ✅

Authentication realms/domains management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "type": "pam",
      "comment": "Linux PAM standard authentication",
      "realm": "pam"
    }
  ]
}
```


### `/access/domains/{realm}` ✅

Individual realm/domain CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `realm` | string | Yes | Realm name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/access/domains/{realm}/sync` ✅

Sync realm/domain from external source

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `realm` | string | Yes | Realm name | - |

**Example Response**:
```json
{
  "data": "OK"
}
```

**Notes**: Inline handler in router; realm sync available in PVE 8.0+


### `/access/groups` ✅

User group management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "comment": "Development team",
      "groupid": "developers"
    }
  ]
}
```

**Notes**: Group management implemented


### `/access/groups/{groupid}` ✅

Individual group operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `groupid` | string | Yes | Group ID | - |

**Example Response**:
```json
{
  "data": {
    "comment": "Development team",
    "groupid": "developers",
    "members": [
      "testuser@pve"
    ]
  }
}
```

**Notes**: Individual group CRUD operations implemented


### `/access/password` ✅

Change user password

| Property | Value |
|----------|-------|
| **Methods** | PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `userid` | string | Yes | User ID | - |
| `password` | string | Yes | New password | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/access/permissions` ✅

Get current user permissions

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/access/roles` ✅

Role management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/access/roles/{roleid}` ✅

Individual role CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `roleid` | string | Yes | Role ID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/access/tfa` ✅

Two-factor authentication management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/access/tfa/{userid}` ✅

User TFA configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `userid` | string | Yes | User ID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/access/ticket` ✅

Authentication ticket creation

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `username` | string | Yes | Username | - |
| `password` | string | Yes | Password | - |
| `realm` | string | No | Authentication realm | - |

**Example Response**:
```json
{
  "data": {
    "ticket": "PVE:root@pam:12345678::...",
    "CSRFPreventionToken": "12345678:..."
  }
}
```

**Notes**: Authentication system implemented


### `/access/users` ✅

User account management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "comment": "Built-in Superuser",
      "enable": 1,
      "userid": "root@pam"
    },
    {
      "enable": 1,
      "userid": "testuser@pve",
      "email": "test@example.com"
    }
  ]
}
```


### `/access/users/{userid}` ✅

Individual user account operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `userid` | string | Yes | User ID | - |

**Example Response**:
```json
{
  "data": {
    "enable": 1,
    "groups": [
      "developers"
    ],
    "userid": "testuser@pve",
    "email": "test@example.com"
  }
}
```

**Notes**: Individual user CRUD operations implemented


### `/access/users/{userid}/token` ✅

List API tokens for user

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `userid` | string | Yes | User ID | - |

**Example Response**:
```json
{
  "data": {
    "comment": "Automation token",
    "expire": 0,
    "privsep": 1,
    "tokenid": "automation"
  }
}
```


### `/access/users/{userid}/token/{tokenid}` ✅

Individual API token operations

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `userid` | string | Yes | User ID | - |
| `tokenid` | string | Yes | Token ID | - |

**Example Response**:
```json
{
  "data": {
    "comment": "Automation token",
    "expire": 0,
    "privsep": 1,
    "tokenid": "automation"
  }
}
```

**Notes**: API token CRUD operations implemented


---


## Resource Pool Management

### `/pools` ✅

Resource pool management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "comment": "Production environment",
      "poolid": "production"
    }
  ]
}
```


### `/pools/{poolid}` ✅

Individual pool operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `poolid` | string | Yes | Pool ID | - |

**Example Response**:
```json
{
  "data": {
    "comment": "Production environment",
    "poolid": "production",
    "members": [
      {
        "node": "pve-node-1",
        "type": "qemu",
        "vmid": 100
      }
    ]
  }
}
```

**Notes**: Complete CRUD operations for resource pools


---


## Software-Defined Networking (SDN)

### `/cluster/sdn` ✅

SDN index

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/sdn/controllers` ✅

SDN controller management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/sdn/controllers/{controller}` ✅

Individual SDN controller operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `controller` | string | Yes | Controller identifier | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/sdn/dns` ✅

SDN DNS plugin management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/sdn/dns/{dns}` ✅

Individual SDN DNS plugin operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `dns` | string | Yes | DNS plugin identifier | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/sdn/ipams` ✅

SDN IPAM plugin management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/sdn/ipams/{ipam}` ✅

Individual SDN IPAM plugin operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `ipam` | string | Yes | IPAM identifier | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/sdn/vnets` ✅

Virtual network management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": [
    {
      "tag": 100,
      "zone": "localnetwork",
      "vnet": "vnet100"
    }
  ]
}
```


### `/cluster/sdn/vnets/{vnet}` ✅

Individual virtual network operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `vnet` | string | Yes | VNet identifier | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/sdn/vnets/{vnet}/subnets` ✅

Subnet management for a virtual network

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `vnet` | string | Yes | VNet identifier | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/sdn/vnets/{vnet}/subnets/{subnet}` ✅

Individual subnet operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `vnet` | string | Yes | VNet identifier | - |
| `subnet` | string | Yes | Subnet identifier | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/sdn/zones` ✅

Software Defined Networking zone management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": [
    {
      "type": "simple",
      "nodes": "pve-node-1,pve-node-2",
      "zone": "localnetwork"
    }
  ]
}
```


### `/cluster/sdn/zones/{zone}` ✅

Individual SDN zone operations

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `zone` | string | Yes | Zone identifier | - |

**Example Response**:
```json
{
  "data": {
    "type": "simple",
    "nodes": "pve-node-1,pve-node-2",
    "zone": "localnetwork"
  }
}
```


---


## Monitoring & Metrics

### `/cluster/metrics` ✅

Cluster metrics index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/metrics/server` ✅

List configured external metric servers

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/metrics/server/{id}` ✅

Get external metric server configuration

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `id` | string | Yes | Metric server ID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/lxc/{vmid}/rrd` ✅

Read container RRD statistics (returns PNG graph)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/rrddata` ✅

Read container RRD statistics (JSON data)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | Container ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/netstat` ✅

Read node network statistics

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/qemu/{vmid}/rrd` ✅

Read VM RRD statistics (returns PNG graph)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/rrddata` ✅

Read VM RRD statistics (JSON data)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | integer | Yes | VM ID | - |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/report` ✅

Get node status report (text format)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": "OK"
}
```


### `/nodes/{node}/rrd` ✅

Read node RRD statistics (returns PNG graph)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `timeframe` | string | No | Time frame | `hour`, `day`, `week`, `month`, `year` |
| `ds` | string | No | Data source | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/rrddata` ✅

Read node RRD statistics (returns JSON data)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `timeframe` | string | No | Time frame | `hour`, `day`, `week`, `month`, `year` |

**Example Response**:
```json
{
  "data": []
}
```


### `/nodes/{node}/services` ✅

List system services on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/services/{service}` ✅

Get service status

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/services/{service}/state` ✅

Control service (start/stop/restart)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/storage/{storage}/rrd` ✅

Storage RRD statistics (graph)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


### `/nodes/{node}/storage/{storage}/rrddata` ✅

Storage RRD statistics (data)

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": [
    {
      "active": 1,
      "enabled": 1,
      "total": 107374182400,
      "type": "dir",
      "used": 21474836480,
      "storage": "local"
    }
  ]
}
```


---


## Backup & Restore

### `/cluster/backup` ✅

List/create backup jobs

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/backup-info/not-backed-up` ✅

List VMs/CTs not covered by any backup job

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 7.0 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/backup/{id}` ✅

Individual backup job CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `id` | string | Yes | Backup job ID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/backup/{id}/included_volumes` ✅

List volumes included in backup job

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 7.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `id` | string | Yes | Backup job ID | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/qmrestore` ✅

Restore VM from backup

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": "OK"
}
```


### `/nodes/{node}/vzdump` ✅

Create backup (vzdump)

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | High |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |
| `vmid` | string | No | VM IDs to backup | - |
| `storage` | string | No | Target storage | - |
| `mode` | string | No | Backup mode | `snapshot`, `suspend`, `stop` |

**Example Response**:
```json
{
  "data": "OK"
}
```

**Notes**: Inline handler in router


### `/nodes/{node}/vzdump/defaults` ✅

Get vzdump default options

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/vzdump/extractconfig` ✅

Extract configuration from backup archive

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": "OK"
}
```


### `/nodes/{node}/vzrestore` ✅

Restore container from backup

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `node` | string | Yes | Node name | - |

**Example Response**:
```json
{
  "data": "OK"
}
```


---


## Hardware Detection & Passthrough

### `/cluster/mapping/dir` ✅ 🔴

Directory mapping list and create

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/mapping/dir/{id}` ✅ 🔴

Directory mapping CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/mapping/pci` ✅ 🔴

PCI resource mapping management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/mapping/pci/{id}` ✅ 🔴

Individual PCI mapping CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/mapping/usb` ✅ 🔴

USB resource mapping management

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/mapping/usb/{id}` ✅ 🔴

Individual USB mapping CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 8.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/hardware/pci` ✅

List PCI devices on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/hardware/pci/{pciid}` ✅

Get PCI device details

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/hardware/usb` ✅

List USB devices on node

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


---


## Firewall Management

### `/cluster/firewall/aliases` ✅

List/create cluster IP aliases

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/aliases/{name}` ✅

Individual alias CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/groups` ✅

List/create security groups

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/groups/{group}` ✅

Get rules / create rule / delete security group

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/groups/{group}/{pos}` ✅

Security group rule CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/ipset` ✅

List/create IP sets

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/ipset/{name}` ✅

List/add entries, delete IP set

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/ipset/{name}/{cidr}` ✅

IP set entry CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/log` ✅

Read cluster firewall log

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/macros` ✅

List available firewall macros

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/options` ✅

Cluster firewall options

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/refs` ✅

List available firewall references

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/rules` ✅

List/create cluster firewall rules

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/firewall/rules/{pos}` ✅

Individual cluster rule CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/firewall` ✅

Node firewall index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/firewall/log` ✅

Read node firewall log

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/firewall/options` ✅

Node firewall options

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/firewall/rules` ✅

List/create node firewall rules

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/firewall/rules/{pos}` ✅

Individual node rule CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/nodes/{node}/lxc/{vmid}/firewall` ✅

Container firewall index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/aliases` ✅

Container-level IP aliases

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/aliases/{name}` ✅

Container alias CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/ipset` ✅

Container-level IP sets

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/ipset/{name}` ✅

Container IP set entries / add / delete

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/ipset/{name}/{cidr}` ✅

Container IP set entry CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/log` ✅

Read container firewall log

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/options` ✅

Container firewall options

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/refs` ✅

Container firewall references

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/rules` ✅

List/create container firewall rules

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/lxc/{vmid}/firewall/rules/{pos}` ✅

Individual container rule CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.1,
    "name": "test-container",
    "status": "running",
    "mem": 536870912,
    "maxmem": 1073741824,
    "vmid": 200,
    "cpus": 1
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall` ✅

VM firewall index

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/aliases` ✅

VM-level IP aliases

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/aliases/{name}` ✅

VM alias CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/ipset` ✅

VM-level IP sets

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/ipset/{name}` ✅

VM IP set entries / add / delete

| Property | Value |
|----------|-------|
| **Methods** | GET, POST, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/ipset/{name}/{cidr}` ✅

VM IP set entry CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/log` ✅

Read VM firewall log

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/options` ✅

VM firewall options

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/refs` ✅

VM firewall references

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/rules` ✅

List/create VM firewall rules

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


### `/nodes/{node}/qemu/{vmid}/firewall/rules/{pos}` ✅

Individual VM rule CRUD

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 6.0 |

**Example Response**:
```json
{
  "data": {
    "cpu": 0.25,
    "name": "test-vm",
    "status": "running",
    "mem": 1073741824,
    "uptime": 3600,
    "maxmem": 2147483648,
    "vmid": 100,
    "cpus": 2
  }
}
```


---


## Notifications

### `/cluster/notifications` ✅ 🔴

Notification system index — lists child resource names

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/endpoints` ✅ 🔴

List available notification endpoint types

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/endpoints/gotify` ✅ 🔴

List or create Gotify notification endpoints

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/endpoints/gotify/{name}` ✅ 🔴

Get, update, or delete a specific Gotify notification endpoint

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Endpoint name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/notifications/endpoints/sendmail` ✅ 🔴

List or create sendmail notification endpoints

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/endpoints/sendmail/{name}` ✅ 🔴

Get, update, or delete a specific sendmail notification endpoint

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Endpoint name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/notifications/endpoints/smtp` ✅ 🔴

List or create SMTP notification endpoints

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/endpoints/smtp/{name}` ✅ 🔴

Get, update, or delete a specific SMTP notification endpoint

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Endpoint name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/notifications/endpoints/webhook` ✅ 🔴

List or create webhook notification endpoints

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 8.2 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/endpoints/webhook/{name}` ✅ 🔴

Get, update, or delete a specific webhook notification endpoint

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 8.2 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Endpoint name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/notifications/matcher-field-values` ✅ 🔴

List possible values for matcher fields

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 8.2 |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/notifications/matcher-fields` ✅ 🔴

List available matcher fields

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Low |
| **Since** | PVE 8.2 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/matchers` ✅ 🔴

List or create notification matchers

| Property | Value |
|----------|-------|
| **Methods** | GET, POST |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/matchers/{name}` ✅ 🔴

Get, update, or delete a specific notification matcher

| Property | Value |
|----------|-------|
| **Methods** | GET, PUT, DELETE |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Matcher name | - |

**Example Response**:
```json
{
  "data": {}
}
```


### `/cluster/notifications/targets` ✅ 🔴

List all notification targets across all endpoint types

| Property | Value |
|----------|-------|
| **Methods** | GET |
| **Priority** | Medium |
| **Since** | PVE 8.1 |

**Example Response**:
```json
{
  "data": []
}
```


### `/cluster/notifications/targets/{name}/test` ✅ 🔴

Send a test notification to a target

| Property | Value |
|----------|-------|
| **Methods** | POST |
| **Priority** | Low |
| **Since** | PVE 8.1 |

**Parameters**:

| Name | Type | Required | Description | Values |
|------|------|----------|-------------|--------|
| `name` | string | Yes | Target name | - |


---


## Error Responses

### Standard Error Format

All errors return JSON with the following structure:

```json
{
  "errors": ["Error message describing what went wrong"]
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| **200** | Request successful |
| **400** | Invalid parameters or request |
| **404** | Resource or endpoint not found |
| **501** | Feature not available in configured PVE version |
| **500** | Server error |

### Version-Specific Errors

When requesting features not available in the configured PVE version:

```json
{
  "errors": [
    "Feature not implemented",
    "SDN features require PVE 8.0+, currently simulating 7.4"
  ]
}
```

---


## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MOCK_PVE_VERSION` | `8.3` | PVE version to simulate (7.0-9.0) |
| `MOCK_PVE_PORT` | `8006` | Server port |
| `MOCK_PVE_HOST` | `0.0.0.0` | Bind address |
| `MOCK_PVE_SSL_ENABLED` | `false` | Enable HTTPS |
| `MOCK_PVE_SSL_KEYFILE` | - | Path to SSL private key |
| `MOCK_PVE_SSL_CERTFILE` | - | Path to SSL certificate |
| `MOCK_PVE_LOG_LEVEL` | `info` | Logging level |
| `MOCK_PVE_DELAY` | `0` | Response delay in milliseconds |
| `MOCK_PVE_ERROR_RATE` | `0` | Error injection rate (0-100) |

### Multi-Version Testing

```bash
# Run multiple versions simultaneously
for version in 7.4 8.0 8.3 9.0; do
  docker run -d --name pve-$version \
    -p $((8000 + ${version%%.*})):8006 \
    -e MOCK_PVE_VERSION=$version \
    ghcr.io/jrjsmrtn/mock-pve-api:latest
done
```

---


## Compatibility Notes

### Differences from Real PVE API

1. **Authentication**: Mock server accepts all requests without authentication
2. **State Persistence**: State is lost when container restarts
3. **Real Operations**: Operations return immediately (no actual VMs created)
4. **Resource Limits**: Simulated resources have configurable limits

### Compatibility Features

1. **Response Schemas**: Match real PVE API response formats
2. **HTTP Status Codes**: Correct status codes for different scenarios
3. **Version-Specific Features**: Accurate feature availability per version
4. **Error Messages**: Similar error message formats

### Client Library Usage

Configure your PVE client library to use `http://localhost:8006` as the PVE host
with SSL verification disabled. The mock server accepts all authentication requests.

---


*This API reference is automatically generated from the `MockPveApi.Coverage` module.*
*Run `mix docs.coverage` to regenerate after modifying endpoint definitions.*
