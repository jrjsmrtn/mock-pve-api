# Mock PVE API - API Reference

Complete reference for all supported endpoints in the Mock PVE API Server.

## Base Information

- **Base URL**: `http://localhost:8006/api2/json`
- **Authentication**: Not required (mock server)
- **Content Type**: `application/json`
- **HTTP Methods**: GET, POST, PUT, DELETE (as per PVE API)

## Core Endpoints

### Version Information

#### `GET /version`
Returns PVE version and capability information.

**Response:**
```json
{
  "data": {
    "version": "8.3",
    "release": "8.3-1", 
    "repoid": "abcd1234",
    "capabilities": {
      "sdn": true,
      "backup_providers": true,
      "notifications": true
    }
  }
}
```

**Version Availability**: All versions (7.0+)

---

## Cluster Management

### Cluster Status

#### `GET /cluster/status`
Returns cluster and node status information.

**Response:**
```json
{
  "data": [
    {
      "type": "cluster",
      "name": "mock-cluster",
      "nodes": 3,
      "quorate": 1
    },
    {
      "type": "node", 
      "id": "node/pve-node-1",
      "name": "pve-node-1",
      "status": "online",
      "level": ""
    }
  ]
}
```

### Cluster Resources

#### `GET /cluster/resources`
Lists all cluster resources (nodes, VMs, containers, storage).

**Parameters:**
- `type` (optional): Filter by resource type (`node`, `qemu`, `lxc`, `storage`)

**Response:**
```json
{
  "data": [
    {
      "id": "node/pve-node-1",
      "type": "node",
      "node": "pve-node-1", 
      "status": "online",
      "cpu": 0.15,
      "maxcpu": 8,
      "mem": 2147483648,
      "maxmem": 8589934592
    },
    {
      "id": "qemu/100",
      "type": "qemu",
      "vmid": 100,
      "name": "test-vm",
      "node": "pve-node-1",
      "status": "running",
      "cpu": 0.25,
      "maxcpu": 2,
      "mem": 1073741824,
      "maxmem": 2147483648
    }
  ]
}
```

---

## Node Management

### List Nodes

#### `GET /nodes`
Lists all cluster nodes.

**Response:**
```json
{
  "data": [
    {
      "node": "pve-node-1",
      "status": "online", 
      "cpu": 0.15,
      "maxcpu": 8,
      "mem": 2147483648,
      "maxmem": 8589934592,
      "disk": 21474836480,
      "maxdisk": 107374182400,
      "uptime": 86400
    }
  ]
}
```

### Node Information

#### `GET /nodes/{node}`
Get detailed information about a specific node.

**Response:**
```json
{
  "data": {
    "node": "pve-node-1",
    "status": "online",
    "cpu": 0.15,
    "loadavg": [0.12, 0.15, 0.18],
    "mem": {
      "used": 2147483648,
      "total": 8589934592,
      "free": 6442450944
    },
    "swap": {
      "used": 0,
      "total": 2147483648,
      "free": 2147483648  
    },
    "rootfs": {
      "used": 21474836480,
      "total": 107374182400, 
      "avail": 85899345920
    },
    "uptime": 86400,
    "wait": 0.02,
    "pveversion": "8.3-1"
  }
}
```

---

## Virtual Machine Management

### List VMs

#### `GET /nodes/{node}/qemu`
Lists virtual machines on a specific node.

**Response:**
```json
{
  "data": [
    {
      "vmid": 100,
      "name": "test-vm",
      "status": "running",
      "cpu": 0.25,
      "maxcpu": 2,
      "mem": 1073741824,
      "maxmem": 2147483648,
      "disk": 0,
      "maxdisk": 32212254720,
      "pid": 12345,
      "uptime": 3600
    }
  ]
}
```

### VM Information

#### `GET /nodes/{node}/qemu/{vmid}`
Get detailed VM information.

**Response:**
```json
{
  "data": {
    "vmid": 100,
    "name": "test-vm",
    "status": "running",
    "cpu": 0.25,
    "cpus": 2,
    "mem": 1073741824,
    "maxmem": 2147483648,
    "balloon": 2147483648,
    "disk": 0,
    "maxdisk": 32212254720,
    "pid": 12345,
    "uptime": 3600,
    "ha": {
      "managed": 0
    }
  }
}
```

### VM Operations

#### `POST /nodes/{node}/qemu/{vmid}/status/start`
Start a virtual machine.

#### `POST /nodes/{node}/qemu/{vmid}/status/stop`
Stop a virtual machine.

#### `POST /nodes/{node}/qemu/{vmid}/status/shutdown`
Gracefully shutdown a virtual machine.

#### `POST /nodes/{node}/qemu/{vmid}/status/reboot`
Reboot a virtual machine.

**Response (all operations):**
```json
{
  "data": "UPID:pve-node-1:00012345:00000000:start:100:user@pam:"
}
```

---

## Container Management

### List Containers

#### `GET /nodes/{node}/lxc`
Lists LXC containers on a specific node.

**Response:**
```json
{
  "data": [
    {
      "vmid": 200,
      "name": "test-container",
      "status": "running",
      "cpu": 0.10,
      "maxcpu": 1,
      "mem": 536870912,
      "maxmem": 1073741824,
      "disk": 0,
      "maxdisk": 8589934592,
      "uptime": 1800
    }
  ]
}
```

### Container Information

#### `GET /nodes/{node}/lxc/{vmid}`
Get detailed container information.

**Response:**
```json
{
  "data": {
    "vmid": 200,
    "name": "test-container", 
    "status": "running",
    "cpu": 0.10,
    "cpus": 1,
    "mem": 536870912,
    "maxmem": 1073741824,
    "swap": 0,
    "maxswap": 536870912,
    "disk": 0,
    "maxdisk": 8589934592,
    "uptime": 1800,
    "ha": {
      "managed": 0
    }
  }
}
```

---

## Storage Management

### List Storage

#### `GET /nodes/{node}/storage`
Lists storage configured on a node.

**Response:**
```json
{
  "data": [
    {
      "storage": "local",
      "type": "dir",
      "active": 1,
      "enabled": 1,
      "used": 21474836480,
      "total": 107374182400,
      "avail": 85899345920
    },
    {
      "storage": "local-lvm",
      "type": "lvm",
      "active": 1, 
      "enabled": 1,
      "used": 0,
      "total": 85899345920,
      "avail": 85899345920
    }
  ]
}
```

### Storage Content

#### `GET /nodes/{node}/storage/{storage}/content`
Lists content in a storage location.

**Parameters:**
- `content` (optional): Filter by content type (`iso`, `vztmpl`, `backup`, `images`)

**Response:**
```json
{
  "data": [
    {
      "volid": "local:iso/debian-12.0.0-amd64-netinst.iso",
      "content": "iso",
      "format": "iso",
      "size": 658505728,
      "ctime": 1693478400
    },
    {
      "volid": "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst",
      "content": "vztmpl", 
      "format": "tgz",
      "size": 234881024,
      "ctime": 1693478400
    }
  ]
}
```

---

## Software Defined Networking (SDN)

**Version Availability**: PVE 8.0+

### SDN Zones

#### `GET /cluster/sdn/zones`
List SDN zones.

**Response:**
```json
{
  "data": [
    {
      "zone": "localnetwork",
      "type": "simple",
      "nodes": "pve-node-1,pve-node-2"
    }
  ]
}
```

### SDN VNets

#### `GET /cluster/sdn/vnets`  
List virtual networks.

**Response:**
```json
{
  "data": [
    {
      "vnet": "vnet100",
      "zone": "localnetwork",
      "tag": 100,
      "alias": "production-net"
    }
  ]
}
```

### SDN Subnets

#### `GET /cluster/sdn/vnets/{vnet}/subnets`
List subnets in a virtual network.

**Response:**
```json
{
  "data": [
    {
      "subnet": "192.168.100.0/24", 
      "vnet": "vnet100",
      "gateway": "192.168.100.1",
      "snat": 1
    }
  ]
}
```

---

## Resource Pools

### List Pools

#### `GET /pools`
Lists resource pools.

**Response:**
```json
{
  "data": [
    {
      "poolid": "production",
      "comment": "Production environment",
      "members": [
        {"type": "qemu", "vmid": 100, "node": "pve-node-1"},
        {"type": "lxc", "vmid": 200, "node": "pve-node-1"}
      ]
    }
  ]
}
```

### Pool Information

#### `GET /pools/{poolid}`
Get detailed pool information.

**Response:**
```json
{
  "data": {
    "poolid": "production",
    "comment": "Production environment", 
    "members": [
      {
        "type": "qemu",
        "vmid": 100,
        "node": "pve-node-1",
        "id": "qemu/100"
      }
    ]
  }
}
```

---

## User Management

### List Users

#### `GET /access/users`
Lists system users.

**Response:**
```json
{
  "data": [
    {
      "userid": "root@pam",
      "comment": "Built-in Superuser",
      "enable": 1,
      "firstname": "root",
      "groups": [],
      "keys": ""
    },
    {
      "userid": "testuser@pve",
      "comment": "Test user",
      "email": "test@example.com",
      "enable": 1,
      "firstname": "Test",
      "lastname": "User",
      "groups": ["developers"]
    }
  ]
}
```

### List Groups

#### `GET /access/groups`
Lists user groups.

**Response:**
```json
{
  "data": [
    {
      "groupid": "developers",
      "comment": "Development team",
      "members": ["testuser@pve"]
    }
  ]
}
```

---

## Backup Operations

**Version Availability**: Basic backup (7.0+), Backup providers (8.2+)

### Backup Providers

#### `GET /cluster/backup-info/providers`
Lists backup providers.

**Version Availability**: PVE 8.2+

**Response:**
```json
{
  "data": [
    {
      "provider": "pbs",
      "name": "Proxmox Backup Server",
      "enabled": 1
    },
    {
      "provider": "external",
      "name": "External Backup",
      "enabled": 0
    }
  ]
}
```

---

## Notification System

**Version Availability**: PVE 8.1+

### Notification Endpoints

#### `GET /cluster/notifications/endpoints`
Lists notification endpoints.

**Response:**
```json
{
  "data": [
    {
      "name": "webhook-alerts",
      "type": "webhook",
      "url": "https://hooks.slack.com/...",
      "enabled": 1
    },
    {
      "name": "email-admin",
      "type": "email", 
      "to": "admin@example.com",
      "enabled": 1
    }
  ]
}
```

---

## Tasks and Jobs

### List Tasks

#### `GET /nodes/{node}/tasks`
Lists running and completed tasks on a node.

**Parameters:**
- `limit` (optional): Maximum number of tasks to return
- `start` (optional): Starting task ID for pagination

**Response:**
```json
{
  "data": [
    {
      "upid": "UPID:pve-node-1:00012345:00000000:qmstart:100:user@pam:",
      "node": "pve-node-1",
      "pid": 12345,
      "pstart": 1693478400,
      "starttime": 1693478400,
      "type": "qmstart",
      "id": "100",
      "user": "user@pam",
      "status": "OK",
      "exitstatus": "OK"
    }
  ]
}
```

---

## Error Responses

### Standard Error Format

All errors return JSON with the following format:

```json
{
  "errors": [
    "Error message describing what went wrong"
  ]
}
```

### HTTP Status Codes

- **200 OK**: Request successful
- **400 Bad Request**: Invalid parameters or request
- **404 Not Found**: Resource or endpoint not found
- **501 Not Implemented**: Feature not available in current PVE version
- **500 Internal Server Error**: Server error (should not occur in mock)

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

## Rate Limiting and Delays

The mock server can simulate real-world conditions:

### Response Delays

```bash
# Add 100ms delay to all responses
MOCK_PVE_DELAY=100

# Add random jitter (±50ms)
MOCK_PVE_JITTER=50
```

### Error Injection

```bash
# Return errors for 10% of requests
MOCK_PVE_ERROR_RATE=10
```

## API Compatibility Notes

### Differences from Real PVE API

1. **Authentication**: Mock server doesn't require authentication
2. **State Persistence**: State is lost when container restarts
3. **Real Operations**: Operations return immediately (no actual VMs created)
4. **Resource Limits**: Simulated resources have configurable limits
5. **Network Operations**: Network calls don't affect real network interfaces

### Compatibility Features

1. **Response Schemas**: Match real PVE API response formats
2. **HTTP Status Codes**: Correct status codes for different scenarios  
3. **Version-Specific Features**: Accurate feature availability per version
4. **Error Messages**: Similar error message formats
5. **Parameter Validation**: Basic parameter validation where applicable

## OpenAPI Specification

A complete OpenAPI specification is available at:
- **GitHub**: `docs/openapi.yaml` (planned)
- **Runtime**: `http://localhost:8006/api2/json/openapi.json` (planned)

## SDK and Client Library Compatibility

The Mock PVE API is designed to work with existing PVE client libraries:

- **Python**: `proxmoxer`, `python-proxmox`
- **JavaScript**: `proxmox-api`, `node-proxmox`
- **Go**: `proxmox-api-go`
- **Elixir**: `pvex`
- **PHP**: `proxmox-ve-api`

Simply configure your client library to use `http://localhost:8006` as the PVE host.

---

*This API reference is automatically tested against the mock server to ensure accuracy. If you find any discrepancies, please report them in our [GitHub Issues](https://github.com/jrjsmrtn/mock-pve-api/issues).*