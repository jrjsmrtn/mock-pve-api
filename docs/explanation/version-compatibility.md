# PVE Version Compatibility System

This document explains how the Mock PVE API Server handles compatibility across different Proxmox VE versions, the reasoning behind the capability-based approach, and how version-specific features are implemented.

## Overview

Proxmox VE has evolved significantly across major versions 7.x, 8.x, and 9.x, introducing new features, changing API responses, and deprecating old functionality. The Mock PVE API Server simulates these differences accurately to ensure client libraries work correctly across version boundaries.

## Version Evolution Timeline

### PVE 7.x Series (2021-2023)
- **7.0**: Base LXC and VM management, cluster features
- **7.1**: Enhanced backup functionality, improved web interface
- **7.2**: Container template improvements, storage enhancements
- **7.3**: Security updates, bug fixes, performance improvements
- **7.4**: Final 7.x release, stability focus

**Key Characteristics:**
- Mature VM and container management
- Traditional storage and networking
- Basic cluster functionality
- Limited software-defined features

### PVE 8.x Series (2023-2025)
- **8.0**: Introduction of SDN (Software Defined Networking) technology preview
- **8.1**: Enhanced notification system, improved cluster management
- **8.2**: Backup provider plugins, storage improvements
- **8.3**: SDN stability improvements, enhanced monitoring

**Key Innovations:**
- **Software Defined Networking**: Virtual networks, zones, subnets
- **Backup Providers**: Pluggable backup system architecture
- **Enhanced Notifications**: Webhook and email notification system
- **Improved Clustering**: Better cluster join and configuration

### PVE 9.x Series (Future/Preview)
- **9.0**: HA affinity rules, enhanced resource management

**Anticipated Features:**
- **HA Affinity Rules**: Advanced high-availability resource placement
- **Enhanced Resource Management**: Improved pool and resource handling
- **Advanced Networking**: Mature SDN implementation
- **Security Enhancements**: Improved authentication and authorization

## Capability-Based Architecture

Instead of version-specific code branches, the mock server uses a capability matrix to determine feature availability:

### Capability Definition
```elixir
# MockPveApi.Capabilities module
@capabilities %{
  "7.0" => %{
    sdn_tech_preview: false,
    backup_providers: false,
    notifications: false,
    ha_affinity: false
  },
  "8.0" => %{
    sdn_tech_preview: true,
    backup_providers: false,
    notifications: false,
    ha_affinity: false
  },
  "8.1" => %{
    sdn_tech_preview: true,
    backup_providers: false,
    notifications: true,
    ha_affinity: false
  },
  "8.2" => %{
    sdn_tech_preview: true,
    backup_providers: true,
    notifications: true,
    ha_affinity: false
  },
  "9.0" => %{
    sdn_tech_preview: true,
    backup_providers: true,
    notifications: true,
    ha_affinity: true
  }
}
```

### Feature Detection
```elixir
# Check if a feature is available in current version
def supports?(version, capability) do
  case get_capabilities(version) do
    %{^capability => true} -> true
    _ -> false
  end
end

# Usage in handlers
def handle_sdn_zones(conn, _params) do
  current_version = get_current_version()
  
  case Capabilities.supports?(current_version, :sdn_tech_preview) do
    true -> 
      zones = State.get_sdn_zones()
      json(conn, %{data: zones})
    
    false ->
      conn
      |> put_status(501)
      |> json(%{
        errors: [
          "Feature not implemented",
          "SDN features require PVE 8.0+, currently simulating #{current_version}"
        ]
      })
  end
end
```

## Version-Specific Features

### Software Defined Networking (SDN) - PVE 8.0+

**Endpoints Affected:**
- `/api2/json/cluster/sdn/zones`
- `/api2/json/cluster/sdn/vnets`
- `/api2/json/cluster/sdn/subnets`

**Implementation:**
```elixir
# Available in PVE 8.0+ only
def list_sdn_zones(conn, _params) do
  if Capabilities.supports?(current_version(), :sdn_tech_preview) do
    zones = [
      %{
        zone: "localnetwork",
        type: "simple",
        nodes: "pve-node-1,pve-node-2"
      }
    ]
    json(conn, %{data: zones})
  else
    send_version_error(conn, "SDN features require PVE 8.0+")
  end
end
```

**Version Differences:**
- **PVE 7.4**: Returns 501 Not Implemented
- **PVE 8.0+**: Returns zone configurations and management endpoints

### Backup Providers - PVE 8.2+

**Endpoints Affected:**
- `/api2/json/cluster/backup-info/providers`

**Implementation:**
```elixir
def list_backup_providers(conn, _params) do
  if Capabilities.supports?(current_version(), :backup_providers) do
    providers = [
      %{provider: "pbs", name: "Proxmox Backup Server", enabled: 1},
      %{provider: "external", name: "External Backup", enabled: 0}
    ]
    json(conn, %{data: providers})
  else
    send_version_error(conn, "Backup providers require PVE 8.2+")
  end
end
```

### Notification System - PVE 8.1+

**Endpoints Affected:**
- `/api2/json/cluster/notifications/endpoints`
- `/api2/json/cluster/notifications/matchers`

**Features:**
- Webhook notifications
- Email notifications  
- SMS notifications (8.2+)
- Custom notification matchers

### HA Affinity Rules - PVE 9.0+

**Endpoints Affected:**
- `/api2/json/cluster/ha/affinity`

**Features:**
- Resource placement rules
- Node preference settings
- Anti-affinity constraints

## Response Format Evolution

### API Response Changes

Some endpoints return different data structures across versions:

#### Version Information Response
```elixir
# PVE 7.x response
%{
  version: "7.4",
  release: "7.4-1",
  repoid: "f123456d"
}

# PVE 8.x response (enhanced)
%{
  version: "8.3",
  release: "8.3-1", 
  repoid: "f123456d",
  keyboard: "en-us",
  capabilities: %{
    sdn: true,
    backup_providers: true,
    notifications: true
  }
}
```

#### Cluster Resources Response
```elixir
# PVE 7.x - Basic resource info
%{
  id: "qemu/100",
  type: "qemu",
  vmid: 100,
  name: "test-vm",
  status: "running"
}

# PVE 8.x - Enhanced with networking info
%{
  id: "qemu/100",
  type: "qemu", 
  vmid: 100,
  name: "test-vm",
  status: "running",
  network: %{
    interfaces: 1,
    sdn_enabled: true
  }
}
```

## Version Configuration

### Environment Variable Control
```bash
# Set specific PVE version to simulate
export MOCK_PVE_VERSION=8.3

# Enable/disable specific features (overrides)
export MOCK_PVE_ENABLE_SDN=true
export MOCK_PVE_ENABLE_BACKUP_PROVIDERS=false
```

### Runtime Version Switching
The mock server supports changing versions without restart through special endpoints:

```bash
# Change simulated version (development only)
curl -X POST http://localhost:8006/api2/json/_admin/version \
  -d '{"version": "7.4"}'

# Get current capabilities
curl http://localhost:8006/api2/json/_admin/capabilities
```

## Error Handling

### Version-Specific Error Messages

When clients request unavailable features:

```json
{
  "errors": [
    "Feature not implemented",
    "SDN features require PVE 8.0+, currently simulating 7.4"
  ]
}
```

### Graceful Degradation

Client libraries should handle version differences gracefully:

```python
# Good: Feature detection
def supports_sdn(client):
    try:
        response = client.get('/cluster/sdn/zones')
        return response.status_code == 200
    except:
        return False

if supports_sdn(pve_client):
    # Use SDN features
    pass
else:
    # Fall back to traditional networking
    pass
```

```python
# Bad: Version string comparison
def supports_sdn(version_string):
    major, minor = version_string.split('.')[:2]
    return int(major) >= 8  # Brittle!
```

## Testing Across Versions

### Multi-Version Test Strategy

```bash
# Test against all supported versions
for version in 7.4 8.0 8.3 9.0; do
  echo "Testing PVE $version..."
  
  podman run -d --name mock-pve-$version \
    -p 800$((${version%%.*})):8006 \
    -e MOCK_PVE_VERSION=$version \
    mock-pve-api:latest
  
  # Run client tests
  PVE_PORT=800$((${version%%.*})) python test_client.py
  
  podman stop mock-pve-$version
  podman rm mock-pve-$version
done
```

### Version Compatibility Matrix Testing

```python
import pytest

@pytest.fixture(params=['7.4', '8.0', '8.3', '9.0'])
def pve_version(request):
    return request.param

def test_version_features(pve_version, mock_server):
    # Test features available in this version
    if version_at_least(pve_version, '8.0'):
        assert_sdn_available(mock_server)
    else:
        assert_sdn_unavailable(mock_server)
```

## Implementation Best Practices

### Handler Implementation

```elixir
defmodule MockPveApi.Handlers.SDN do
  @moduledoc "SDN-specific endpoint handlers"
  
  def list_zones(conn, _params) do
    # Always check capability first
    with true <- Capabilities.supports?(current_version(), :sdn_tech_preview),
         zones <- State.get_sdn_zones() do
      json(conn, %{data: zones})
    else
      false -> send_capability_error(conn, "SDN", "8.0+")
      error -> handle_error(conn, error)
    end
  end
  
  # Helper for consistent error messages
  defp send_capability_error(conn, feature, required_version) do
    current = current_version()
    conn
    |> put_status(501)
    |> json(%{
      errors: [
        "Feature not implemented",
        "#{feature} features require PVE #{required_version}, currently simulating #{current}"
      ]
    })
  end
end
```

### Adding New Version Support

1. **Update Capability Matrix**: Add new version with feature flags
2. **Add Version-Specific Logic**: Implement new endpoints/responses
3. **Update Tests**: Add test cases for new version
4. **Document Changes**: Update version compatibility docs
5. **Validate Compatibility**: Test against real PVE if possible

## Future Version Planning

### Anticipated Changes in PVE 9.x+
- Enhanced SDN with overlay networks
- Advanced HA scheduling algorithms
- Improved backup compression and deduplication
- Cloud provider integrations
- Enhanced security and RBAC

### Extensibility Design
The capability system is designed to easily accommodate future versions:

```elixir
# Adding PVE 9.1 support
@capabilities Map.put(@capabilities, "9.1", %{
  sdn_tech_preview: true,
  backup_providers: true,
  notifications: true,  
  ha_affinity: true,
  cloud_integrations: true,  # New feature
  enhanced_rbac: true        # New feature
})
```

## Troubleshooting Version Issues

### Common Problems

1. **Feature Not Available**: Check if feature exists in target version
2. **Unexpected Response Format**: Verify response schema matches version
3. **Version Detection Failing**: Ensure MOCK_PVE_VERSION is set correctly
4. **Tests Failing**: Validate test assumptions about version capabilities

### Debugging Tools

```bash
# Check current version and capabilities
curl http://localhost:8006/api2/json/version

# Debug capability matrix
curl http://localhost:8006/api2/json/_debug/capabilities

# Test specific feature availability
curl http://localhost:8006/api2/json/cluster/sdn/zones
```

---

*Version compatibility is maintained through systematic testing against multiple PVE versions. If you encounter version-specific issues, please report them with the specific PVE version and expected behavior.*