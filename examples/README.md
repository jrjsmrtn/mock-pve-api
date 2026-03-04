# Client Examples

This directory contains a shell/curl example demonstrating how to use the Mock PVE API Server.

## Available Examples

| Language | File | Description |
|----------|------|-------------|
| **Shell** | [`shell/test-endpoints.sh`](shell/test-endpoints.sh) | Bash script using curl — no extra dependencies |

## Quick Start

1. **Start the mock server:**
   ```bash
   podman run -d --name mock-pve -p 8006:8006 mock-pve-api:latest
   ```

2. **Run the example:**
   ```bash
   ./examples/shell/test-endpoints.sh
   ```

## Configuration

The script supports environment variables:
- `PVE_HOST` (default: `localhost`)
- `PVE_PORT` (default: `8006`)
- `TIMEOUT` (default: `10`)

## Documentation

For detailed information about using the mock server, see:
- **[Client Examples Reference](../docs/reference/client-examples.md)**

---

*The example is tested against the Mock PVE API Server to ensure accuracy.*
