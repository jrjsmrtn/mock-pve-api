# Mock PVE API

[![GHCR](https://img.shields.io/badge/GHCR-ghcr.io%2Fjrjsmrtn%2Fmock--pve--api-blue)](https://github.com/jrjsmrtn/mock-pve-api/pkgs/container/mock-pve-api)
[![Podman Compatible](https://img.shields.io/badge/podman-compatible-326ce5.svg)](https://podman.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/jrjsmrtn/mock-pve-api/workflows/CI/badge.svg)](https://github.com/jrjsmrtn/mock-pve-api/actions)

A lightweight, containerized Mock Proxmox VE API Server for testing and development. Simulates the PVE REST API across versions 7.0-9.0 with HTTPS, stateful resources, and 220 endpoints — no Proxmox infrastructure required.

## Features

- **220 API endpoints** with version-specific behaviour (PVE 7.0 through 9.0)
- **HTTPS by default** matching real PVE API — self-signed certs auto-generated on first startup
- **Stateful resource management** — VM, container, storage, pool, and firewall lifecycle
- **Validated against proxmoxer** — the most popular Python PVE client (37/38 pass)
- **Container-ready** — multi-arch images (amd64/arm64) on GHCR, signed with cosign
- **CI/CD friendly** — zero external dependencies, configurable via environment variables
- **Simulation features** — response delay, error injection, feature toggles

## Quick Start

### Container (recommended)

```bash
# Pull from GHCR
podman pull ghcr.io/jrjsmrtn/mock-pve-api:latest

# Run (HTTPS with auto-generated self-signed certs)
podman run -d -p 8006:8006 -e MOCK_PVE_VERSION=8.3 ghcr.io/jrjsmrtn/mock-pve-api:latest

# Test (-k for self-signed certs)
curl -k https://localhost:8006/api2/json/version
```

Also works with Docker — replace `podman` with `docker`.

### From source

```bash
git clone https://github.com/jrjsmrtn/mock-pve-api.git
cd mock-pve-api
mix deps.get
mix run --no-halt

curl -k https://localhost:8006/api2/json/version
```

### Makefile targets

```bash
make container-build       # Build production image locally
make container-run         # Run from GHCR
make container-run-versions  # Run PVE 7.4, 8.0, 8.3, 9.0 simultaneously
```

## Usage Examples

### curl

```bash
# Version info (no auth required)
curl -k https://localhost:8006/api2/json/version

# Authenticate
curl -k -X POST https://localhost:8006/api2/json/access/ticket \
  -d "username=root@pam&password=secret"

# List nodes (with API token)
curl -k -H "Authorization: PVEAPIToken=root@pam!test=secret" \
  https://localhost:8006/api2/json/nodes
```

### proxmoxer (Python)

```python
from proxmoxer import ProxmoxAPI

pve = ProxmoxAPI("localhost", port=8006, user="root@pam",
                 password="secret", verify_ssl=False)

print(pve.version.get())
print(pve.nodes.get())
print(pve.nodes("pve-node1").qemu.get())
```

### GitHub Actions

```yaml
services:
  mock-pve:
    image: ghcr.io/jrjsmrtn/mock-pve-api:latest
    ports: ["8006:8006"]
    env:
      MOCK_PVE_VERSION: "8.3"
    options: >-
      --health-cmd "curl -fk https://localhost:8006/api2/json/version || exit 1"
      --health-interval 10s
      --health-timeout 5s
      --health-retries 5
      --health-start-period 10s
```

### Multi-version testing

```bash
podman run -d -p 8074:8006 -e MOCK_PVE_VERSION=7.4 ghcr.io/jrjsmrtn/mock-pve-api:latest
podman run -d -p 8083:8006 -e MOCK_PVE_VERSION=8.3 ghcr.io/jrjsmrtn/mock-pve-api:latest
podman run -d -p 8090:8006 -e MOCK_PVE_VERSION=9.0 ghcr.io/jrjsmrtn/mock-pve-api:latest

curl -k https://localhost:8074/api2/json/version  # PVE 7.4
curl -k https://localhost:8083/api2/json/version  # PVE 8.3
curl -k https://localhost:8090/api2/json/version  # PVE 9.0
```

## Configuration

| Variable | Default | Description |
|----------|---------|-------------|
| `MOCK_PVE_VERSION` | `8.3` | PVE version to simulate (7.0-9.0) |
| `MOCK_PVE_PORT` | `8006` | Server port |
| `MOCK_PVE_HOST` | `0.0.0.0` | Bind address |
| `MOCK_PVE_SSL_ENABLED` | `true` | HTTPS enabled; set `false` for HTTP |
| `MOCK_PVE_SSL_KEYFILE` | `certs/server.key` | SSL private key (auto-generated if missing) |
| `MOCK_PVE_SSL_CERTFILE` | `certs/server.crt` | SSL certificate (auto-generated if missing) |
| `MOCK_PVE_DELAY` | `0` | Response delay in milliseconds |
| `MOCK_PVE_ERROR_RATE` | `0` | Simulate error percentage (0-100) |
| `MOCK_PVE_ENABLE_SDN` | `true` | Enable SDN endpoints (8.0+) |
| `MOCK_PVE_ENABLE_FIREWALL` | `true` | Enable firewall endpoints |
| `MOCK_PVE_ENABLE_BACKUP_PROVIDERS` | `true` | Enable backup provider endpoints (8.2+) |
| `MOCK_PVE_LOG_LEVEL` | `info` | Logging level (debug/info/warn/error) |

## Supported PVE Versions

| Version | Key Features |
|---------|-------------|
| **7.0-7.4** | Core virtualisation, containers, storage, Ceph |
| **8.0** | + SDN (tech preview), realm sync, resource mappings |
| **8.1** | + Notifications, webhooks, filters |
| **8.2** | + Backup providers, VMware import |
| **8.3** | + OVA import improvements |
| **9.0** | + SDN fabrics, HA affinity rules, LVM snapshots |

## API Coverage

220 endpoints across all categories:

- **Access** — users, groups, roles, domains, ACL, tickets, tokens
- **Cluster** — status, config, resources, HA, backup jobs, replication, options
- **Nodes** — listing, DNS, APT, network, disks, tasks, hardware, time
- **VMs (QEMU)** — full lifecycle, config, snapshots, cloning, migration, agent
- **Containers (LXC)** — full lifecycle, config, snapshots, cloning
- **Storage** — cluster and node level, content, volumes, upload
- **SDN** — zones, vnets, subnets, controllers (8.0+)
- **Firewall** — cluster, node, VM/CT level rules, aliases, ipsets, groups
- **Notifications** — endpoints, matchers, targets (8.1+)
- **Metrics** — RRD data for nodes, VMs, containers, storage

## Development

```bash
mix deps.get          # Install dependencies
mix test              # Run 1080 tests
mix format            # Format code
make install-hooks    # Install lefthook git hooks
make validate         # Full quality pipeline
```

### Client examples

```bash
# Shell/curl example
./examples/shell/test-endpoints.sh

# proxmoxer integration test (pip install proxmoxer requests)
python3 examples/proxmoxer/test_proxmoxer.py
```

### Container images

- **Registry**: `ghcr.io/jrjsmrtn/mock-pve-api`
- **Base**: Alpine 3.22 (~41 MB)
- **Architectures**: `linux/amd64`, `linux/arm64`
- **Security**: Non-root user, cosign-signed, SBOM/provenance attestations

## Documentation

**Tutorials**: [Getting Started](docs/tutorials/getting-started.md) | [Your First Test](docs/tutorials/your-first-test.md) | [Understanding Versions](docs/tutorials/understanding-versions.md)

**How-To**: [Client Integration](docs/how-to/client-integration.md) | [Multi-Version Testing](docs/how-to/multi-version-testing.md) | [Container Deployment](docs/how-to/container-deployment.md) | [CI/CD Setup](docs/how-to/setup-ci-cd.md)

**Reference**: [API Reference](docs/reference/api-reference.md) | [Environment Variables](docs/reference/environment-variables.md) | [Client Examples](docs/reference/client-examples.md) | [Quality Gates](docs/reference/quality-gates.md)

**Explanation**: [Architecture Decisions](docs/explanation/architecture-decisions.md) | [Version Compatibility](docs/explanation/version-compatibility.md) | [State Management](docs/explanation/state-management.md)

**Architecture**: [C4 Model](docs/architecture/README.md) | [ADRs](docs/adr/)

## License

MIT - see [LICENSE](LICENSE).

## Support

- [Issues](https://github.com/jrjsmrtn/mock-pve-api/issues)
- [Discussions](https://github.com/jrjsmrtn/mock-pve-api/discussions)
- [Security Policy](SECURITY.md)

## Related Projects

- [pvex](https://github.com/jrjsmrtn/pvex) - Elixir client for Proxmox VE
- [proxmoxer](https://github.com/proxmoxer/proxmoxer) - Python Proxmox API wrapper
