# Environment Variables Reference

Complete reference for all environment variables supported by the Mock PVE API Server.

## Core Configuration

### `MOCK_PVE_VERSION`
**Default**: `8.3`  
**Type**: String  
**Valid Values**: `7.0`, `7.1`, `7.2`, `7.3`, `7.4`, `8.0`, `8.1`, `8.2`, `8.3`, `9.0`

Sets the Proxmox VE version to simulate. This affects available API endpoints, response formats, and feature availability.

**Example:**
```bash
# Simulate PVE 8.0
MOCK_PVE_VERSION=8.0

# Simulate PVE 7.4 (legacy)
MOCK_PVE_VERSION=7.4

# Simulate PVE 9.0 (latest features)
MOCK_PVE_VERSION=9.0
```

### `MOCK_PVE_PORT`
**Default**: `8006`  
**Type**: Integer  
**Valid Range**: `1024-65535`

TCP port for the HTTP server to bind to.

**Example:**
```bash
# Use alternative port
MOCK_PVE_PORT=9006

# Use development port
MOCK_PVE_PORT=8007
```

### `MOCK_PVE_HOST`
**Default**: `0.0.0.0`  
**Type**: String  
**Valid Values**: Any valid IP address or hostname

Network interface to bind the server to. Use `127.0.0.1` for localhost-only access.

**Example:**
```bash
# Bind to all interfaces (container default)
MOCK_PVE_HOST=0.0.0.0

# Bind to localhost only
MOCK_PVE_HOST=127.0.0.1

# Bind to specific interface
MOCK_PVE_HOST=192.168.1.100
```

---

## Logging Configuration

### `MOCK_PVE_LOG_LEVEL`
**Default**: `info`  
**Type**: String  
**Valid Values**: `debug`, `info`, `warn`, `error`

Controls the verbosity of log output.

**Example:**
```bash
# Debug mode (verbose)
MOCK_PVE_LOG_LEVEL=debug

# Production mode (minimal)
MOCK_PVE_LOG_LEVEL=error
```

**Log Level Details:**
- **`debug`**: All requests, responses, and internal state changes
- **`info`**: HTTP requests and significant operations
- **`warn`**: Deprecated features and non-critical issues
- **`error`**: Only errors and failures

---

## Feature Toggle Variables

### `MOCK_PVE_ENABLE_SDN`
**Default**: `true`  
**Type**: Boolean  
**Valid Values**: `true`, `false`, `1`, `0`

Enable or disable Software Defined Networking endpoints (PVE 8.0+ only).

**Example:**
```bash
# Enable SDN features (default for PVE 8.0+)
MOCK_PVE_ENABLE_SDN=true

# Disable SDN features
MOCK_PVE_ENABLE_SDN=false
```

**Affects Endpoints:**
- `/api2/json/cluster/sdn/zones`
- `/api2/json/cluster/sdn/vnets`
- `/api2/json/cluster/sdn/subnets`

### `MOCK_PVE_ENABLE_FIREWALL`
**Default**: `true`  
**Type**: Boolean  
**Valid Values**: `true`, `false`, `1`, `0`

Enable or disable firewall-related endpoints.

**Example:**
```bash
# Enable firewall endpoints (default)
MOCK_PVE_ENABLE_FIREWALL=true

# Disable firewall endpoints
MOCK_PVE_ENABLE_FIREWALL=false
```

### `MOCK_PVE_ENABLE_BACKUP_PROVIDERS`
**Default**: `true`  
**Type**: Boolean  
**Valid Values**: `true`, `false`, `1`, `0`

Enable or disable backup provider endpoints (PVE 8.2+ only).

**Example:**
```bash
# Enable backup providers (default for PVE 8.2+)
MOCK_PVE_ENABLE_BACKUP_PROVIDERS=true

# Disable backup providers
MOCK_PVE_ENABLE_BACKUP_PROVIDERS=false
```

**Affects Endpoints:**
- `/api2/json/cluster/backup-info/providers`

---

## Simulation Configuration

### `MOCK_PVE_DELAY`
**Default**: `0`  
**Type**: Integer  
**Valid Range**: `0-5000` (milliseconds)

Add artificial delay to all API responses to simulate network latency or slow systems.

**Example:**
```bash
# No delay (default)
MOCK_PVE_DELAY=0

# Add 100ms delay
MOCK_PVE_DELAY=100

# Simulate slow network (1 second)
MOCK_PVE_DELAY=1000
```

### `MOCK_PVE_JITTER`
**Default**: `0`  
**Type**: Integer  
**Valid Range**: `0-1000` (milliseconds)

Add random jitter to response delays (±N milliseconds).

**Example:**
```bash
# No jitter (default)
MOCK_PVE_JITTER=0

# Add ±50ms random jitter
MOCK_PVE_JITTER=50

# Add ±200ms random jitter
MOCK_PVE_JITTER=200
```

### `MOCK_PVE_ERROR_RATE`
**Default**: `0`  
**Type**: Integer  
**Valid Range**: `0-100` (percentage)

Randomly return HTTP 500 errors for a percentage of requests.

**Example:**
```bash
# No artificial errors (default)
MOCK_PVE_ERROR_RATE=0

# Fail 5% of requests
MOCK_PVE_ERROR_RATE=5

# Fail 10% of requests (chaos testing)
MOCK_PVE_ERROR_RATE=10
```

---

## Development Configuration

### `MIX_ENV`
**Default**: `prod`  
**Type**: String  
**Valid Values**: `prod`, `dev`, `test`

Elixir application environment. Affects logging, compilation, and debugging features.

**Example:**
```bash
# Production mode (default in container)
MIX_ENV=prod

# Development mode (more verbose logging)
MIX_ENV=dev

# Test mode
MIX_ENV=test
```

**Environment Effects:**
- **`prod`**: Minimal logging, optimized performance
- **`dev`**: Debug logging, code reloading (not available in container)
- **`test`**: Test-specific configuration and fixtures

---

## Advanced Configuration

### `MOCK_PVE_MAX_RESOURCES`
**Default**: `1000`  
**Type**: Integer  
**Valid Range**: `10-10000`

Maximum number of simulated resources (VMs, containers, pools) to prevent memory exhaustion.

**Example:**
```bash
# Default limit
MOCK_PVE_MAX_RESOURCES=1000

# Lower limit for testing
MOCK_PVE_MAX_RESOURCES=100

# Higher limit for load testing
MOCK_PVE_MAX_RESOURCES=5000
```

### `MOCK_PVE_INIT_STATE`
**Default**: `default`  
**Type**: String  
**Valid Values**: `default`, `empty`, `large`

Initial resource state when server starts.

**Example:**
```bash
# Standard test resources (default)
MOCK_PVE_INIT_STATE=default

# Start with no resources
MOCK_PVE_INIT_STATE=empty

# Start with many resources for testing
MOCK_PVE_INIT_STATE=large
```

**State Details:**
- **`default`**: 1 VM, 1 container, 2 storage pools
- **`empty`**: No resources, clean state
- **`large`**: 10 VMs, 5 containers, 4 storage pools

---

## Container-Specific Variables

### `PODMAN_CONTAINER_NAME`
**Type**: String  
**Set by**: Podman runtime

Container name when running in Podman (read-only).

### `DOCKER_CONTAINER_ID`
**Type**: String  
**Set by**: Docker runtime  

Container ID when running in Docker (read-only).

---

## Boolean Value Parsing

All boolean environment variables accept these values:

**True Values**: `true`, `TRUE`, `1`, `yes`, `YES`, `on`, `ON`  
**False Values**: `false`, `FALSE`, `0`, `no`, `NO`, `off`, `OFF`

**Example:**
```bash
# All equivalent to enabling SDN
MOCK_PVE_ENABLE_SDN=true
MOCK_PVE_ENABLE_SDN=1
MOCK_PVE_ENABLE_SDN=yes
MOCK_PVE_ENABLE_SDN=on
```

---

## Configuration Examples

### Development Environment
```bash
# Development with debug logging
export MIX_ENV=dev
export MOCK_PVE_LOG_LEVEL=debug
export MOCK_PVE_VERSION=8.3
export MOCK_PVE_PORT=8006
```

### CI/CD Environment
```bash
# Stable configuration for testing
export MOCK_PVE_VERSION=8.3
export MOCK_PVE_LOG_LEVEL=warn
export MOCK_PVE_INIT_STATE=default
export MOCK_PVE_DELAY=0
```

### Load Testing Environment
```bash
# Configuration for load testing
export MOCK_PVE_MAX_RESOURCES=5000
export MOCK_PVE_INIT_STATE=large
export MOCK_PVE_LOG_LEVEL=error
export MOCK_PVE_DELAY=10
export MOCK_PVE_JITTER=5
```

### Chaos Testing Environment
```bash
# Unstable environment for resilience testing
export MOCK_PVE_ERROR_RATE=15
export MOCK_PVE_DELAY=200
export MOCK_PVE_JITTER=100
export MOCK_PVE_LOG_LEVEL=info
```

### Legacy PVE Testing
```bash
# Test against old PVE version
export MOCK_PVE_VERSION=7.4
export MOCK_PVE_ENABLE_SDN=false
export MOCK_PVE_ENABLE_BACKUP_PROVIDERS=false
export MOCK_PVE_LOG_LEVEL=info
```

---

## Container Usage

### Podman
```bash
podman run -d --name mock-pve-api \
  -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  -e MOCK_PVE_DELAY=50 \
  ghcr.io/jrjsmrtn/mock-pve-api:latest
```

### Docker Compose
```yaml
version: '3.8'
services:
  mock-pve-api:
    image: ghcr.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "8006:8006"
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_LOG_LEVEL=info
      - MOCK_PVE_ENABLE_SDN=true
      - MOCK_PVE_DELAY=25
      - MOCK_PVE_JITTER=10
```

---

## Validation

Environment variables are validated at startup:

**Invalid Version:**
```
❌ Error: Invalid MOCK_PVE_VERSION: '8.5'
   Valid versions: 7.0, 7.1, 7.2, 7.3, 7.4, 8.0, 8.1, 8.2, 8.3, 9.0
```

**Invalid Port:**
```
❌ Error: Invalid MOCK_PVE_PORT: '99999'
   Port must be between 1024 and 65535
```

**Invalid Boolean:**
```
❌ Error: Invalid MOCK_PVE_ENABLE_SDN: 'maybe'
   Must be true/false, yes/no, 1/0, or on/off
```

---

*Environment variables are processed at runtime and can be changed between container restarts. Changes take effect immediately when the container is restarted.*