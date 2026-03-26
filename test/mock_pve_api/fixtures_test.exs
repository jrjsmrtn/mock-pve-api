# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.FixturesTest do
  use ExUnit.Case, async: false

  alias MockPveApi.{Fixtures, State}

  setup do
    original_version = Application.get_env(:mock_pve_api, :pve_version, "8.0")
    State.reset()

    on_exit(fn ->
      Application.put_env(:mock_pve_api, :pve_version, original_version)
      State.reset()
    end)

    :ok
  end

  # --- cluster_resources/0 ---

  describe "cluster_resources/0" do
    test "returns base node resources" do
      resources = Fixtures.cluster_resources()
      assert length(resources) >= 2
      assert Enum.all?(resources, &is_map/1)

      node_resources = Enum.filter(resources, &(&1.type == "node"))
      assert length(node_resources) == 2
    end

    test "includes SDN resources for 8.x" do
      # Default version is 8.0 (from config), which has SDN
      version = State.get_pve_version()

      if String.starts_with?(version, "8.") do
        resources = Fixtures.cluster_resources()
        sdn_resources = Enum.filter(resources, &(&1.type == "sdn"))
        assert length(sdn_resources) >= 1
      end
    end
  end

  # --- node_status/1 ---

  describe "node_status/1" do
    test "returns base status fields" do
      status = Fixtures.node_status("pve-node1")
      assert status.node == "pve-node1"
      assert status.status == "online"
      assert is_map(status.memory)
      assert is_map(status.disk)
      assert is_list(status.loadavg)
      assert is_map(status.cpuinfo)
    end

    test "includes cgroup version based on PVE version" do
      status = Fixtures.node_status("pve-node1")
      version = State.get_pve_version()

      cond do
        String.starts_with?(version, "8.") ->
          assert status.cgroup == "v2"

        String.starts_with?(version, "7.") ->
          assert status.cgroup == "v1"

        true ->
          :ok
      end
    end
  end

  # --- storage_content/2 ---

  describe "storage_content/2" do
    test "returns ISO and backup content for local storage" do
      content = Fixtures.storage_content("local")
      assert length(content) >= 2
      types = Enum.map(content, & &1.content)
      assert "iso" in types
      assert "backup" in types
    end

    test "returns images content for local-lvm storage" do
      content = Fixtures.storage_content("local-lvm")
      assert length(content) == 1
      assert hd(content).content == "images"
    end

    test "returns empty list for unknown storage" do
      assert Fixtures.storage_content("nonexistent") == []
    end

    test "includes import content for 8.2+ on local storage" do
      content = Fixtures.storage_content("local", "8.2")
      import_items = Enum.filter(content, &(&1.content == "import"))
      assert length(import_items) == 1
    end

    test "no import content for 7.x on local storage" do
      content = Fixtures.storage_content("local", "7.4")
      import_items = Enum.filter(content, &(&1.content == "import"))
      assert import_items == []
    end
  end

  # --- sdn_zones/0 ---

  describe "sdn_zones/0" do
    test "returns SDN zone fixtures" do
      zones = Fixtures.sdn_zones()
      assert length(zones) == 2
      types = Enum.map(zones, & &1.type)
      assert "vlan" in types
      assert "simple" in types
    end
  end

  # --- notification_endpoints/0 ---

  describe "notification_endpoints/0" do
    test "returns notification endpoint fixtures" do
      endpoints = Fixtures.notification_endpoints()
      assert length(endpoints) == 2
      assert Enum.any?(endpoints, &(&1.type == "smtp"))
      assert Enum.any?(endpoints, &(&1.type == "gotify"))
    end
  end

  # --- backup_providers/0 ---

  describe "backup_providers/0" do
    test "returns backup provider fixtures" do
      providers = Fixtures.backup_providers()
      assert length(providers) == 2
      types = Enum.map(providers, & &1.type)
      assert "pbs" in types
      assert "s3" in types
    end
  end

  # --- pool_response/1 ---

  describe "pool_response/1" do
    test "returns pool data with version-specific fields" do
      pool = %{poolid: "test", comment: "Test pool"}
      response = Fixtures.pool_response(pool)
      assert response.poolid == "test"
    end
  end

  # --- task_response/2 ---

  describe "task_response/2" do
    test "returns base task structure" do
      task = Fixtures.task_response("qmstart")
      assert task.type == "qmstart"
      assert task.status == "running"
      assert is_binary(task.upid)
    end

    test "includes extra fields for 8.x" do
      task = Fixtures.task_response("qmstart", "8.0")
      assert Map.has_key?(task, :worker_id)
      assert Map.has_key?(task, :saved)
    end

    test "does not include extra fields for 7.x" do
      task = Fixtures.task_response("vzdump", "7.4")
      refute Map.has_key?(task, :worker_id)
      refute Map.has_key?(task, :saved)
    end

    test "includes extra fields for 8.3" do
      task = Fixtures.task_response("pctstart", "8.3")
      assert Map.has_key?(task, :worker_id)
    end
  end

  # --- node_status version branches ---

  describe "node_status/1 version branches" do
    test "returns cgroup v1 for PVE 7.x" do
      set_pve_version("7.4")
      status = Fixtures.node_status("pve-node1")
      assert status.cgroup == "v1"
      assert status.kversion == "5.15.108-1-pve"
    end

    test "returns cgroup v2 for PVE 8.0" do
      set_pve_version("8.0")
      status = Fixtures.node_status("pve-node1")
      assert status.cgroup == "v2"
      assert status.kversion == "6.2.16-15-pve"
    end

    test "returns correct kernel for 8.1" do
      set_pve_version("8.1")
      status = Fixtures.node_status("pve-node1")
      assert status.kversion == "6.5.11-7-pve"
    end

    test "returns correct kernel for 8.2" do
      set_pve_version("8.2")
      status = Fixtures.node_status("pve-node1")
      assert status.kversion == "6.8.4-2-pve"
    end

    test "returns correct kernel for 8.3" do
      set_pve_version("8.3")
      status = Fixtures.node_status("pve-node1")
      assert status.kversion == "6.8.12-1-pve"
    end

    test "returns default kernel for 9.x" do
      set_pve_version("9.0")
      status = Fixtures.node_status("pve-node1")
      assert is_binary(status.kversion)
    end

    test "returns base status for unknown version" do
      set_pve_version("9.0")
      status = Fixtures.node_status("pve-node1")
      assert status.node == "pve-node1"
    end
  end

  # --- pool_response version branches ---

  describe "pool_response/1 version branches" do
    test "adds enhanced fields for 8.x" do
      set_pve_version("8.0")
      pool = %{poolid: "prod", comment: "Production"}
      response = Fixtures.pool_response(pool)
      assert response.type == "pool"
      assert is_map(response.permissions)
      assert is_map(response.resource_limits)
    end

    test "returns plain pool data for 7.x" do
      set_pve_version("7.4")
      pool = %{poolid: "dev", comment: "Development"}
      response = Fixtures.pool_response(pool)
      assert response.poolid == "dev"
      refute Map.has_key?(response, :type)
    end
  end

  # --- storage_content version edge cases ---

  describe "storage_content/2 version edge cases" do
    test "no import content for 8.2+ on non-local storage" do
      content = Fixtures.storage_content("local-lvm", "8.2")
      import_items = Enum.filter(content, &(&1.content == "import"))
      assert import_items == []
    end

    test "no import content for 8.1 on local storage" do
      content = Fixtures.storage_content("local", "8.1")
      import_items = Enum.filter(content, &(&1.content == "import"))
      assert import_items == []
    end
  end

  # --- cluster_resources version branches ---

  describe "cluster_resources/0 version branches" do
    test "no SDN resources for 7.x" do
      set_pve_version("7.4")
      resources = Fixtures.cluster_resources()
      sdn_resources = Enum.filter(resources, &(&1.type == "sdn"))
      assert sdn_resources == []
    end
  end

  # Helper to set PVE version in both Application env and State GenServer
  defp set_pve_version(version) do
    Application.put_env(:mock_pve_api, :pve_version, version)
    State.reset()
  end
end
