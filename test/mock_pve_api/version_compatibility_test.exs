# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

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

  # Use the port from test config (config/test.exs) — the app is already running there
  @test_port Application.compile_env(:mock_pve_api, :port, 8007)

  # Test against multiple PVE versions with their expected capabilities.
  # SDN zones exist since 7.0 per pve-openapi specs (they were added to the API docs early).
  # Notifications were added in 8.1. SDN fabrics in 9.0.
  @test_versions [
    {"7.0", [:basic, :sdn]},
    {"7.4", [:basic, :ceph_pacific, :sdn]},
    {"8.0", [:basic, :ceph_pacific, :sdn, :cgroupv2]},
    {"8.1", [:basic, :ceph_pacific, :sdn, :cgroupv2, :notifications]},
    {"8.2",
     [:basic, :ceph_pacific, :sdn, :cgroupv2, :notifications, :backup_providers, :vmware_import]},
    {"8.3",
     [:basic, :ceph_pacific, :sdn, :cgroupv2, :notifications, :backup_providers, :vmware_import]}
  ]

  setup do
    on_exit(fn -> TestHelper.stop_server() end)
    :ok
  end

  describe "version detection and compatibility" do
    for {version, _expected_capabilities} <- @test_versions do
      test "PVE #{version} returns correct version info" do
        {:ok, _pid} =
          TestHelper.start_server(port: @test_port, pve_version: unquote(version))

        :ok = TestHelper.wait_for_server("127.0.0.1", @test_port, timeout: 5_000)

        # Test version endpoint
        {:ok, response} = http_get("http://127.0.0.1:#{@test_port}/api2/json/version")

        assert response["data"]["version"] =~ unquote(version)
        assert response["data"]["release"] != nil
        assert response["data"]["repoid"] != nil
      end
    end
  end

  describe "version-specific feature availability" do
    for {version, expected_capabilities} <- @test_versions do
      test "PVE #{version} correctly implements feature availability" do
        {:ok, _pid} =
          TestHelper.start_server(port: @test_port, pve_version: unquote(version))

        :ok = TestHelper.wait_for_server("127.0.0.1", @test_port, timeout: 5_000)

        base_url = "http://127.0.0.1:#{@test_port}/api2/json"

        # Test SDN endpoints (available in PVE 8.0+)
        if :sdn in unquote(expected_capabilities) do
          {:ok, zones_response} = http_get("#{base_url}/cluster/sdn/zones")
          assert is_list(zones_response["data"])

          {:ok, vnets_response} = http_get("#{base_url}/cluster/sdn/vnets")
          assert is_list(vnets_response["data"])
        else
          {:error, {501, _}} = http_get("#{base_url}/cluster/sdn/zones")
          {:error, {501, _}} = http_get("#{base_url}/cluster/sdn/vnets")
        end

        # Test notification endpoints (available in PVE 8.1+)
        if :notifications in unquote(expected_capabilities) do
          {:ok, endpoints_response} = http_get("#{base_url}/cluster/notifications/endpoints")
          assert is_list(endpoints_response["data"])
        else
          {:error, {501, _}} = http_get("#{base_url}/cluster/notifications/endpoints")
        end

        # Backup-info/providers is not a real PVE API endpoint — skip version gating test.
        # Real backup endpoints (/cluster/backup) exist since 7.0 per pve-openapi specs.
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

      basic_endpoints = [
        "/version",
        "/nodes",
        "/cluster/status",
        "/cluster/resources",
        "/pools"
      ]

      # Test each version sequentially (State holds a single global version)
      for version <- versions_to_test do
        {:ok, _pid} =
          TestHelper.start_server(port: @test_port, pve_version: version)

        :ok = TestHelper.wait_for_server("127.0.0.1", @test_port, timeout: 5_000)

        base_url = "http://127.0.0.1:#{@test_port}/api2/json"

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
      {:ok, _pid} = TestHelper.start_server(port: @test_port, pve_version: "7.4")
      :ok = TestHelper.wait_for_server("127.0.0.1", @test_port, timeout: 5_000)

      base_url = "http://127.0.0.1:#{@test_port}/api2/json"

      # Test that PVE 7.4 properly rejects features added after 7.4
      # Notification endpoints were added in 8.1 per pve-openapi specs
      {:error, {501, error_response}} =
        http_get("#{base_url}/cluster/notifications/endpoints")

      assert is_map(error_response["errors"])
      message = error_response["errors"]["message"]
      assert is_binary(message)
      assert String.contains?(message, "7.4") or String.contains?(message, "not available")
    end

    test "mixed version feature calls handle gracefully" do
      {:ok, _pid} = TestHelper.start_server(port: @test_port, pve_version: "8.0")
      :ok = TestHelper.wait_for_server("127.0.0.1", @test_port, timeout: 5_000)

      base_url = "http://127.0.0.1:#{@test_port}/api2/json"

      # PVE 8.0 should have SDN zones (exist since 7.0) but not notifications (8.1+)
      {:ok, _response} = http_get("#{base_url}/cluster/sdn/zones")
      {:error, {501, _}} = http_get("#{base_url}/cluster/notifications/endpoints")
    end
  end

  describe "sequential multi-version testing" do
    test "multiple versions produce correct behavior when tested sequentially" do
      versions = ["7.4", "8.0", "8.3"]

      for version <- versions do
        {:ok, _pid} =
          TestHelper.start_server(port: @test_port, pve_version: version)

        :ok = TestHelper.wait_for_server("127.0.0.1", @test_port, timeout: 5_000)

        base_url = "http://127.0.0.1:#{@test_port}/api2/json"

        # Test version endpoint
        {:ok, response} = http_get("#{base_url}/version")
        assert response["data"]["version"] =~ version

        # SDN zones exist since 7.0 per pve-openapi; notifications since 8.1
        case version do
          "7.4" ->
            {:ok, _} = http_get("#{base_url}/cluster/sdn/zones")
            {:error, {501, _}} = http_get("#{base_url}/cluster/notifications/endpoints")

          "8.0" ->
            {:ok, _} = http_get("#{base_url}/cluster/sdn/zones")
            {:error, {501, _}} = http_get("#{base_url}/cluster/notifications/endpoints")

          "8.3" ->
            {:ok, _} = http_get("#{base_url}/cluster/sdn/zones")
            {:ok, _} = http_get("#{base_url}/cluster/notifications/endpoints")
        end
      end
    end
  end

  # Helper functions

  defp http_get(url) do
    headers = [{"authorization", "PVEAPIToken=test@pve!test=test-token-secret"}]

    case Finch.build(:get, url, headers)
         |> Finch.request(MockPveApi.Finch, receive_timeout: 10_000) do
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
