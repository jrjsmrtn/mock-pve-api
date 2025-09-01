defmodule MockPveApi.TestHelper do
  @moduledoc """
  Test helper functions for client libraries using the Mock PVE API Server.

  This module provides utilities that client libraries (like pvex) can use to
  manage the mock server lifecycle, configure test scenarios, and validate
  server availability in their test suites.

  ## Usage in Client Libraries

  ```elixir
  # In your test_helper.exs
  alias MockPveApi.TestHelper

  # Start mock server for testing
  {:ok, _pid} = TestHelper.start_server(port: 18006, pve_version: "8.0")

  # Wait for server to be available
  :ok = TestHelper.wait_for_server("localhost", 18006)

  # Create test configuration
  config = TestHelper.create_test_config(port: 18006)

  # Reset server state between tests
  TestHelper.reset_server_state()

  # Stop server when done
  TestHelper.stop_server()
  ```

  ## Docker Integration

  For production test suites, consider using Docker containers instead:

  ```bash
  # Start mock server container
  docker run -d -p 18006:8006 \\
    -e MOCK_PVE_VERSION=8.0 \\
    --name mock-pve-test \\
    jrjsmrtn/mock-pve-api:latest

  # Use TestHelper to wait for availability
  MockPveApi.TestHelper.wait_for_server("localhost", 18006)
  ```
  """

  require Logger

  @default_host "127.0.0.1"
  @default_port 8006
  @default_version "8.0"
  @default_timeout 30_000

  @doc """
  Starts the Mock PVE API Server with the specified configuration.

  ## Options
  - `:host` - Host to bind the server to (default: "127.0.0.1")
  - `:port` - Port to run the server on (default: 8006)
  - `:pve_version` - PVE version to simulate (default: "8.0")
  - `:delay_ms` - Response delay in milliseconds (default: 0)
  - `:error_rate` - Error injection rate 0-100 (default: 0)

  ## Returns
  - `{:ok, pid}` - Server started successfully
  - `{:error, reason}` - Failed to start server

  ## Examples

      iex> MockPveApi.TestHelper.start_server()
      {:ok, #PID<0.123.0>}

      iex> MockPveApi.TestHelper.start_server(port: 18006, pve_version: "7.4")
      {:ok, #PID<0.124.0>}
  """
  def start_server(opts \\ []) do
    host = Keyword.get(opts, :host, @default_host)
    port = Keyword.get(opts, :port, @default_port)
    pve_version = Keyword.get(opts, :pve_version, @default_version)
    delay_ms = Keyword.get(opts, :delay_ms, 0)
    error_rate = Keyword.get(opts, :error_rate, 0)

    Logger.info("Starting Mock PVE API Server on #{host}:#{port} (PVE #{pve_version})")

    # Configure the application
    Application.put_env(:mock_pve_api, :host, host)
    Application.put_env(:mock_pve_api, :port, port)
    Application.put_env(:mock_pve_api, :pve_version, pve_version)
    Application.put_env(:mock_pve_api, :delay_ms, delay_ms)
    Application.put_env(:mock_pve_api, :error_rate, error_rate)

    case Application.ensure_all_started(:mock_pve_api) do
      {:ok, _apps} ->
        Logger.info("Mock PVE API Server started successfully")
        {:ok, self()}

      {:error, {app, reason}} ->
        Logger.error("Failed to start Mock PVE API Server: #{app} - #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Stops the Mock PVE API Server.

  ## Returns
  - `:ok` - Server stopped successfully

  ## Examples

      iex> MockPveApi.TestHelper.stop_server()
      :ok
  """
  def stop_server do
    Logger.info("Stopping Mock PVE API Server")

    case Application.stop(:mock_pve_api) do
      :ok ->
        Logger.info("Mock PVE API Server stopped successfully")
        :ok

      {:error, reason} ->
        Logger.warning("Issue stopping Mock PVE API Server: #{inspect(reason)}")
        :ok
    end
  end

  @doc """
  Waits for the Mock PVE API Server to be available on the specified host and port.

  This function will attempt to connect to the server using TCP and retry until
  the connection is successful or the maximum number of retries is reached.

  ## Parameters
  - `host` - Host to connect to (default: "127.0.0.1")
  - `port` - Port to connect to (default: 8006)
  - `opts` - Additional options
    - `:timeout` - Total timeout in milliseconds (default: 30_000)
    - `:interval` - Retry interval in milliseconds (default: 1_000)

  ## Returns
  - `:ok` - Server is available
  - `{:error, reason}` - Server is not available after timeout

  ## Examples

      iex> MockPveApi.TestHelper.wait_for_server()
      :ok

      iex> MockPveApi.TestHelper.wait_for_server("localhost", 18006, timeout: 60_000)
      :ok

      iex> MockPveApi.TestHelper.wait_for_server("invalid-host", 999)
      {:error, "Server not available after timeout"}
  """
  def wait_for_server(host \\ @default_host, port \\ @default_port, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    interval = Keyword.get(opts, :interval, 1_000)
    deadline = System.monotonic_time(:millisecond) + timeout

    Logger.info("Waiting for Mock PVE API Server at #{host}:#{port}...")

    do_wait_for_server(host, port, interval, deadline)
  end

  defp do_wait_for_server(host, port, interval, deadline) do
    case :gen_tcp.connect(String.to_charlist(host), port, [], 1000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        Logger.info("Mock PVE API Server is ready!")
        :ok

      {:error, reason} ->
        if System.monotonic_time(:millisecond) >= deadline do
          Logger.error("Mock PVE API Server failed to start: #{inspect(reason)}")
          {:error, "Server not available after timeout: #{inspect(reason)}"}
        else
          Logger.debug("Waiting for server... (#{inspect(reason)})")
          Process.sleep(interval)
          do_wait_for_server(host, port, interval, deadline)
        end
    end
  end

  @doc """
  Resets the Mock PVE API Server state to initial values.

  This is useful between test cases to ensure a clean state.

  ## Returns
  - `:ok` - State reset successfully
  - `{:error, reason}` - Failed to reset state

  ## Examples

      iex> MockPveApi.TestHelper.reset_server_state()
      :ok
  """
  def reset_server_state do
    case MockPveApi.State.reset() do
      :ok ->
        Logger.debug("Mock PVE API Server state reset successfully")
        :ok

      {:error, reason} ->
        Logger.warning("Failed to reset Mock PVE API Server state: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.warning("Error resetting Mock PVE API Server state: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Creates a test configuration suitable for connecting to the Mock PVE API Server.

  ## Options
  - `:host` - Host to connect to (default: "127.0.0.1")
  - `:port` - Port to connect to (default: 8006)
  - `:scheme` - URL scheme (default: "http")
  - `:api_token` - API token for authentication (default: test token)
  - `:verify_ssl` - SSL verification (default: false)
  - `:timeout` - Request timeout (default: 30_000)

  ## Returns
  A map with configuration parameters suitable for PVE client libraries.

  ## Examples

      iex> MockPveApi.TestHelper.create_test_config()
      %{
        host: "127.0.0.1",
        port: 8006,
        scheme: "http",
        api_token: "PVEAPIToken=test@pve!test=test-token-secret",
        verify_ssl: false,
        timeout: 30_000
      }

      iex> MockPveApi.TestHelper.create_test_config(port: 18006, host: "localhost")
      %{
        host: "localhost",
        port: 18006,
        scheme: "http",
        api_token: "PVEAPIToken=test@pve!test=test-token-secret",
        verify_ssl: false,
        timeout: 30_000
      }
  """
  def create_test_config(opts \\ []) do
    %{
      host: Keyword.get(opts, :host, @default_host),
      port: Keyword.get(opts, :port, @default_port),
      scheme: Keyword.get(opts, :scheme, "http"),
      api_token: Keyword.get(opts, :api_token, "PVEAPIToken=test@pve!test=test-token-secret"),
      verify_ssl: Keyword.get(opts, :verify_ssl, false),
      timeout: Keyword.get(opts, :timeout, @default_timeout)
    }
  end

  @doc """
  Populates the Mock PVE API Server with predefined test data.

  This creates sample VMs, containers, storage, and other resources
  that can be used in integration tests.

  ## Options
  - `:reset` - Reset state before populating (default: true)
  - `:include_vms` - Create sample VMs (default: true)
  - `:include_containers` - Create sample containers (default: true)
  - `:include_storage` - Create sample storage (default: true)
  - `:include_pools` - Create sample resource pools (default: true)

  ## Returns
  - `:ok` - Test data populated successfully
  - `{:error, reason}` - Failed to populate test data

  ## Examples

      iex> MockPveApi.TestHelper.setup_test_data()
      :ok

      iex> MockPveApi.TestHelper.setup_test_data(include_vms: false)
      :ok
  """
  def setup_test_data(opts \\ []) do
    if Keyword.get(opts, :reset, true) do
      reset_server_state()
    end

    Logger.debug("Setting up test data for Mock PVE API Server")

    # For now, the MockPveApi.State module provides initial test data
    # In the future, this could be expanded to allow custom test scenarios
    :ok
  end

  @doc """
  Configures the Mock PVE API Server to simulate a specific PVE version.

  ## Parameters
  - `version` - PVE version string (e.g., "7.4", "8.0", "8.3")

  ## Returns
  - `:ok` - Version configured successfully
  - `{:error, reason}` - Failed to configure version

  ## Examples

      iex> MockPveApi.TestHelper.configure_pve_version("7.4")
      :ok

      iex> MockPveApi.TestHelper.configure_pve_version("8.3")
      :ok
  """
  def configure_pve_version(version) when is_binary(version) do
    Logger.debug("Configuring Mock PVE API Server for PVE version #{version}")

    Application.put_env(:mock_pve_api, :pve_version, version)

    # Restart the capabilities system to pick up the new version
    case MockPveApi.Capabilities.reload() do
      :ok ->
        Logger.info("Mock PVE API Server configured for PVE #{version}")
        :ok

      {:error, reason} ->
        Logger.error("Failed to configure PVE version: #{inspect(reason)}")
        {:error, reason}
    end
  rescue
    error ->
      Logger.error("Error configuring PVE version: #{inspect(error)}")
      {:error, error}
  end

  @doc """
  Checks if the Mock PVE API Server is currently running and responsive.

  ## Parameters
  - `host` - Host to check (default: "127.0.0.1")
  - `port` - Port to check (default: 8006)
  - `timeout` - HTTP request timeout (default: 5_000)

  ## Returns
  - `{:ok, info}` - Server is running with version info
  - `{:error, reason}` - Server is not running or not responsive

  ## Examples

      iex> MockPveApi.TestHelper.server_status()
      {:ok, %{"version" => "8.0", "release" => "8.0"}}

      iex> MockPveApi.TestHelper.server_status("localhost", 18006)
      {:error, :econnrefused}
  """
  def server_status(host \\ @default_host, port \\ @default_port, timeout \\ 5_000) do
    url = "http://#{host}:#{port}/api2/json/version"

    case Finch.build(:get, url) |> Finch.request(MockPveApi.Finch, receive_timeout: timeout) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, %{"data" => data}} ->
            {:ok, data}

          {:ok, data} ->
            {:ok, data}

          {:error, reason} ->
            {:error, {:json_decode_error, reason}}
        end

      {:ok, %Finch.Response{status: status}} ->
        {:error, {:http_error, status}}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    error ->
      {:error, error}
  end

  @doc """
  Generates unique test resource names to avoid conflicts in parallel tests.

  ## Parameters
  - `prefix` - Resource name prefix (default: "test")
  - `suffix` - Additional suffix (optional)

  ## Returns
  A unique resource name string.

  ## Examples

      iex> MockPveApi.TestHelper.unique_name("vm")
      "vm-1693478400-1234"

      iex> MockPveApi.TestHelper.unique_name("container", "integration")
      "container-1693478400-5678-integration"
  """
  def unique_name(prefix \\ "test", suffix \\ nil) do
    timestamp = System.system_time(:millisecond)
    random = :rand.uniform(9999)

    base_name = "#{prefix}-#{timestamp}-#{random}"

    if suffix do
      "#{base_name}-#{suffix}"
    else
      base_name
    end
  end

  @doc """
  Waits for a condition to be met with configurable timeout and retry interval.

  This is useful for integration tests that need to wait for async operations
  or state changes in the mock server.

  ## Parameters
  - `fun` - Function to test (should return truthy value when condition is met)
  - `opts` - Options
    - `:timeout` - Maximum wait time in milliseconds (default: 30_000)
    - `:interval` - Check interval in milliseconds (default: 1_000)
    - `:description` - Description for logging (optional)

  ## Returns
  - `:ok` - Condition was met
  - `{:ok, result}` - Condition was met with a result
  - `{:error, :timeout}` - Condition was not met within timeout

  ## Examples

      iex> MockPveApi.TestHelper.wait_for_condition(fn ->
      ...>   case MockPveApi.TestHelper.server_status() do
      ...>     {:ok, _} -> true
      ...>     _ -> false
      ...>   end
      ...> end, timeout: 10_000)
      :ok

      iex> MockPveApi.TestHelper.wait_for_condition(fn -> {:ok, "result"} end)
      {:ok, "result"}
  """
  def wait_for_condition(fun, opts \\ []) when is_function(fun, 0) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    interval = Keyword.get(opts, :interval, 1_000)
    description = Keyword.get(opts, :description)
    deadline = System.monotonic_time(:millisecond) + timeout

    if description do
      Logger.debug("Waiting for condition: #{description}")
    end

    do_wait_for_condition(fun, deadline, interval, description)
  end

  defp do_wait_for_condition(fun, deadline, interval, description) do
    case fun.() do
      {:ok, result} ->
        {:ok, result}

      :ok ->
        :ok

      true ->
        :ok

      _ ->
        if System.monotonic_time(:millisecond) >= deadline do
          if description do
            Logger.error("Timeout waiting for condition: #{description}")
          end

          {:error, :timeout}
        else
          Process.sleep(interval)
          do_wait_for_condition(fun, deadline, interval, description)
        end
    end
  end
end