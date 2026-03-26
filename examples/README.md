# Client Examples

This directory contains example scripts demonstrating how to use the Mock PVE API Server.

## Available Examples

| Language | Directory | Description | Auth |
|----------|-----------|-------------|------|
| **Shell** | [`shell/test-endpoints.sh`](shell/test-endpoints.sh) | Bash script using curl — no extra dependencies | API Token header |
| **Python** | [`proxmoxer/test_proxmoxer.py`](proxmoxer/test_proxmoxer.py) | [proxmoxer](https://github.com/proxmoxer/proxmoxer) integration test | Ticket + API Token |

## Quick Start

```bash
# Start mock server (HTTPS by default, like real PVE)
mix run --no-halt

# Run the shell example
./examples/shell/test-endpoints.sh

# Run the proxmoxer test (requires: pip install proxmoxer requests)
python3 examples/proxmoxer/test_proxmoxer.py
```

Self-signed TLS certificates are auto-generated on first startup if none exist.

To use HTTP instead: `MOCK_PVE_SSL_ENABLED=false mix run --no-halt`

## Configuration

Both scripts support environment variables:
- `PVE_HOST` (default: `localhost`)
- `PVE_PORT` (default: `8006`)

## Documentation

For detailed information, see:
- **[Client Examples Reference](../docs/reference/client-examples.md)**

---

*All examples are tested against the Mock PVE API Server to ensure accuracy.*
