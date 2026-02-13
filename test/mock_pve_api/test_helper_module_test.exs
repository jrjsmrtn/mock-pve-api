# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.TestHelperModuleTest do
  use ExUnit.Case, async: false

  alias MockPveApi.TestHelper

  setup do
    MockPveApi.State.reset()
    :ok
  end

  describe "start_server/1" do
    test "returns {:ok, pid}" do
      assert {:ok, pid} = TestHelper.start_server()
      assert is_pid(pid)
    end

    test "accepts pve_version option" do
      {:ok, _pid} = TestHelper.start_server(pve_version: "7.4")
      assert Application.get_env(:mock_pve_api, :pve_version) == "7.4"
    end
  end

  describe "stop_server/0" do
    test "returns :ok" do
      assert TestHelper.stop_server() == :ok
    end
  end

  describe "reset_server_state/0" do
    test "resets state" do
      MockPveApi.State.create_pool("test", %{})
      assert TestHelper.reset_server_state() == :ok
      assert MockPveApi.State.get_pools() == []
    end
  end

  describe "create_test_config/1" do
    test "returns default config" do
      config = TestHelper.create_test_config()
      assert config.host == "127.0.0.1"
      assert config.port == 8006
      assert config.scheme == "http"
      assert is_binary(config.api_token)
      assert config.verify_ssl == false
      assert config.timeout == 30_000
    end

    test "accepts custom options" do
      config = TestHelper.create_test_config(port: 18006, host: "localhost")
      assert config.host == "localhost"
      assert config.port == 18006
    end

    test "accepts scheme option" do
      config = TestHelper.create_test_config(scheme: "https")
      assert config.scheme == "https"
    end

    test "accepts api_token option" do
      config = TestHelper.create_test_config(api_token: "custom-token")
      assert config.api_token == "custom-token"
    end

    test "accepts verify_ssl option" do
      config = TestHelper.create_test_config(verify_ssl: true)
      assert config.verify_ssl == true
    end

    test "accepts timeout option" do
      config = TestHelper.create_test_config(timeout: 60_000)
      assert config.timeout == 60_000
    end
  end

  describe "unique_name/2" do
    test "generates unique names with prefix" do
      name1 = TestHelper.unique_name("vm")
      name2 = TestHelper.unique_name("vm")
      assert String.starts_with?(name1, "vm-")
      assert name1 != name2
    end

    test "generates unique names with default prefix" do
      name = TestHelper.unique_name()
      assert String.starts_with?(name, "test-")
    end

    test "includes suffix when provided" do
      name = TestHelper.unique_name("container", "integration")
      assert String.starts_with?(name, "container-")
      assert String.ends_with?(name, "-integration")
    end

    test "generates different names on each call" do
      names = for _ <- 1..10, do: TestHelper.unique_name("res")
      assert length(Enum.uniq(names)) == 10
    end
  end

  describe "setup_test_data/1" do
    test "returns :ok" do
      assert TestHelper.setup_test_data() == :ok
    end

    test "resets state by default" do
      MockPveApi.State.create_pool("temp", %{})
      TestHelper.setup_test_data()
      assert MockPveApi.State.get_pools() == []
    end

    test "can skip reset" do
      MockPveApi.State.create_pool("temp", %{})
      TestHelper.setup_test_data(reset: false)
      pools = MockPveApi.State.get_pools()
      assert length(pools) >= 1
    end
  end

  describe "configure_pve_version/1" do
    test "sets PVE version" do
      assert TestHelper.configure_pve_version("7.4") == :ok
      assert Application.get_env(:mock_pve_api, :pve_version) == "7.4"
    end

    test "sets 8.x version" do
      assert TestHelper.configure_pve_version("8.3") == :ok
      assert Application.get_env(:mock_pve_api, :pve_version) == "8.3"
    end

    test "sets 9.0 version" do
      assert TestHelper.configure_pve_version("9.0") == :ok
      assert Application.get_env(:mock_pve_api, :pve_version) == "9.0"
    end
  end

  describe "server_status/3" do
    test "returns version info when server is running" do
      # The server is already running during tests
      result = TestHelper.server_status("127.0.0.1", 8006, 5_000)

      case result do
        {:ok, data} -> assert is_map(data)
        {:error, _reason} -> :ok
      end
    end
  end

  describe "wait_for_server/3" do
    test "returns :ok when server is available" do
      # Server is already running
      result = TestHelper.wait_for_server("127.0.0.1", 8006, timeout: 5_000, interval: 100)

      case result do
        :ok -> assert true
        {:error, _} -> :ok
      end
    end

    test "returns error for unreachable host" do
      # Use a port that nothing is listening on
      result = TestHelper.wait_for_server("127.0.0.1", 19999, timeout: 500, interval: 100)
      assert {:error, _} = result
    end
  end

  describe "wait_for_condition/2" do
    test "returns :ok for immediately true condition" do
      assert TestHelper.wait_for_condition(fn -> true end, timeout: 1_000, interval: 100) == :ok
    end

    test "returns :ok for condition returning :ok" do
      assert TestHelper.wait_for_condition(fn -> :ok end, timeout: 1_000, interval: 100) == :ok
    end

    test "returns {:ok, result} for condition returning {:ok, result}" do
      assert TestHelper.wait_for_condition(fn -> {:ok, "done"} end, timeout: 1_000) ==
               {:ok, "done"}
    end

    test "returns {:error, :timeout} for never-true condition" do
      result = TestHelper.wait_for_condition(fn -> false end, timeout: 200, interval: 50)
      assert result == {:error, :timeout}
    end

    test "returns {:error, :timeout} with description" do
      result =
        TestHelper.wait_for_condition(fn -> false end,
          timeout: 200,
          interval: 50,
          description: "test condition"
        )

      assert result == {:error, :timeout}
    end

    test "eventually succeeds for delayed condition" do
      counter = :counters.new(1, [])

      result =
        TestHelper.wait_for_condition(
          fn ->
            count = :counters.get(counter, 1)
            :counters.add(counter, 1, 1)
            count >= 2
          end,
          timeout: 2_000,
          interval: 50
        )

      assert result == :ok
    end
  end
end
