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
end
