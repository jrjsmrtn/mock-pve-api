# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Sprint13Test do
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn

  alias MockPveApi.Router
  alias MockPveApi.State

  @opts Router.init([])

  setup do
    prev_version = Application.get_env(:mock_pve_api, :pve_version, "8.3")

    on_exit(fn ->
      Application.put_env(:mock_pve_api, :pve_version, prev_version)
      State.reset()
    end)

    Application.put_env(:mock_pve_api, :pve_version, "9.0")
    State.reset()
    :ok
  end

  defp request(method, path, body \\ nil) do
    conn =
      conn(method, path, body)
      |> put_req_header("authorization", "Bearer test-token")
      |> put_req_header("content-type", "application/json")

    Router.call(conn, @opts)
  end

  defp json_body(conn) do
    Jason.decode!(conn.resp_body)
  end

  # --- Access index stubs ---

  test "GET /access returns 200" do
    conn = request(:get, "/api2/json/access")
    assert conn.status == 200
    assert %{"data" => _} = json_body(conn)
  end

  test "GET /access/openid returns 200" do
    conn = request(:get, "/api2/json/access/openid")
    assert conn.status == 200
  end

  test "POST /access/openid/auth-url returns 200" do
    conn =
      request(
        :post,
        "/api2/json/access/openid/auth-url",
        ~s({"redirect_url":"https://example.com"})
      )

    assert conn.status == 200
  end

  test "POST /access/openid/login returns 200" do
    conn = request(:post, "/api2/json/access/openid/login", ~s({"code":"abc","state":"xyz"}))
    assert conn.status == 200
  end

  test "POST /access/vncticket returns 200" do
    conn =
      request(
        :post,
        "/api2/json/access/vncticket",
        ~s({"username":"root@pam","password":"secret"})
      )

    assert conn.status == 200
  end

  # --- Cluster config stubs ---

  test "GET /cluster/config/apiversion returns 200" do
    conn = request(:get, "/api2/json/cluster/config/apiversion")
    assert conn.status == 200
    assert %{"data" => _} = json_body(conn)
  end

  test "GET /cluster/config/qdevice returns 200" do
    conn = request(:get, "/api2/json/cluster/config/qdevice")
    assert conn.status == 200
  end

  test "GET /cluster/config/totem returns 200" do
    conn = request(:get, "/api2/json/cluster/config/totem")
    assert conn.status == 200
  end

  # --- Cluster ceph flags ---

  test "GET /cluster/ceph/flags/:flag returns 200" do
    conn = request(:get, "/api2/json/cluster/ceph/flags/noout")
    assert conn.status == 200
    body = json_body(conn)
    assert %{"data" => %{"name" => "noout"}} = body
  end

  test "PUT /cluster/ceph/flags/:flag returns 200" do
    conn = request(:put, "/api2/json/cluster/ceph/flags/noout", ~s({"value":true}))
    assert conn.status == 200
  end

  # --- Cluster HA rules ---

  test "GET /cluster/ha/rules returns empty list initially" do
    conn = request(:get, "/api2/json/cluster/ha/rules")
    assert conn.status == 200
    assert %{"data" => []} = json_body(conn)
  end

  test "POST /cluster/ha/rules creates a rule" do
    conn = request(:post, "/api2/json/cluster/ha/rules", ~s({"id":"r1","type":"vm"}))
    assert conn.status == 200
  end

  test "GET /cluster/ha/rules/:rule returns rule" do
    request(:post, "/api2/json/cluster/ha/rules", ~s({"id":"r2","type":"vm"}))
    conn = request(:get, "/api2/json/cluster/ha/rules/r2")
    assert conn.status == 200
    assert %{"data" => _} = json_body(conn)
  end

  test "GET /cluster/ha/rules/:rule for unknown returns 404" do
    conn = request(:get, "/api2/json/cluster/ha/rules/nonexistent")
    assert conn.status == 404
  end

  test "DELETE /cluster/ha/rules/:rule removes rule" do
    request(:post, "/api2/json/cluster/ha/rules", ~s({"id":"r3","type":"vm"}))
    conn = request(:delete, "/api2/json/cluster/ha/rules/r3")
    assert conn.status == 200
    conn2 = request(:get, "/api2/json/cluster/ha/rules/r3")
    assert conn2.status == 404
  end

  # --- SDN fabrics stubs ---

  test "GET /cluster/sdn/fabrics returns 200" do
    conn = request(:get, "/api2/json/cluster/sdn/fabrics")
    assert conn.status == 200
  end

  test "GET /cluster/sdn/fabrics/all returns 200" do
    conn = request(:get, "/api2/json/cluster/sdn/fabrics/all")
    assert conn.status == 200
  end

  test "GET /cluster/sdn/fabrics/fabric returns 200" do
    conn = request(:get, "/api2/json/cluster/sdn/fabrics/fabric")
    assert conn.status == 200
  end

  test "POST /cluster/sdn/lock returns 200" do
    conn = request(:post, "/api2/json/cluster/sdn/lock")
    assert conn.status == 200
  end

  test "DELETE /cluster/sdn/lock returns 200" do
    conn = request(:delete, "/api2/json/cluster/sdn/lock")
    assert conn.status == 200
  end

  test "POST /cluster/sdn/rollback returns 200" do
    conn = request(:post, "/api2/json/cluster/sdn/rollback")
    assert conn.status == 200
  end

  test "GET /cluster/sdn/ipams/:ipam/status returns 200" do
    conn = request(:get, "/api2/json/cluster/sdn/ipams/ipam1/status")
    assert conn.status == 200
  end

  # --- Cluster mapping CRUD ---

  test "GET /cluster/mapping/pci returns list" do
    conn = request(:get, "/api2/json/cluster/mapping/pci")
    assert conn.status == 200
    assert %{"data" => []} = json_body(conn)
  end

  test "POST /cluster/mapping/dir creates mapping" do
    conn = request(:post, "/api2/json/cluster/mapping/dir", ~s({"id":"mydir","path":"/mnt/data"}))
    assert conn.status == 200
    assert %{"data" => %{"id" => "mydir"}} = json_body(conn)
  end

  test "GET /cluster/mapping/dir/:id returns 404 for unknown" do
    conn = request(:get, "/api2/json/cluster/mapping/dir/notfound")
    assert conn.status == 404
  end

  # --- Node stubs ---

  test "GET /nodes/:node/hardware returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/hardware")
    assert conn.status == 200
  end

  test "GET /nodes/:node/hardware/pci/:pciid/mdev returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/hardware/pci/0000:00:02.0/mdev")
    assert conn.status == 200
  end

  test "GET /nodes/:node/disks returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/disks")
    assert conn.status == 200
  end

  test "PUT /nodes/:node/disks/wipedisk returns 200" do
    conn = request(:put, "/api2/json/nodes/pve1/disks/wipedisk", ~s({"disk":"sdb"}))
    assert conn.status == 200
  end

  test "DELETE /nodes/:node/disks/lvm/:name returns 200" do
    conn = request(:delete, "/api2/json/nodes/pve1/disks/lvm/pve")
    assert conn.status == 200
  end

  test "GET /nodes/:node/aplinfo returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/aplinfo")
    assert conn.status == 200
  end

  test "POST /nodes/:node/aplinfo returns 200" do
    conn = request(:post, "/api2/json/nodes/pve1/aplinfo", ~s({"storage":"local"}))
    assert conn.status == 200
  end

  test "POST /nodes/:node/vncshell returns 200" do
    conn = request(:post, "/api2/json/nodes/pve1/vncshell", "")
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

  test "GET /nodes/:node/sdn returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/sdn")
    assert conn.status == 200
  end

  test "GET /nodes/:node/sdn/zones returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/sdn/zones")
    assert conn.status == 200
  end

  test "GET /nodes/:node/sdn/zones/:zone returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/sdn/zones/myzone")
    assert conn.status == 200
  end

  test "GET /nodes/:node/sdn/zones/:zone/content returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/sdn/zones/myzone/content")
    assert conn.status == 200
  end

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
    conn = request(:post, "/api2/json/nodes/pve1/ceph/init", ~s({"network":"10.0.0.0/8"}))
    assert conn.status == 200
  end

  test "POST /nodes/:node/ceph/start returns 200" do
    conn = request(:post, "/api2/json/nodes/pve1/ceph/start", "")
    assert conn.status == 200
  end

  test "POST /nodes/:node/ceph/stop returns 200" do
    conn = request(:post, "/api2/json/nodes/pve1/ceph/stop", "")
    assert conn.status == 200
  end

  test "GET /nodes/:node/ceph/osd/:osdid returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/ceph/osd/0")
    assert conn.status == 200
  end

  test "POST /nodes/:node/ceph/osd/:osdid/in returns 200" do
    conn = request(:post, "/api2/json/nodes/pve1/ceph/osd/0/in", "")
    assert conn.status == 200
  end

  test "POST /nodes/:node/storage/:storage/download-url returns 200" do
    conn =
      request(
        :post,
        "/api2/json/nodes/pve1/storage/local/download-url",
        ~s({"url":"http://example.com/img.iso","filename":"img.iso"})
      )

    assert conn.status == 200
  end

  test "GET /nodes/:node/storage/:storage/import-metadata returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/storage/local/import-metadata")
    assert conn.status == 200
  end

  test "GET /nodes/:node/storage/:storage returns 200" do
    conn = request(:get, "/api2/json/nodes/pve1/storage/local")
    assert conn.status == 200
  end

  test "POST /nodes/:node/qemu/:vmid/dbus-vmstate returns 200" do
    conn = request(:post, "/api2/json/nodes/pve1/qemu/100/dbus-vmstate", "")
    assert conn.status == 200
  end
end
