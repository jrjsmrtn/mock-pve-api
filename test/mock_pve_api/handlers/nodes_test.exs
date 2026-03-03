# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.NodesTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Nodes
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params, path_params) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

  # --- Node info ---

  describe "list_nodes/1" do
    test "returns all nodes" do
      conn = build_conn(:get, "/api2/json/nodes", %{}, %{"node" => "pve-node1"})
      conn = Nodes.list_nodes(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  describe "get_node/1" do
    test "returns node info" do
      conn = build_conn(:get, "/api2/json/nodes/pve-node1", %{}, %{"node" => "pve-node1"})
      conn = Nodes.get_node(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["node"] == "pve-node1"
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown", %{}, %{"node" => "unknown"})
      conn = Nodes.get_node(conn)
      assert conn.status == 404
    end
  end

  describe "get_node_status/1" do
    test "returns node status" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/status", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_status(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_map(body["data"]["memory"])
      assert is_map(body["data"]["rootfs"])
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/status", %{}, %{"node" => "unknown"})
      conn = Nodes.get_node_status(conn)
      assert conn.status == 404
    end
  end

  describe "get_node_version/1" do
    test "returns node version info" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/version", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_version(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"]["version"])
      assert is_binary(body["data"]["kernel"])
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/version", %{}, %{"node" => "unknown"})
      conn = Nodes.get_node_version(conn)
      assert conn.status == 404
    end
  end

  describe "get_node_tasks/1" do
    test "returns empty list initially" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_tasks(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == []
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/tasks", %{}, %{"node" => "unknown"})
      conn = Nodes.get_node_tasks(conn)
      assert conn.status == 404
    end
  end

  describe "get_node_syslog/1" do
    test "returns syslog entries" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/syslog", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_syslog(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      assert length(body["data"]) > 0
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/syslog", %{}, %{"node" => "unknown"})
      conn = Nodes.get_node_syslog(conn)
      assert conn.status == 404
    end
  end

  describe "get_node_network/1" do
    test "returns network interfaces" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/network", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_network(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/network", %{}, %{"node" => "unknown"})
      conn = Nodes.get_node_network(conn)
      assert conn.status == 404
    end
  end

  describe "execute_command/1" do
    test "executes command on node" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/execute",
          %{"command" => "uptime"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.execute_command(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["exitcode"] == 0
    end

    test "returns 404 for unknown node" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/unknown/execute",
          %{"command" => "uptime"},
          %{"node" => "unknown"}
        )

      conn = Nodes.execute_command(conn)
      assert conn.status == 404
    end
  end

  # --- VM endpoints ---

  describe "list_vms/1" do
    test "returns VMs for node" do
      State.create_vm("pve-node1", 100, %{})

      conn = build_conn(:get, "/api2/json/nodes/pve-node1/qemu", %{}, %{"node" => "pve-node1"})
      conn = Nodes.list_vms(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 1
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/qemu", %{}, %{"node" => "unknown"})
      conn = Nodes.list_vms(conn)
      assert conn.status == 404
    end
  end

  describe "get_vm/1" do
    test "returns VM info with extended fields" do
      State.create_vm("pve-node1", 100, %{name: "test-vm"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100"
        })

      conn = Nodes.get_vm(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["vmid"] == 100
      assert Map.has_key?(body["data"], "digest")
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/999", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Nodes.get_vm(conn)
      assert conn.status == 404
    end
  end

  describe "create_vm/1" do
    test "creates VM with explicit vmid" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu",
          %{"vmid" => "100", "name" => "new-vm", "memory" => "4096"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_vm(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end

    test "creates VM with auto vmid" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu",
          %{"name" => "auto-vm"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_vm(conn)
      assert conn.status == 200
    end

    test "returns 404 for unknown node" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/unknown/qemu",
          %{"vmid" => "100"},
          %{"node" => "unknown"}
        )

      conn = Nodes.create_vm(conn)
      assert conn.status == 404
    end

    test "returns 400 for duplicate VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu",
          %{"vmid" => "100"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_vm(conn)
      assert conn.status == 400
    end
  end

  describe "update_vm/1" do
    test "updates VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/qemu/100",
          %{"memory" => 8192},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.update_vm(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/qemu/999",
          %{},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.update_vm(conn)
      assert conn.status == 404
    end
  end

  describe "get_vm_config/1" do
    test "returns VM config" do
      State.create_vm("pve-node1", 100, %{name: "config-test"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/config", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100"
        })

      conn = Nodes.get_vm_config(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["name"] == "config-test"
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/999/config", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Nodes.get_vm_config(conn)
      assert conn.status == 404
    end
  end

  describe "get_vm_status/1" do
    test "returns VM status" do
      State.create_vm("pve-node1", 100, %{name: "status-test"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/status/current", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100"
        })

      conn = Nodes.get_vm_status(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["vmid"] == 100
    end
  end

  describe "update_vm_config/1" do
    test "updates VM config fields" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/qemu/100/config",
          %{"name" => "renamed", "memory" => "8192"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.update_vm_config(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/qemu/999/config",
          %{},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.update_vm_config(conn)
      assert conn.status == 404
    end
  end

  describe "vm_action/1" do
    test "starts a VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/status/start",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "action" => "start"}
        )

      conn = Nodes.vm_action(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])

      # VM should now be running
      vm = State.get_vm("pve-node1", 100)
      assert vm.status == "running"
    end

    test "stops a VM" do
      State.create_vm("pve-node1", 100, %{status: "running"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/status/stop",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "action" => "stop"}
        )

      conn = Nodes.vm_action(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/999/status/start",
          %{},
          %{"node" => "pve-node1", "vmid" => "999", "action" => "start"}
        )

      conn = Nodes.vm_action(conn)
      assert conn.status == 404
    end
  end

  describe "delete_vm/1" do
    test "deletes a VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/qemu/100", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100"
        })

      conn = Nodes.delete_vm(conn)

      assert conn.status == 200
      :timer.sleep(10)
      assert State.get_vm("pve-node1", 100) == nil
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/qemu/999", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Nodes.delete_vm(conn)
      assert conn.status == 404
    end
  end

  # --- Container endpoints ---

  describe "list_containers/1" do
    test "returns containers for node" do
      State.create_container("pve-node1", 200, %{})

      conn = build_conn(:get, "/api2/json/nodes/pve-node1/lxc", %{}, %{"node" => "pve-node1"})
      conn = Nodes.list_containers(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 1
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/lxc", %{}, %{"node" => "unknown"})
      conn = Nodes.list_containers(conn)
      assert conn.status == 404
    end
  end

  describe "get_container/1" do
    test "returns container info" do
      State.create_container("pve-node1", 200, %{hostname: "test-ct"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/200", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200"
        })

      conn = Nodes.get_container(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["vmid"] == 200
      assert Map.has_key?(body["data"], "digest")
    end

    test "returns 404 for nonexistent container" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/999", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Nodes.get_container(conn)
      assert conn.status == 404
    end
  end

  describe "create_container/1" do
    test "creates container" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc",
          %{"vmid" => "200", "hostname" => "new-ct"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_container(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end

    test "returns 404 for unknown node" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/unknown/lxc",
          %{"vmid" => "200"},
          %{"node" => "unknown"}
        )

      conn = Nodes.create_container(conn)
      assert conn.status == 404
    end
  end

  describe "update_container/1" do
    test "updates container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/lxc/200",
          %{"memory" => 2048},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Nodes.update_container(conn)
      assert conn.status == 200
    end
  end

  describe "get_container_config/1" do
    test "returns container config" do
      State.create_container("pve-node1", 200, %{hostname: "config-ct"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/config", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200"
        })

      conn = Nodes.get_container_config(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["hostname"] == "config-ct"
    end
  end

  describe "get_container_status/1" do
    test "returns container status" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/status/current", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200"
        })

      conn = Nodes.get_container_status(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["vmid"] == 200
    end
  end

  describe "update_container_config/1" do
    test "updates container config" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/lxc/200/config",
          %{"hostname" => "renamed-ct"},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Nodes.update_container_config(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent container" do
      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/lxc/999/config",
          %{},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.update_container_config(conn)
      assert conn.status == 404
    end
  end

  describe "container_action/1" do
    test "starts a container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/status/start",
          %{},
          %{"node" => "pve-node1", "vmid" => "200", "action" => "start"}
        )

      conn = Nodes.container_action(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent container" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/999/status/start",
          %{},
          %{"node" => "pve-node1", "vmid" => "999", "action" => "start"}
        )

      conn = Nodes.container_action(conn)
      assert conn.status == 404
    end
  end

  describe "delete_container/1" do
    test "deletes a container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/lxc/200", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200"
        })

      conn = Nodes.delete_container(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent container" do
      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/lxc/999", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Nodes.delete_container(conn)
      assert conn.status == 404
    end
  end

  # --- Migration ---

  describe "migrate_vm/1" do
    test "migrates VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/migrate",
          %{"target" => "pve-node2"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.migrate_vm(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end

    test "returns 400 when target missing" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/migrate",
          %{},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.migrate_vm(conn)
      assert conn.status == 400
    end

    test "returns 400 for nonexistent VM" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/999/migrate",
          %{"target" => "pve-node2"},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.migrate_vm(conn)
      assert conn.status == 400
    end
  end

  describe "migrate_container/1" do
    test "migrates container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/migrate",
          %{"target" => "pve-node2"},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Nodes.migrate_container(conn)

      assert conn.status == 200
    end

    test "returns 400 when target missing" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/migrate",
          %{},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Nodes.migrate_container(conn)
      assert conn.status == 400
    end
  end

  # --- Snapshot ---

  describe "create_vm_snapshot/1" do
    test "creates snapshot" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/snapshot",
          %{"snapname" => "snap1"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.create_vm_snapshot(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/999/snapshot",
          %{},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.create_vm_snapshot(conn)
      assert conn.status == 404
    end
  end

  # --- Backup ---

  describe "create_backup/1" do
    test "creates backup for VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/vzdump",
          %{"vmid" => "100"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_backup(conn)

      assert conn.status == 200
    end

    test "returns 400 when vmid missing" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/vzdump",
          %{},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_backup(conn)
      assert conn.status == 400
    end
  end

  describe "list_backup_files/1" do
    test "returns backup files" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/storage/local/backup", %{}, %{
          "node" => "pve-node1",
          "storage" => "local"
        })

      conn = Nodes.list_backup_files(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
    end
  end

  # --- Clone ---

  describe "clone_vm/1" do
    test "clones a VM" do
      State.create_vm("pve-node1", 100, %{name: "original"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/clone",
          %{"newid" => "101", "name" => "cloned"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.clone_vm(conn)

      assert conn.status == 200
      assert State.get_vm("pve-node1", 101) != nil
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/999/clone",
          %{},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.clone_vm(conn)
      assert conn.status == 404
    end
  end

  describe "clone_container/1" do
    test "clones a container" do
      State.create_container("pve-node1", 200, %{hostname: "original"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/clone",
          %{"newid" => "201"},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Nodes.clone_container(conn)

      assert conn.status == 200
      assert State.get_container("pve-node1", 201) != nil
    end

    test "returns 404 for nonexistent container" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/999/clone",
          %{},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.clone_container(conn)
      assert conn.status == 404
    end
  end

  # --- Task status/log ---

  describe "get_task_status/1" do
    test "returns task status" do
      {:ok, upid} = State.create_task("pve-node1", "qmstart", %{vmid: 100})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/status", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_status(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["type"] == "qmstart"
    end

    test "returns 404 for nonexistent task" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/nonexistent/status", %{}, %{
          "node" => "pve-node1",
          "upid" => "nonexistent"
        })

      conn = Nodes.get_task_status(conn)
      assert conn.status == 404
    end
  end

  describe "get_task_log/1" do
    test "returns task log" do
      {:ok, upid} = State.create_task("pve-node1", "qmstart", %{vmid: 100})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      assert length(body["data"]) > 0
    end

    test "returns 404 for nonexistent task" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/nonexistent/log", %{}, %{
          "node" => "pve-node1",
          "upid" => "nonexistent"
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 404
    end
  end

  # --- Time ---

  describe "get_node_time/1" do
    test "returns time configuration" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/time", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_time(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"]["timezone"])
      assert is_integer(body["data"]["time"])
    end
  end

  describe "set_node_time/1" do
    test "sets time configuration" do
      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/time",
          %{"timezone" => "UTC"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.set_node_time(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["timezone"] == "UTC"
    end
  end

  # --- Task log generation for different task types ---

  describe "get_task_log/1 with different task types" do
    test "generates qmstop task logs" do
      {:ok, upid} = State.create_task("pve-node1", "qmstop", %{vmid: 100})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      logs = body["data"]
      assert length(logs) >= 4
      assert Enum.any?(logs, fn l -> String.contains?(l["t"], "stopping VM") end)
    end

    test "generates qmigrate task logs" do
      {:ok, upid} = State.create_task("pve-node1", "qmigrate", %{vmid: 100, target: "pve-node2"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      logs = body["data"]
      assert length(logs) >= 5
      assert Enum.any?(logs, fn l -> String.contains?(l["t"], "migration") end)
    end

    test "generates qmclone task logs" do
      {:ok, upid} = State.create_task("pve-node1", "qmclone", %{vmid: 100, newid: 101})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      logs = body["data"]
      assert length(logs) >= 6
      assert Enum.any?(logs, fn l -> String.contains?(l["t"], "clone") end)
    end

    test "generates pctclone task logs" do
      {:ok, upid} = State.create_task("pve-node1", "pctclone", %{vmid: 200, newid: 201})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      logs = body["data"]
      assert length(logs) >= 6
      assert Enum.any?(logs, fn l -> String.contains?(l["t"], "clone") end)
    end

    test "generates vzdump task logs" do
      {:ok, upid} = State.create_task("pve-node1", "vzdump", %{vmid: 100})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      logs = body["data"]
      assert length(logs) >= 6
      assert Enum.any?(logs, fn l -> String.contains?(l["t"], "backup") end)
    end

    test "generates default task logs for unknown type" do
      {:ok, upid} = State.create_task("pve-node1", "custom_task", %{})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log", %{}, %{
          "node" => "pve-node1",
          "upid" => upid
        })

      conn = Nodes.get_task_log(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      logs = body["data"]
      assert length(logs) >= 3
    end
  end

  # --- Backup edge cases ---

  describe "create_backup/1 edge cases" do
    test "creates backup even for nonexistent vmid (state allows it)" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/vzdump",
          %{"vmid" => "999"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_backup(conn)
      assert conn.status == 200
    end
  end

  # --- Container creation edge cases ---

  describe "create_container/1 edge cases" do
    test "creates container with auto vmid" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc",
          %{"hostname" => "auto-ct"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_container(conn)
      assert conn.status == 200
    end

    test "returns 400 for duplicate container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc",
          %{"vmid" => "200"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_container(conn)
      assert conn.status == 400
    end
  end

  # --- Migration error cases ---

  describe "migrate_container/1 error cases" do
    test "returns 400 for nonexistent container" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/999/migrate",
          %{"target" => "pve-node2"},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Nodes.migrate_container(conn)
      assert conn.status == 400
    end
  end

  # --- VM action edge cases ---

  describe "vm_action/1 other actions" do
    test "shutdown action sets stopped" do
      State.create_vm("pve-node1", 100, %{status: "running"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/status/shutdown",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "action" => "shutdown"}
        )

      conn = Nodes.vm_action(conn)
      assert conn.status == 200
      assert State.get_vm("pve-node1", 100).status == "stopped"
    end

    test "reboot action sets running" do
      State.create_vm("pve-node1", 100, %{status: "running"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/status/reboot",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "action" => "reboot"}
        )

      conn = Nodes.vm_action(conn)
      assert conn.status == 200
      assert State.get_vm("pve-node1", 100).status == "running"
    end

    test "unknown action defaults to stopped" do
      State.create_vm("pve-node1", 100, %{status: "running"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/status/suspend",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "action" => "suspend"}
        )

      conn = Nodes.vm_action(conn)
      assert conn.status == 200
      assert State.get_vm("pve-node1", 100).status == "stopped"
    end
  end

  # --- Container action edge cases ---

  describe "container_action/1 other actions" do
    test "shutdown sets stopped" do
      State.create_container("pve-node1", 200, %{status: "running"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/status/shutdown",
          %{},
          %{"node" => "pve-node1", "vmid" => "200", "action" => "shutdown"}
        )

      conn = Nodes.container_action(conn)
      assert conn.status == 200
    end

    test "unknown action defaults to stopped" do
      State.create_container("pve-node1", 200, %{status: "running"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/status/suspend",
          %{},
          %{"node" => "pve-node1", "vmid" => "200", "action" => "suspend"}
        )

      conn = Nodes.container_action(conn)
      assert conn.status == 200
    end
  end

  # --- Clone error cases ---

  describe "clone_vm/1 error cases" do
    test "returns 400 for duplicate newid" do
      State.create_vm("pve-node1", 100, %{name: "original"})
      State.create_vm("pve-node1", 101, %{name: "existing"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/clone",
          %{"newid" => "101"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.clone_vm(conn)
      assert conn.status == 400
    end
  end

  describe "clone_container/1 error cases" do
    test "returns 400 for duplicate newid" do
      State.create_container("pve-node1", 200, %{hostname: "original"})
      State.create_container("pve-node1", 201, %{hostname: "existing"})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/clone",
          %{"newid" => "201"},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Nodes.clone_container(conn)
      assert conn.status == 400
    end
  end

  # --- VM creation with integer vmid ---

  describe "create_vm/1 with integer vmid" do
    test "handles integer vmid in params" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu",
          %{"vmid" => 100, "name" => "int-vm"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_vm(conn)
      assert conn.status == 200
    end
  end

  describe "create_container/1 with integer vmid" do
    test "handles integer vmid in params" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc",
          %{"vmid" => 200, "hostname" => "int-ct"},
          %{"node" => "pve-node1"}
        )

      conn = Nodes.create_container(conn)
      assert conn.status == 200
    end
  end

  # --- Router integration tests for Sprint 4.9.4 endpoints ---

  defp request(method, path, body \\ nil) do
    conn =
      Plug.Test.conn(method, path, body && Jason.encode!(body))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", "PVEAPIToken=root@pam!test=secret")

    MockPveApi.Router.call(conn, MockPveApi.Router.init([]))
  end

  defp json(conn, status) do
    assert conn.status == status
    Jason.decode!(conn.resp_body)
  end

  describe "node DNS" do
    test "get DNS returns defaults" do
      conn = request(:get, "/api2/json/nodes/pve-node1/dns")
      data = json(conn, 200)["data"]
      assert data["dns1"] == "8.8.8.8"
    end

    test "update DNS" do
      conn =
        request(:put, "/api2/json/nodes/pve-node1/dns", %{
          "dns1" => "1.1.1.1",
          "search" => "example.com"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/nodes/pve-node1/dns")
      data = json(conn, 200)["data"]
      assert data["dns1"] == "1.1.1.1"
      assert data["search"] == "example.com"
    end
  end

  describe "APT endpoints" do
    test "get apt updates returns list" do
      conn = request(:get, "/api2/json/nodes/pve-node1/apt/update")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert length(data) > 0
    end

    test "post apt update returns UPID" do
      conn = request(:post, "/api2/json/nodes/pve-node1/apt/update")
      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
    end

    test "get apt versions returns list" do
      conn = request(:get, "/api2/json/nodes/pve-node1/apt/versions")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert length(data) > 0
    end
  end

  describe "network interface CRUD" do
    test "get existing interface" do
      conn = request(:get, "/api2/json/nodes/pve-node1/network/eth0")
      data = json(conn, 200)["data"]
      assert data["iface"] == "eth0"
      assert data["type"] == "eth"
    end

    test "get nonexistent interface returns 404" do
      conn = request(:get, "/api2/json/nodes/pve-node1/network/eth99")
      assert conn.status == 404
    end

    test "update interface" do
      conn =
        request(:put, "/api2/json/nodes/pve-node1/network/eth0", %{
          "address" => "10.0.0.100",
          "netmask" => "255.255.0.0"
        })

      assert conn.status == 200

      updated = State.get_node_network_iface("pve-node1", "eth0")
      assert updated.address == "10.0.0.100"
      assert updated.netmask == "255.255.0.0"
    end

    test "delete interface" do
      conn = request(:delete, "/api2/json/nodes/pve-node1/network/eth0")
      assert conn.status == 200
      assert State.get_node_network_iface("pve-node1", "eth0") == nil
    end

    test "delete nonexistent interface returns 404" do
      conn = request(:delete, "/api2/json/nodes/pve-node1/network/eth99")
      assert conn.status == 404
    end
  end

  describe "disks list" do
    test "list disks returns array" do
      conn = request(:get, "/api2/json/nodes/pve-node1/disks/list")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert length(data) > 0
      disk = hd(data)
      assert Map.has_key?(disk, "devpath")
      assert Map.has_key?(disk, "size")
    end
  end

  describe "task delete" do
    test "delete existing task" do
      {:ok, upid} = State.create_task("pve-node1", "test", %{})
      conn = request(:delete, "/api2/json/nodes/pve-node1/tasks/#{URI.encode(upid)}")
      assert conn.status == 200
    end

    test "delete nonexistent task returns 404" do
      conn = request(:delete, "/api2/json/nodes/pve-node1/tasks/UPID:nonexistent:")
      assert conn.status == 404
    end
  end

  describe "node config" do
    test "get config returns defaults" do
      conn = request(:get, "/api2/json/nodes/pve-node1/config")
      data = json(conn, 200)["data"]
      assert is_map(data)
    end

    test "update config" do
      conn =
        request(:put, "/api2/json/nodes/pve-node1/config", %{
          "description" => "Production node"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/nodes/pve-node1/config")
      data = json(conn, 200)["data"]
      assert data["description"] == "Production node"
    end
  end

  describe "vzdump defaults" do
    test "returns default options" do
      conn = request(:get, "/api2/json/nodes/pve-node1/vzdump/defaults")
      data = json(conn, 200)["data"]
      assert data["mode"] == "snapshot"
      assert data["compress"] == "zstd"
      assert data["storage"] == "local"
    end
  end

  # --- Router integration tests for Sprint 4.9.5 endpoints ---

  describe "vzdump extractconfig" do
    test "returns mock extracted config" do
      conn = request(:get, "/api2/json/nodes/pve-node1/vzdump/extractconfig")
      data = json(conn, 200)["data"]
      assert is_binary(data)
      assert String.contains?(data, "cores")
      assert String.contains?(data, "memory")
    end

    test "returns 404 for unknown node" do
      conn = request(:get, "/api2/json/nodes/unknown/vzdump/extractconfig")
      assert conn.status == 404
    end
  end

  describe "qmrestore" do
    test "returns UPID for VM restore" do
      conn =
        request(:post, "/api2/json/nodes/pve-node1/qmrestore", %{
          "archive" => "local:backup/vzdump-qemu-100.vma.zst",
          "vmid" => 200
        })

      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
      assert String.contains?(data, "qmrestore")
    end

    test "returns 404 for unknown node" do
      conn = request(:post, "/api2/json/nodes/unknown/qmrestore", %{})
      assert conn.status == 404
    end
  end

  describe "vzrestore" do
    test "returns UPID for container restore" do
      conn =
        request(:post, "/api2/json/nodes/pve-node1/vzrestore", %{
          "archive" => "local:backup/vzdump-lxc-101.tar.zst",
          "vmid" => 201
        })

      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
      assert String.contains?(data, "vzrestore")
    end

    test "returns 404 for unknown node" do
      conn = request(:post, "/api2/json/nodes/unknown/vzrestore", %{})
      assert conn.status == 404
    end
  end

  describe "VM pending config" do
    test "returns pending config for existing VM" do
      State.create_vm("pve-node1", 500, %{name: "pending-vm", memory: 2048, cores: 2})

      conn = request(:get, "/api2/json/nodes/pve-node1/qemu/500/pending")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert Enum.any?(data, fn entry -> entry["key"] == "name" end)
    end

    test "returns 404 for nonexistent VM" do
      conn = request(:get, "/api2/json/nodes/pve-node1/qemu/9999/pending")
      assert conn.status == 404
    end
  end

  describe "container pending config" do
    test "returns pending config for existing container" do
      State.create_container("pve-node1", 501, %{hostname: "pending-ct", memory: 512, cores: 1})

      conn = request(:get, "/api2/json/nodes/pve-node1/lxc/501/pending")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert Enum.any?(data, fn entry -> entry["key"] == "hostname" end)
    end

    test "returns 404 for nonexistent container" do
      conn = request(:get, "/api2/json/nodes/pve-node1/lxc/9999/pending")
      assert conn.status == 404
    end
  end

  describe "VM disk resize" do
    test "resizes VM disk" do
      State.create_vm("pve-node1", 502, %{name: "resize-vm", memory: 2048, cores: 2})

      conn =
        request(:put, "/api2/json/nodes/pve-node1/qemu/502/resize", %{
          "disk" => "scsi0",
          "size" => "+10G"
        })

      assert conn.status == 200
    end

    test "returns 404 for nonexistent VM" do
      conn =
        request(:put, "/api2/json/nodes/pve-node1/qemu/9999/resize", %{
          "disk" => "scsi0",
          "size" => "+10G"
        })

      assert conn.status == 404
    end
  end

  describe "container disk resize" do
    test "resizes container disk" do
      State.create_container("pve-node1", 503, %{hostname: "resize-ct", memory: 512, cores: 1})

      conn =
        request(:put, "/api2/json/nodes/pve-node1/lxc/503/resize", %{
          "disk" => "rootfs",
          "size" => "+5G"
        })

      assert conn.status == 200
    end

    test "returns 404 for nonexistent container" do
      conn =
        request(:put, "/api2/json/nodes/pve-node1/lxc/9999/resize", %{
          "disk" => "rootfs",
          "size" => "+5G"
        })

      assert conn.status == 404
    end
  end

  describe "VM rrddata" do
    test "returns RRD data for existing VM" do
      State.create_vm("pve-node1", 504, %{name: "rrd-vm", memory: 2048, cores: 2})

      conn = request(:get, "/api2/json/nodes/pve-node1/qemu/504/rrddata")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert length(data) > 0
      first = List.first(data)
      assert Map.has_key?(first, "time")
      assert Map.has_key?(first, "cpu")
    end

    test "returns 404 for nonexistent VM" do
      conn = request(:get, "/api2/json/nodes/pve-node1/qemu/9999/rrddata")
      assert conn.status == 404
    end
  end

  describe "container rrddata" do
    test "returns RRD data for existing container" do
      State.create_container("pve-node1", 505, %{hostname: "rrd-ct", memory: 256, cores: 1})

      conn = request(:get, "/api2/json/nodes/pve-node1/lxc/505/rrddata")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert length(data) > 0
      first = List.first(data)
      assert Map.has_key?(first, "time")
      assert Map.has_key?(first, "cpu")
    end

    test "returns 404 for nonexistent container" do
      conn = request(:get, "/api2/json/nodes/pve-node1/lxc/9999/rrddata")
      assert conn.status == 404
    end
  end

  # ── Node Hosts ──

  describe "node hosts" do
    test "GET returns hosts data" do
      conn = request(:get, "/api2/json/nodes/pve-node1/hosts")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"]["data"])
      assert String.contains?(body["data"]["data"], "localhost")
    end

    test "POST returns success" do
      conn = request(:post, "/api2/json/nodes/pve-node1/hosts", %{data: "127.0.0.1 localhost"})
      assert conn.status == 200
    end
  end

  # ── Node Subscription ──

  describe "node subscription" do
    test "GET returns subscription info" do
      conn = request(:get, "/api2/json/nodes/pve-node1/subscription")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["status"] == "notfound"
    end

    test "POST returns success" do
      conn = request(:post, "/api2/json/nodes/pve-node1/subscription", %{key: "pve2s-1234567890"})
      assert conn.status == 200
    end
  end

  # ── Bulk Operations ──

  describe "bulk operations" do
    test "POST startall returns UPID" do
      conn = request(:post, "/api2/json/nodes/pve-node1/startall")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert String.contains?(body["data"], "startall")
    end

    test "POST stopall returns UPID" do
      conn = request(:post, "/api2/json/nodes/pve-node1/stopall")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert String.contains?(body["data"], "stopall")
    end

    test "POST migrateall returns UPID" do
      conn = request(:post, "/api2/json/nodes/pve-node1/migrateall", %{target: "pve-node2"})
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert String.contains?(body["data"], "migrateall")
    end
  end

  # ── Journal ──

  describe "node journal" do
    test "GET returns empty journal" do
      conn = request(:get, "/api2/json/nodes/pve-node1/journal")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == []
    end
  end

  # ── Certificates ──

  describe "node certificates" do
    test "GET returns certificate info" do
      conn = request(:get, "/api2/json/nodes/pve-node1/certificates/info")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      cert = hd(body["data"])
      assert Map.has_key?(cert, "fingerprint")
      assert Map.has_key?(cert, "subject")
    end
  end

  # ── Disks SMART ──

  describe "node disks smart" do
    test "GET returns SMART data" do
      conn = request(:get, "/api2/json/nodes/pve-node1/disks/smart")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["health"] == "PASSED"
    end
  end

  # ── VM Feature / Template / Agent / Cloud-Init / Unlink / Move Disk ──

  describe "VM feature check" do
    test "returns hasFeature for existing VM" do
      conn = request(:get, "/api2/json/nodes/pve-node1/qemu/100/feature")
      data = json(conn, 200)["data"]
      assert data["hasFeature"] == true
    end
  end

  describe "VM convert to template" do
    test "returns success" do
      conn = request(:post, "/api2/json/nodes/pve-node1/qemu/100/template")
      assert conn.status == 200
    end
  end

  describe "VM agent" do
    test "returns agent result" do
      conn = request(:post, "/api2/json/nodes/pve-node1/qemu/100/agent", %{command: "ping"})
      data = json(conn, 200)["data"]
      assert Map.has_key?(data, "result")
    end
  end

  describe "VM cloud-init dump" do
    test "returns cloud-init config" do
      conn = request(:get, "/api2/json/nodes/pve-node1/qemu/100/cloudinit/dump")
      data = json(conn, 200)["data"]
      assert is_binary(data)
      assert String.contains?(data, "cloud-init")
    end
  end

  describe "VM unlink" do
    test "returns success" do
      conn = request(:put, "/api2/json/nodes/pve-node1/qemu/100/unlink", %{idlist: "unused0"})
      assert conn.status == 200
    end
  end

  describe "VM move disk" do
    test "returns UPID" do
      conn =
        request(:post, "/api2/json/nodes/pve-node1/qemu/100/move_disk", %{
          disk: "scsi0",
          storage: "local-lvm"
        })

      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
      assert String.contains?(data, "move_disk")
    end
  end

  # ── Container Feature / Template / Move Volume ──

  describe "container feature check" do
    test "returns hasFeature for existing container" do
      conn = request(:get, "/api2/json/nodes/pve-node1/lxc/200/feature")
      data = json(conn, 200)["data"]
      assert data["hasFeature"] == true
    end
  end

  describe "container convert to template" do
    test "returns success" do
      conn = request(:post, "/api2/json/nodes/pve-node1/lxc/200/template")
      assert conn.status == 200
    end
  end

  describe "container move volume" do
    test "returns UPID" do
      conn =
        request(:post, "/api2/json/nodes/pve-node1/lxc/200/move_volume", %{
          volume: "rootfs",
          storage: "local-lvm"
        })

      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
      assert String.contains?(data, "move_volume")
    end
  end

  # --- VM Sendkey ---

  describe "vm_sendkey/1" do
    test "sends key event to VM" do
      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/qemu/100/sendkey",
          %{"key" => "ctrl-alt-delete"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Nodes.vm_sendkey(conn)
      assert conn.status == 200
    end
  end

  # --- Disk Management ---

  describe "disk management" do
    test "list LVM volumes" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/disks/lvm", %{}, %{"node" => "pve-node1"})

      conn = Nodes.list_disks_lvm(conn)
      body = json(conn, 200)
      assert is_list(body["data"])
    end

    test "create LVM volume" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/disks/lvm", %{"device" => "/dev/sdb"}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.create_disk_lvm(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "list LVM thin pools" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/disks/lvmthin", %{}, %{"node" => "pve-node1"})

      conn = Nodes.list_disks_lvmthin(conn)
      body = json(conn, 200)
      assert is_list(body["data"])
    end

    test "create LVM thin pool" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/disks/lvmthin", %{}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.create_disk_lvmthin(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "list ZFS pools" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/disks/zfs", %{}, %{"node" => "pve-node1"})

      conn = Nodes.list_disks_zfs(conn)
      body = json(conn, 200)
      assert is_list(body["data"])
    end

    test "create ZFS pool" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/disks/zfs", %{}, %{"node" => "pve-node1"})

      conn = Nodes.create_disk_zfs(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "initialize GPT disk" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/disks/initgpt", %{"disk" => "/dev/sdb"}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.init_disk_gpt(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end
  end

  # --- Node Ceph ---

  describe "node Ceph" do
    test "get Ceph status" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/ceph/status", %{}, %{"node" => "pve-node1"})

      conn = Nodes.get_node_ceph_status(conn)
      body = json(conn, 200)
      assert body["data"]["health"]["status"] == "HEALTH_OK"
    end

    test "list Ceph OSDs" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/ceph/osd", %{}, %{"node" => "pve-node1"})

      conn = Nodes.list_node_ceph_osd(conn)
      json(conn, 200)
    end

    test "create Ceph OSD" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/ceph/osd", %{"dev" => "/dev/sdc"}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.create_node_ceph_osd(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "list Ceph pools" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/ceph/pools", %{}, %{"node" => "pve-node1"})

      conn = Nodes.list_node_ceph_pools(conn)
      body = json(conn, 200)
      assert is_list(body["data"])
    end

    test "create Ceph pool" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/ceph/pools", %{"name" => "rbd"}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.create_node_ceph_pool(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end
  end

  # --- ACME Certificate ---

  describe "ACME certificate" do
    test "order new certificate" do
      conn =
        build_conn(:post, "/api2/json/nodes/pve-node1/certificates/acme/certificate", %{}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.acme_certificate_new(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "renew certificate" do
      conn =
        build_conn(:put, "/api2/json/nodes/pve-node1/certificates/acme/certificate", %{}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.acme_certificate_renew(conn)
      body = json(conn, 200)
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "delete certificate" do
      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/certificates/acme/certificate", %{}, %{
          "node" => "pve-node1"
        })

      conn = Nodes.acme_certificate_delete(conn)
      json(conn, 200)
    end
  end

  # ---------------------------------------------------------------------------
  # Sprint 11: VM/LXC console, cloudinit, scan, services, replication
  # ---------------------------------------------------------------------------

  describe "VM status index" do
    test "GET /nodes/:node/qemu/:vmid/status returns 200" do
      State.create_vm("pve1", 100, %{"name" => "test"})
      conn = request(:get, "/api2/json/nodes/pve1/qemu/100/status")
      assert conn.status == 200
    end
  end

  describe "LXC status index" do
    test "GET /nodes/:node/lxc/:vmid/status returns 200" do
      State.create_container("pve1", 200, %{"hostname" => "test"})
      conn = request(:get, "/api2/json/nodes/pve1/lxc/200/status")
      assert conn.status == 200
    end
  end

  describe "VM console stubs" do
    setup do
      State.create_vm("pve1", 100, %{"name" => "test"})
      :ok
    end

    test "POST vncproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/vncproxy")
      assert conn.status == 200
    end

    test "POST termproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/termproxy")
      assert conn.status == 200
    end

    test "POST spiceproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/spiceproxy")
      assert conn.status == 200
    end

    test "GET vncwebsocket returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/qemu/100/vncwebsocket")
      assert conn.status == 200
    end

    test "POST mtunnel returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/mtunnel")
      assert conn.status == 200
    end

    test "GET mtunnelwebsocket returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/qemu/100/mtunnelwebsocket")
      assert conn.status == 200
    end

    test "POST remote_migrate returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/remote_migrate")
      assert conn.status == 200
    end

    test "POST monitor returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/monitor")
      assert conn.status == 200
    end
  end

  describe "VM cloudinit" do
    setup do
      State.create_vm("pve1", 100, %{"name" => "test"})
      :ok
    end

    test "GET cloudinit returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/qemu/100/cloudinit")
      assert conn.status == 200
    end

    test "PUT cloudinit returns 200" do
      conn = request(:put, "/api2/json/nodes/pve1/qemu/100/cloudinit")
      assert conn.status == 200
    end
  end

  describe "LXC console stubs" do
    setup do
      State.create_container("pve1", 200, %{"hostname" => "test"})
      :ok
    end

    test "POST vncproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/vncproxy")
      assert conn.status == 200
    end

    test "POST termproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/termproxy")
      assert conn.status == 200
    end

    test "POST spiceproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/spiceproxy")
      assert conn.status == 200
    end

    test "GET vncwebsocket returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/lxc/200/vncwebsocket")
      assert conn.status == 200
    end

    test "POST mtunnel returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/mtunnel")
      assert conn.status == 200
    end

    test "GET mtunnelwebsocket returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/lxc/200/mtunnelwebsocket")
      assert conn.status == 200
    end

    test "POST remote_migrate returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/remote_migrate")
      assert conn.status == 200
    end

    test "GET interfaces returns 200 with list" do
      conn = request(:get, "/api2/json/nodes/pve1/lxc/200/interfaces")
      assert conn.status == 200
      assert is_list(json(conn, 200)["data"])
    end
  end

  describe "node scan" do
    test "GET /nodes/:node/scan returns scan types index" do
      conn = request(:get, "/api2/json/nodes/pve1/scan")
      assert conn.status == 200
      assert is_list(json(conn, 200)["data"])
    end

    test "GET /nodes/:node/scan/:type returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/scan/nfs")
      assert conn.status == 200
    end

    test "GET /nodes/:node/scan/:type works for any type" do
      for type <- ~w(cifs lvm lvmthin pbs zfs glusterfs iscsi) do
        conn = request(:get, "/api2/json/nodes/pve1/scan/#{type}")
        assert conn.status == 200, "Expected 200 for scan/#{type}"
      end
    end
  end

  describe "node services actions" do
    test "POST /nodes/:node/services/:service/reload returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/services/pveproxy/reload")
      assert conn.status == 200
    end

    test "POST /nodes/:node/services/:service/restart returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/services/pveproxy/restart")
      assert conn.status == 200
    end

    test "POST /nodes/:node/services/:service/start returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/services/pveproxy/start")
      assert conn.status == 200
    end

    test "POST /nodes/:node/services/:service/stop returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/services/pveproxy/stop")
      assert conn.status == 200
    end
  end

  describe "node replication stubs" do
    test "GET /nodes/:node/replication returns empty list" do
      conn = request(:get, "/api2/json/nodes/pve1/replication")
      assert conn.status == 200
      assert json(conn, 200)["data"] == []
    end

    test "GET /nodes/:node/replication/:id returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/replication/job1")
      assert conn.status == 200
    end

    test "GET /nodes/:node/replication/:id/log returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/replication/job1/log")
      assert conn.status == 200
    end

    test "POST /nodes/:node/replication/:id/schedule_now returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/replication/job1/schedule_now")
      assert conn.status == 200
    end

    test "GET /nodes/:node/replication/:id/status returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/replication/job1/status")
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # Sprint 12: APT, certificates, disks/directory, console, VM/LXC status actions
  # ---------------------------------------------------------------------------

  describe "node apt" do
    test "GET /nodes/:node/apt returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/apt")
      assert conn.status == 200
    end

    test "GET /nodes/:node/apt/changelog returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/apt/changelog")
      assert conn.status == 200
    end

    test "GET /nodes/:node/apt/repositories returns 200 with map" do
      conn = request(:get, "/api2/json/nodes/pve1/apt/repositories")
      assert conn.status == 200
      assert is_map(json(conn, 200)["data"])
    end

    test "POST /nodes/:node/apt/repositories returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/apt/repositories")
      assert conn.status == 200
    end

    test "PUT /nodes/:node/apt/repositories returns 200" do
      conn = request(:put, "/api2/json/nodes/pve1/apt/repositories")
      assert conn.status == 200
    end
  end

  describe "node certificate stubs" do
    test "GET /nodes/:node/certificates returns list" do
      conn = request(:get, "/api2/json/nodes/pve1/certificates")
      assert conn.status == 200
      assert is_list(json(conn, 200)["data"])
    end

    test "GET /nodes/:node/certificates/acme returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/certificates/acme")
      assert conn.status == 200
    end

    test "POST /nodes/:node/certificates/custom returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/certificates/custom")
      assert conn.status == 200
    end

    test "DELETE /nodes/:node/certificates/custom returns 200" do
      conn = request(:delete, "/api2/json/nodes/pve1/certificates/custom")
      assert conn.status == 200
    end
  end

  describe "node disks directory" do
    test "GET /nodes/:node/disks/directory returns list" do
      conn = request(:get, "/api2/json/nodes/pve1/disks/directory")
      assert conn.status == 200
      assert is_list(json(conn, 200)["data"])
    end

    test "POST /nodes/:node/disks/directory returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/disks/directory")
      assert conn.status == 200
    end

    test "DELETE /nodes/:node/disks/directory/:name returns 200" do
      conn = request(:delete, "/api2/json/nodes/pve1/disks/directory/local-dir")
      assert conn.status == 200
    end
  end

  describe "node console and power management stubs" do
    test "POST /nodes/:node/termproxy returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/termproxy")
      assert conn.status == 200
    end

    test "POST /nodes/:node/spiceshell returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/spiceshell")
      assert conn.status == 200
    end

    test "GET /nodes/:node/vncwebsocket returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/vncwebsocket")
      assert conn.status == 200
    end

    test "POST /nodes/:node/wakeonlan returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/wakeonlan")
      assert conn.status == 200
    end

    test "POST /nodes/:node/suspendall returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/suspendall")
      assert conn.status == 200
    end
  end

  describe "VM specific status actions" do
    setup do
      State.create_vm("pve1", 100, %{"name" => "test-vm"})
      :ok
    end

    test "POST /nodes/:node/qemu/:vmid/status/start returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/status/start")
      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu/:vmid/status/stop returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/status/stop")
      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu/:vmid/status/shutdown returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/status/shutdown")
      assert conn.status == 200
    end
  end

  describe "LXC specific status actions" do
    setup do
      State.create_container("pve1", 200, %{"hostname" => "test-ct"})
      :ok
    end

    test "POST /nodes/:node/lxc/:vmid/status/start returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/status/start")
      assert conn.status == 200
    end

    test "POST /nodes/:node/lxc/:vmid/status/shutdown returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/lxc/200/status/shutdown")
      assert conn.status == 200
    end
  end

  # ---------------------------------------------------------------------------
  # Sprint 13: disks index, aplinfo, misc stubs, Ceph stubs, dbus-vmstate
  # ---------------------------------------------------------------------------

  describe "node disks stubs" do
    test "GET /nodes/:node/disks returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/disks")
      assert conn.status == 200
    end

    test "PUT /nodes/:node/disks/wipedisk returns 200" do
      conn = request(:put, "/api2/json/nodes/pve1/disks/wipedisk", %{"disk" => "sdb"})
      assert conn.status == 200
    end

    test "DELETE /nodes/:node/disks/lvm/:name returns 200" do
      conn = request(:delete, "/api2/json/nodes/pve1/disks/lvm/pve")
      assert conn.status == 200
    end
  end

  describe "node aplinfo" do
    test "GET /nodes/:node/aplinfo returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/aplinfo")
      assert conn.status == 200
    end

    test "POST /nodes/:node/aplinfo returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/aplinfo", %{"storage" => "local"})
      assert conn.status == 200
    end
  end

  describe "node misc stubs" do
    test "POST /nodes/:node/vncshell returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/vncshell")
      assert conn.status == 200
    end

    test "GET /nodes/:node/query-url-metadata returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/query-url-metadata")
      assert conn.status == 200
    end

    test "GET /nodes/:node/query-oci-repo-tags returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/query-oci-repo-tags")
      assert conn.status == 200
    end
  end

  describe "node Ceph stubs" do
    test "GET /nodes/:node/ceph returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/ceph")
      assert conn.status == 200
    end

    test "GET /nodes/:node/ceph/cfg returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/ceph/cfg")
      assert conn.status == 200
    end

    test "GET /nodes/:node/ceph/pool returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/ceph/pool")
      assert conn.status == 200
    end

    test "GET /nodes/:node/ceph/pools/:name returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/ceph/pools/cephpool")
      assert conn.status == 200
    end

    test "POST /nodes/:node/ceph/init returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/ceph/init", %{"network" => "10.0.0.0/8"})
      assert conn.status == 200
    end

    test "POST /nodes/:node/ceph/start returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/ceph/start")
      assert conn.status == 200
    end

    test "POST /nodes/:node/ceph/stop returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/ceph/stop")
      assert conn.status == 200
    end

    test "GET /nodes/:node/ceph/osd/:osdid returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/ceph/osd/0")
      assert conn.status == 200
    end

    test "POST /nodes/:node/ceph/osd/:osdid/in returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/ceph/osd/0/in")
      assert conn.status == 200
    end
  end

  describe "VM dbus-vmstate" do
    test "POST /nodes/:node/qemu/:vmid/dbus-vmstate returns 200" do
      conn = request(:post, "/api2/json/nodes/pve1/qemu/100/dbus-vmstate")
      assert conn.status == 200
    end
  end
end
