# ADR-0008: Environment Variable Configuration Strategy

**Date:** 2025-01-30  
**Status:** Accepted  
**Deciders:** Development Team

## Context and Problem Statement

Mock PVE API Server needs flexible configuration to simulate different PVE versions, enable/disable features, and adjust behavior for various testing scenarios. Configuration must work seamlessly in containers, CI/CD pipelines, and local development. The configuration approach affects ease of use, maintainability, and deployment flexibility. How should we implement configuration management for the mock server?

## Decision Drivers

* **Container-Native**: Configuration via environment variables for Podman/Docker/K8s
* **CI/CD Friendly**: Easy configuration in CI pipeline YAML files
* **Zero Config Files**: No need to manage config files in containers
* **Runtime Flexibility**: Change behavior without rebuilding images
* **Validation**: Prevent invalid configurations that break simulation
* **Documentation**: Self-documenting configuration options
* **Backward Compatibility**: Configuration changes don't break existing usage

## Considered Options

* **Option 1**: Environment variables with sensible defaults
* **Option 2**: Configuration files (YAML/JSON) with optional env override
* **Option 3**: Command-line arguments with env fallback
* **Option 4**: Runtime API for configuration changes
* **Option 5**: Hybrid approach (multiple configuration sources)

## Decision Outcome

Chosen option: "**Option 1: Environment variables with sensible defaults**", because environment variables are the most container-native, CI/CD-friendly configuration approach that requires no additional files or complex setup.

### Positive Consequences

* **Container-Native**: Perfect fit for Docker and Kubernetes deployments
* **CI/CD Integration**: Natural integration with pipeline environment variables
* **Zero Files**: No configuration files to manage or mount in containers
* **Runtime Flexibility**: Change configuration without rebuilding images
* **Process Isolation**: Each container instance can have different configuration
* **Docker Compose Friendly**: Easy configuration in docker-compose.yml
* **Cloud-Native**: Works perfectly with cloud container services
* **Debugging**: Easy to inspect configuration via environment

### Negative Consequences

* **Limited Nesting**: Environment variables are flat, no deep object structures
* **Type Coercion**: All values are strings, need parsing for booleans/integers
* **Visibility**: Environment variables may be visible in process lists
* **Validation Complexity**: Need custom validation for complex configurations

## Pros and Cons of the Options

### Option 1: Environment Variables

* Good, because universal support across all deployment platforms
* Good, because no file management or mounting required
* Good, because natural fit for containerized applications
* Good, because easy CI/CD pipeline integration
* Good, because runtime configuration without rebuilds
* Bad, because limited data structure support
* Bad, because potential security concerns with sensitive data

### Option 2: Configuration Files

* Good, because supports complex nested configuration structures
* Good, because version control and documentation friendly
* Good, because validation through schemas
* Bad, because requires file mounting in containers
* Bad, because static configuration, requires restarts for changes
* Bad, because additional complexity in CI/CD pipelines

### Option 3: Command-line Arguments

* Good, because explicit and self-documenting
* Good, because type safety through argument parsing
* Bad, because complex in container environments
* Bad, because limited CI/CD integration
* Bad, because podman run commands become unwieldy

### Option 4: Runtime API Configuration

* Good, because dynamic configuration changes
* Good, because complex data structures supported
* Bad, because adds API complexity and security concerns
* Bad, because requires additional endpoints and documentation
* Bad, because stateful configuration management

### Option 5: Hybrid Approach

* Good, because maximum flexibility for different use cases
* Good, because can optimize for different deployment scenarios
* Bad, because increased complexity and confusion
* Bad, because multiple configuration sources to maintain
* Bad, because unclear precedence and debugging

## Configuration Schema

### Core Configuration Variables
```bash
# Version Configuration
MOCK_PVE_VERSION=8.3              # PVE version to simulate (7.0-9.0)
MOCK_PVE_RELEASE=8.3-1            # PVE release string (optional)

# Server Configuration  
MOCK_PVE_PORT=8006                # HTTP server port
MOCK_PVE_HOST=0.0.0.0             # Bind address
MOCK_PVE_TIMEOUT=30000            # Request timeout (milliseconds)

# Feature Toggles
MOCK_PVE_ENABLE_SDN=true          # Enable SDN endpoints (8.0+ only)
MOCK_PVE_ENABLE_FIREWALL=true     # Enable firewall endpoints
MOCK_PVE_ENABLE_BACKUP_PROVIDERS=true # Enable backup providers (8.2+ only)
MOCK_PVE_ENABLE_NOTIFICATIONS=true     # Enable notification endpoints (8.1+ only)

# Simulation Options
MOCK_PVE_DELAY=0                  # Response delay in milliseconds
MOCK_PVE_ERROR_RATE=0             # Error injection rate (0-100)
MOCK_PVE_JITTER=0                 # Response time jitter (milliseconds)

# Logging Configuration
MOCK_PVE_LOG_LEVEL=info           # Log level (debug|info|warn|error)
MOCK_PVE_LOG_FORMAT=text          # Log format (text|json)

# Resource Limits
MOCK_PVE_MAX_VMS=1000            # Maximum simulated VMs
MOCK_PVE_MAX_CONTAINERS=1000     # Maximum simulated containers
MOCK_PVE_MAX_STORAGE=100         # Maximum storage entries

# State Configuration (Future)
MOCK_PVE_STATE_BACKEND=memory     # State backend (memory|sqlite|file)
MOCK_PVE_STATE_PERSIST=false      # Persist state across restarts
MOCK_PVE_STATE_FILE=/tmp/state.json # State persistence file
```

### Implementation Strategy
```elixir
defmodule MockPveApi.Config do
  @moduledoc """
  Configuration management using environment variables with validation and defaults.
  """
  
  @default_config %{
    version: "8.3",
    port: 8006,
    host: "0.0.0.0",
    enable_sdn: true,
    enable_firewall: true,
    enable_backup_providers: true,
    delay: 0,
    error_rate: 0,
    log_level: :info,
    max_vms: 1000
  }
  
  def get_config do
    @default_config
    |> Map.merge(load_from_env())
    |> validate_config!()
  end
  
  defp load_from_env do
    %{
      version: get_env("MOCK_PVE_VERSION", "8.3"),
      port: get_env_integer("MOCK_PVE_PORT", 8006),
      host: get_env("MOCK_PVE_HOST", "0.0.0.0"),
      enable_sdn: get_env_boolean("MOCK_PVE_ENABLE_SDN", true),
      delay: get_env_integer("MOCK_PVE_DELAY", 0),
      error_rate: get_env_integer("MOCK_PVE_ERROR_RATE", 0),
      log_level: get_env_atom("MOCK_PVE_LOG_LEVEL", :info),
      max_vms: get_env_integer("MOCK_PVE_MAX_VMS", 1000)
    }
  end
```

### Type Coercion and Validation
```elixir
defp get_env_integer(key, default) do
  case System.get_env(key) do
    nil -> default
    value -> 
      case Integer.parse(value) do
        {int, ""} -> int
        _ -> raise ArgumentError, "Invalid integer for #{key}: #{value}"
      end
  end
end

defp get_env_boolean(key, default) do
  case System.get_env(key) do
    nil -> default
    "true" -> true
    "false" -> false
    value -> raise ArgumentError, "Invalid boolean for #{key}: #{value}"
  end
end

defp validate_config!(config) do
  # Validate PVE version
  unless config.version in ["7.0", "7.1", "7.2", "7.3", "7.4", "8.0", "8.1", "8.2", "8.3", "9.0"] do
    raise ArgumentError, "Unsupported PVE version: #{config.version}"
  end
  
  # Validate port range
  unless config.port >= 1024 and config.port <= 65535 do
    raise ArgumentError, "Port must be between 1024 and 65535: #{config.port}"
  end
  
  # Validate error rate
  unless config.error_rate >= 0 and config.error_rate <= 100 do
    raise ArgumentError, "Error rate must be between 0 and 100: #{config.error_rate}"
  end
  
  config
end
```

## Usage Examples

### Docker Run
```bash
# Basic usage with defaults
podman run -p 8006:8006 jrjsmrtn/mock-pve-api:latest

# PVE 7.4 simulation
podman run -p 8006:8006 \
  -e MOCK_PVE_VERSION=7.4 \
  jrjsmrtn/mock-pve-api:latest

# Debug configuration
podman run -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.3 \
  -e MOCK_PVE_LOG_LEVEL=debug \
  -e MOCK_PVE_DELAY=100 \
  jrjsmrtn/mock-pve-api:latest

# Chaos testing
podman run -p 8006:8006 \
  -e MOCK_PVE_VERSION=8.0 \
  -e MOCK_PVE_ERROR_RATE=10 \
  -e MOCK_PVE_JITTER=50 \
  jrjsmrtn/mock-pve-api:latest
```

### Docker Compose
```yaml
version: '3.8'
services:
  mock-pve-7:
    image: jrjsmrtn/mock-pve-api:latest
    ports: ["8007:8006"]
    environment:
      - MOCK_PVE_VERSION=7.4
      - MOCK_PVE_ENABLE_SDN=false
      
  mock-pve-8:
    image: jrjsmrtn/mock-pve-api:latest
    ports: ["8008:8006"] 
    environment:
      - MOCK_PVE_VERSION=8.3
      - MOCK_PVE_ENABLE_SDN=true
      - MOCK_PVE_LOG_LEVEL=debug
      
  mock-pve-chaos:
    image: jrjsmrtn/mock-pve-api:latest
    ports: ["8009:8006"]
    environment:
      - MOCK_PVE_VERSION=8.0
      - MOCK_PVE_ERROR_RATE=15
      - MOCK_PVE_DELAY=200
      - MOCK_PVE_JITTER=100
```

### GitHub Actions
```yaml
services:
  mock-pve:
    image: jrjsmrtn/mock-pve-api:latest
    ports: ["8006:8006"]
    env:
      MOCK_PVE_VERSION: "8.3"
      MOCK_PVE_LOG_LEVEL: "debug"
    options: >-
      --health-cmd "curl -f http://localhost:8006/api2/json/version"
      --health-interval 10s
```

### Kubernetes Deployment
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mock-pve-api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: mock-pve-api
  template:
    metadata:
      labels:
        app: mock-pve-api
    spec:
      containers:
      - name: mock-pve-api
        image: jrjsmrtn/mock-pve-api:latest
        ports:
        - containerPort: 8006
        env:
        - name: MOCK_PVE_VERSION
          value: "8.3"
        - name: MOCK_PVE_LOG_LEVEL
          value: "info"
        - name: MOCK_PVE_MAX_VMS
          value: "500"
        resources:
          limits:
            memory: "128Mi"
            cpu: "500m"
```

## Configuration Categories

### Version Simulation
```bash
MOCK_PVE_VERSION=8.3              # Core PVE version
MOCK_PVE_RELEASE=8.3-1            # Specific release string
MOCK_PVE_REPOID=abcd1234          # Repository ID override
```

### Feature Control
```bash
# Enable/disable major feature sets
MOCK_PVE_ENABLE_SDN=true          # SDN endpoints (8.0+)
MOCK_PVE_ENABLE_FIREWALL=true     # Firewall management
MOCK_PVE_ENABLE_BACKUP_PROVIDERS=true # Backup providers (8.2+)
MOCK_PVE_ENABLE_NOTIFICATIONS=true    # Notification system (8.1+)
MOCK_PVE_ENABLE_HA=true               # HA management
```

### Behavior Modification
```bash
# Response timing and reliability
MOCK_PVE_DELAY=0                  # Base response delay
MOCK_PVE_JITTER=0                 # Random delay variation
MOCK_PVE_ERROR_RATE=0             # Percentage of requests that should fail
MOCK_PVE_TIMEOUT=30000            # Request timeout

# Resource simulation
MOCK_PVE_MAX_VMS=1000            # Limit simulated VMs
MOCK_PVE_MAX_CONTAINERS=1000     # Limit simulated containers
MOCK_PVE_INITIAL_VMS=10          # VMs to create on startup
```

### Development and Debugging  
```bash
# Logging configuration
MOCK_PVE_LOG_LEVEL=info          # debug|info|warn|error
MOCK_PVE_LOG_FORMAT=text         # text|json
MOCK_PVE_LOG_REQUESTS=false      # Log all HTTP requests

# Development features
MOCK_PVE_DEBUG_STATE=false       # Expose state inspection endpoints
MOCK_PVE_METRICS=false           # Enable metrics endpoints
MOCK_PVE_PROFILE=false           # Enable performance profiling
```

## Validation and Error Handling

### Configuration Validation
```elixir
defmodule MockPveApi.Config.Validator do
  @valid_versions ["7.0", "7.1", "7.2", "7.3", "7.4", "8.0", "8.1", "8.2", "8.3", "9.0"]
  @valid_log_levels [:debug, :info, :warn, :error]
  
  def validate_version!(version) do
    unless version in @valid_versions do
      raise ArgumentError, """
      Invalid PVE version: #{version}
      Supported versions: #{Enum.join(@valid_versions, ", ")}
      """
    end
    version
  end
  
  def validate_capability!(version, capability, enabled) do
    if enabled and not MockPveApi.Capabilities.supports?(version, capability) do
      raise ArgumentError, """
      Feature #{capability} cannot be enabled for PVE #{version}
      This feature requires a newer PVE version
      """
    end
    enabled
  end
end
```

### Startup Configuration Check
```elixir
def start(_type, _args) do
  config = MockPveApi.Config.get_config()
  
  Logger.info("Starting Mock PVE API Server", [
    version: config.version,
    port: config.port,
    sdn_enabled: config.enable_sdn,
    log_level: config.log_level
  ])
  
  # Validate capability combinations
  MockPveApi.Config.Validator.validate_capabilities!(config)
  
  children = [
    {MockPveApi.State, config},
    {Plug.Cowboy, scheme: :http, plug: MockPveApi.Router, options: [port: config.port]}
  ]
  
  opts = [strategy: :one_for_one, name: MockPveApi.Supervisor]
  Supervisor.start_link(children, opts)
end
```

## Documentation Integration

### Self-Documenting Configuration
```elixir
def get_config_documentation do
  %{
    "MOCK_PVE_VERSION" => %{
      description: "PVE version to simulate",
      type: "string",
      default: "8.3",
      valid_values: ["7.0", "7.1", "7.2", "7.3", "7.4", "8.0", "8.1", "8.2", "8.3", "9.0"],
      example: "8.0"
    },
    "MOCK_PVE_ENABLE_SDN" => %{
      description: "Enable Software Defined Networking endpoints",
      type: "boolean", 
      default: true,
      note: "Only effective for PVE 8.0+",
      example: "false"
    }
    # ... more configuration options
  }
end
```

### Configuration Endpoint
```elixir
# Development/debug endpoint to show current configuration
get "/api2/json/config" do
  if Application.get_env(:mock_pve_api, :debug_mode, false) do
    config = MockPveApi.Config.get_config()
    json(conn, %{data: config})
  else
    send_resp(conn, 404, "Not Found")
  end
end
```

## Testing Strategy

### Configuration Testing
```elixir
describe "configuration management" do
  test "loads defaults when no environment variables set" do
    config = MockPveApi.Config.get_config()
    assert config.version == "8.3"
    assert config.port == 8006
    assert config.enable_sdn == true
  end
  
  test "overrides defaults with environment variables" do
    System.put_env("MOCK_PVE_VERSION", "7.4")
    System.put_env("MOCK_PVE_ENABLE_SDN", "false")
    
    config = MockPveApi.Config.get_config()
    assert config.version == "7.4"
    assert config.enable_sdn == false
  end
  
  test "validates invalid configurations" do
    System.put_env("MOCK_PVE_VERSION", "invalid")
    assert_raise ArgumentError, fn ->
      MockPveApi.Config.get_config()
    end
  end
end
```

### Integration Testing
```bash
# Test with different configurations in CI
for version in 7.4 8.0 8.3 9.0; do
  echo "Testing PVE $version configuration..."
  podman run --rm -d --name test-$version \
    -p 800$version:8006 \
    -e MOCK_PVE_VERSION=$version \
    jrjsmrtn/mock-pve-api:latest
  
  sleep 2
  curl -f http://localhost:800$version/api2/json/version
  docker stop test-$version
done
```

## Migration and Compatibility

### Backward Compatibility
- **Deprecated Variables**: Support old names with warnings
- **Default Changes**: Careful consideration of default value changes
- **Feature Flags**: Use feature flags for breaking changes

### Configuration Migration
```elixir
# Support deprecated environment variable names
defp handle_deprecated_config(config) do
  # Support old MOCK_PVE_LOG_LEVEL format
  case System.get_env("MOCK_LOG_LEVEL") do
    nil -> config
    level -> 
      Logger.warn("MOCK_LOG_LEVEL is deprecated, use MOCK_PVE_LOG_LEVEL")
      Map.put(config, :log_level, String.to_atom(level))
  end
end
```

## Links

* [12-Factor App Configuration](https://12factor.net/config)
* [Docker Environment Variables](https://docs.docker.com/compose/environment-variables/)
* [Kubernetes ConfigMaps](https://kubernetes.io/docs/concepts/configuration/configmap/)

## Success Criteria

1. **Zero-config startup with sensible defaults** ✓
2. **All major configuration via environment variables** ✓
3. **Comprehensive validation with clear error messages** ✓
4. **CI/CD pipeline integration without config files** ✓
5. **Runtime configuration changes without rebuilds** ✓
6. **Self-documenting configuration options** ✓