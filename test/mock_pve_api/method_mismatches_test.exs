# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.MethodMismatchesTest do
  @moduledoc """
  Integration tests for Sprint 4.9.7 — Fix 21 Method Mismatches in Coverage Modules.

  Verifies that all new routes added in this sprint return 200 (or appropriate
  success codes), and that previously phantom methods now return 405.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.{Router, State}

  @opts Router.init([])

  setup do
    State.reset()
    :ok
  end

  defp call(conn) do
    Router.call(conn, @opts)
  end

  defp authed_conn(method, path, body \\ nil) do
    conn =
      if body do
        Plug.Test.conn(method, path, Jason.encode!(body))
        |> Plug.Conn.put_req_header("content-type", "application/json")
      else
        Plug.Test.conn(method, path)
      end

    conn |> Plug.Conn.put_req_header("authorization", "Bearer mock-token")
  end

  # --- Group A: phantom method removal ---

  describe "Group A — phantom methods removed" do
    test "PUT /nodes/:node/qemu/:vmid returns 405 (phantom method removed)" do
      conn = authed_conn(:put, "/api2/json/nodes/pve-node1/qemu/100") |> call()
      assert conn.status == 405
    end

    test "PUT /nodes/:node/lxc/:vmid returns 405 (phantom method removed)" do
      conn = authed_conn(:put, "/api2/json/nodes/pve-node1/lxc/200") |> call()
      assert conn.status == 405
    end
  end

  # --- Group B: PUT → POST for /cluster/config ---

  describe "Group B — PUT→POST fix for /cluster/config" do
    test "POST /cluster/config returns 200" do
      conn = authed_conn(:post, "/api2/json/cluster/config", %{}) |> call()
      assert conn.status == 200
    end

    test "PUT /cluster/config returns 405 (method changed to POST)" do
      conn = authed_conn(:put, "/api2/json/cluster/config", %{}) |> call()
      assert conn.status == 405
    end
  end

  # --- Group C: new access routes ---

  describe "Group C — Access handler new methods" do
    test "GET /access/ticket returns 200" do
      conn = authed_conn(:get, "/api2/json/access/ticket") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body, "data")
    end

    test "PUT /access/tfa returns 200" do
      conn = authed_conn(:put, "/api2/json/access/tfa", %{}) |> call()
      assert conn.status == 200
    end

    test "POST /access/tfa/:userid returns 200" do
      conn = authed_conn(:post, "/api2/json/access/tfa/root@pam", %{type: "totp"}) |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body, "data")
    end
  end

  # --- Group C: new cluster routes ---

  describe "Group C — Cluster handler new methods" do
    test "GET /cluster/config/join returns 200" do
      conn = authed_conn(:get, "/api2/json/cluster/config/join") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body["data"], "totem")
      assert Map.has_key?(body["data"], "nodelist")
    end

    test "POST /cluster/config/nodes/:node returns 200" do
      conn =
        authed_conn(:post, "/api2/json/cluster/config/nodes/pve-node3", %{
          hostname: "pve-node3",
          fingerprint: "AA:BB:CC"
        })
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end
  end

  # --- Group C: new firewall route ---

  describe "Group C — Firewall handler new methods" do
    test "POST /cluster/firewall/groups/:group returns 200" do
      # First create the security group
      authed_conn(:post, "/api2/json/cluster/firewall/groups", %{group: "web-servers"})
      |> call()

      conn =
        authed_conn(:post, "/api2/json/cluster/firewall/groups/web-servers", %{
          action: "ACCEPT",
          type: "in",
          proto: "tcp",
          dport: "443"
        })
        |> call()

      assert conn.status == 200
    end
  end

  # --- Group C: new metrics routes ---

  describe "Group C — Metrics server CRUD" do
    test "POST /cluster/metrics/server/:id creates a server" do
      conn =
        authed_conn(:post, "/api2/json/cluster/metrics/server/influx1", %{
          type: "influxdb",
          server: "192.168.1.20",
          port: 8089
        })
        |> call()

      assert conn.status == 200
    end

    test "PUT /cluster/metrics/server/:id updates a server" do
      # Create first
      authed_conn(:post, "/api2/json/cluster/metrics/server/influx1", %{
        type: "influxdb",
        server: "192.168.1.20",
        port: 8089
      })
      |> call()

      conn =
        authed_conn(:put, "/api2/json/cluster/metrics/server/influx1", %{port: 9090})
        |> call()

      assert conn.status == 200
    end

    test "DELETE /cluster/metrics/server/:id removes a server" do
      # Create first
      authed_conn(:post, "/api2/json/cluster/metrics/server/influx1", %{
        type: "influxdb",
        server: "192.168.1.20",
        port: 8089
      })
      |> call()

      conn = authed_conn(:delete, "/api2/json/cluster/metrics/server/influx1") |> call()
      assert conn.status == 200
    end

    test "GET /cluster/metrics/server lists servers including newly created" do
      authed_conn(:post, "/api2/json/cluster/metrics/server/influx1", %{
        type: "influxdb",
        server: "192.168.1.20",
        port: 8089
      })
      |> call()

      conn = authed_conn(:get, "/api2/json/cluster/metrics/server") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      assert length(body["data"]) == 1
    end
  end

  # --- Group C: SDN apply ---

  describe "Group C — SDN apply" do
    test "PUT /cluster/sdn returns 200" do
      conn = authed_conn(:put, "/api2/json/cluster/sdn", %{}) |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end
  end

  # --- Group C: VM new routes ---

  describe "Group C — VM new methods" do
    setup do
      State.create_vm("pve-node1", 100, %{name: "test-vm", memory: 2048, cores: 2})
      :ok
    end

    test "GET /nodes/:node/qemu/:vmid/migrate returns preconditions" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/migrate") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      data = body["data"]
      assert Map.has_key?(data, "running")
      assert Map.has_key?(data, "local_disks")
      assert Map.has_key?(data, "local_resources")
    end

    test "POST /nodes/:node/qemu/:vmid/config returns UPID" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/qemu/100/config", %{memory: 4096})
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "GET /nodes/:node/qemu/:vmid/agent returns agent info" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/agent") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body["data"], "supported")
    end
  end

  # --- Group C: Container new routes ---

  describe "Group C — Container new methods" do
    setup do
      State.create_container("pve-node1", 200, %{hostname: "test-ct", memory: 1024})
      :ok
    end

    test "GET /nodes/:node/lxc/:vmid/migrate returns preconditions" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/migrate") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      data = body["data"]
      assert Map.has_key?(data, "running")
      assert Map.has_key?(data, "local_volumes")
    end
  end

  # --- Group C: Node network routes ---

  describe "Group C — Node network new methods" do
    test "POST /nodes/:node/network creates an interface" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/network", %{
          iface: "eth1",
          type: "eth",
          method: "static",
          address: "10.0.0.2",
          netmask: "255.255.255.0"
        })
        |> call()

      assert conn.status == 200
    end

    test "PUT /nodes/:node/network reloads config and returns nil" do
      conn = authed_conn(:put, "/api2/json/nodes/pve-node1/network") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end

    test "DELETE /nodes/:node/network reverts pending changes and returns nil" do
      conn = authed_conn(:delete, "/api2/json/nodes/pve-node1/network") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end
  end

  # --- Group C: Node subscription routes ---

  describe "Group C — Node subscription new methods" do
    test "PUT /nodes/:node/subscription updates key and returns nil" do
      conn =
        authed_conn(:put, "/api2/json/nodes/pve-node1/subscription", %{key: "pve-abc123"})
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end

    test "DELETE /nodes/:node/subscription deletes key and returns nil" do
      conn = authed_conn(:delete, "/api2/json/nodes/pve-node1/subscription") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end
  end

  # --- Group C: Node tasks GET ---

  describe "Group C — Node task GET by UPID" do
    test "GET /nodes/:node/tasks/:upid returns task summary" do
      upid = "UPID:pve-node1:00001234:000000:00000000:task:pve-node1:root@pam:"

      conn =
        authed_conn(
          :get,
          "/api2/json/nodes/pve-node1/tasks/#{URI.encode(upid, &URI.char_unreserved?/1)}"
        )
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert Map.has_key?(body["data"], "upid")
      assert Map.has_key?(body["data"], "status")
    end
  end

  # --- Group C: Storage volume new routes ---

  describe "Group C — Storage volume new methods" do
    test "POST /nodes/:node/storage/:storage/content/:volume copies volume and returns UPID" do
      conn =
        authed_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content/backup%2Ftest.vma",
          %{
            target: "local",
            target_volume: "backup/test-copy.vma"
          }
        )
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
      assert String.starts_with?(body["data"], "UPID:")
    end

    test "PUT /nodes/:node/storage/:storage/content/:volume updates attributes and returns nil" do
      conn =
        authed_conn(:put, "/api2/json/nodes/pve-node1/storage/local/content/backup%2Ftest.vma", %{
          notes: "updated notes"
        })
        |> call()

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end
  end
end
