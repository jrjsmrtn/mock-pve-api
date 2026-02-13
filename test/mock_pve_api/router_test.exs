# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.RouterTest do
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

  # --- Auth plug ---

  describe "authentication" do
    test "version endpoint does not require auth" do
      conn = Plug.Test.conn(:get, "/api2/json/version") |> call()
      assert conn.status == 200
    end

    test "ticket endpoint does not require auth" do
      conn =
        Plug.Test.conn(
          :post,
          "/api2/json/access/ticket",
          Jason.encode!(%{username: "root@pam", password: "secret"})
        )
        |> Plug.Conn.put_req_header("content-type", "application/json")
        |> call()

      assert conn.status == 200
    end

    test "other endpoints return 401 without auth" do
      conn = Plug.Test.conn(:get, "/api2/json/nodes") |> call()
      assert conn.status == 401
      body = Jason.decode!(conn.resp_body)
      assert body["errors"]["message"] == "authentication failure"
    end

    test "Bearer token auth passes" do
      conn = authed_conn(:get, "/api2/json/nodes") |> call()
      assert conn.status == 200
    end

    test "PVEAuthCookie auth passes" do
      conn =
        Plug.Test.conn(:get, "/api2/json/nodes")
        |> Plug.Conn.put_req_header("authorization", "PVEAuthCookie=some-ticket")
        |> call()

      assert conn.status == 200
    end

    test "PVEAPIToken auth passes" do
      conn =
        Plug.Test.conn(:get, "/api2/json/nodes")
        |> Plug.Conn.put_req_header("authorization", "PVEAPIToken=user@pam!token=value")
        |> call()

      assert conn.status == 200
    end

    test "cookie-based auth passes" do
      conn =
        Plug.Test.conn(:get, "/api2/json/nodes")
        |> Plug.Conn.put_req_header("cookie", "PVEAuthCookie=some-ticket; other=value")
        |> call()

      assert conn.status == 200
    end

    test "cookie without PVEAuthCookie returns 401" do
      conn =
        Plug.Test.conn(:get, "/api2/json/nodes")
        |> Plug.Conn.put_req_header("cookie", "other=value; session=abc")
        |> call()

      assert conn.status == 401
    end

    test "unknown authorization header format returns 401" do
      conn =
        Plug.Test.conn(:get, "/api2/json/nodes")
        |> Plug.Conn.put_req_header("authorization", "Basic dXNlcjpwYXNz")
        |> call()

      assert conn.status == 401
    end
  end

  # --- CORS ---

  describe "CORS headers" do
    test "includes CORS headers in response" do
      conn = authed_conn(:get, "/api2/json/nodes") |> call()

      assert Plug.Conn.get_resp_header(conn, "access-control-allow-origin") == ["*"]

      allow_methods = Plug.Conn.get_resp_header(conn, "access-control-allow-methods")
      assert length(allow_methods) == 1
      assert allow_methods |> hd() =~ "GET"
      assert allow_methods |> hd() =~ "POST"

      allow_headers = Plug.Conn.get_resp_header(conn, "access-control-allow-headers")
      assert length(allow_headers) == 1
      assert allow_headers |> hd() =~ "authorization"
    end
  end

  # --- Node routes ---

  describe "node routes" do
    test "GET /nodes returns nodes" do
      conn = authed_conn(:get, "/api2/json/nodes") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end

    test "GET /nodes/:node returns specific node" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/status returns node status" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/status") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/version returns node version" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/version") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/tasks returns tasks" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/tasks") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/syslog returns syslog" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/syslog") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/network returns network" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/network") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/execute runs command" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/execute", %{command: "uptime"}) |> call()

      assert conn.status == 200
    end

    test "GET /nodes/:node/time returns time" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/time") |> call()
      assert conn.status == 200
    end

    test "PUT /nodes/:node/time sets time" do
      conn = authed_conn(:put, "/api2/json/nodes/pve-node1/time", %{timezone: "UTC"}) |> call()
      assert conn.status == 200
    end
  end

  # --- VM routes ---

  describe "VM routes" do
    test "GET /nodes/:node/qemu returns VMs" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu creates VM" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/qemu", %{vmid: 100, name: "test"})
        |> call()

      assert conn.status == 200
    end

    test "GET /nodes/:node/qemu/:vmid returns VM" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu/100") |> call()
      assert conn.status == 200
    end

    test "PUT /nodes/:node/qemu/:vmid updates VM" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:put, "/api2/json/nodes/pve-node1/qemu/100", %{memory: 4096}) |> call()
      assert conn.status == 200
    end

    test "DELETE /nodes/:node/qemu/:vmid deletes VM" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:delete, "/api2/json/nodes/pve-node1/qemu/100") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/qemu/:vmid/config returns config" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/config") |> call()
      assert conn.status == 200
    end

    test "PUT /nodes/:node/qemu/:vmid/config updates config" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        authed_conn(:put, "/api2/json/nodes/pve-node1/qemu/100/config", %{name: "updated"})
        |> call()

      assert conn.status == 200
    end

    test "GET /nodes/:node/qemu/:vmid/status/current returns status" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/status/current") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu/:vmid/status/:action starts VM" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:post, "/api2/json/nodes/pve-node1/qemu/100/status/start") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu/:vmid/migrate migrates VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/qemu/100/migrate", %{
          target: "pve-node2"
        })
        |> call()

      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu/:vmid/snapshot creates snapshot" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/qemu/100/snapshot", %{snapname: "snap1"})
        |> call()

      assert conn.status == 200
    end

    test "POST /nodes/:node/qemu/:vmid/clone clones VM" do
      State.create_vm("pve-node1", 100, %{name: "original"})

      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/qemu/100/clone", %{newid: 101})
        |> call()

      assert conn.status == 200
    end
  end

  # --- Container routes ---

  describe "container routes" do
    test "GET /nodes/:node/lxc returns containers" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/lxc") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/lxc creates container" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/lxc", %{vmid: 200, hostname: "ct"})
        |> call()

      assert conn.status == 200
    end

    test "GET /nodes/:node/lxc/:vmid returns container" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/lxc/200") |> call()
      assert conn.status == 200
    end

    test "PUT /nodes/:node/lxc/:vmid updates container" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:put, "/api2/json/nodes/pve-node1/lxc/200", %{memory: 2048}) |> call()
      assert conn.status == 200
    end

    test "DELETE /nodes/:node/lxc/:vmid deletes container" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:delete, "/api2/json/nodes/pve-node1/lxc/200") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/lxc/:vmid/config returns config" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/config") |> call()
      assert conn.status == 200
    end

    test "PUT /nodes/:node/lxc/:vmid/config updates config" do
      State.create_container("pve-node1", 200, %{})

      conn =
        authed_conn(:put, "/api2/json/nodes/pve-node1/lxc/200/config", %{hostname: "renamed"})
        |> call()

      assert conn.status == 200
    end

    test "GET /nodes/:node/lxc/:vmid/status/current returns status" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/status/current") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/lxc/:vmid/status/:action starts container" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:post, "/api2/json/nodes/pve-node1/lxc/200/status/start") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/lxc/:vmid/migrate migrates container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/lxc/200/migrate", %{target: "pve-node2"})
        |> call()

      assert conn.status == 200
    end

    test "POST /nodes/:node/lxc/:vmid/clone clones container" do
      State.create_container("pve-node1", 200, %{hostname: "original"})

      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/lxc/200/clone", %{newid: 201})
        |> call()

      assert conn.status == 200
    end
  end

  # --- Backup routes ---

  describe "backup routes" do
    test "POST /nodes/:node/vzdump creates backup" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:post, "/api2/json/nodes/pve-node1/vzdump", %{vmid: "100"}) |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/storage/:storage/backup lists backups" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/storage/local/backup") |> call()
      assert conn.status == 200
    end
  end

  # --- Task routes ---

  describe "task routes" do
    test "GET /nodes/:node/tasks/:upid/status returns task status" do
      {:ok, upid} = State.create_task("pve-node1", "qmstart", %{vmid: 100})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/status") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/tasks/:upid/log returns task log" do
      {:ok, upid} = State.create_task("pve-node1", "qmstart", %{vmid: 100})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/tasks/#{upid}/log") |> call()
      assert conn.status == 200
    end
  end

  # --- Metrics routes ---

  describe "metrics routes" do
    test "GET /nodes/:node/rrd returns RRD data" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/rrd") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/rrddata returns RRD data points" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/rrddata") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/qemu/:vmid/rrd returns VM RRD" do
      State.create_vm("pve-node1", 100, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/qemu/100/rrd") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/lxc/:vmid/rrd returns container RRD" do
      State.create_container("pve-node1", 200, %{})
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/lxc/200/rrd") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/netstat returns network stats" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/netstat") |> call()
      assert conn.status == 200
    end

    test "GET /nodes/:node/report returns node report" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/report") |> call()
      assert conn.status == 200
    end

    test "GET /cluster/metrics/server/:id returns cluster metrics" do
      conn = authed_conn(:get, "/api2/json/cluster/metrics/server/node1") |> call()
      assert conn.status == 200
    end
  end

  # --- Storage routes ---

  describe "storage routes" do
    test "GET /storage returns storage list" do
      conn = authed_conn(:get, "/api2/json/storage") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end

    test "GET /nodes/:node/storage/:storage/content returns content" do
      conn = authed_conn(:get, "/api2/json/nodes/pve-node1/storage/local/content") |> call()
      assert conn.status == 200
    end

    test "POST /nodes/:node/storage/:storage/content creates content" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/storage/local/content", %{
          filename: "test.iso"
        })
        |> call()

      assert conn.status == 200
    end
  end

  # --- Cluster routes ---

  describe "cluster routes" do
    test "GET /cluster/status returns cluster status" do
      conn = authed_conn(:get, "/api2/json/cluster/status") |> call()
      assert conn.status == 200
    end

    test "GET /cluster/resources returns resources" do
      conn = authed_conn(:get, "/api2/json/cluster/resources") |> call()
      assert conn.status == 200
    end

    test "GET /cluster/nextid returns next VMID" do
      conn = authed_conn(:get, "/api2/json/cluster/nextid") |> call()
      assert conn.status == 200
    end

    test "GET /cluster/config returns config" do
      conn = authed_conn(:get, "/api2/json/cluster/config") |> call()
      assert conn.status == 200
    end

    test "PUT /cluster/config updates config" do
      conn = authed_conn(:put, "/api2/json/cluster/config", %{name: "test-cluster"}) |> call()
      assert conn.status == 200
    end

    test "POST /cluster/config/join joins cluster" do
      conn =
        authed_conn(:post, "/api2/json/cluster/config/join", %{hostname: "pve-new"})
        |> call()

      assert conn.status == 200
    end

    test "GET /cluster/config/nodes returns nodes config" do
      conn = authed_conn(:get, "/api2/json/cluster/config/nodes") |> call()
      assert conn.status == 200
    end

    test "DELETE /cluster/config/nodes/:node removes node" do
      conn = authed_conn(:delete, "/api2/json/cluster/config/nodes/pve-node2") |> call()
      assert conn.status == 200
    end

    test "GET /cluster/backup-info/providers returns providers or 501" do
      conn = authed_conn(:get, "/api2/json/cluster/backup-info/providers") |> call()
      assert conn.status in [200, 501]
    end

    test "GET /cluster/ha/affinity returns affinity rules" do
      conn = authed_conn(:get, "/api2/json/cluster/ha/affinity") |> call()
      # 501 if PVE version < 9.0
      assert conn.status in [200, 501]
    end

    test "POST /cluster/ha/affinity creates affinity rule" do
      conn =
        authed_conn(:post, "/api2/json/cluster/ha/affinity", %{
          name: "rule1",
          nodes: "pve-node1"
        })
        |> call()

      # 501 if PVE version < 9.0
      assert conn.status in [200, 501]
    end
  end

  # --- Pool routes ---

  describe "pool routes" do
    test "GET /pools returns pools" do
      conn = authed_conn(:get, "/api2/json/pools") |> call()
      assert conn.status == 200
    end

    test "GET /pools/:poolid returns specific pool" do
      State.create_pool("test-pool", %{})
      conn = authed_conn(:get, "/api2/json/pools/test-pool") |> call()
      assert conn.status == 200
    end

    test "POST /pools creates pool" do
      conn = authed_conn(:post, "/api2/json/pools", %{poolid: "test-pool"}) |> call()
      assert conn.status == 200
    end

    test "PUT /pools/:poolid updates pool" do
      State.create_pool("test-pool", %{})
      conn = authed_conn(:put, "/api2/json/pools/test-pool", %{comment: "Updated"}) |> call()
      assert conn.status == 200
    end

    test "DELETE /pools/:poolid deletes pool" do
      State.create_pool("test-pool", %{})
      conn = authed_conn(:delete, "/api2/json/pools/test-pool") |> call()
      assert conn.status == 200
    end
  end

  # --- Access routes ---

  describe "access routes" do
    test "GET /access/users returns users" do
      conn = authed_conn(:get, "/api2/json/access/users") |> call()
      assert conn.status == 200
    end

    test "POST /access/users creates user" do
      conn =
        authed_conn(:post, "/api2/json/access/users", %{
          userid: "test@pam",
          password: "secret"
        })
        |> call()

      assert conn.status == 200
    end

    test "GET /access/users/:userid returns user" do
      conn = authed_conn(:get, "/api2/json/access/users/root@pam") |> call()
      assert conn.status == 200
    end

    test "PUT /access/users/:userid updates user" do
      conn =
        authed_conn(:put, "/api2/json/access/users/root@pam", %{comment: "Updated"})
        |> call()

      assert conn.status == 200
    end

    test "DELETE /access/users/:userid deletes user" do
      State.create_user("testdel@pam", %{})

      conn = authed_conn(:delete, "/api2/json/access/users/testdel@pam") |> call()
      assert conn.status == 200
    end

    test "GET /access/users/:userid/token lists tokens" do
      conn = authed_conn(:get, "/api2/json/access/users/root@pam/token") |> call()
      assert conn.status == 200
    end

    test "POST /access/users/:userid/token/:tokenid creates token" do
      conn =
        authed_conn(:post, "/api2/json/access/users/root@pam/token/automation", %{
          comment: "test"
        })
        |> call()

      assert conn.status == 200
    end

    test "GET /access/users/:userid/token/:tokenid gets token" do
      State.create_api_token("root@pam", "automation", %{})

      conn =
        authed_conn(:get, "/api2/json/access/users/root@pam/token/automation")
        |> call()

      assert conn.status == 200
    end

    test "PUT /access/users/:userid/token/:tokenid updates token" do
      State.create_api_token("root@pam", "automation", %{})

      conn =
        authed_conn(:put, "/api2/json/access/users/root@pam/token/automation", %{
          comment: "updated"
        })
        |> call()

      assert conn.status == 200
    end

    test "DELETE /access/users/:userid/token/:tokenid deletes token" do
      State.create_api_token("root@pam", "automation", %{})

      conn =
        authed_conn(:delete, "/api2/json/access/users/root@pam/token/automation")
        |> call()

      assert conn.status == 200
    end

    test "GET /access/groups returns groups" do
      conn = authed_conn(:get, "/api2/json/access/groups") |> call()
      assert conn.status == 200
    end

    test "POST /access/groups creates group" do
      conn =
        authed_conn(:post, "/api2/json/access/groups", %{groupid: "devs"})
        |> call()

      assert conn.status == 200
    end

    test "GET /access/groups/:groupid returns group" do
      State.create_group("devs", %{})
      conn = authed_conn(:get, "/api2/json/access/groups/devs") |> call()
      assert conn.status == 200
    end

    test "PUT /access/groups/:groupid updates group" do
      State.create_group("devs", %{})

      conn =
        authed_conn(:put, "/api2/json/access/groups/devs", %{comment: "Developers"})
        |> call()

      assert conn.status == 200
    end

    test "DELETE /access/groups/:groupid deletes group" do
      State.create_group("devs", %{})
      conn = authed_conn(:delete, "/api2/json/access/groups/devs") |> call()
      assert conn.status == 200
    end

    test "GET /access/domains returns domains" do
      conn = authed_conn(:get, "/api2/json/access/domains") |> call()
      assert conn.status == 200
    end

    test "GET /access/permissions returns permissions" do
      conn = authed_conn(:get, "/api2/json/access/permissions") |> call()
      assert conn.status == 200
    end

    test "PUT /access/acl sets ACL" do
      conn =
        authed_conn(:put, "/api2/json/access/acl", %{
          path: "/vms",
          users: "root@pam",
          roles: "PVEAdmin"
        })
        |> call()

      assert conn.status == 200
    end

    test "GET /access/roles returns roles" do
      conn = authed_conn(:get, "/api2/json/access/roles") |> call()
      assert conn.status == 200
    end
  end

  # --- SDN routes ---

  describe "SDN routes" do
    test "GET /cluster/sdn/zones returns zones list" do
      conn = authed_conn(:get, "/api2/json/cluster/sdn/zones") |> call()
      assert conn.status in [200, 501]
    end

    test "GET /cluster/sdn/zones/:zone returns zone" do
      conn = authed_conn(:get, "/api2/json/cluster/sdn/zones/vlan-zone") |> call()
      assert conn.status in [200, 501]
    end

    test "PUT /cluster/sdn/zones/:zone updates zone" do
      conn =
        authed_conn(:put, "/api2/json/cluster/sdn/zones/vlan-zone", %{bridge: "vmbr1"})
        |> call()

      assert conn.status in [200, 501]
    end

    test "DELETE /cluster/sdn/zones/:zone deletes zone" do
      conn = authed_conn(:delete, "/api2/json/cluster/sdn/zones/vlan-zone") |> call()
      assert conn.status in [200, 501]
    end

    test "GET /cluster/sdn/vnets returns vnets" do
      conn = authed_conn(:get, "/api2/json/cluster/sdn/vnets") |> call()
      assert conn.status in [200, 501]
    end

    test "POST /cluster/sdn/vnets creates vnet" do
      conn =
        authed_conn(:post, "/api2/json/cluster/sdn/vnets", %{vnet: "vnet100", zone: "simple"})
        |> call()

      assert conn.status in [200, 501]
    end

    test "GET /cluster/sdn/subnets returns subnets" do
      conn = authed_conn(:get, "/api2/json/cluster/sdn/subnets") |> call()
      assert conn.status in [200, 501]
    end
  end

  # --- Inline routes (realm sync, notifications, VMware import, backup providers) ---

  describe "inline routes" do
    test "POST /access/domains/:realm/sync returns sync task" do
      conn = authed_conn(:post, "/api2/json/access/domains/pam/sync") |> call()
      assert conn.status in [200, 501]
    end

    test "GET /cluster/notifications/endpoints returns endpoints" do
      conn = authed_conn(:get, "/api2/json/cluster/notifications/endpoints") |> call()
      assert conn.status in [200, 501]
    end

    test "GET /cluster/notifications/filters returns filters" do
      conn = authed_conn(:get, "/api2/json/cluster/notifications/filters") |> call()
      assert conn.status in [200, 501]
    end

    test "POST /nodes/:node/storage/:storage/import returns import task" do
      conn =
        authed_conn(:post, "/api2/json/nodes/pve-node1/storage/local/import")
        |> call()

      assert conn.status in [200, 501]
    end

    test "GET /cluster/backup-providers returns providers" do
      conn = authed_conn(:get, "/api2/json/cluster/backup-providers") |> call()
      assert conn.status in [200, 501]
    end
  end

  # --- Coverage API endpoints ---

  describe "coverage API endpoints" do
    test "GET /_coverage/stats returns stats" do
      conn = authed_conn(:get, "/api2/json/_coverage/stats") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_map(body["data"])
      assert Map.has_key?(body["data"], "total")
    end

    test "GET /_coverage/categories returns category stats" do
      conn = authed_conn(:get, "/api2/json/_coverage/categories") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_map(body["data"])
    end

    test "GET /_coverage/missing returns missing critical endpoints" do
      conn = authed_conn(:get, "/api2/json/_coverage/missing") |> call()
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
    end
  end

  # --- Catch-all ---

  describe "catch-all" do
    test "returns 404 for completely unknown endpoint" do
      conn = authed_conn(:get, "/api2/json/completely/unknown/path") |> call()
      assert conn.status in [404, 501]
    end

    test "catch-all with known but unrouted endpoint path" do
      # A path that Coverage might recognize but isn't routed
      conn = authed_conn(:get, "/api2/json/cluster/sdn/fabrics") |> call()
      assert conn.status in [200, 404, 501]
    end
  end

  # --- Endpoint support check ---

  describe "endpoint support" do
    test "version endpoint is always supported" do
      conn = Plug.Test.conn(:get, "/api2/json/version") |> call()
      assert conn.status == 200
    end

    test "coverage API endpoints always pass through" do
      conn = authed_conn(:get, "/api2/json/_coverage/stats") |> call()
      assert conn.status == 200
    end
  end
end
