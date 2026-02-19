# Understanding PVE Versions

This tutorial explains how Proxmox VE versions work and how the mock server simulates version-specific behavior.

## Learning Objectives

- Understand PVE version numbering
- Learn which features are available in each version  
- Practice testing version-specific behavior
- Understand capability detection

## PVE Version Overview

Proxmox VE uses semantic versioning with major.minor format:

### Version Timeline
```
PVE 7.x (2021-2023)
├── 7.0: Base virtualization platform
├── 7.1: + Ceph Octopus  
├── 7.2: + Network improvements
├── 7.3: + Ceph Pacific
└── 7.4: + Pre-upgrade validation

PVE 8.x (2023-2025) 
├── 8.0: + SDN (Software Defined Networking)
├── 8.1: + Enhanced notifications  
├── 8.2: + Backup providers, VMware import
└── 8.3: + OVA improvements

PVE 9.x (2025+)
└── 9.0: + HA affinity rules, ZFS expansion
```

## Feature Availability by Version

Let's explore what features are available in different versions:

### Testing PVE 7.4 (Legacy)

```bash
# Start PVE 7.4 server
podman run -d --name pve-74 -p 8074:8006 \
  -e MOCK_PVE_VERSION=7.4 mock-pve-api:latest

# Get authentication  
TICKET=$(curl -s -X POST http://localhost:8074/api2/json/access/ticket \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=root@pam&password=secret" | \
  jq -r .data.ticket)

# Test basic features (available)
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8074/api2/json/nodes

# Test SDN (not available in 7.4)
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8074/api2/json/cluster/sdn/zones
# Expected: 501 Not Implemented or feature not available error
```

### Testing PVE 8.3 (Current)

```bash
# Start PVE 8.3 server
podman run -d --name pve-83 -p 8083:8006 \
  -e MOCK_PVE_VERSION=8.3 mock-pve-api:latest

# Same authentication process...
TICKET=$(curl -s -X POST http://localhost:8083/api2/json/access/ticket \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=root@pam&password=secret" | \
  jq -r .data.ticket)

# Test SDN (available in 8.0+)
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8083/api2/json/cluster/sdn/zones
# Expected: {"data": []} (empty list, but endpoint works)

# Test backup providers (available in 8.2+)  
curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8083/api2/json/cluster/backup-info/providers
```

### Testing PVE 9.0 (Future)

```bash
# Start PVE 9.0 server
podman run -d --name pve-90 -p 8090:8006 \
  -e MOCK_PVE_VERSION=9.0 mock-pve-api:latest

# Test HA affinity rules (9.0+ only)
TICKET=$(curl -s -X POST http://localhost:8090/api2/json/access/ticket \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=root@pam&password=secret" | \
  jq -r .data.ticket)

curl -H "Authorization: PVEAuthCookie=$TICKET" \
  http://localhost:8090/api2/json/cluster/ha/affinity
```

## Capability Detection

Your client code should detect capabilities rather than hardcoding version checks:

### Good Practice: Feature Detection
```python
# Check if SDN is available
def has_sdn_support(client):
    try:
        response = client.get('/cluster/sdn/zones')
        return response.status_code == 200
    except:
        return False

# Use the feature
if has_sdn_support(pve_client):
    zones = pve_client.get('/cluster/sdn/zones')
else:
    print("SDN not supported in this PVE version")
```

### Anti-Pattern: Version String Comparison
```python
# DON'T do this - brittle and error-prone
if pve_version >= "8.0":
    # What about 8.0-beta? 8.0.1? Custom builds?
    zones = client.get('/cluster/sdn/zones')
```

## Version Response Differences

The version endpoint itself changes between versions:

### PVE 7.4 Response
```json
{
  "data": {
    "version": "7.4",
    "release": "7.4", 
    "keyboard": "en-us",
    "repoid": "d7b7b6e9"
  }
}
```

### PVE 9.0 Response  
```json
{
  "data": {
    "version": "9.0-2",
    "release": "9.0",
    "console": "xtermjs",
    "keyboard": "en-us", 
    "repoid": "5fc0b8d1"
  }
}
```

**Notice:** PVE 9.0 includes a `console` field that wasn't in earlier versions.

## Testing Strategy

When testing across versions, use this approach:

1. **Start with Latest**: Test against the newest version first
2. **Test Backwards**: Verify compatibility with older versions
3. **Feature Gates**: Use capability detection, not version strings
4. **Error Handling**: Gracefully handle unsupported features

## Cleanup

```bash
# Stop all test containers
podman stop pve-74 pve-83 pve-90
podman rm pve-74 pve-83 pve-90
```

## Next Steps

- Learn [Multi-Version Testing](../how-to/multi-version-testing.md) strategies
- Check the [Version Compatibility Explanation](../explanation/version-compatibility.md)
- See [Client Integration](../how-to/client-integration.md) best practices