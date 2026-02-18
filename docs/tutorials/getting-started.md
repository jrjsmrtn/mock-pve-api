# Getting Started with Mock PVE API

This guide will help you get up and running with the Mock PVE API Server in just a few minutes.

## Quick Start

### Prerequisites

- **Podman** (recommended) or Docker
- Or **Elixir 1.15+ and OTP 26+** for running from source

### 1. Run with Podman (Recommended)

The easiest way to start the Mock PVE API Server:

```bash
# Start the server (will pull image if not present)
podman run -d -p 8006:8006 docker.io/docker.io/jrjsmrtn/mock-pve-api:latest

# Verify it's working
curl http://localhost:8006/api2/json/version
```

You should see a JSON response with version information:

```json
{
  "data": {
    "version": "8.3",
    "release": "8.3-1", 
    "repoid": "abcd1234"
  }
}
```

### 2. Test Basic Endpoints

```bash
# Get cluster status
curl http://localhost:8006/api2/json/cluster/status

# List nodes
curl http://localhost:8006/api2/json/nodes

# List cluster resources
curl http://localhost:8006/api2/json/cluster/resources
```

## Configuration Options

### Environment Variables

Configure the mock server behavior using environment variables:

```bash
# Run PVE 7.4 simulation
podman run -d -p 8006:8006 \
  -e MOCK_PVE_VERSION=7.4 \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Enable debug logging
podman run -d -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  docker.io/jrjsmrtn/mock-pve-api:latest

# Add response delays for testing
podman run -d -p 8006:8006 \
  -e MOCK_PVE_DELAY=100 \
  -e MOCK_PVE_JITTER=50 \
  docker.io/jrjsmrtn/mock-pve-api:latest
```

### Common Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MOCK_PVE_VERSION` | `8.3` | PVE version to simulate |
| `MOCK_PVE_PORT` | `8006` | Server port |
| `MOCK_PVE_LOG_LEVEL` | `info` | Logging level |
| `MOCK_PVE_DELAY` | `0` | Response delay (ms) |
| `MOCK_PVE_ERROR_RATE` | `0` | Error injection rate (%) |

See [Environment Variables Reference](../reference/environment-variables.md) for complete options.

## Version Compatibility

### Supported PVE Versions

The Mock PVE API Server supports the following Proxmox VE versions:

| PVE Version | Key Features | Docker Tag |
|-------------|--------------|------------|
| **7.0-7.4** | Basic virtualization, containers, storage | `pve7` |
| **8.0-8.3** | + SDN, notifications, backup providers | `pve8` |
| **9.0** | + SDN fabrics, HA affinity rules | `pve9` |

### Version-Specific Testing

```bash
# Test SDN features (available in 8.0+)
podman run -d -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.0 \
  docker.io/jrjsmrtn/mock-pve-api:latest

curl http://localhost:8006/api2/json/cluster/sdn/zones

# Test on PVE 7.4 (should return 501 Not Implemented)
podman run -d -p 8007:8006 \
  -e MOCK_PVE_VERSION=7.4 \
  docker.io/jrjsmrtn/mock-pve-api:latest

curl http://localhost:8007/api2/json/cluster/sdn/zones
```

## Docker Compose Setup

For more complex scenarios, use Docker Compose:

Create `docker-compose.yml`:

```yaml
version: '3.8'
services:
  # Latest PVE for main testing
  mock-pve-latest:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "8006:8006"
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_LOG_LEVEL=info
  
  # PVE 7.4 for compatibility testing  
  mock-pve-7:
    image: docker.io/jrjsmrtn/mock-pve-api:pve7
    ports:
      - "8007:8006"
    environment:
      - MOCK_PVE_VERSION=7.4
      - MOCK_PVE_ENABLE_SDN=false
  
  # Development/debug instance
  mock-pve-debug:
    image: docker.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "8008:8006"
    environment:
      - MOCK_PVE_VERSION=8.0
      - MOCK_PVE_LOG_LEVEL=debug
      - MOCK_PVE_DELAY=50
```

Start all services:

```bash
docker-compose up -d

# Test different versions
curl http://localhost:8006/api2/json/version  # PVE 8.3
curl http://localhost:8007/api2/json/version  # PVE 7.4  
curl http://localhost:8008/api2/json/version  # PVE 8.0 debug
```

## CI/CD Integration

### GitHub Actions

Add to your `.github/workflows/test.yml`:

```yaml
name: Test with Mock PVE API

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mock-pve:
        image: docker.io/jrjsmrtn/mock-pve-api:latest
        ports:
          - 8006:8006
        env:
          MOCK_PVE_VERSION: "8.3"
          MOCK_PVE_LOG_LEVEL: "debug"
        options: >-
          --health-cmd "curl -f http://localhost:8006/api2/json/version || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4
      
      - name: Test against Mock PVE API
        run: |
          # Wait for service to be ready
          curl -f http://localhost:8006/api2/json/version
          
          # Run your tests
          python -m pytest tests/
        env:
          PVE_HOST: localhost
          PVE_PORT: 8006
```

### GitLab CI

Add to your `.gitlab-ci.yml`:

```yaml
test:
  image: python:3.11
  services:
    - name: docker.io/jrjsmrtn/mock-pve-api:latest
      alias: mock-pve
      variables:
        MOCK_PVE_VERSION: "8.3"
        MOCK_PVE_LOG_LEVEL: "info"

  script:
    - pip install -r requirements.txt
    - python -m pytest tests/
  
  variables:
    PVE_HOST: mock-pve
    PVE_PORT: 8006
```

## Language Examples

### Python

```python
import requests

# Configure client for mock server
base_url = "http://localhost:8006/api2/json"

# Get version info
response = requests.get(f"{base_url}/version")
version_info = response.json()["data"]
print(f"PVE Version: {version_info['version']}")

# List VMs
response = requests.get(f"{base_url}/cluster/resources?type=vm")
vms = response.json()["data"]
print(f"Found {len(vms)} VMs")
```

### JavaScript/Node.js

```javascript
const axios = require('axios');

const baseURL = 'http://localhost:8006/api2/json';
const client = axios.create({ baseURL });

async function testMockPVE() {
  // Get version
  const version = await client.get('/version');
  console.log('PVE Version:', version.data.data.version);
  
  // Get nodes
  const nodes = await client.get('/nodes');
  console.log('Nodes:', nodes.data.data.length);
}

testMockPVE();
```

### cURL Scripts

```bash
#!/bin/bash
# Test script for Mock PVE API

BASE_URL="http://localhost:8006/api2/json"

echo "Testing Mock PVE API..."

# Version check
echo "=== Version ==="
curl -s "$BASE_URL/version" | jq .

# Cluster status
echo "=== Cluster Status ==="
curl -s "$BASE_URL/cluster/status" | jq .

# Node list
echo "=== Nodes ==="
curl -s "$BASE_URL/nodes" | jq .

echo "Tests completed!"
```

## Running from Source

If you prefer to run from source code:

### Prerequisites

- Elixir 1.15+
- OTP 26+

### Steps

```bash
# Clone repository
git clone https://github.com/jrjsmrtn/mock-pve-api.git
cd mock-pve-api

# Install dependencies
mix deps.get

# Compile
mix compile

# Run server
mix run --no-halt
```

The server will be available at `http://localhost:8006`.

### Development Mode

```bash
# Start with interactive shell
iex -S mix run --no-halt

# In the IEx console, you can:
MockPveApi.State.reset_state()         # Reset state
MockPveApi.Config.get_config()         # View configuration
MockPveApi.State.inspect_state()       # Inspect current state
```

## Troubleshooting

### Common Issues

#### Container Won't Start

```bash
# Check if port is already in use
sudo netstat -tulpn | grep :8006

# Use different port
podman run -d -p 8007:8006 docker.io/jrjsmrtn/mock-pve-api:latest
```

#### Version Not Recognized

```bash
# Check supported versions
podman run --rm docker.io/jrjsmrtn/mock-pve-api:latest mix run -e "
  IO.inspect(MockPveApi.Capabilities.supported_versions())
"
```

#### API Returns 501 Errors

This is normal behavior when requesting version-specific features:

```bash
# SDN not available in PVE 7.x
podman run -d -p 8006:8006 \
  -e MOCK_PVE_VERSION=7.4 \
  docker.io/jrjsmrtn/mock-pve-api:latest

curl http://localhost:8006/api2/json/cluster/sdn/zones
# Returns: {"errors": ["SDN features not available in PVE 7.4. Requires PVE 8.0+"]}
```

#### Connection Refused

```bash
# Wait for container to start
sleep 3

# Check container status
docker ps
docker logs <container_id>

# Test health check
curl -f http://localhost:8006/api2/json/version || echo "Not ready"
```

### Debug Mode

Enable debug logging for troubleshooting:

```bash
podman run -d -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  docker.io/jrjsmrtn/mock-pve-api:latest

# View logs
docker logs <container_id>
```

## Next Steps

- **[API Reference](../reference/api-reference.md)**: Complete list of supported endpoints
- **[Environment Variables Reference](../reference/environment-variables.md)**: Detailed configuration options
- **[CI/CD Setup Guide](../how-to/setup-ci-cd.md)**: Advanced CI/CD patterns
- **[Version Compatibility Explanation](../explanation/version-compatibility.md)**: PVE version differences
- **[Client Examples](../../examples/)**: Language-specific client examples

## Getting Help

- **GitHub Issues**: https://github.com/jrjsmrtn/mock-pve-api/issues
- **Discussions**: https://github.com/jrjsmrtn/mock-pve-api/discussions  
- **Documentation**: Comprehensive guides in the `docs/` directory following Diátaxis framework

Happy testing with Mock PVE API! 🚀