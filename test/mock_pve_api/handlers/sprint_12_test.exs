# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Sprint12Test do
  @moduledoc """
  Tests for Sprint 4.9.12 endpoints:
  - Node apt index/changelog/repositories
  - Node capabilities (qemu, cpu, machines, cpu-flags, migration)
  - Node certificates index/acme/custom
  - Node disks/directory CRUD
  - Node console stubs (termproxy, spiceshell, vncwebsocket)
  - Node wakeonlan/suspendall
  - VM/LXC specific status action catalog entries
  - Access TFA per-entry (GET/PUT/DELETE)
  - Access user TFA methods and unlock-tfa
  - SDN vnet firewall stubs
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

  # --- Node apt endpoints ---

  describe "node apt" do
    test "GET /nodes/:node/apt returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/apt")
      assert conn.status == 200
    end

    test "GET /nodes/:node/apt/changelog returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/apt/changelog")
      assert conn.status == 200
    end

    test "GET /nodes/:node/apt/repositories returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/apt/repositories")
      assert conn.status == 200
      body = json_body(conn)
      assert is_map(body["data"])
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

  # --- Node capabilities ---

  describe "node capabilities" do
    test "GET /nodes/:node/capabilities returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/capabilities")
      assert conn.status == 200
    end

    test "GET /nodes/:node/capabilities/qemu returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/capabilities/qemu")
      assert conn.status == 200
    end

    test "GET /nodes/:node/capabilities/qemu/cpu returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/capabilities/qemu/cpu")
      assert conn.status == 200
    end

    test "GET /nodes/:node/capabilities/qemu/machines returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/capabilities/qemu/machines")
      assert conn.status == 200
    end

    test "GET /nodes/:node/capabilities/qemu/cpu-flags returns 200 on 9.0" do
      Application.put_env(:mock_pve_api, :pve_version, "9.0")
      State.reset()
      conn = request(:get, "/api2/json/nodes/pve1/capabilities/qemu/cpu-flags")
      assert conn.status == 200
    end

    test "GET /nodes/:node/capabilities/qemu/migration returns 200 on 9.0" do
      Application.put_env(:mock_pve_api, :pve_version, "9.0")
      State.reset()
      conn = request(:get, "/api2/json/nodes/pve1/capabilities/qemu/migration")
      assert conn.status == 200
    end
  end

  # --- Node certificates ---

  describe "node certificates" do
    test "GET /nodes/:node/certificates returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/certificates")
      assert conn.status == 200
      body = json_body(conn)
      assert is_list(body["data"])
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

  # --- Node disks/directory ---

  describe "node disks directory" do
    test "GET /nodes/:node/disks/directory returns 200" do
      conn = request(:get, "/api2/json/nodes/pve1/disks/directory")
      assert conn.status == 200
      body = json_body(conn)
      assert is_list(body["data"])
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

  # --- Node console stubs ---

  describe "node console and power management" do
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

    test "POST /nodes/:node/suspendall returns 200 on 8.1+" do
      conn = request(:post, "/api2/json/nodes/pve1/suspendall")
      assert conn.status == 200
    end
  end

  # --- VM specific status actions ---

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

  # --- LXC specific status actions ---

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

  # --- Access TFA per-entry ---

  describe "TFA per-entry" do
    test "GET /access/tfa/:userid/:id returns 200" do
      conn = request(:get, "/api2/json/access/tfa/root@pam/tfa-123")
      assert conn.status == 200
    end

    test "PUT /access/tfa/:userid/:id returns 200" do
      conn = request(:put, "/api2/json/access/tfa/root@pam/tfa-123")
      assert conn.status == 200
    end

    test "DELETE /access/tfa/:userid/:id returns 200" do
      conn = request(:delete, "/api2/json/access/tfa/root@pam/tfa-123")
      assert conn.status == 200
    end
  end

  # --- Access user TFA and unlock ---

  describe "user TFA management" do
    test "GET /access/users/:userid/tfa returns list" do
      conn = request(:get, "/api2/json/access/users/root@pam/tfa")
      assert conn.status == 200
      body = json_body(conn)
      assert is_list(body["data"])
    end

    test "PUT /access/users/:userid/unlock-tfa returns 200" do
      conn = request(:put, "/api2/json/access/users/root@pam/unlock-tfa")
      assert conn.status == 200
    end
  end

  # --- SDN vnet firewall ---

  describe "SDN vnet firewall" do
    test "GET /cluster/sdn/vnets/:vnet/firewall returns list" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/myvnet/firewall")
      assert conn.status == 200
      body = json_body(conn)
      assert is_list(body["data"])
    end

    test "GET /cluster/sdn/vnets/:vnet/firewall/options returns 200" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/myvnet/firewall/options")
      assert conn.status == 200
    end

    test "PUT /cluster/sdn/vnets/:vnet/firewall/options returns 200" do
      conn = request(:put, "/api2/json/cluster/sdn/vnets/myvnet/firewall/options")
      assert conn.status == 200
    end

    test "GET /cluster/sdn/vnets/:vnet/firewall/rules returns list" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/myvnet/firewall/rules")
      assert conn.status == 200
      body = json_body(conn)
      assert is_list(body["data"])
    end

    test "POST /cluster/sdn/vnets/:vnet/firewall/rules returns 200" do
      conn = request(:post, "/api2/json/cluster/sdn/vnets/myvnet/firewall/rules")
      assert conn.status == 200
    end

    test "GET /cluster/sdn/vnets/:vnet/firewall/rules/:pos returns 200" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/myvnet/firewall/rules/0")
      assert conn.status == 200
    end

    test "PUT /cluster/sdn/vnets/:vnet/firewall/rules/:pos returns 200" do
      conn = request(:put, "/api2/json/cluster/sdn/vnets/myvnet/firewall/rules/0")
      assert conn.status == 200
    end

    test "DELETE /cluster/sdn/vnets/:vnet/firewall/rules/:pos returns 200" do
      conn = request(:delete, "/api2/json/cluster/sdn/vnets/myvnet/firewall/rules/0")
      assert conn.status == 200
    end
  end
end
