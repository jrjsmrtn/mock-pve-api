defmodule MockPveApi.VersionCompatibilityTest do
  @moduledoc """
  Version compatibility tests for the Mock PVE API Server.

  This test suite validates that the mock server correctly simulates different PVE versions
  and that version-specific features are available or properly return 501 errors based on
  the configured version.

  Originally ported from the pvex project where this functionality was battle-tested
  across 135+ integration tests with 100% pass rate.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.{TestHelper, Capabilities}

  @moduletag :version_compatibility

  # Test against multiple PVE versions with their expected capabilities
  @test_versions [
    {"7.0", [:basic]},
    {"7.4", [:basic, :ceph_pacific]},
    {"8.0", [:basic, :ceph_pacific, :sdn, :cgroupv2]},
    {"8.1", [:basic, :ceph_pacific, :sdn, :cgroupv2, :notifications]},
    {"8.2", [:basic, :ceph_pacific, :sdn, :cgroupv2, :notifications, :backup_providers, :vmware_import]},
    {"8.3", [:basic, :ceph_pacific, :sdn, :cgroupv2, :notifications, :backup_providers, :vmware_import]}
  ]

  describe "version detection and compatibility" do
    for {version, expected_capabilities} <- @test_versions do
      test "PVE #{version} returns correct version info and capabilities" do
        port = unique_port_for_version(unquote(version))
        
        # Start mock server with specific version
        {:ok, _pid} = TestHelper.start_server(port: port, pve_version: unquote(version))
        :ok = TestHelper.wait_for_server("127.0.0.1", port)

        on_exit(fn ->
          TestHelper.stop_server()
        end)

        # Test version endpoint
        {:ok, response} = http_get("http://127.0.0.1:#{port}/api2/json/version")
        
        assert response["data"]["version"] =~ unquote(version)
        assert response["data"]["release"] != nil
        assert response["data"]["repoid"] != nil

        # Verify capabilities match expected
        capabilities = response["data"]["capabilities"] || %{}
        expected_caps = unquote(expected_capabilities)

        # Check expected capabilities are present
        for capability <- expected_caps do
          capability_key = atom_to_capability_key(capability)
          assert capabilities[capability_key] == true, 
            "Expected capability #{capability_key} to be true for PVE #{unquote(version)}"
        end

        # Test that capabilities not in expected list are false or missing
        all_possible_caps = [:sdn, :backup_providers, :notifications, :vmware_import, :cgroupv2, :ceph_pacific]
        
        for capability <- all_possible_caps -- expected_caps do
          capability_key = atom_to_capability_key(capability)
          capability_value = capabilities[capability_key]
          
          # Should be false or missing (nil)
          assert capability_value != true,
            "Expected capability #{capability_key} to be false or missing for PVE #{unquote(version)}, got: #{inspect(capability_value)}"
        end
      end
    end
  end

  describe "version-specific feature availability" do
    for {version, expected_capabilities} <- @test_versions do
      test "PVE #{version} correctly implements feature availability" do
        port = unique_port_for_version(unquote(version))
        
        {:ok, _pid} = TestHelper.start_server(port: port, pve_version: unquote(version))
        :ok = TestHelper.wait_for_server("127.0.0.1", port)

        on_exit(fn ->
          TestHelper.stop_server()
        end)

        base_url = "http://127.0.0.1:#{port}/api2/json"

        # Test SDN endpoints (available in PVE 8.0+)
        if :sdn in unquote(expected_capabilities) do
          # SDN should be available
          {:ok, zones_response} = http_get("#{base_url}/cluster/sdn/zones")
          assert is_list(zones_response["data"])

          {:ok, vnets_response} = http_get("#{base_url}/cluster/sdn/vnets")  
          assert is_list(vnets_response["data"])
        else
          # SDN should return 501
          {:error, {501, error_response}} = http_get("#{base_url}/cluster/sdn/zones")
          assert is_list(error_response["errors"])
          assert Enum.any?(error_response["errors"], &String.contains?(&1, "SDN"))

          {:error, {501, error_response}} = http_get("#{base_url}/cluster/sdn/vnets")
          assert is_list(error_response["errors"])
          assert Enum.any?(error_response["errors"], &String.contains?(&1, "SDN"))
        end

        # Test notification endpoints (available in PVE 8.1+)
        if :notifications in unquote(expected_capabilities) do
          # Notifications should be available
          {:ok, endpoints_response} = http_get("#{base_url}/cluster/notifications/endpoints")
          assert is_list(endpoints_response["data"])
        else
          # Notifications should return 501
          {:error, {501, error_response}} = http_get("#{base_url}/cluster/notifications/endpoints")
          assert is_list(error_response["errors"])
          assert Enum.any?(error_response["errors"], &String.contains?(&1, "notification"))
        end

        # Test backup provider endpoints (available in PVE 8.2+)
        if :backup_providers in unquote(expected_capabilities) do
          # Backup providers should be available
          {:ok, providers_response} = http_get("#{base_url}/cluster/backup-info/providers")
          assert is_list(providers_response["data"])
        else
          # Backup providers should return 501
          {:error, {501, error_response}} = http_get("#{base_url}/cluster/backup-info/providers")
          assert is_list(error_response["errors"])
          assert Enum.any?(error_response["errors"], fn error ->
            String.contains?(error, "backup") or String.contains?(error, "provider")
          end)
        end
      end
    end
  end

  describe "version comparison logic" do
    test "capabilities system correctly determines version support" do
      # Test various version comparison scenarios
      assert Capabilities.version_supports?("8.0", :sdn_tech_preview) == true
      assert Capabilities.version_supports?("7.4", :sdn_tech_preview) == false
      assert Capabilities.version_supports?("8.1", :notification_endpoints) == true
      assert Capabilities.version_supports?("8.0", :notification_endpoints) == false
      assert Capabilities.version_supports?("8.2", :backup_providers) == true
      assert Capabilities.version_supports?("8.1", :backup_providers) == false
    end

    test "edge case versions are handled correctly" do
      # Test edge cases
      assert Capabilities.version_supports?("7.4.1", :sdn_tech_preview) == false
      assert Capabilities.version_supports?("8.0-rc1", :sdn_tech_preview) == true
      assert Capabilities.version_supports?("8.1.0", :notification_endpoints) == true
      assert Capabilities.version_supports?("9.0", :sdn_stable) == true
      assert Capabilities.version_supports?("9.0", :notification_endpoints) == true
      assert Capabilities.version_supports?("9.0", :backup_providers) == true
    end
  end

  describe "cross-version API consistency" do
    test "basic endpoints work across all versions" do
      versions_to_test = ["7.4", "8.0", "8.3"]
      
      # Start multiple servers for concurrent testing
      servers = Enum.map(versions_to_test, fn version ->
        port = unique_port_for_version(version)
        {:ok, _pid} = TestHelper.start_server(port: port, pve_version: version)
        :ok = TestHelper.wait_for_server("127.0.0.1", port)
        
        {version, port}
      end)

      on_exit(fn ->
        TestHelper.stop_server()
      end)

      # Test that basic endpoints work consistently across versions
      basic_endpoints = [
        "/version",
        "/nodes",
        "/cluster/status",
        "/cluster/resources",
        "/pools"
      ]

      for {version, port} <- servers do
        base_url = "http://127.0.0.1:#{port}/api2/json"
        
        for endpoint <- basic_endpoints do
          {:ok, response} = http_get("#{base_url}#{endpoint}")
          assert is_map(response)
          assert Map.has_key?(response, "data")
          
          # Version endpoint should return the correct version
          if endpoint == "/version" do
            assert response["data"]["version"] =~ version
          end
        end
      end
    end
  end

  describe "feature degradation and error handling" do
    test "unsupported features return proper 501 errors with descriptive messages" do
      port = unique_port_for_version("7.4")
      
      {:ok, _pid} = TestHelper.start_server(port: port, pve_version: "7.4")
      :ok = TestHelper.wait_for_server("127.0.0.1", port)

      on_exit(fn ->
        TestHelper.stop_server()
      end)

      base_url = "http://127.0.0.1:#{port}/api2/json"

      # Test that PVE 7.4 properly rejects 8.x features
      unsupported_endpoints = [
        "/cluster/sdn/zones",
        "/cluster/sdn/vnets",
        "/cluster/notifications/endpoints",
        "/cluster/backup-info/providers"
      ]

      for endpoint <- unsupported_endpoints do
        {:error, {501, error_response}} = http_get("#{base_url}#{endpoint}")
        
        # Should have errors array
        assert is_list(error_response["errors"])
        assert length(error_response["errors"]) > 0
        
        # Should mention the feature and version requirement
        error_message = Enum.join(error_response["errors"], " ")
        assert String.contains?(error_message, "7.4") or String.contains?(error_message, "not implemented")
      end
    end

    test "mixed version feature calls handle gracefully" do
      port = unique_port_for_version("8.0")
      
      {:ok, _pid} = TestHelper.start_server(port: port, pve_version: "8.0")
      :ok = TestHelper.wait_for_server("127.0.0.1", port)

      on_exit(fn ->
        TestHelper.stop_server()
      end)

      base_url = "http://127.0.0.1:#{port}/api2/json"

      # PVE 8.0 should have SDN but not notifications or backup providers
      {:ok, _response} = http_get("#{base_url}/cluster/sdn/zones")  # Should work
      {:error, {501, _}} = http_get("#{base_url}/cluster/notifications/endpoints")  # Should fail
      {:error, {501, _}} = http_get("#{base_url}/cluster/backup-info/providers")  # Should fail
    end
  end

  describe "concurrent version testing" do
    @tag :concurrent
    test "multiple versions can run simultaneously without interference" do
      versions = ["7.4", "8.0", "8.3"]
      
      # Start multiple servers concurrently
      servers = Enum.map(versions, fn version ->
        port = unique_port_for_version(version)
        {:ok, _pid} = TestHelper.start_server(port: port, pve_version: version)
        {version, port}
      end)

      # Wait for all servers to be ready
      for {_version, port} <- servers do
        :ok = TestHelper.wait_for_server("127.0.0.1", port)
      end

      on_exit(fn ->
        TestHelper.stop_server()
      end)

      # Test all servers concurrently
      tasks = Enum.map(servers, fn {version, port} ->
        Task.async(fn ->
          base_url = "http://127.0.0.1:#{port}/api2/json"
          
          # Test version endpoint
          {:ok, response} = http_get("#{base_url}/version")
          assert response["data"]["version"] =~ version
          
          # Test version-specific features
          case version do
            "7.4" ->
              {:error, {501, _}} = http_get("#{base_url}/cluster/sdn/zones")
              
            "8.0" ->
              {:ok, _} = http_get("#{base_url}/cluster/sdn/zones")
              {:error, {501, _}} = http_get("#{base_url}/cluster/notifications/endpoints")
              
            "8.3" ->
              {:ok, _} = http_get("#{base_url}/cluster/sdn/zones")
              {:ok, _} = http_get("#{base_url}/cluster/notifications/endpoints")
              {:ok, _} = http_get("#{base_url}/cluster/backup-info/providers")
          end
          
          {version, :success}
        end)
      end)

      # Wait for all tasks to complete
      results = Enum.map(tasks, &Task.await(&1, 30_000))
      
      # Verify all tests passed
      for {version, result} <- results do
        assert result == :success, "Concurrent test failed for version #{version}"
      end
    end
  end

  # Helper functions

  defp unique_port_for_version(version) do
    # Generate unique port based on version to avoid conflicts
    # Base port 19000 + version hash
    base_port = 19000
    version_hash = :crypto.hash(:md5, version) |> :binary.decode_unsigned() |> rem(100)
    base_port + version_hash
  end

  defp atom_to_capability_key(atom) do
    case atom do
      :sdn -> "sdn"
      :backup_providers -> "backup_providers"
      :notifications -> "notifications"
      :vmware_import -> "vmware_import"
      :cgroupv2 -> "cgroupv2"
      :ceph_pacific -> "ceph_pacific"
      _ -> Atom.to_string(atom)
    end
  end

  defp http_get(url) do
    case Finch.build(:get, url) |> Finch.request(MockPveHttp, receive_timeout: 10_000) do
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