# Migrating from pvex Embedded Mock Server

This guide helps pvex users transition from the embedded Mock PVE Server to the standalone Mock PVE API Server. The standalone version provides the same functionality with improved performance, easier maintenance, and broader ecosystem compatibility.

## Overview

The Mock PVE API Server was originally developed as part of the pvex project during Sprint G to enable infrastructure-independent testing. Due to its success and broader ecosystem value, it has been extracted as a standalone project that can serve any PVE client library in any programming language.

## Migration Timeline

- **Current (2025-08-30)**: Both embedded and standalone versions are available
- **pvex 0.3.x**: Embedded mock server deprecated but functional
- **pvex 1.0.x**: Embedded mock server removed, standalone version required

## Quick Migration

### Before (Embedded Mock Server)
```elixir
# In your test suite
defmodule MyTest do
  use ExUnit.Case
  
  setup do
    # Start embedded mock server
    TestHelper.start_mock_server(port: 18006, pve_version: "8.0")
    
    on_exit(fn ->
      TestHelper.stop_mock_server()
    end)
    
    config = TestHelper.mock_server_config(port: 18006)
    {:ok, client} = Pvex.Client.new(config)
    
    {:ok, client: client}
  end
end
```

### After (Standalone Mock Server)
```elixir
# In your test suite
defmodule MyTest do
  use ExUnit.Case
  
  setup do
    # Option 1: Use standalone Elixir server (development)
    {:ok, _pid} = MockPveApi.TestHelper.start_server(port: 18006, pve_version: "8.0")
    :ok = MockPveApi.TestHelper.wait_for_server("localhost", 18006)
    
    on_exit(fn ->
      MockPveApi.TestHelper.stop_server()
    end)
    
    # Option 2: Use Docker container (CI/CD)
    # podman run -d -p 18006:8006 -e MOCK_PVE_VERSION=8.0 ghcr.io/jrjsmrtn/mock-pve-api:latest
    
    config = %Pvex.Config{
      host: "localhost",
      port: 18006,
      scheme: "http",
      api_token: "PVEAPIToken=test@pve!test=test-token-secret",
      verify_ssl: false
    }
    {:ok, client} = Pvex.Client.new(config)
    
    {:ok, client: client}
  end
end
```

## Dependencies

### Add Mock PVE API Dependency

Add to your `mix.exs`:

```elixir
def deps do
  [
    {:pvex, "~> 0.2.0"},
    # For development/test environments
    {:mock_pve_api, "~> 0.1.0", only: [:test, :dev]}
  ]
end
```

For production CI/CD, use Docker containers instead:

```elixir
def deps do
  [
    {:pvex, "~> 0.2.0"}
    # No mock_pve_api dependency needed for Docker-based testing
  ]
end
```

## Migration Strategies

### Strategy 1: Direct Elixir Dependency (Development)

Best for local development and small test suites.

```elixir
# test/test_helper.exs
if Code.ensure_loaded?(MockPveApi.TestHelper) do
  # Use standalone mock server
  alias MockPveApi.TestHelper, as: MockHelper
else
  # Fallback to embedded mock (during transition)
  alias MockPveHelper, as: MockHelper
end

# Start mock server
MockHelper.start_server(port: 18006, pve_version: "8.0")
MockHelper.wait_for_server("localhost", 18006)

# Create unified test helper
defmodule TestHelper do
  def mock_config(opts \\ []) do
    if Code.ensure_loaded?(MockPveApi.TestHelper) do
      MockPveApi.TestHelper.create_test_config(opts)
      |> Map.put(:__struct__, Pvex.Config)
    else
      MockPveHelper.mock_config(opts)
    end
  end
  
  def reset_mock_state do
    if Code.ensure_loaded?(MockPveApi.TestHelper) do
      MockPveApi.TestHelper.reset_server_state()
    else
      MockPveHelper.reset_mock_state()
    end
  end
end
```

### Strategy 2: Docker Container (CI/CD)

Best for CI/CD pipelines and production testing.

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    services:
      mock-pve:
        image: ghcr.io/jrjsmrtn/mock-pve-api:latest
        ports:
          - 18006:8006
        env:
          MOCK_PVE_VERSION: "8.0"
    
    steps:
      - uses: actions/checkout@v4
      - uses: erlef/setup-beam@v1
        with:
          elixir-version: '1.15'
          otp-version: '26'
      
      - name: Install dependencies
        run: mix deps.get
      
      - name: Wait for mock server
        run: |
          for i in {1..30}; do
            if curl -f http://localhost:18006/api2/json/version; then
              echo "Mock server ready"
              break
            fi
            echo "Waiting for mock server... ($i/30)"
            sleep 2
          done
      
      - name: Run tests
        run: mix test
        env:
          MOCK_PVE_HOST: localhost
          MOCK_PVE_PORT: 18006
```

```elixir
# test/test_helper.exs for CI/CD
defmodule TestHelper do
  def ci_mock_config do
    %Pvex.Config{
      host: System.get_env("MOCK_PVE_HOST", "localhost"),
      port: String.to_integer(System.get_env("MOCK_PVE_PORT", "18006")),
      scheme: "http",
      api_token: "PVEAPIToken=test@pve!test=test-token-secret",
      verify_ssl: false,
      timeout: 30_000
    }
  end
  
  def wait_for_ci_mock_server do
    host = System.get_env("MOCK_PVE_HOST", "localhost")
    port = String.to_integer(System.get_env("MOCK_PVE_PORT", "18006"))
    
    # Wait for server to be ready
    Enum.reduce_while(1..30, :error, fn i, _acc ->
      case :gen_tcp.connect(String.to_charlist(host), port, [], 1000) do
        {:ok, socket} ->
          :gen_tcp.close(socket)
          IO.puts("Mock server ready after #{i} attempts")
          {:halt, :ok}
        
        {:error, _} ->
          IO.puts("Waiting for mock server... (#{i}/30)")
          Process.sleep(2000)
          {:cont, :error}
      end
    end)
  end
end

# Wait for CI mock server if available
if System.get_env("CI") do
  TestHelper.wait_for_ci_mock_server()
end
```

### Strategy 3: Hybrid Approach

Use Docker in CI/CD, standalone library in development:

```elixir
# test/test_helper.exs
defmodule TestHelper do
  def start_mock_server(opts \\ []) do
    cond do
      # CI/CD environment - assume Docker container is running
      System.get_env("CI") ->
        wait_for_ci_mock_server()
        :ok
      
      # Development with standalone library
      Code.ensure_loaded?(MockPveApi.TestHelper) ->
        MockPveApi.TestHelper.start_server(opts)
        MockPveApi.TestHelper.wait_for_server("localhost", opts[:port] || 18006)
      
      # Fallback to embedded mock (transition period)
      Code.ensure_loaded?(MockPveHelper) ->
        MockPveHelper.start_mock_server(opts)
      
      true ->
        {:error, :no_mock_server_available}
    end
  end
  
  def mock_config(opts \\ []) do
    base_config = %{
      host: "localhost",
      port: 18006,
      scheme: "http", 
      api_token: "PVEAPIToken=test@pve!test=test-token-secret",
      verify_ssl: false,
      timeout: 30_000
    }
    
    config = Enum.into(opts, base_config)
    struct(Pvex.Config, config)
  end
end
```

## Configuration Mapping

### Old Configuration (Embedded)
```elixir
MockPveHelper.mock_config([
  port: 18006,
  host: "127.0.0.1",
  pve_version: "8.0"
])
```

### New Configuration (Standalone)
```elixir
# Server configuration
MockPveApi.TestHelper.start_server([
  port: 18006,
  host: "127.0.0.1", 
  pve_version: "8.0",
  delay_ms: 0,
  error_rate: 0
])

# Client configuration
MockPveApi.TestHelper.create_test_config([
  host: "127.0.0.1",
  port: 18006,
  scheme: "http",
  api_token: "PVEAPIToken=test@pve!test=test-token-secret",
  verify_ssl: false,
  timeout: 30_000
])
```

## Function Mapping

| Old Function (Embedded) | New Function (Standalone) | Notes |
|-------------------------|---------------------------|-------|
| `MockPveHelper.start_mock_server/1` | `MockPveApi.TestHelper.start_server/1` | Similar API, improved options |
| `MockPveHelper.stop_mock_server/0` | `MockPveApi.TestHelper.stop_server/0` | Identical |
| `MockPveHelper.reset_mock_state/0` | `MockPveApi.TestHelper.reset_server_state/0` | Renamed for clarity |
| `MockPveHelper.mock_config/1` | `MockPveApi.TestHelper.create_test_config/1` | Returns plain map instead of struct |
| `MockPveHelper.wait_for_server/3` | `MockPveApi.TestHelper.wait_for_server/3` | Enhanced with better options |
| `MockPveHelper.setup_test_data/0` | `MockPveApi.TestHelper.setup_test_data/1` | Enhanced with options |
| `MockPveHelper.configure_pve7/0` | `MockPveApi.TestHelper.configure_pve_version/1` | Unified version configuration |
| `MockPveHelper.configure_pve8/0` | `MockPveApi.TestHelper.configure_pve_version/1` | Unified version configuration |

## Performance Improvements

The standalone Mock PVE API Server provides several performance improvements:

### Startup Time
- **Embedded**: ~2-3 seconds (includes compilation)
- **Standalone**: <1 second (pre-compiled)

### Memory Usage
- **Embedded**: Shared with test process
- **Standalone**: Isolated process, predictable memory usage

### Test Isolation
- **Embedded**: State shared across tests
- **Standalone**: Clean state between test runs

### Concurrent Testing
- **Embedded**: Single server instance
- **Standalone**: Multiple servers on different ports

```elixir
# Run tests against multiple PVE versions concurrently
defmodule MultiVersionTest do
  use ExUnit.Case, async: false
  
  @versions [
    {"7.4", 18074},
    {"8.0", 18080}, 
    {"8.3", 18083}
  ]
  
  setup_all do
    # Start multiple mock servers
    Enum.each(@versions, fn {version, port} ->
      MockPveApi.TestHelper.start_server(port: port, pve_version: version)
      MockPveApi.TestHelper.wait_for_server("localhost", port)
    end)
    
    on_exit(fn ->
      # Cleanup handled by test process exit
    end)
    
    :ok
  end
  
  for {version, port} <- @versions do
    test "PVE #{version} compatibility" do
      config = MockPveApi.TestHelper.create_test_config(port: unquote(port))
      {:ok, client} = Pvex.Client.new(struct(Pvex.Config, config))
      
      # Test version-specific features...
    end
  end
end
```

## Docker Integration

### Local Development with Docker Compose

```yaml
# docker-compose.test.yml
version: '3.8'

services:
  mock-pve-7:
    image: ghcr.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "18074:8006"
    environment:
      - MOCK_PVE_VERSION=7.4

  mock-pve-8:
    image: ghcr.io/jrjsmrtn/mock-pve-api:latest
    ports:
      - "18080:8006"
    environment:
      - MOCK_PVE_VERSION=8.0
```

```bash
# Start test environment
docker-compose -f docker-compose.test.yml up -d

# Run tests
mix test

# Cleanup
docker-compose -f docker-compose.test.yml down
```

### Makefile Integration

```makefile
# Makefile
.PHONY: test-with-mock

test-with-mock:
	@echo "Starting Mock PVE API Server..."
	podman run -d --name mock-pve-test \
		-p 18006:8006 \
		-e MOCK_PVE_VERSION=8.0 \
		ghcr.io/jrjsmrtn/mock-pve-api:latest
	@echo "Waiting for server to be ready..."
	@for i in $$(seq 1 30); do \
		if curl -s -f http://localhost:18006/api2/json/version > /dev/null; then \
			echo "Mock server ready"; \
			break; \
		fi; \
		echo "Waiting... ($$i/30)"; \
		sleep 2; \
	done
	@echo "Running tests..."
	MOCK_PVE_HOST=localhost MOCK_PVE_PORT=18006 mix test
	@echo "Cleaning up..."
	docker stop mock-pve-test && docker rm mock-pve-test

test-local:
	@echo "Using embedded mock server for local testing..."
	mix test
```

## Troubleshooting

### Common Issues

#### 1. Mock Server Not Starting
```elixir
# Check if port is available
case :gen_tcp.listen(18006, [:binary, active: false, reuseaddr: true]) do
  {:ok, socket} ->
    :gen_tcp.close(socket)
    IO.puts("Port 18006 is available")
  
  {:error, :eaddrinuse} ->
    IO.puts("Port 18006 is already in use")
    
  {:error, reason} ->
    IO.puts("Port issue: #{inspect(reason)}")
end

# Check dependencies
case Code.ensure_loaded(MockPveApi.TestHelper) do
  true -> IO.puts("Mock PVE API available")
  false -> IO.puts("Mock PVE API not available - add to deps")
end
```

#### 2. Docker Container Issues
```bash
# Check if container is running
docker ps | grep mock-pve-api

# Check container logs
docker logs mock-pve-test

# Check port binding
docker port mock-pve-test

# Test direct connection
curl http://localhost:18006/api2/json/version
```

#### 3. Test Timeouts
```elixir
# Increase timeout for slow environments
config = MockPveApi.TestHelper.create_test_config(timeout: 60_000)

# Wait with retry
MockPveApi.TestHelper.wait_for_server("localhost", 18006, timeout: 60_000)

# Use condition waiting
MockPveApi.TestHelper.wait_for_condition(fn ->
  case HTTPoison.get("http://localhost:18006/api2/json/version") do
    {:ok, %{status_code: 200}} -> true
    _ -> false
  end
end, timeout: 60_000)
```

## Best Practices

### 1. Test Isolation
```elixir
# Reset state between tests
setup do
  MockPveApi.TestHelper.reset_server_state()
  :ok
end
```

### 2. Resource Cleanup
```elixir
# Generate unique names to avoid conflicts
test "VM operations" do
  vm_name = MockPveApi.TestHelper.unique_name("test-vm")
  # Use vm_name in test...
end
```

### 3. Version Testing
```elixir
# Test version-specific features
defmodule VersionFeatureTest do
  use ExUnit.Case
  
  for version <- ["7.4", "8.0", "8.3"] do
    test "SDN features in PVE #{version}" do
      port = 18000 + String.to_integer(String.replace(unquote(version), ".", ""))
      MockPveApi.TestHelper.start_server(port: port, pve_version: unquote(version))
      
      config = MockPveApi.TestHelper.create_test_config(port: port)
      {:ok, client} = Pvex.Client.new(struct(Pvex.Config, config))
      
      # Test SDN based on version
      if String.starts_with?(unquote(version), "8") do
        assert {:ok, _} = Pvex.Resources.SDN.list_zones(client)
      else
        assert {:error, _} = Pvex.Resources.SDN.list_zones(client)
      end
    end
  end
end
```

## Getting Help

- **GitHub Issues**: [mock-pve-api issues](https://github.com/jrjsmrtn/mock-pve-api/issues)
- **pvex Issues**: [pvex issues](https://github.com/jrjsmrtn/pvex/issues)
- **Docker Hub**: [mock-pve-api images](https://hub.docker.com/r/jrjsmrtn/mock-pve-api)

## Contributing

The Mock PVE API Server welcomes contributions to improve compatibility and add features. See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.