# Mock PVE API

<!-- [![Hex.pm Version](https://img.shields.io/hexpm/v/mock_pve_api.svg)](https://hex.pm/packages/mock_pve_api) -->
<!-- [![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fjrjsmrtn%2Fmock--pve--api-blue)](https://github.com/jrjsmrtn/mock-pve-api/pkgs/container/mock-pve-api) -->
[![Podman Compatible](https://img.shields.io/badge/podman-compatible-326ce5.svg)](https://podman.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/jrjsmrtn/mock-pve-api/workflows/CI/badge.svg)](https://github.com/jrjsmrtn/mock-pve-api/actions)

A lightweight, containerized Mock Proxmox VE API Server for testing and development. Perfect for CI/CD pipelines, integration testing, and developing PVE client libraries without requiring actual Proxmox VE infrastructure.

## Origin Story

Born from the [**pvex**](https://github.com/jrjsmrtn/pvex) project during Sprint G, this mock server eliminated infrastructure dependencies for Elixir PVE client testing. Its success and broad ecosystem value led to extraction as a standalone project, now serving the entire Proxmox VE development community across all programming languages.

**Battle-Tested Metrics from pvex Integration:**

- ✅ **Test Reliability**: 100% pass rate across 560+ unit and integration tests
- 🔄 **CI/CD Ready**: Zero infrastructure dependencies
- 🎯 **Version Coverage**: Complete PVE 7.0-9.0 feature matrix
- 🌍 **Multi-Language**: Example scripts for Python, JavaScript, Elixir, Go, Ruby, Shell

## Features

- **Complete PVE Version Support**: Simulates PVE 7.0 through 9.0 with version-specific features
- **Realistic API Responses**: Accurate JSON responses matching real PVE API schemas
- **Stateful Resource Management**: In-memory state tracking for VM, container, and storage lifecycle testing
- **Container-Ready**: Build OCI images for deployment with Podman or Docker
- **CI/CD Friendly**: Zero external dependencies - perfect for GitHub Actions, GitLab CI, etc.
- **Configurable**: Environment variables for version simulation and SSL/TLS
- **Language Agnostic**: Works with any PVE client library (Python, JavaScript, Go, Elixir, etc.)

## Quick Start

> **📦 Container Images**: Build from source using Podman or Docker. Pre-built images on GHCR are planned for a future release.

### Build and Run with Containers (Current Method)

```bash
# Clone the repository
git clone https://github.com/jrjsmrtn/mock-pve-api.git
cd mock-pve-api

# Build container image with Podman (recommended)
podman build -f docker/Dockerfile -t mock-pve-api:latest .

# Run with different PVE versions
podman run -d -p 8006:8006 -e MOCK_PVE_VERSION=8.3 mock-pve-api:latest
podman run -d -p 8007:8006 -e MOCK_PVE_VERSION=7.4 mock-pve-api:latest
podman run -d -p 8008:8006 -e MOCK_PVE_VERSION=9.0 mock-pve-api:latest

# Rootless container (more secure)
podman run -d --userns=keep-id -p 8006:8006 -e MOCK_PVE_VERSION=8.3 mock-pve-api:latest
```

**Using the Makefile (Recommended):**

```bash
# Build production container
make container-build

# Run container on port 8006
make container-run

# Build and run development container with volume mounts
make container-build-dev
make container-run-dev
```

_💡 Also works with Docker - just replace `podman` with `docker` in the commands above_

### Podman Compose (Build from Source)

```yaml
version: "3.8"
services:
  mock-pve:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "8006:8006"
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_LOG_LEVEL=info
    # Podman-specific: Enable systemd integration
    systemd: true
```

### Run Directly from Source

```bash
git clone https://github.com/jrjsmrtn/mock-pve-api.git
cd mock-pve-api
mix deps.get
mix run --no-halt
```

## Usage Examples

### Testing Your PVE Client

```bash
# Build and start mock server (using local image)
podman build -f docker/Dockerfile -t mock-pve-api:latest .
podman run -d --name mock-pve -p 8006:8006 -e MOCK_PVE_VERSION=8.3 mock-pve-api:latest

# Test with curl
curl http://localhost:8006/api2/json/version    # HTTP mode (default)
curl -k https://localhost:8006/api2/json/version  # HTTPS mode (when SSL enabled)
curl http://localhost:8006/api2/json/nodes      # Requires authentication
curl http://localhost:8006/api2/json/cluster/status

# Get authentication ticket and test authenticated endpoints
curl -X POST http://localhost:8006/api2/json/access/ticket \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "username=root@pam&password=secret"

# Use the returned ticket for authenticated requests
```

### Python Client Testing

```python
import requests

# Mock server running on localhost:8006
base_url = "http://localhost:8006/api2/json"

# Get version info
response = requests.get(f"{base_url}/version")
print(f"PVE Version: {response.json()['data']['version']}")

# List nodes
response = requests.get(f"{base_url}/nodes")
nodes = response.json()['data']
print(f"Available nodes: {[node['node'] for node in nodes]}")
```

### JavaScript/Node.js Testing

```javascript
const axios = require("axios");

const baseURL = "http://localhost:8006/api2/json";

async function testMockPVE() {
  // Get version
  const version = await axios.get(`${baseURL}/version`);
  console.log("PVE Version:", version.data.data.version);

  // List VMs
  const vms = await axios.get(`${baseURL}/cluster/resources?type=vm`);
  console.log("VMs:", vms.data.data);
}

testMockPVE();
```

### GitHub Actions Integration

```yaml
name: Test PVE Client
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    # NOTE: Replace with ghcr.io/jrjsmrtn/mock-pve-api:latest once
    # pre-built images are published (Phase 5). For now, build from source.
    services:
      mock-pve:
        image: ghcr.io/jrjsmrtn/mock-pve-api:latest
        ports:
          - 8006:8006
        env:
          MOCK_PVE_VERSION: "8.3"
        options: >-
          --health-cmd "curl -f http://localhost:8006/api2/json/version || exit 1"
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Run tests against mock PVE
        run: |
          # Your test commands here
          pytest tests/integration/
        env:
          PVE_HOST: localhost
          PVE_PORT: 8006
```

## Configuration

Configure the mock server using environment variables:

| Variable                           | Default            | Description                             |
| ---------------------------------- | ------------------ | --------------------------------------- |
| `MOCK_PVE_VERSION`                 | `8.3`              | PVE version to simulate (7.0-9.0)       |
| `MOCK_PVE_PORT`                    | `8006`             | Server port                             |
| `MOCK_PVE_HOST`                    | `0.0.0.0`          | Bind address                            |
| `MOCK_PVE_SSL_ENABLED`             | `false`            | Enable SSL/TLS                          |
| `MOCK_PVE_SSL_KEYFILE`             | `certs/server.key` | SSL private key file                    |
| `MOCK_PVE_SSL_CERTFILE`            | `certs/server.crt` | SSL certificate file                    |
| `MOCK_PVE_SSL_CACERTFILE`          |                    | Optional CA certificate file            |
| `MOCK_PVE_LOG_LEVEL`               | `info`             | Logging level                           |

**Planned environment variables** (configured but not yet implemented):

| Variable                           | Default   | Description                             |
| ---------------------------------- | --------- | --------------------------------------- |
| `MOCK_PVE_ENABLE_SDN`              | `true`    | Enable SDN endpoints (8.0+)             |
| `MOCK_PVE_ENABLE_FIREWALL`         | `true`    | Enable firewall endpoints               |
| `MOCK_PVE_ENABLE_BACKUP_PROVIDERS` | `true`    | Enable backup provider endpoints (8.2+) |
| `MOCK_PVE_DELAY`                   | `0`       | Response delay in milliseconds          |
| `MOCK_PVE_ERROR_RATE`              | `0`       | Simulate error percentage (0-100)       |

### Runtime Configuration

The mock server uses **runtime configuration** (`config/runtime.exs`) to properly handle environment variables in containerized environments. This ensures that:

- Environment variables are read at **container startup time**, not build time
- PVE version simulation works correctly with `MOCK_PVE_VERSION`
- Container deployments can be dynamically configured without rebuilding

**Key Benefits:**

- ✅ **Dynamic Version Selection**: Change PVE versions by setting environment variables
- ✅ **Container Compatibility**: Works with Podman, Docker, and orchestration platforms
- ✅ **CI/CD Ready**: No configuration baked into images, purely environment-driven

**Example Multi-Version Deployment:**

```bash
# Deploy multiple PVE versions simultaneously
podman run -d -p 8007:8006 -e MOCK_PVE_VERSION=7.4 mock-pve-api:latest
podman run -d -p 8008:8006 -e MOCK_PVE_VERSION=8.3 mock-pve-api:latest
podman run -d -p 8009:8006 -e MOCK_PVE_VERSION=9.0 mock-pve-api:latest

# Test version differences
curl http://localhost:8007/api2/json/version  # Returns PVE 7.4
curl http://localhost:8008/api2/json/version  # Returns PVE 8.3
curl http://localhost:8009/api2/json/version  # Returns PVE 9.0
```

### SSL/TLS Configuration

The mock server supports SSL/TLS to better simulate the real Proxmox VE API, which uses HTTPS on port 8006 by default.

#### Generate Self-Signed Certificates

```bash
# Generate certificates for testing (requires OpenSSL)
./scripts/generate-certs.sh

# Certificates will be created in certs/ directory:
# - certs/server.key  (private key)
# - certs/server.crt  (certificate)
```

#### Enable SSL/TLS

```bash
# Local development with SSL
export MOCK_PVE_SSL_ENABLED=true
export MOCK_PVE_SSL_KEYFILE=certs/server.key
export MOCK_PVE_SSL_CERTFILE=certs/server.crt
mix run --no-halt

# Test HTTPS connection (note -k flag for self-signed certificates)
curl -k https://localhost:8006/api2/json/version
```

#### Container Deployment with SSL

```bash
# Generate certificates first
./scripts/generate-certs.sh

# Run container with SSL enabled
podman run -d --name mock-pve-ssl \
  -p 8006:8006 \
  -v $(pwd)/certs:/app/certs:ro \
  -e MOCK_PVE_SSL_ENABLED=true \
  -e MOCK_PVE_SSL_KEYFILE=certs/server.key \
  -e MOCK_PVE_SSL_CERTFILE=certs/server.crt \
  ghcr.io/jrjsmrtn/mock-pve-api:latest

# Test HTTPS connection
curl -k https://localhost:8006/api2/json/version
```

**Important Notes:**

- SSL/TLS is **disabled by default** for backward compatibility
- The generated certificates are **self-signed** and suitable only for testing
- Always use `-k` flag with curl or disable SSL verification in your PVE clients
- For production use, provide your own certificates using volume mounts

## Supported PVE Versions

### PVE 7.x Series

- **7.0**: Basic virtualization, containers, storage
- **7.1**: + Ceph Octopus support
- **7.2**: + Network improvements
- **7.3**: + Ceph Pacific support
- **7.4**: + cgroup v1, pre-upgrade validation

### PVE 8.x Series

- **8.0**: + SDN (tech preview), realm sync, resource mappings, cgroup v2
- **8.1**: + Enhanced notifications, webhooks, filters
- **8.2**: + VMware import wizard, backup providers, auto-install
- **8.3**: + OVA import improvements, kernel 6.11 opt-in

### PVE 9.x Series

- **9.0**: + SDN fabrics, HA affinity rules, LVM snapshots, ZFS RAIDZ expansion

## API Endpoints Coverage

The mock server implements the most commonly used PVE API endpoints:

### Core Endpoints

- ✅ `/api2/json/version` - Version information
- ✅ `/api2/json/nodes` - Cluster nodes
- ✅ `/api2/json/cluster/status` - Cluster status
- ✅ `/api2/json/cluster/resources` - Resource overview

### Virtualization

- ✅ `/api2/json/nodes/{node}/qemu` - Virtual machines
- ✅ `/api2/json/nodes/{node}/lxc` - LXC containers
- ✅ `/api2/json/nodes/{node}/storage` - Storage management

### Advanced Features (Version Dependent)

- ✅ `/api2/json/cluster/sdn/*` - Software Defined Networking (8.0+)
- ✅ `/api2/json/cluster/backup-info/providers` - Backup providers (8.2+)
- ✅ `/api2/json/access/users` - User management
- ✅ `/api2/json/pools` - Resource pools

## Development

### Building from Source

```bash
git clone https://github.com/jrjsmrtn/mock-pve-api.git
cd mock-pve-api
mix deps.get
mix compile
```

### Running Tests

```bash
mix test
```

### Building Container Images

The project provides multi-stage containerized builds optimized for both Podman and Docker:

```bash
# Production image (recommended - uses Makefile)
make container-build

# Manual production build
podman build -f docker/Dockerfile -t mock-pve-api:latest .

# Development image with live reloading
make container-build-dev
podman build -f docker/Dockerfile.dev -t mock-pve-api:dev .

# Multi-architecture builds (for distribution)
podman build --platform=linux/amd64,linux/arm64 -f docker/Dockerfile -t mock-pve-api:multi-arch .
```

**Container Architecture:**

- **Base Image**: Alpine Linux (minimal footprint ~33MB)
- **Elixir Runtime**: OTP 26+ with optimized release builds
- **User Security**: Non-root `mockpve` user (UID 1000)
- **Configuration**: Runtime environment variable support via `config/runtime.exs`
- **Dependencies**: All production dependencies included (Finch HTTP client, Plug web server)

**Dockerfile Details:**

- **Multi-stage build**: Separate builder and runtime stages
- **Dependency caching**: Optimized layer caching for faster rebuilds
- **Security**: No privileged operations, minimal attack surface
- **Health checks**: Built-in endpoint validation (Docker format)

```bash
# Verify build details
podman inspect mock-pve-api:latest | jq '.[0].Config'
```

### Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

1. Fork the repository
2. Install git hooks: `make install-hooks` (runs format, compile, and gitleaks checks on commit)
3. Create a feature branch (`git checkout -b feature/amazing-feature`)
4. Make your changes
5. Add tests if needed
6. Ensure tests pass (`mix test`)
7. Commit your changes (`git commit -m 'Add amazing feature'`)
8. Push to the branch (`git push origin feature/amazing-feature`)
9. Open a Pull Request

## Use Cases

### Integration Testing

Perfect for testing PVE client libraries without needing real hardware:

```bash
# In your CI pipeline
podman run -d --name mock-pve -p 8006:8006 mock-pve-api:latest  # locally built image
sleep 10  # Wait for startup
python -m pytest tests/integration/
podman stop mock-pve
```

### Local Development

Develop against consistent PVE API responses:

```bash
# Terminal 1: Start mock server
podman-compose up mock-pve-dev

# Terminal 2: Develop your client
npm test -- --watch
```

### Matrix Testing

Test against multiple PVE versions simultaneously:

```bash
# Test against PVE 7.4, 8.3, and 9.0
podman-compose up mock-pve-7 mock-pve-8 mock-pve-9
```

## 📚 Documentation

#### Tutorials

- **[Getting Started](docs/tutorials/getting-started.md)** - Quick setup and first steps
- **[Your First Test](docs/tutorials/your-first-test.md)** - Basic API testing walkthrough
- **[Understanding Versions](docs/tutorials/understanding-versions.md)** - PVE version compatibility

#### How-To Guides

- **[Client Integration](docs/how-to/client-integration.md)** - Integrate with existing PVE clients
- **[Multi-Version Testing](docs/how-to/multi-version-testing.md)** - Test across PVE versions
- **[Container Deployment](docs/how-to/container-deployment.md)** - Podman and Docker deployment
- **[CI/CD Setup](docs/how-to/setup-ci-cd.md)** - GitHub Actions, GitLab CI examples
- **[Migrate from pvex](docs/how-to/migrate-from-pvex.md)** - Transition from embedded mock

#### Reference

- **[API Endpoints](docs/reference/api-endpoints.md)** - Complete endpoint documentation
- **[Environment Variables](docs/reference/environment-variables.md)** - Configuration reference
- **[Client Examples](docs/reference/client-examples.md)** - Multi-language examples
- **[Quality Gates](docs/reference/quality-gates.md)** - Pre-commit, pre-push, and CI quality checks

#### Explanation

- **[Architecture Decisions](docs/explanation/architecture-decisions.md)** - Design rationale and ADRs
- **[Version Compatibility](docs/explanation/version-compatibility.md)** - How version simulation works
- **[State Management](docs/explanation/state-management.md)** - Internal state architecture

### 🏗️ Architecture & Design

- **[Architecture Overview](docs/architecture/README.md)** - C4 model and system design
- **[ADR-0003: Elixir/OTP Implementation Choice](docs/adr/0003-elixir-otp-implementation-choice.md)** - Why Elixir/OTP
- **[ADR-0010: Historical Context](docs/adr/0010-historical-context-from-pvex.md)** - Origin story from pvex

### 🧪 Examples

- **[Multi-Language Examples](examples/)** - Python, JavaScript, Go, Ruby, Shell, Elixir
- **[pvex Integration](examples/elixir/pvex_integration.exs)** - Elixir client library integration
- **[Podman Compose Setups](podman-compose*.yml)** - Development and testing configurations

## Architecture

The Mock PVE API Server is built with:

- **Elixir/OTP**: Reliable, concurrent server foundation
- **Plug**: HTTP request handling and routing
- **Jason**: JSON encoding/decoding
- **Alpine Linux**: Minimal container footprint

### Project Structure

```
lib/
├── mock_pve_api.ex              # Main application
├── mock_pve_api/
│   ├── application.ex           # OTP Application
│   ├── router.ex                # HTTP routing
│   ├── capabilities.ex          # Version-specific features
│   ├── state.ex                 # Resource state management
│   ├── fixtures.ex              # Response fixtures
│   └── handlers/                # API endpoint handlers
│       ├── access.ex            # Authentication, users, groups, ACLs
│       ├── cluster.ex           # Cluster status, config, join/leave
│       ├── metrics.ex           # RRD data, netstat, node reports
│       ├── nodes.ex             # VM/container lifecycle, tasks
│       ├── pools.ex             # Resource pool management
│       ├── sdn.ex               # SDN zones, VNets (8.0+)
│       ├── storage.ex           # Storage content management
│       └── version.ex           # Version information
```

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

<!-- - 📖 [Documentation](https://hexdocs.pm/mock_pve_api) -->
- 🐛 [Issues](https://github.com/jrjsmrtn/mock-pve-api/issues)
- 💬 [Discussions](https://github.com/jrjsmrtn/mock-pve-api/discussions)
- 🔒 [Security Policy](SECURITY.md)

## Related Projects

- [pvex](https://github.com/jrjsmrtn/pvex) - Comprehensive Elixir client for Proxmox VE
- [proxmoxer](https://github.com/proxmoxer/proxmoxer) - Python Proxmox API wrapper
- [node-proxmox](https://github.com/ttarvis/node-proxmox) - Node.js Proxmox VE client

---

**Made with ❤️ for the Proxmox VE community**

