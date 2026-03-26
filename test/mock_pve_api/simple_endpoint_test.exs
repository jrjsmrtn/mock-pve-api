# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.SimpleEndpointTest do
  @moduledoc """
  Simple endpoint validation that uses the existing server on port 8006.

  This test validates all implemented endpoints by making HTTP requests to a running
  mock server instance, avoiding the complexity of starting multiple test servers.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.Coverage

  @moduletag :simple_endpoint_validation
  @base_url "http://127.0.0.1:#{Application.compile_env(:mock_pve_api, :port, 8007)}/api2/json"

  describe "endpoint availability validation" do
    test "validates all implemented endpoints are accessible" do
      # Ensure server is running
      case http_get("#{@base_url}/version") do
        {:ok, _} ->
          :ok

        {:error, _} ->
          flunk("Mock PVE API server must be running on port 8006. Run: mix run --no-halt")
      end

      # Get only implemented endpoints from coverage matrix
      all_endpoints = get_implemented_endpoints()
      count = length(all_endpoints)

      assert count >= 37,
             "Expected at least 37 implemented endpoints, found #{count}"

      IO.puts("\n=== TESTING #{count} IMPLEMENTED ENDPOINTS ===")

      # Test each endpoint
      results =
        for endpoint <- all_endpoints do
          test_endpoint(endpoint)
        end

      # Count results
      successes = Enum.count(results, &(elem(&1, 0) == :ok))
      version_incompatible = Enum.count(results, &(elem(&1, 0) == :version_incompatible))
      failures = Enum.count(results, &(elem(&1, 0) == :error))

      IO.puts("Results:")
      IO.puts("  ✅ Successful: #{successes}")
      IO.puts("  🔄 Version Incompatible: #{version_incompatible}")
      IO.puts("  ❌ Failed: #{failures}")

      # Show failures
      if failures > 0 do
        IO.puts("\nFAILURES:")

        for {status, path, reason} <- results, status == :error do
          IO.puts("  - #{path}: #{reason}")
        end
      end

      # Assert high success rate
      total_valid = successes + version_incompatible
      success_rate = total_valid / length(all_endpoints) * 100

      assert success_rate >= 90.0,
             "Success rate too low: #{Float.round(success_rate, 1)}%"
    end

    test "validates HTTP methods for core endpoints" do
      # Test key endpoints with their expected methods
      endpoint_method_tests = [
        {"/version", [:get]},
        {"/nodes", [:get]},
        {"/cluster/status", [:get]},
        {"/cluster/resources", [:get]},
        {"/pools", [:get, :post]},
        {"/access/users", [:get, :post]},
        {"/access/tickets", [:post]}
      ]

      for {path, expected_methods} <- endpoint_method_tests do
        for method <- expected_methods do
          result = http_request(method, "#{@base_url}#{path}")

          # Should not return 405 (Method Not Allowed) for expected methods
          assert not match?({:error, {405, _}}, result),
                 "Expected method #{method} should be allowed for #{path}"
        end

        # Test that unsupported methods return 405
        all_methods = [:get, :post, :put, :delete, :patch]
        unsupported_methods = all_methods -- expected_methods

        for method <- unsupported_methods do
          result = http_request(method, "#{@base_url}#{path}")

          # Should return 405 for unsupported methods (or other error, but not success)
          refute match?({:ok, _}, result),
                 "Unsupported method #{method} should not succeed for #{path}"
        end
      end
    end

    test "validates response format consistency" do
      # Test key endpoints for consistent response format
      test_endpoints = [
        "/version",
        "/nodes",
        "/cluster/status",
        "/cluster/resources",
        "/pools"
      ]

      for path <- test_endpoints do
        case http_get("#{@base_url}#{path}") do
          {:ok, response} ->
            assert is_map(response), "Response should be a map for #{path}"
            assert Map.has_key?(response, "data"), "Response should have 'data' field for #{path}"

          {:error, {status, _}} when status in [501, 401, 403] ->
            # These are acceptable - endpoint may not be available or need auth
            :ok

          {:error, reason} ->
            flunk("Unexpected error for #{path}: #{inspect(reason)}")
        end
      end
    end

    test "validates version-specific endpoint behavior" do
      # Get server version
      {:ok, version_response} = http_get("#{@base_url}/version")
      server_version = version_response["data"]["version"]

      IO.puts("Testing version-specific behavior for PVE #{server_version}")

      # Test SDN endpoints (available since PVE 7.0 as tech preview)
      sdn_result = http_get("#{@base_url}/cluster/sdn/zones")

      if version_supports_sdn?(server_version) do
        # For PVE 7.0+, SDN should either work or return acceptable errors (not 501)
        refute match?({:error, {501, _}}, sdn_result),
               "SDN should not return 501 in PVE #{server_version}"
      else
        assert match?({:error, {501, _}}, sdn_result),
               "SDN should return 501 in PVE #{server_version}"
      end

      # Test notification endpoints (should work on PVE 8.1+)
      notification_result = http_get("#{@base_url}/cluster/notifications/endpoints")

      if version_supports_notifications?(server_version) do
        # For PVE 8.1+, notifications should either work or return acceptable errors (not 501)
        refute match?({:error, {501, _}}, notification_result),
               "Notifications should not return 501 in PVE #{server_version}"
      else
        # For PVE 8.0 and below, notifications may or may not return 501, so we'll be lenient
        case notification_result do
          # Expected 501
          {:error, {501, _}} -> :ok
          # Maybe implemented anyway
          {:ok, _} -> :ok
          # Other errors are acceptable
          _ -> :ok
        end
      end

      # Test backup providers (should work on PVE 8.2+)
      backup_result = http_get("#{@base_url}/cluster/backup-info/providers")

      if version_supports_backup_providers?(server_version) do
        # For PVE 8.2+, backup providers should either work or return acceptable errors (not 501)
        refute match?({:error, {501, _}}, backup_result),
               "Backup providers should not return 501 in PVE #{server_version}"
      else
        # For earlier versions, we'll be lenient about the response
        case backup_result do
          # Expected 501
          {:error, {501, _}} -> :ok
          # Maybe implemented anyway
          {:ok, _} -> :ok
          # Other errors are acceptable
          _ -> :ok
        end
      end
    end
  end

  # Helper Functions

  defp resolve_path_parameters(path) do
    path
    |> String.replace("{node}", "pve1")
    |> String.replace("{vmid}", "100")
    |> String.replace("{storage}", "local")
    |> String.replace("{poolid}", "test-pool")
    |> String.replace("{userid}", "test@pve")
    |> String.replace("{groupid}", "test-group")
    |> String.replace("{tokenid}", "test-token")
    |> String.replace("{zone}", "test-zone")
    |> String.replace("{snapname}", "test-snap")
    |> String.replace("{sid}", "vm:100")
    |> String.replace("{rule}", "rule-1")
    |> String.replace("{command}", "start")
    |> String.replace("{action}", "start")
    |> String.replace("{realm}", "pam")
    |> String.replace("{roleid}", "Administrator")
    |> String.replace("{id}", "test-id")
    |> String.replace("{upid}", "UPID:pve1:00000001:00000000:00000000:test:0:root@pam:")
    |> String.replace("{pos}", "0")
    |> String.replace("{group}", "test-group")
    |> String.replace("{name}", "test-name")
    |> String.replace("{vnet}", "test-vnet")
    |> String.replace("{subnet}", "10.0.0.0-24")
    |> String.replace("{controller}", "test-ctrl")
    |> String.replace("{cidr}", "10.0.0.0-24")
    |> String.replace("{volume}", "local:iso/test.iso")
    |> String.replace("{iface}", "eth0")
    |> String.replace("{pciid}", "0000:00:00.0")
    |> String.replace("{service}", "pvedaemon")
  end

  defp get_all_endpoints do
    Coverage.get_categories()
    |> Enum.flat_map(&Coverage.get_category_endpoints/1)
    |> Enum.sort_by(& &1.path)
  end

  defp get_implemented_endpoints do
    get_all_endpoints()
    |> Enum.filter(&(&1.status == :implemented))
  end

  defp test_endpoint(endpoint) do
    # Test the primary method (usually GET)
    primary_method = if :get in endpoint.methods, do: :get, else: hd(endpoint.methods)

    # Convert parameterized paths to concrete paths
    test_path = resolve_path_parameters(endpoint.path)

    # Remove /api2/json prefix from path since base_url already includes it
    clean_path = String.replace_prefix(test_path, "/api2/json", "")

    case http_request(primary_method, "#{@base_url}#{clean_path}") do
      {:ok, response} ->
        if is_map(response) and Map.has_key?(response, "data") do
          {:ok, endpoint.path, "Valid response"}
        else
          {:error, endpoint.path, "Invalid response format"}
        end

      {:error, {status, _}} when status in [400, 401, 403, 404, 422] ->
        # These are acceptable - endpoint may need parameters, permissions, or resource doesn't exist
        {:ok, endpoint.path, "Expected error (#{status})"}

      {:error, {501, _}} ->
        # Feature not implemented - this is expected for some version-specific endpoints
        {:version_incompatible, endpoint.path, "501 Not Implemented"}

      {:error, {405, _}} ->
        {:error, endpoint.path, "Method Not Allowed for declared method"}

      {:error, reason} ->
        {:error, endpoint.path, "HTTP error: #{inspect(reason)}"}
    end
  end

  defp version_supports_sdn?(version) do
    case Version.compare(version, "7.0.0") do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  rescue
    _ ->
      String.starts_with?(version, "7.") or String.starts_with?(version, "8.") or
        String.starts_with?(version, "9.")
  end

  defp version_supports_notifications?(version) do
    case Version.compare(version, "8.1.0") do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  rescue
    _ ->
      String.starts_with?(version, "8.1") or
        String.starts_with?(version, "8.2") or
        String.starts_with?(version, "8.3") or
        String.starts_with?(version, "9.")
  end

  defp version_supports_backup_providers?(version) do
    case Version.compare(version, "8.2.0") do
      :gt -> true
      :eq -> true
      :lt -> false
    end
  rescue
    _ ->
      String.starts_with?(version, "8.2") or
        String.starts_with?(version, "8.3") or
        String.starts_with?(version, "9.")
  end

  defp http_get(url) do
    http_request(:get, url)
  end

  defp http_request(method, url) do
    case Finch.build(method, url) |> Finch.request(MockPveApi.Finch, receive_timeout: 10_000) do
      {:ok, %Finch.Response{status: 200, body: body}} ->
        case Jason.decode(body) do
          {:ok, json} -> {:ok, json}
          {:error, reason} -> {:error, {:json_decode_error, reason}}
        end

      {:ok, %Finch.Response{status: status, body: body}} when status >= 400 ->
        case Jason.decode(body) do
          {:ok, json} -> {:error, {status, json}}
          {:error, _} -> {:error, {status, body}}
        end

      {:error, reason} ->
        {:error, {:http_error, reason}}
    end
  end
end
