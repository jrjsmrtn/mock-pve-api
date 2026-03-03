# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Sprint11Test do
  @moduledoc """
  Tests for Sprint 4.9.11 endpoints:
  - VM/LXC status index
  - VM/LXC console stubs (vncproxy, termproxy, spiceproxy, etc.)
  - VM cloudinit get/update
  - LXC interfaces
  - Node scan stubs
  - Node services actions
  - Node replication stubs
  - Cluster tasks
  - HA manager_status + resource migrate/relocate
  - Metrics export
  - SDN vnet IPs
  - Bulk-action/guest
  """

  use ExUnit.Case, async: false

  alias MockPveApi.State

  setup do
    original_version = Application.get_env(:mock_pve_api, :pve_version, "8.0")
    Application.put_env(:mock_pve_api, :pve_version, "8.3")
    State.reset()

    on_exit(fn ->
      Application.put_env(:mock_pve_api, :pve_version, original_version)
      State.reset()
    end)

    :ok
  end

  defp request(method, path, body \\ nil) do
    conn =
      Plug.Test.conn(method, path, body && Jason.encode!(body))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", "PVEAPIToken=root@pam!test=secret")

    MockPveApi.Router.call(conn, [])
  end

  defp json_body(conn) do
    Jason.decode!(conn.resp_body)
  end

  # --- VM status index ---

  describe "VM status index" do
    test "GET /nodes/:node/qemu/:vmid/status returns 200" do
      State.create_vm("pve1", 100, %{"name" => "test"})
      conn = request(:get, "/api2/json/nodes/pve1/qemu/100/status")
      assert conn.status == 200
    end
  end

  # --- LXC status index ---

  describe "LXC status index" do
    test "GET /nodes/:node/lxc/:vmid/status returns 200" do
      State.create_container("pve1", 200, %{"hostname" => "test"})
      conn = request(:get, "/api2/json/nodes/pve1/lxc/200/status")
      assert conn.status == 200
    end
  end

  # --- VM console stubs ---

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

  # --- VM cloudinit ---

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

  # --- LXC console stubs ---

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
      assert is_list(json_body(conn)["data"])
    end
  end

  # --- Node scan ---

  describe "Node scan" do
    test "GET /nodes/:node/scan returns scan types index" do
      conn = request(:get, "/api2/json/nodes/pve1/scan")
      assert conn.status == 200
      body = json_body(conn)
      assert is_list(body["data"])
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

  # --- Node services actions ---

  describe "Node services actions" do
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

  # --- Node replication ---

  describe "Node replication stubs" do
    test "GET /nodes/:node/replication returns empty list" do
      conn = request(:get, "/api2/json/nodes/pve1/replication")
      assert conn.status == 200
      assert json_body(conn)["data"] == []
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

  # --- Cluster tasks ---

  describe "Cluster tasks" do
    test "GET /cluster/tasks returns empty list" do
      conn = request(:get, "/api2/json/cluster/tasks")
      assert conn.status == 200
      assert json_body(conn)["data"] == []
    end
  end

  # --- HA manager_status and resource actions ---

  describe "HA enhancements" do
    test "GET /cluster/ha/manager_status returns 200" do
      conn = request(:get, "/api2/json/cluster/ha/manager_status")
      assert conn.status == 200
    end

    test "POST /cluster/ha/resources/:sid/migrate returns 200" do
      conn = request(:post, "/api2/json/cluster/ha/resources/vm%3A100/migrate")
      assert conn.status == 200
    end

    test "POST /cluster/ha/resources/:sid/relocate returns 200" do
      conn = request(:post, "/api2/json/cluster/ha/resources/vm%3A100/relocate")
      assert conn.status == 200
    end
  end

  # --- Metrics export ---

  describe "Metrics export" do
    test "GET /cluster/metrics/export returns 200" do
      conn = request(:get, "/api2/json/cluster/metrics/export")
      assert conn.status == 200
    end
  end

  # --- SDN vnet IPs ---

  describe "SDN vnet IPs" do
    test "POST /cluster/sdn/vnets/:vnet/ips returns 200" do
      conn = request(:post, "/api2/json/cluster/sdn/vnets/myvnet/ips", %{ip: "10.0.0.1/24"})
      assert conn.status == 200
    end

    test "PUT /cluster/sdn/vnets/:vnet/ips returns 200" do
      conn = request(:put, "/api2/json/cluster/sdn/vnets/myvnet/ips")
      assert conn.status == 200
    end

    test "DELETE /cluster/sdn/vnets/:vnet/ips returns 200" do
      conn = request(:delete, "/api2/json/cluster/sdn/vnets/myvnet/ips")
      assert conn.status == 200
    end
  end

  # --- Bulk-action/guest (PVE 9.0+) ---

  describe "Bulk-action/guest" do
    setup do
      Application.put_env(:mock_pve_api, :pve_version, "9.0")
      State.reset()
      :ok
    end

    test "GET /cluster/bulk-action/guest returns 200" do
      conn = request(:get, "/api2/json/cluster/bulk-action/guest")
      assert conn.status == 200
    end

    test "POST /cluster/bulk-action/guest/start returns 200" do
      conn = request(:post, "/api2/json/cluster/bulk-action/guest/start")
      assert conn.status == 200
    end

    test "POST /cluster/bulk-action/guest/shutdown returns 200" do
      conn = request(:post, "/api2/json/cluster/bulk-action/guest/shutdown")
      assert conn.status == 200
    end

    test "POST /cluster/bulk-action/guest/suspend returns 200" do
      conn = request(:post, "/api2/json/cluster/bulk-action/guest/suspend")
      assert conn.status == 200
    end

    test "POST /cluster/bulk-action/guest/migrate returns 200" do
      conn = request(:post, "/api2/json/cluster/bulk-action/guest/migrate")
      assert conn.status == 200
    end
  end
end
