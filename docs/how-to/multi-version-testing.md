# How to Test Across Multiple PVE Versions

This guide shows you how to set up comprehensive testing across different Proxmox VE versions using the mock server.

## Problem Solved

You need to ensure your PVE client code works correctly across different PVE versions (7.x, 8.x, 9.x) without maintaining multiple physical Proxmox clusters.

## Quick Solution

Use multiple mock server containers with different `MOCK_PVE_VERSION` environment variables:

```bash
# Start multiple versions simultaneously
podman run -d --name pve-74 -p 8074:8006 -e MOCK_PVE_VERSION=7.4 mock-pve-api:latest
podman run -d --name pve-83 -p 8083:8006 -e MOCK_PVE_VERSION=8.3 mock-pve-api:latest  
podman run -d --name pve-90 -p 8090:8006 -e MOCK_PVE_VERSION=9.0 mock-pve-api:latest

# Run your test suite against each
for port in 8074 8083 8090; do
  PVE_HOST=localhost PVE_PORT=$port pytest tests/
done
```

## Detailed Setup

### 1. Container-Based Multi-Version Testing

Create a test configuration that spins up multiple versions:

```bash
#!/bin/bash
# test-multi-version.sh

# Define versions to test
VERSIONS=("7.4" "8.3" "9.0")
PORTS=(8074 8083 8090)

# Start all versions
for i in "${!VERSIONS[@]}"; do
  version=${VERSIONS[$i]}
  port=${PORTS[$i]}
  
  echo "Starting PVE ${version} on port ${port}"
  podman run -d --name "pve-${version//.}" \
    -p "${port}:8006" \
    -e "MOCK_PVE_VERSION=${version}" \
    -e "MOCK_PVE_LOG_LEVEL=warn" \
    mock-pve-api:latest
done

# Wait for all containers to be ready
for port in "${PORTS[@]}"; do
  echo "Waiting for PVE on port ${port}"
  timeout 30 bash -c "until curl -f http://localhost:${port}/api2/json/version; do sleep 1; done"
done

echo "All PVE versions ready for testing"
```

### 2. Programmatic Multi-Version Testing

#### Python Example

```python
# test_multi_version.py
import pytest
import requests
from contextlib import contextmanager

PVE_CONFIGS = [
    {"version": "7.4", "port": 8074, "features": {"sdn": False, "backup_providers": False}},
    {"version": "8.3", "port": 8083, "features": {"sdn": True, "backup_providers": True}}, 
    {"version": "9.0", "port": 8090, "features": {"sdn": True, "backup_providers": True, "ha_affinity": True}},
]

@pytest.fixture(params=PVE_CONFIGS)
def pve_client(request):
    config = request.param
    base_url = f"http://localhost:{config['port']}/api2/json"
    
    # Get authentication ticket
    auth_response = requests.post(f"{base_url}/access/ticket", data={
        "username": "root@pam", 
        "password": "secret"
    })
    ticket = auth_response.json()["data"]["ticket"]
    
    return {
        "base_url": base_url,
        "headers": {"Authorization": f"PVEAuthCookie={ticket}"},
        "version": config["version"],
        "features": config["features"]
    }

def test_basic_functionality(pve_client):
    """Test that basic APIs work across all versions"""
    # Version endpoint should always work
    response = requests.get(f"{pve_client['base_url']}/version")
    assert response.status_code == 200
    assert response.json()["data"]["version"].startswith(pve_client["version"])
    
    # Authenticated endpoints should work
    response = requests.get(f"{pve_client['base_url']}/nodes", 
                          headers=pve_client["headers"])
    assert response.status_code == 200

def test_version_specific_features(pve_client):
    """Test features that are version-dependent"""
    
    # SDN endpoints
    response = requests.get(f"{pve_client['base_url']}/cluster/sdn/zones",
                          headers=pve_client["headers"])
    
    if pve_client["features"]["sdn"]:
        assert response.status_code == 200
    else:
        assert response.status_code in [501, 404]  # Not supported
        
    # Backup providers (8.2+)  
    response = requests.get(f"{pve_client['base_url']}/cluster/backup-info/providers",
                          headers=pve_client["headers"])
    
    if pve_client["features"]["backup_providers"]:
        assert response.status_code == 200
    else:
        assert response.status_code in [501, 404]

def test_graceful_degradation(pve_client):
    """Ensure client handles unsupported features gracefully"""
    # Try to access a 9.0+ feature on older versions
    response = requests.get(f"{pve_client['base_url']}/cluster/ha/affinity",
                          headers=pve_client["headers"])
    
    if pve_client["features"].get("ha_affinity"):
        assert response.status_code == 200
    else:
        # Should fail gracefully, not crash
        assert response.status_code in [501, 404]
        # Should return proper JSON error
        assert "error" in response.json() or "errors" in response.json()
```

### 3. Docker Compose Multi-Version Setup

```yaml
# docker-compose.multi-version.yml
version: '3.8'

services:
  pve-74:
    build: .
    ports:
      - "8074:8006"  
    environment:
      - MOCK_PVE_VERSION=7.4
      - MOCK_PVE_LOG_LEVEL=warn
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
      
  pve-83:
    build: .
    ports:
      - "8083:8006"
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_LOG_LEVEL=warn
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
      
  pve-90:
    build: .
    ports:
      - "8090:8006"
    environment:
      - MOCK_PVE_VERSION=9.0
      - MOCK_PVE_LOG_LEVEL=warn
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8006/api2/json/version"]
```

Usage:
```bash
# Start all versions
podman-compose -f docker-compose.multi-version.yml up -d

# Run tests
pytest test_multi_version.py

# Cleanup
podman-compose -f docker-compose.multi-version.yml down
```

### 4. GitHub Actions Multi-Version Matrix

```yaml
# .github/workflows/multi-version-test.yml
name: Multi-Version PVE Testing
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        pve_version: ["7.4", "8.3", "9.0"]
        
    steps:
      - uses: actions/checkout@v4
      
      - name: Build mock server
        run: docker build -t mock-pve-api .
        
      - name: Start PVE ${{ matrix.pve_version }}
        run: |
          docker run -d --name mock-pve \
            -p 8006:8006 \
            -e MOCK_PVE_VERSION=${{ matrix.pve_version }} \
            mock-pve-api
          timeout 30 bash -c 'until curl -f http://localhost:8006/api2/json/version; do sleep 1; done'
          
      - name: Run tests against PVE ${{ matrix.pve_version }}
        run: pytest tests/
        env:
          PVE_HOST: localhost
          PVE_PORT: 8006
          PVE_VERSION: ${{ matrix.pve_version }}
```

## Best Practices

### 1. Feature Detection, Not Version Checking

```python
# Good: Test actual capability
def supports_sdn(client):
    try:
        response = client.get('/cluster/sdn/zones')
        return response.status_code == 200
    except:
        return False

# Bad: Hardcoded version comparison  
def supports_sdn(version):
    return version >= "8.0"  # Brittle!
```

### 2. Isolated Test Data

Each version should use independent test data:

```python
@pytest.fixture
def test_resources(pve_client):
    """Create test VMs/containers specific to this version"""
    version = pve_client["version"] 
    vm_id = 1000 + int(version.replace(".", ""))  # 1074, 1083, 1090
    
    # Create test VM
    requests.post(f"{pve_client['base_url']}/nodes/pve-node1/qemu", 
                  headers=pve_client["headers"],
                  data={"vmid": vm_id, "name": f"test-vm-{version}"})
    
    yield {"vm_id": vm_id}
    
    # Cleanup
    requests.delete(f"{pve_client['base_url']}/nodes/pve-node1/qemu/{vm_id}",
                   headers=pve_client["headers"])
```

### 3. Parallel Test Execution

Run tests in parallel for faster feedback:

```bash
# Using pytest-xdist
pip install pytest-xdist

# Run tests across all versions in parallel
pytest -n 3 test_multi_version.py  # 3 = number of versions
```

## Troubleshooting

**Containers Won't Start:**
- Check port conflicts: `netstat -tlnp | grep :80`
- Verify images are built: `podman images | grep mock-pve-api`

**Tests Failing Randomly:**
- Add startup wait times: containers need time to initialize
- Check for resource conflicts between parallel tests
- Use unique identifiers per version

**Feature Detection Issues:**
- Mock server returns 501 for unsupported endpoints
- Some features may return empty lists vs errors
- Check response structure, not just status codes

## Cleanup Script

```bash
#!/bin/bash
# cleanup-versions.sh

echo "Stopping all PVE mock servers..."
podman ps --format "table {{.Names}}" | grep pve- | xargs -r podman stop
podman ps -a --format "table {{.Names}}" | grep pve- | xargs -r podman rm

echo "Cleanup complete"
```