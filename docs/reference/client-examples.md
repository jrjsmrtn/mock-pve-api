# Client Examples Reference

This reference documents all available client examples for testing the Mock PVE API Server.

## Available Examples

### Shell Script (`shell/test-endpoints.sh`)
Bash script using curl and jq for API testing.

**Features:**
- Works with standard shell tools (curl required, jq optional)
- Comprehensive endpoint coverage
- Version-specific feature detection
- CI/CD friendly output

**Dependencies:**
- curl (standard on most systems)
- jq (optional, for JSON parsing)

**Usage:**
```bash
chmod +x examples/shell/test-endpoints.sh
./examples/shell/test-endpoints.sh
```

---

### Proxmoxer Integration (`proxmoxer/test_proxmoxer.py`)
Python integration test using the [proxmoxer](https://github.com/proxmoxer/proxmoxer) library — the most popular Python client for Proxmox VE.

**Features:**
- Ticket-based and API token authentication
- Full VM lifecycle (list, create, get config, delete)
- Cluster, node, storage, pool, and access operations
- Version-specific feature testing (SDN, backup providers, HA affinity, notifications)
- Firewall endpoint validation
- Structured pass/fail/skip output

**Dependencies:**
```bash
pip install proxmoxer requests
```

**Usage:**
```bash
# Requires SSL-enabled mock server (proxmoxer uses HTTPS):
MOCK_PVE_SSL_ENABLED=true \
  MOCK_PVE_SSL_KEYFILE=certs/server.key \
  MOCK_PVE_SSL_CERTFILE=certs/server.crt \
  mix run --no-halt

# Run the test
python3 examples/proxmoxer/test_proxmoxer.py
```

## Client Library Compatibility

| Library | Language | Auth | Status | Notes |
|---------|----------|------|--------|-------|
| **proxmoxer** 2.3.0 | Python | Ticket, API Token | 37/38 pass | Requires HTTPS (self-signed OK with `verify_ssl=False`) |
| **curl** | Shell | API Token header | Full pass | HTTP or HTTPS |

## Configuration

All examples support environment variable configuration:

| Variable | Default | Description |
|----------|---------|-------------|
| `PVE_HOST` | `localhost` | Mock server hostname |
| `PVE_PORT` | `8006` | Mock server port |

**Example:**
```bash
export PVE_HOST=localhost
export PVE_PORT=8006
python3 examples/proxmoxer/test_proxmoxer.py
```

## Testing Examples

### Automated Testing
```bash
# Test all examples against running mock server
make test-examples
```

### Manual Testing
```bash
# Start mock server with SSL
MOCK_PVE_SSL_ENABLED=true \
  MOCK_PVE_SSL_KEYFILE=certs/server.key \
  MOCK_PVE_SSL_CERTFILE=certs/server.crt \
  mix run --no-halt

# Test proxmoxer
python3 examples/proxmoxer/test_proxmoxer.py

# Test shell/curl
./examples/shell/test-endpoints.sh
```

## CI/CD Integration

### GitHub Actions
```yaml
name: Test PVE Client
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      mock-pve:
        image: ghcr.io/jrjsmrtn/mock-pve-api:latest
        ports: ["8006:8006"]
        env:
          MOCK_PVE_VERSION: "8.3"

    steps:
      - uses: actions/checkout@v4

      - name: Test Shell client
        run: ./examples/shell/test-endpoints.sh

      - name: Test proxmoxer client
        run: |
          pip install proxmoxer requests
          python3 examples/proxmoxer/test_proxmoxer.py
```

---

*These examples are tested against the Mock PVE API Server to ensure accuracy.*
