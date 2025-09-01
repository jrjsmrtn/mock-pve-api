#!/usr/bin/env elixir

#
# pvex Integration Example with Mock PVE API Server
#
# This example demonstrates how to use the Mock PVE API Server with the pvex 
# Elixir client library for comprehensive testing scenarios.
#
# Requirements:
#   - pvex client library
#   - mock-pve-api server (running or as dependency)
#   - httpoison for HTTP requests
#   - jason for JSON handling
#
# Usage:
#   # Option 1: Use running mock server (Docker)
#   podman run -d -p 8006:8006 -e MOCK_PVE_VERSION=8.0 docker.io/jrjsmrtn/mock-pve-api:latest
#   elixir examples/elixir/pvex_integration.exs
#   
#   # Option 2: Use embedded mock server (development)
#   EMBEDDED_MOCK=true elixir examples/elixir/pvex_integration.exs
#

# Mix.install dependencies for standalone script execution
Mix.install([
  {:httpoison, "~> 2.0"},
  {:jason, "~> 1.4"},
  {:finch, "~> 0.16"}
])

# Simulated pvex client for demonstration
# In real usage, you would use the actual pvex library
defmodule SimulatedPvex do
  @moduledoc """
  Simulated pvex client for demonstration purposes.
  In practice, replace this with the actual pvex library.
  """

  defmodule Config do
    @enforce_keys [:host, :port]
    defstruct [
      :host,
      :port,
      scheme: "http",
      api_token: "PVEAPIToken=test@pve!test=test-token-secret",
      verify_ssl: false,
      timeout: 30_000
    ]
  end

  defmodule Client do
    def new(%Config{} = config) do
      # In real pvex, this would set up HTTP client, authentication, etc.
      {:ok, config}
    end

    def get(client, path) do
      url = "#{client.scheme}://#{client.host}:#{client.port}/api2/json#{path}"

      case HTTPoison.get(url, [{"Authorization", "PVEAPIToken=" <> client.api_token}]) do
        {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
          Jason.decode(body)

        {:ok, %HTTPoison.Response{status_code: status, body: body}} ->
          case Jason.decode(body) do
            {:ok, %{"errors" => errors}} -> {:error, {status, errors}}
            _ -> {:error, {status, body}}
          end

        {:error, error} ->
          {:error, error}
      end
    end
  end

  # Simulated resource modules
  defmodule Resources do
    defmodule VMs do
      def list(client, opts \\ []) do
        node = Keyword.get(opts, :node, "pve-node-1")
        Client.get(client, "/nodes/#{node}/qemu")
      end

      def get(client, opts) do
        node = Keyword.fetch!(opts, :node)
        vmid = Keyword.fetch!(opts, :vmid)
        Client.get(client, "/nodes/#{node}/qemu/#{vmid}")
      end

      def start(client, opts) do
        node = Keyword.fetch!(opts, :node)
        vmid = Keyword.fetch!(opts, :vmid)
        Client.post(client, "/nodes/#{node}/qemu/#{vmid}/status/start")
      end
    end

    defmodule Containers do
      def list(client, opts \\ []) do
        node = Keyword.get(opts, :node, "pve-node-1")
        Client.get(client, "/nodes/#{node}/lxc")
      end

      def get(client, opts) do
        node = Keyword.fetch!(opts, :node)
        vmid = Keyword.fetch!(opts, :vmid)
        Client.get(client, "/nodes/#{node}/lxc/#{vmid}")
      end
    end

    defmodule SDN do
      def list_zones(client) do
        Client.get(client, "/cluster/sdn/zones")
      end

      def list_vnets(client) do
        Client.get(client, "/cluster/sdn/vnets")
      end
    end

    defmodule Storage do
      def list(client, opts \\ []) do
        node = Keyword.get(opts, :node, "pve-node-1")
        Client.get(client, "/nodes/#{node}/storage")
      end

      def content(client, opts) do
        node = Keyword.fetch!(opts, :node)
        storage = Keyword.fetch!(opts, :storage)
        Client.get(client, "/nodes/#{node}/storage/#{storage}/content")
      end
    end

    defmodule Cluster do
      def status(client) do
        Client.get(client, "/cluster/status")
      end

      def resources(client) do
        Client.get(client, "/cluster/resources")
      end
    end

    defmodule ResourcePools do
      def list(client) do
        Client.get(client, "/pools")
      end

      def get(client, poolid) do
        Client.get(client, "/pools/#{poolid}")
      end
    end
  end
end

defmodule MockPveIntegrationExample do
  @moduledoc """
  Comprehensive example of using Mock PVE API Server with pvex for testing.
  
  This example demonstrates:
  - Setting up mock server (embedded or external)
  - Basic API operations (VMs, containers, storage)
  - Version-specific feature testing (SDN for PVE 8.x)
  - Error handling and edge cases
  - Multi-version compatibility testing
  """

  require Logger

  def main do
    IO.puts("🚀 Mock PVE API Server - pvex Integration Example")
    IO.puts("=" <> String.duplicate("=", 53))

    case setup_mock_server() do
      {:ok, config} ->
        run_comprehensive_tests(config)

      {:error, reason} ->
        IO.puts("❌ Failed to setup mock server: #{inspect(reason)}")
        System.halt(1)
    end
  end

  defp setup_mock_server do
    cond do
      use_embedded_mock?() ->
        setup_embedded_mock()

      external_mock_available?() ->
        setup_external_mock()

      true ->
        IO.puts("❌ No mock server available")
        IO.puts("\n💡 To run this example:")
        IO.puts("  1. Start Docker container: podman run -d -p 8006:8006 docker.io/jrjsmrtn/mock-pve-api:latest")
        IO.puts("  2. Or use embedded mock: EMBEDDED_MOCK=true elixir pvex_integration.exs")
        {:error, :no_mock_server}
    end
  end

  defp use_embedded_mock? do
    System.get_env("EMBEDDED_MOCK") == "true"
  end

  defp external_mock_available? do
    case :gen_tcp.connect('localhost', 8006, [], 1000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        true

      {:error, _} ->
        false
    end
  end

  defp setup_embedded_mock do
    IO.puts("🔧 Setting up embedded mock server...")

    # This would use MockPveApi.TestHelper in real scenario
    # For this example, we assume external server is available
    config = %SimulatedPvex.Config{
      host: "localhost",
      port: 18006,
      scheme: "http"
    }

    IO.puts("✅ Embedded mock server configured")
    {:ok, config}
  end

  defp setup_external_mock do
    IO.puts("🔧 Using external mock server on localhost:8006...")

    config = %SimulatedPvex.Config{
      host: "localhost",
      port: 8006,
      scheme: "http"
    }

    case wait_for_server(config, 30) do
      :ok ->
        IO.puts("✅ External mock server is ready")
        {:ok, config}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp wait_for_server(config, retries) do
    case :gen_tcp.connect(String.to_charlist(config.host), config.port, [], 1000) do
      {:ok, socket} ->
        :gen_tcp.close(socket)
        :ok

      {:error, _} when retries > 0 ->
        Process.sleep(1000)
        wait_for_server(config, retries - 1)

      {:error, reason} ->
        {:error, "Server not available: #{inspect(reason)}"}
    end
  end

  defp run_comprehensive_tests(config) do
    {:ok, client} = SimulatedPvex.Client.new(config)

    IO.puts("\n🔍 Running comprehensive pvex integration tests...")

    try do
      # Test 1: Version Information
      test_version_info(client)

      # Test 2: Cluster Operations
      test_cluster_operations(client)

      # Test 3: Node Management
      test_node_operations(client)

      # Test 4: VM Operations
      test_vm_operations(client)

      # Test 5: Container Operations
      test_container_operations(client)

      # Test 6: Storage Operations
      test_storage_operations(client)

      # Test 7: Resource Pool Operations
      test_resource_pool_operations(client)

      # Test 8: Version-Specific Features
      test_version_specific_features(client)

      # Test 9: Error Handling
      test_error_handling(client)

      # Test 10: Concurrent Operations
      test_concurrent_operations(client)

      IO.puts("\n" <> String.duplicate("=", 55))
      IO.puts("🎉 All integration tests completed successfully!")
      IO.puts("\nMock PVE API Server is working perfectly with pvex!")
    rescue
      error ->
        IO.puts("\n❌ Test failed with error: #{inspect(error)}")
        System.halt(1)
    end
  end

  defp test_version_info(client) do
    IO.puts("\n🔍 Test 1: Version Information")

    case SimulatedPvex.Client.get(client, "/version") do
      {:ok, %{"data" => version_data}} ->
        version = version_data["version"]
        release = version_data["release"]
        repoid = version_data["repoid"]

        IO.puts("  ✅ PVE Version: #{version}")
        IO.puts("  ✅ Release: #{release}")
        IO.puts("  ✅ Repository ID: #{repoid}")

        # Store version for later tests
        Process.put(:pve_version, version)

      {:error, reason} ->
        raise "Version test failed: #{inspect(reason)}"
    end
  end

  defp test_cluster_operations(client) do
    IO.puts("\n🔍 Test 2: Cluster Operations")

    # Test cluster status
    case SimulatedPvex.Resources.Cluster.status(client) do
      {:ok, %{"data" => status_data}} ->
        cluster_info =
          status_data
          |> Enum.find(fn item -> item["type"] == "cluster" end)

        if cluster_info do
          IO.puts("  ✅ Cluster: #{cluster_info["name"]} (#{cluster_info["nodes"]} nodes)")
        end

        node_count =
          status_data
          |> Enum.count(fn item -> item["type"] == "node" end)

        IO.puts("  ✅ Online nodes: #{node_count}")

      {:error, reason} ->
        raise "Cluster status test failed: #{inspect(reason)}"
    end

    # Test cluster resources
    case SimulatedPvex.Resources.Cluster.resources(client) do
      {:ok, %{"data" => resources}} ->
        resource_counts = count_resources_by_type(resources)

        Enum.each(resource_counts, fn {type, count} ->
          IO.puts("  ✅ #{String.capitalize(type)} resources: #{count}")
        end)

      {:error, reason} ->
        raise "Cluster resources test failed: #{inspect(reason)}"
    end
  end

  defp test_node_operations(client) do
    IO.puts("\n🔍 Test 3: Node Management")

    case SimulatedPvex.Client.get(client, "/nodes") do
      {:ok, %{"data" => nodes}} ->
        IO.puts("  ✅ Found #{length(nodes)} nodes")

        Enum.each(nodes, fn node ->
          cpu_percent = (node["cpu"] * 100) |> Float.round(1)
          memory_gb = (node["mem"] / (1024 * 1024 * 1024)) |> Float.round(1)

          IO.puts(
            "    - #{node["node"]}: #{node["status"]}, CPU: #{cpu_percent}%, Memory: #{memory_gb}GB"
          )
        end)

      {:error, reason} ->
        raise "Node operations test failed: #{inspect(reason)}"
    end
  end

  defp test_vm_operations(client) do
    IO.puts("\n🔍 Test 4: VM Operations")

    case SimulatedPvex.Resources.VMs.list(client) do
      {:ok, %{"data" => vms}} ->
        IO.puts("  ✅ Found #{length(vms)} VMs")

        Enum.each(vms, fn vm ->
          IO.puts("    - VM #{vm["vmid"]}: #{vm["name"]} (#{vm["status"]})")

          # Test getting individual VM details
          case SimulatedPvex.Resources.VMs.get(client, node: "pve-node-1", vmid: vm["vmid"]) do
            {:ok, %{"data" => vm_details}} ->
              cpu_cores = vm_details["cpus"] || vm_details["maxcpu"] || "N/A"
              memory_mb = ((vm_details["maxmem"] || 0) / (1024 * 1024)) |> round()
              IO.puts("      CPU cores: #{cpu_cores}, Memory: #{memory_mb}MB")

            {:error, _} ->
              IO.puts("      Details unavailable")
          end
        end)

      {:error, reason} ->
        raise "VM operations test failed: #{inspect(reason)}"
    end
  end

  defp test_container_operations(client) do
    IO.puts("\n🔍 Test 5: Container Operations")

    case SimulatedPvex.Resources.Containers.list(client) do
      {:ok, %{"data" => containers}} ->
        IO.puts("  ✅ Found #{length(containers)} containers")

        Enum.each(containers, fn container ->
          IO.puts("    - CT #{container["vmid"]}: #{container["name"]} (#{container["status"]})")

          # Test getting individual container details
          case SimulatedPvex.Resources.Containers.get(client,
                 node: "pve-node-1",
                 vmid: container["vmid"]
               ) do
            {:ok, %{"data" => ct_details}} ->
              cpu_cores = ct_details["cpus"] || ct_details["maxcpu"] || "N/A"
              memory_mb = ((ct_details["maxmem"] || 0) / (1024 * 1024)) |> round()
              IO.puts("      CPU cores: #{cpu_cores}, Memory: #{memory_mb}MB")

            {:error, _} ->
              IO.puts("      Details unavailable")
          end
        end)

      {:error, reason} ->
        raise "Container operations test failed: #{inspect(reason)}"
    end
  end

  defp test_storage_operations(client) do
    IO.puts("\n🔍 Test 6: Storage Operations")

    case SimulatedPvex.Resources.Storage.list(client) do
      {:ok, %{"data" => storages}} ->
        IO.puts("  ✅ Found #{length(storages)} storage devices")

        Enum.each(storages, fn storage ->
          used_gb = ((storage["used"] || 0) / (1024 * 1024 * 1024)) |> Float.round(1)
          total_gb = ((storage["total"] || 0) / (1024 * 1024 * 1024)) |> Float.round(1)

          IO.puts(
            "    - #{storage["storage"]}: #{storage["type"]}, #{used_gb}GB/#{total_gb}GB used"
          )

          # Test storage content for 'local' storage
          if storage["storage"] == "local" do
            case SimulatedPvex.Resources.Storage.content(client,
                   node: "pve-node-1",
                   storage: "local"
                 ) do
              {:ok, %{"data" => content}} ->
                content_counts = count_content_by_type(content)

                Enum.each(content_counts, fn {type, count} ->
                  IO.puts("      #{type}: #{count} items")
                end)

              {:error, _} ->
                IO.puts("      Content listing unavailable")
            end
          end
        end)

      {:error, reason} ->
        raise "Storage operations test failed: #{inspect(reason)}"
    end
  end

  defp test_resource_pool_operations(client) do
    IO.puts("\n🔍 Test 7: Resource Pool Operations")

    case SimulatedPvex.Resources.ResourcePools.list(client) do
      {:ok, %{"data" => pools}} ->
        IO.puts("  ✅ Found #{length(pools)} resource pools")

        Enum.each(pools, fn pool ->
          member_count = length(pool["members"] || [])
          comment = pool["comment"] || "No comment"

          IO.puts("    - Pool '#{pool["poolid"]}': #{member_count} members")
          IO.puts("      Comment: #{comment}")

          # Test getting detailed pool information
          case SimulatedPvex.Resources.ResourcePools.get(client, pool["poolid"]) do
            {:ok, %{"data" => pool_details}} ->
              members = pool_details["members"] || []

              if length(members) > 0 do
                IO.puts("      Members:")

                Enum.each(members, fn member ->
                  case member do
                    %{"type" => "qemu", "vmid" => vmid} ->
                      IO.puts("        - VM #{vmid}")

                    %{"type" => "lxc", "vmid" => vmid} ->
                      IO.puts("        - Container #{vmid}")

                    %{"type" => type} ->
                      IO.puts("        - #{String.capitalize(type)}")
                  end
                end)
              end

            {:error, _} ->
              IO.puts("      Details unavailable")
          end
        end)

      {:error, reason} ->
        raise "Resource pool operations test failed: #{inspect(reason)}"
    end
  end

  defp test_version_specific_features(client) do
    IO.puts("\n🔍 Test 8: Version-Specific Features")

    pve_version = Process.get(:pve_version, "8.0")
    IO.puts("  Testing features for PVE #{pve_version}")

    # Test SDN features (available in PVE 8.0+)
    if version_at_least?(pve_version, "8.0") do
      IO.puts("  🔍 Testing SDN zones (PVE 8.0+)...")

      case SimulatedPvex.Resources.SDN.list_zones(client) do
        {:ok, %{"data" => zones}} ->
          IO.puts("    ✅ SDN Zones: #{length(zones)} zones available")

          Enum.each(zones, fn zone ->
            IO.puts("      - Zone '#{zone["zone"]}': #{zone["type"]}")
          end)

        {:error, {501, _errors}} ->
          IO.puts("    ⚠️  SDN zones returned 501 (feature not implemented in this version)")

        {:error, reason} ->
          IO.puts("    ⚠️  SDN zones test failed: #{inspect(reason)}")
      end

      IO.puts("  🔍 Testing SDN vnets (PVE 8.0+)...")

      case SimulatedPvex.Resources.SDN.list_vnets(client) do
        {:ok, %{"data" => vnets}} ->
          IO.puts("    ✅ SDN VNets: #{length(vnets)} vnets available")

          Enum.each(vnets, fn vnet ->
            IO.puts("      - VNet '#{vnet["vnet"]}' in zone '#{vnet["zone"]}'")
          end)

        {:error, {501, _errors}} ->
          IO.puts("    ⚠️  SDN vnets returned 501 (feature not implemented in this version)")

        {:error, reason} ->
          IO.puts("    ⚠️  SDN vnets test failed: #{inspect(reason)}")
      end
    else
      IO.puts("  ⏭️  SDN features not available in PVE #{pve_version}")
    end

    # Test backup providers (available in PVE 8.2+)
    if version_at_least?(pve_version, "8.2") do
      IO.puts("  🔍 Testing backup providers (PVE 8.2+)...")

      case SimulatedPvex.Client.get(client, "/cluster/backup-info/providers") do
        {:ok, %{"data" => providers}} ->
          IO.puts("    ✅ Backup Providers: #{length(providers)} providers available")

          Enum.each(providers, fn provider ->
            status = if provider["enabled"], do: "enabled", else: "disabled"
            IO.puts("      - #{provider["name"]}: #{status}")
          end)

        {:error, {501, _errors}} ->
          IO.puts("    ⚠️  Backup providers returned 501 (feature not implemented in this version)")

        {:error, reason} ->
          IO.puts("    ⚠️  Backup providers test failed: #{inspect(reason)}")
      end
    else
      IO.puts("  ⏭️  Backup providers not available in PVE #{pve_version}")
    end
  end

  defp test_error_handling(client) do
    IO.puts("\n🔍 Test 9: Error Handling")

    # Test 404 error
    case SimulatedPvex.Client.get(client, "/nonexistent/endpoint") do
      {:error, {404, _}} ->
        IO.puts("  ✅ 404 error handling works correctly")

      {:ok, _} ->
        IO.puts("  ⚠️  Expected 404 error but got success response")

      {:error, reason} ->
        IO.puts("  ⚠️  Unexpected error: #{inspect(reason)}")
    end

    # Test invalid VM ID
    case SimulatedPvex.Resources.VMs.get(client, node: "pve-node-1", vmid: 99999) do
      {:error, _} ->
        IO.puts("  ✅ Invalid VM ID error handling works correctly")

      {:ok, _} ->
        IO.puts("  ⚠️  Expected error for invalid VM ID but got success")
    end

    # Test invalid node name
    case SimulatedPvex.Resources.VMs.list(client, node: "nonexistent-node") do
      {:error, _} ->
        IO.puts("  ✅ Invalid node error handling works correctly")

      {:ok, _} ->
        IO.puts("  ⚠️  Expected error for invalid node but got success")
    end
  end

  defp test_concurrent_operations(client) do
    IO.puts("\n🔍 Test 10: Concurrent Operations")

    # Test concurrent API calls
    tasks =
      [
        fn -> SimulatedPvex.Client.get(client, "/version") end,
        fn -> SimulatedPvex.Resources.Cluster.status(client) end,
        fn -> SimulatedPvex.Resources.VMs.list(client) end,
        fn -> SimulatedPvex.Resources.Storage.list(client) end,
        fn -> SimulatedPvex.Resources.ResourcePools.list(client) end
      ]

    start_time = System.monotonic_time(:millisecond)

    results =
      tasks
      |> Enum.map(&Task.async/1)
      |> Enum.map(&Task.await/1)

    end_time = System.monotonic_time(:millisecond)
    duration = end_time - start_time

    successful_requests = Enum.count(results, fn
      {:ok, _} -> true
      _ -> false
    end)

    IO.puts("  ✅ Concurrent operations: #{successful_requests}/#{length(tasks)} successful")
    IO.puts("  ✅ Execution time: #{duration}ms")

    if successful_requests == length(tasks) do
      IO.puts("  ✅ All concurrent requests handled correctly")
    else
      IO.puts("  ⚠️  Some concurrent requests failed")
    end
  end

  # Utility functions

  defp count_resources_by_type(resources) do
    resources
    |> Enum.group_by(fn resource -> resource["type"] end)
    |> Enum.map(fn {type, items} -> {type, length(items)} end)
    |> Enum.sort()
  end

  defp count_content_by_type(content) do
    content
    |> Enum.group_by(fn item -> item["content"] end)
    |> Enum.map(fn {type, items} -> {type, length(items)} end)
    |> Enum.sort()
  end

  defp version_at_least?(version, min_version) do
    version_parts = parse_version(version)
    min_version_parts = parse_version(min_version)

    case {version_parts, min_version_parts} do
      {[major, minor | _], [min_major, min_minor | _]} ->
        cond do
          major > min_major -> true
          major == min_major and minor >= min_minor -> true
          true -> false
        end

      _ ->
        false
    end
  end

  defp parse_version(version) when is_binary(version) do
    version
    |> String.split(".")
    |> Enum.map(&String.to_integer/1)
  catch
    _, _ -> [0, 0]
  end
end

# ExUnit-style test module for structured testing
defmodule PvexIntegrationTest do
  @moduledoc """
  ExUnit-style test module demonstrating how to structure pvex tests
  with the Mock PVE API Server.
  """

  # This would be `use ExUnit.Case` in real testing
  def run_structured_tests do
    IO.puts("\n" <> String.duplicate("=", 55))
    IO.puts("🧪 Running structured integration tests...")

    try do
      setup_test()
      test_basic_connectivity()
      test_resource_management()
      test_version_compatibility()
      test_error_conditions()
      test_state_management()

      IO.puts("✅ All structured tests passed!")
    rescue
      error ->
        IO.puts("❌ Structured test failed: #{inspect(error)}")
        reraise error, __STACKTRACE__
    end
  end

  defp setup_test do
    config = %SimulatedPvex.Config{
      host: "localhost",
      port: 8006
    }

    {:ok, client} = SimulatedPvex.Client.new(config)
    Process.put(:test_client, client)
    IO.puts("  🔧 Test setup completed")
  end

  defp test_basic_connectivity do
    client = Process.get(:test_client)

    assert {:ok, %{"data" => _}} = SimulatedPvex.Client.get(client, "/version")
    assert {:ok, %{"data" => _}} = SimulatedPvex.Resources.Cluster.status(client)

    IO.puts("  ✅ Basic connectivity test passed")
  end

  defp test_resource_management do
    client = Process.get(:test_client)

    # Test VM resource management
    assert {:ok, %{"data" => vms}} = SimulatedPvex.Resources.VMs.list(client)
    assert is_list(vms)

    if length(vms) > 0 do
      vm = hd(vms)
      assert is_map(vm)
      assert Map.has_key?(vm, "vmid")
      assert Map.has_key?(vm, "name")
      assert Map.has_key?(vm, "status")
    end

    # Test storage resource management
    assert {:ok, %{"data" => storages}} = SimulatedPvex.Resources.Storage.list(client)
    assert is_list(storages)

    IO.puts("  ✅ Resource management test passed")
  end

  defp test_version_compatibility do
    client = Process.get(:test_client)

    {:ok, %{"data" => version_data}} = SimulatedPvex.Client.get(client, "/version")
    version = version_data["version"]

    # Test version-specific features
    case version do
      "7." <> _ ->
        # Test PVE 7.x specific behavior
        case SimulatedPvex.Resources.SDN.list_zones(client) do
          {:error, {501, _}} -> :ok  # Expected for PVE 7.x
          _ -> raise "Expected 501 error for SDN in PVE 7.x"
        end

      "8." <> _ ->
        # Test PVE 8.x specific behavior
        case SimulatedPvex.Resources.SDN.list_zones(client) do
          {:ok, _} -> :ok  # Expected for PVE 8.x
          {:error, {501, _}} -> :ok  # Also acceptable if not implemented
          error -> raise "Unexpected SDN error in PVE 8.x: #{inspect(error)}"
        end

      _ ->
        IO.puts("  ⚠️  Unknown PVE version: #{version}")
    end

    IO.puts("  ✅ Version compatibility test passed")
  end

  defp test_error_conditions do
    client = Process.get(:test_client)

    # Test 404 error
    assert {:error, {404, _}} = SimulatedPvex.Client.get(client, "/invalid/endpoint")

    # Test invalid resource access
    case SimulatedPvex.Resources.VMs.get(client, node: "invalid-node", vmid: 999) do
      {:error, _} -> :ok  # Expected error
      {:ok, _} -> raise "Expected error for invalid node/VM combination"
    end

    IO.puts("  ✅ Error conditions test passed")
  end

  defp test_state_management do
    client = Process.get(:test_client)

    # Test that state is consistent across calls
    {:ok, %{"data" => vms1}} = SimulatedPvex.Resources.VMs.list(client)
    {:ok, %{"data" => vms2}} = SimulatedPvex.Resources.VMs.list(client)

    # Should get same VMs (assuming no modifications)
    vm_ids1 = Enum.map(vms1, & &1["vmid"]) |> Enum.sort()
    vm_ids2 = Enum.map(vms2, & &1["vmid"]) |> Enum.sort()

    if vm_ids1 != vm_ids2 do
      IO.puts("  ⚠️  VM list changed between calls: #{inspect(vm_ids1)} vs #{inspect(vm_ids2)}")
    else
      IO.puts("  ✅ State management test passed")
    end
  end

  # Simple assertion function
  defp assert({:ok, _} = result), do: result
  defp assert({:error, _}), do: raise("Assertion failed: expected success")
  defp assert(true), do: :ok
  defp assert(false), do: raise("Assertion failed")

  defp assert({:error, {status, _}} = result, {:error, {status, _}}), do: result

  defp assert(actual, expected) when actual == expected, do: actual
  defp assert(actual, expected), do: raise("Assertion failed: #{inspect(actual)} != #{inspect(expected)}")
end

# Main execution
case System.argv() do
  ["--structured"] ->
    PvexIntegrationTest.run_structured_tests()

  ["--help"] ->
    IO.puts("""
    pvex Integration Example with Mock PVE API Server

    Usage:
      elixir pvex_integration.exs [options]

    Options:
      --structured    Run structured ExUnit-style tests
      --help         Show this help message

    Environment Variables:
      EMBEDDED_MOCK=true    Use embedded mock server (requires mock_pve_api dependency)

    Examples:
      # Use external mock server (Docker)
      podman run -d -p 8006:8006 -e MOCK_PVE_VERSION=8.0 docker.io/jrjsmrtn/mock-pve-api:latest
      elixir pvex_integration.exs

      # Run structured tests
      elixir pvex_integration.exs --structured

      # Use embedded mock (development)
      EMBEDDED_MOCK=true elixir pvex_integration.exs
    """)

  _ ->
    MockPveIntegrationExample.main()
end