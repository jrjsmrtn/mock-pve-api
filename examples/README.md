# Client Examples

This directory contains client example implementations in various programming languages that demonstrate how to use the Mock PVE API Server.

## Available Languages

| Language | File | Description |
|----------|------|-------------|
| **Python** | [`python/test_client.py`](python/test_client.py) | Complete Python client with requests library |
| **JavaScript** | [`javascript/test-client.js`](javascript/test-client.js) | Node.js client using axios |
| **Elixir** | [`elixir/test_client.exs`](elixir/test_client.exs) | Native Elixir HTTP client |
| **Go** | [`go/test-client.go`](go/test-client.go) | Go client with strong typing |
| **Ruby** | [`ruby/test_client.rb`](ruby/test_client.rb) | Ruby client using HTTParty |
| **Shell** | [`shell/test-endpoints.sh`](shell/test-endpoints.sh) | Bash script using curl |

## Quick Start

1. **Start the mock server:**
   ```bash
   podman run -d --name mock-pve -p 8006:8006 mock-pve-api:latest
   ```

2. **Run any example:**
   ```bash
   # Python
   pip install requests
   python examples/python/test_client.py
   
   # JavaScript  
   npm install axios
   node examples/javascript/test-client.js
   
   # Go
   go run examples/go/test-client.go
   
   # Shell
   ./examples/shell/test-endpoints.sh
   ```

## Configuration

All examples support environment variables:
- `PVE_HOST` (default: `localhost`)
- `PVE_PORT` (default: `8006`)

## Documentation

For detailed information about the examples including features, usage patterns, and CI/CD integration, see:
- **[Client Examples Reference](../docs/reference/client-examples.md)**

---

*Examples are tested against the Mock PVE API Server to ensure accuracy.*