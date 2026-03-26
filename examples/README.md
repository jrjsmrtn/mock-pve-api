# Client Examples

This directory contains example scripts demonstrating how to use the Mock PVE API Server.

## Available Examples

| Language | Directory | Description | Auth |
|----------|-----------|-------------|------|
| **Shell** | [`shell/test-endpoints.sh`](shell/test-endpoints.sh) | Bash script using curl — no extra dependencies | API Token header |
| **Python** | [`proxmoxer/test_proxmoxer.py`](proxmoxer/test_proxmoxer.py) | [proxmoxer](https://github.com/proxmoxer/proxmoxer) integration test | Ticket + API Token |

## Quick Start

### Shell (HTTP)

```bash
# Start mock server
mix run --no-halt

# Run the example
./examples/shell/test-endpoints.sh
```

### Proxmoxer (HTTPS required)

```bash
# Install proxmoxer
pip install proxmoxer requests

# Start mock server with SSL (proxmoxer uses HTTPS)
MOCK_PVE_SSL_ENABLED=true \
  MOCK_PVE_SSL_KEYFILE=certs/server.key \
  MOCK_PVE_SSL_CERTFILE=certs/server.crt \
  mix run --no-halt

# Run the test
python3 examples/proxmoxer/test_proxmoxer.py
```

## Configuration

Both scripts support environment variables:
- `PVE_HOST` (default: `localhost`)
- `PVE_PORT` (default: `8006`)

## Documentation

For detailed information, see:
- **[Client Examples Reference](../docs/reference/client-examples.md)**

---

*All examples are tested against the Mock PVE API Server to ensure accuracy.*
