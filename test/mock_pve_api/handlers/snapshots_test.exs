# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.SnapshotsTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Snapshots
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params, path_params) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

  # --- VM Snapshot CRUD ---

  describe "VM snapshot lifecycle" do
    setup do
      State.create_vm("pve-node1", 100, %{name: "test-vm"})
      :ok
    end

    test "list_snapshots returns current pseudo-snapshot when no snapshots" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/snapshot", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100"
        })

      conn = Snapshots.list_snapshots(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 1
      assert hd(body["data"])["name"] == "current"
    end

    test "create_snapshot creates a snapshot and returns UPID" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/snapshot",
          %{"snapname" => "snap1", "description" => "First snapshot"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Snapshots.create_snapshot(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
      assert String.contains?(body["data"], "UPID:")
    end

    test "list_snapshots includes created snapshots" do
      State.create_snapshot(100, "snap1", %{"description" => "First"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/snapshot", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100"
        })

      conn = Snapshots.list_snapshots(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      # current + snap1
      assert length(body["data"]) == 2
      names = Enum.map(body["data"], & &1["name"])
      assert "current" in names
      assert "snap1" in names
    end

    test "get_snapshot returns snapshot info" do
      State.create_snapshot(100, "snap1", %{"description" => "Test"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/snapshot/snap1", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100",
          "snapname" => "snap1"
        })

      conn = Snapshots.get_snapshot(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["name"] == "snap1"
      assert body["data"]["description"] == "Test"
    end

    test "get_snapshot returns 404 for nonexistent snapshot" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/snapshot/nope", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100",
          "snapname" => "nope"
        })

      conn = Snapshots.get_snapshot(conn)
      assert conn.status == 404
    end

    test "get_snapshot_config returns snapshot config" do
      State.create_snapshot(100, "snap1", %{"description" => "Config test"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/snapshot/snap1/config", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100",
          "snapname" => "snap1"
        })

      conn = Snapshots.get_snapshot_config(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["description"] == "Config test"
    end

    test "update_snapshot_config updates description" do
      State.create_snapshot(100, "snap1", %{"description" => "Old"})

      conn =
        build_conn(
          :put,
          "/api2/json/nodes/pve-node1/qemu/100/snapshot/snap1/config",
          %{"description" => "Updated description"},
          %{"node" => "pve-node1", "vmid" => "100", "snapname" => "snap1"}
        )

      conn = Snapshots.update_snapshot_config(conn)
      assert conn.status == 200

      # Verify the update
      {:ok, config} = State.get_snapshot_config(100, "snap1")
      assert config.description == "Updated description"
    end

    test "delete_snapshot removes the snapshot" do
      State.create_snapshot(100, "snap1", %{})

      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/qemu/100/snapshot/snap1", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100",
          "snapname" => "snap1"
        })

      conn = Snapshots.delete_snapshot(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])

      # Verify it's gone
      assert State.get_snapshot(100, "snap1") == nil
    end

    test "delete_snapshot returns 404 for nonexistent" do
      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/qemu/100/snapshot/nope", %{}, %{
          "node" => "pve-node1",
          "vmid" => "100",
          "snapname" => "nope"
        })

      conn = Snapshots.delete_snapshot(conn)
      assert conn.status == 404
    end

    test "rollback_snapshot removes newer snapshots" do
      State.create_snapshot(100, "snap1", %{})

      State.create_snapshot(100, "snap2", %{})

      State.create_snapshot(100, "snap3", %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/snapshot/snap1/rollback",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "snapname" => "snap1"}
        )

      conn = Snapshots.rollback_snapshot(conn)

      assert conn.status == 200

      # snap1 should remain, snap2 and snap3 should be gone
      assert State.get_snapshot(100, "snap1") != nil
      assert State.get_snapshot(100, "snap2") == nil
      assert State.get_snapshot(100, "snap3") == nil
    end

    test "rollback_snapshot returns 404 for nonexistent" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/snapshot/nope/rollback",
          %{},
          %{"node" => "pve-node1", "vmid" => "100", "snapname" => "nope"}
        )

      conn = Snapshots.rollback_snapshot(conn)
      assert conn.status == 404
    end

    test "create_snapshot rejects duplicate snapname" do
      State.create_snapshot(100, "snap1", %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/100/snapshot",
          %{"snapname" => "snap1"},
          %{"node" => "pve-node1", "vmid" => "100"}
        )

      conn = Snapshots.create_snapshot(conn)
      assert conn.status == 400
    end

    test "snapshot parent chain is maintained" do
      State.create_snapshot(100, "snap1", %{})

      State.create_snapshot(100, "snap2", %{})

      snap1 = State.get_snapshot(100, "snap1")
      snap2 = State.get_snapshot(100, "snap2")

      assert snap1.parent == nil
      assert snap2.parent == "snap1"
    end

    test "delete_snapshot updates child parent pointers" do
      State.create_snapshot(100, "snap1", %{})

      State.create_snapshot(100, "snap2", %{})

      State.create_snapshot(100, "snap3", %{})

      # Delete snap2 (middle), snap3 should point to snap1
      State.delete_snapshot(100, "snap2")

      snap3 = State.get_snapshot(100, "snap3")
      assert snap3.parent == "snap1"
    end
  end

  # --- VM snapshot with nonexistent VM ---

  describe "VM snapshot with nonexistent VM" do
    test "list_snapshots returns 404" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/qemu/999/snapshot", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Snapshots.list_snapshots(conn)
      assert conn.status == 404
    end

    test "create_snapshot returns 404" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/qemu/999/snapshot",
          %{"snapname" => "snap1"},
          %{"node" => "pve-node1", "vmid" => "999"}
        )

      conn = Snapshots.create_snapshot(conn)
      assert conn.status == 404
    end
  end

  # --- Container Snapshot CRUD ---

  describe "Container snapshot lifecycle" do
    setup do
      State.create_container("pve-node1", 200, %{hostname: "test-ct"})
      :ok
    end

    test "list_snapshots returns current pseudo-snapshot" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/snapshot", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200"
        })

      conn = Snapshots.list_snapshots(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 1
      assert hd(body["data"])["name"] == "current"
    end

    test "create_snapshot creates container snapshot" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/snapshot",
          %{"snapname" => "ct-snap1"},
          %{"node" => "pve-node1", "vmid" => "200"}
        )

      conn = Snapshots.create_snapshot(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end

    test "get_snapshot returns container snapshot" do
      State.create_snapshot(200, "ct-snap1", %{"description" => "CT snap"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/snapshot/ct-snap1", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200",
          "snapname" => "ct-snap1"
        })

      conn = Snapshots.get_snapshot(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["name"] == "ct-snap1"
    end

    test "delete_snapshot removes container snapshot" do
      State.create_snapshot(200, "ct-snap1", %{})

      conn =
        build_conn(:delete, "/api2/json/nodes/pve-node1/lxc/200/snapshot/ct-snap1", %{}, %{
          "node" => "pve-node1",
          "vmid" => "200",
          "snapname" => "ct-snap1"
        })

      conn = Snapshots.delete_snapshot(conn)

      assert conn.status == 200
      assert State.get_snapshot(200, "ct-snap1") == nil
    end

    test "rollback container snapshot" do
      State.create_snapshot(200, "ct-snap1", %{})

      State.create_snapshot(200, "ct-snap2", %{})

      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/lxc/200/snapshot/ct-snap1/rollback",
          %{},
          %{"node" => "pve-node1", "vmid" => "200", "snapname" => "ct-snap1"}
        )

      conn = Snapshots.rollback_snapshot(conn)

      assert conn.status == 200
      assert State.get_snapshot(200, "ct-snap1") != nil
      assert State.get_snapshot(200, "ct-snap2") == nil
    end
  end

  # --- Container snapshot with nonexistent container ---

  describe "Container snapshot with nonexistent container" do
    test "list_snapshots returns 404" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/lxc/999/snapshot", %{}, %{
          "node" => "pve-node1",
          "vmid" => "999"
        })

      conn = Snapshots.list_snapshots(conn)
      assert conn.status == 404
    end
  end

  # --- Snapshot isolation between VMs ---

  describe "snapshot isolation" do
    test "snapshots are isolated between different VMIDs" do
      State.create_vm("pve-node1", 100, %{})
      State.create_vm("pve-node1", 101, %{})

      State.create_snapshot(100, "snap1", %{})
      State.create_snapshot(101, "snap1", %{})

      # Both should exist independently
      assert State.get_snapshot(100, "snap1") != nil
      assert State.get_snapshot(101, "snap1") != nil

      # Delete from VM 100 should not affect VM 101
      State.delete_snapshot(100, "snap1")
      assert State.get_snapshot(100, "snap1") == nil
      assert State.get_snapshot(101, "snap1") != nil
    end
  end
end
