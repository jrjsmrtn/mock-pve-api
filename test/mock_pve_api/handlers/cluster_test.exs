# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.ClusterTest do
  @moduledoc """
  Tests for cluster handler endpoints including HA resources, HA groups,
  HA affinity rules, backup jobs, backup info, and cluster options.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Cluster
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params \\ %{}, path_params \\ %{}) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

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

  # Existing cluster tests (direct handler calls)

  describe "get_resources/1" do
    test "returns cluster resources" do
      conn = build_conn(:get, "/api2/json/cluster/resources")
      conn = Cluster.get_resources(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      assert length(body["data"]) >= 2
    end
  end

  describe "get_next_vmid/1" do
    test "returns next available VMID" do
      conn = build_conn(:get, "/api2/json/cluster/nextid")
      conn = Cluster.get_next_vmid(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_integer(body["data"])
    end
  end

  describe "get_cluster_status/1" do
    test "returns cluster status" do
      conn = build_conn(:get, "/api2/json/cluster/status")
      conn = Cluster.get_cluster_status(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  describe "join_cluster/1" do
    test "joins a node to the cluster" do
      conn =
        build_conn(:post, "/api2/json/cluster/config/join", %{
          "hostname" => "pve-node3",
          "votes" => 1
        })

      conn = Cluster.join_cluster(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_binary(body["data"])
    end

    test "returns 400 when hostname is missing" do
      conn = build_conn(:post, "/api2/json/cluster/config/join", %{"votes" => 1})
      conn = Cluster.join_cluster(conn)
      assert conn.status == 400
    end
  end

  describe "get_cluster_config/1" do
    test "returns cluster configuration" do
      conn = build_conn(:get, "/api2/json/cluster/config")
      conn = Cluster.get_cluster_config(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["cluster_name"] == "pve-cluster"
    end
  end

  describe "update_cluster_config/1" do
    test "updates cluster name" do
      conn =
        build_conn(:put, "/api2/json/cluster/config", %{"cluster_name" => "new-cluster"})

      conn = Cluster.update_cluster_config(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["cluster_name"] == "new-cluster"
    end
  end

  describe "get_cluster_nodes_config/1" do
    test "returns nodes configuration" do
      conn = build_conn(:get, "/api2/json/cluster/config/nodes")
      conn = Cluster.get_cluster_nodes_config(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  describe "remove_cluster_node/1" do
    test "removes an existing node" do
      conn =
        build_conn(:delete, "/api2/json/cluster/config/nodes/pve-node2", %{}, %{
          "node" => "pve-node2"
        })

      conn = Cluster.remove_cluster_node(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent node" do
      conn =
        build_conn(:delete, "/api2/json/cluster/config/nodes/nonexistent", %{}, %{
          "node" => "nonexistent"
        })

      conn = Cluster.remove_cluster_node(conn)
      assert conn.status == 404
    end
  end

  describe "list_backup_providers/1" do
    test "returns backup providers" do
      conn = build_conn(:get, "/api2/json/cluster/backup-info/providers")
      conn = Cluster.list_backup_providers(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  # Sprint 4.9.2 - HA Resources (via router)

  describe "HA resources" do
    test "list empty HA resources" do
      conn = request(:get, "/api2/json/cluster/ha/resources")
      assert json(conn, 200)["data"] == []
    end

    test "create and list HA resource" do
      conn = request(:post, "/api2/json/cluster/ha/resources", %{"sid" => "vm:100"})
      assert conn.status == 200

      conn = request(:get, "/api2/json/cluster/ha/resources")
      resources = json(conn, 200)["data"]
      assert length(resources) == 1
      assert hd(resources)["sid"] == "vm:100"
      assert hd(resources)["type"] == "vm"
    end

    test "get individual HA resource" do
      State.create_ha_resource("vm:100", %{"state" => "started"})

      conn = request(:get, "/api2/json/cluster/ha/resources/vm:100")
      resource = json(conn, 200)["data"]
      assert resource["sid"] == "vm:100"
      assert resource["state"] == "started"
    end

    test "update HA resource" do
      State.create_ha_resource("vm:100", %{"state" => "started"})

      conn =
        request(:put, "/api2/json/cluster/ha/resources/vm:100", %{"state" => "disabled"})

      assert conn.status == 200

      updated = State.get_ha_resource("vm:100")
      assert updated.state == "disabled"
    end

    test "delete HA resource" do
      State.create_ha_resource("vm:100", %{})

      conn = request(:delete, "/api2/json/cluster/ha/resources/vm:100")
      assert conn.status == 200
      assert State.get_ha_resource("vm:100") == nil
    end

    test "create duplicate HA resource returns 400" do
      State.create_ha_resource("vm:100", %{})
      conn = request(:post, "/api2/json/cluster/ha/resources", %{"sid" => "vm:100"})
      assert conn.status == 400
    end

    test "get nonexistent HA resource returns 404" do
      conn = request(:get, "/api2/json/cluster/ha/resources/vm:999")
      assert conn.status == 404
    end

    test "create HA resource requires sid" do
      conn = request(:post, "/api2/json/cluster/ha/resources", %{})
      assert conn.status == 400
    end

    test "ct resource type detected from sid" do
      State.create_ha_resource("ct:200", %{})
      resource = State.get_ha_resource("ct:200")
      assert resource.type == "ct"
    end
  end

  # Sprint 4.9.2 - HA Status

  describe "HA status" do
    test "get HA status with no resources" do
      conn = request(:get, "/api2/json/cluster/ha/status/current")
      status = json(conn, 200)["data"]
      assert length(status) == 1
      assert hd(status)["type"] == "manager"
    end

    test "get HA status with resources" do
      State.create_ha_resource("vm:100", %{"state" => "started"})

      conn = request(:get, "/api2/json/cluster/ha/status/current")
      status = json(conn, 200)["data"]
      assert length(status) == 2

      service = Enum.find(status, &(&1["type"] == "service"))
      assert service["sid"] == "vm:100"
    end
  end

  # Sprint 4.9.2 - HA Groups

  describe "HA groups" do
    test "list empty HA groups" do
      conn = request(:get, "/api2/json/cluster/ha/groups")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for HA group" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/ha/groups", %{
          "group" => "db-group",
          "nodes" => "pve-node1,pve-node2"
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/ha/groups/db-group")
      group = json(conn, 200)["data"]
      assert group["group"] == "db-group"
      assert group["nodes"] == "pve-node1,pve-node2"

      # Update
      conn =
        request(:put, "/api2/json/cluster/ha/groups/db-group", %{
          "comment" => "Database servers"
        })

      assert conn.status == 200
      updated = State.get_ha_group("db-group")
      assert updated.comment == "Database servers"

      # Delete
      conn = request(:delete, "/api2/json/cluster/ha/groups/db-group")
      assert conn.status == 200
      assert State.get_ha_group("db-group") == nil
    end

    test "create duplicate HA group returns 400" do
      State.create_ha_group("test-group", %{})
      conn = request(:post, "/api2/json/cluster/ha/groups", %{"group" => "test-group"})
      assert conn.status == 400
    end

    test "get nonexistent HA group returns 404" do
      conn = request(:get, "/api2/json/cluster/ha/groups/nonexistent")
      assert conn.status == 404
    end

    test "create HA group requires group name" do
      conn = request(:post, "/api2/json/cluster/ha/groups", %{})
      assert conn.status == 400
    end
  end

  # Sprint 4.9.2 - HA Affinity Rules (now stateful)

  describe "HA affinity rules" do
    test "list empty affinity rules" do
      conn = request(:get, "/api2/json/cluster/ha/affinity")
      assert json(conn, 200)["data"] == []
    end

    test "create and get affinity rule" do
      conn =
        request(:post, "/api2/json/cluster/ha/affinity", %{
          "id" => "rule-1",
          "type" => "anti-affinity"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/cluster/ha/affinity/rule-1")
      rule = json(conn, 200)["data"]
      assert rule["id"] == "rule-1"
      assert rule["type"] == "anti-affinity"
    end

    test "update affinity rule" do
      State.create_ha_affinity_rule("rule-1", %{"type" => "affinity"})

      conn =
        request(:put, "/api2/json/cluster/ha/affinity/rule-1", %{"comment" => "Updated rule"})

      assert conn.status == 200
      updated = State.get_ha_affinity_rule("rule-1")
      assert updated.comment == "Updated rule"
    end

    test "delete affinity rule" do
      State.create_ha_affinity_rule("rule-1", %{})

      conn = request(:delete, "/api2/json/cluster/ha/affinity/rule-1")
      assert conn.status == 200
      assert State.get_ha_affinity_rule("rule-1") == nil
    end

    test "get nonexistent affinity rule returns 404" do
      conn = request(:get, "/api2/json/cluster/ha/affinity/nonexistent")
      assert conn.status == 404
    end
  end

  # Sprint 4.9.2 - Backup Jobs

  describe "backup jobs" do
    test "list empty backup jobs" do
      conn = request(:get, "/api2/json/cluster/backup")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for backup job" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/backup", %{
          "schedule" => "mon-fri 02:00",
          "storage" => "local",
          "vmid" => "100,200"
        })

      assert conn.status == 200
      job_id = json(conn, 200)["data"]
      assert is_binary(job_id)

      # List
      conn = request(:get, "/api2/json/cluster/backup")
      jobs = json(conn, 200)["data"]
      assert length(jobs) == 1

      # Get
      conn = request(:get, "/api2/json/cluster/backup/#{job_id}")
      job = json(conn, 200)["data"]
      assert job["schedule"] == "mon-fri 02:00"
      assert job["vmid"] == "100,200"

      # Update
      conn =
        request(:put, "/api2/json/cluster/backup/#{job_id}", %{"schedule" => "sat 01:00"})

      assert conn.status == 200
      updated = State.get_backup_job(job_id)
      assert updated.schedule == "sat 01:00"

      # Delete
      conn = request(:delete, "/api2/json/cluster/backup/#{job_id}")
      assert conn.status == 200
      assert State.get_backup_job(job_id) == nil
    end

    test "get nonexistent backup job returns 404" do
      conn = request(:get, "/api2/json/cluster/backup/nonexistent")
      assert conn.status == 404
    end

    test "backup job IDs auto-increment" do
      {:ok, job1} = State.create_backup_job(%{})
      {:ok, job2} = State.create_backup_job(%{})
      assert job1.id == "backup-1"
      assert job2.id == "backup-2"
    end
  end

  # Sprint 4.9.2 - Backup Job Included Volumes

  describe "backup job included volumes" do
    test "get included volumes for explicit vmids" do
      {:ok, job} = State.create_backup_job(%{"vmid" => "100,200"})

      conn = request(:get, "/api2/json/cluster/backup/#{job.id}/included_volumes")
      response = json(conn, 200)["data"]
      assert length(response["children"]) == 2
    end

    test "get included volumes for 'all' backup" do
      State.create_vm("pve-node1", 100, %{})
      State.create_vm("pve-node1", 101, %{})
      {:ok, job} = State.create_backup_job(%{"all" => 1})

      conn = request(:get, "/api2/json/cluster/backup/#{job.id}/included_volumes")
      response = json(conn, 200)["data"]
      assert length(response["children"]) == 2
    end

    test "get included volumes for nonexistent job returns 404" do
      conn = request(:get, "/api2/json/cluster/backup/nonexistent/included_volumes")
      assert conn.status == 404
    end
  end

  # Sprint 4.9.2 - Backup Info Not Backed Up

  describe "backup-info not-backed-up" do
    test "returns VMs not in any backup job" do
      State.create_vm("pve-node1", 100, %{name: "backed-up-vm"})
      State.create_vm("pve-node1", 101, %{name: "not-backed-up-vm"})
      State.create_backup_job(%{"vmid" => "100"})

      conn = request(:get, "/api2/json/cluster/backup-info/not-backed-up")
      not_backed = json(conn, 200)["data"]
      assert length(not_backed) == 1
      assert hd(not_backed)["vmid"] == 101
    end

    test "returns empty when all VMs are backed up" do
      State.create_vm("pve-node1", 100, %{})
      State.create_backup_job(%{"all" => 1})

      conn = request(:get, "/api2/json/cluster/backup-info/not-backed-up")
      assert json(conn, 200)["data"] == []
    end

    test "returns empty when no VMs exist" do
      conn = request(:get, "/api2/json/cluster/backup-info/not-backed-up")
      assert json(conn, 200)["data"] == []
    end
  end

  # Sprint 4.9.2 - Cluster Options

  describe "cluster options" do
    test "get default cluster options" do
      conn = request(:get, "/api2/json/cluster/options")
      options = json(conn, 200)["data"]
      assert options["keyboard"] == "en-us"
      assert options["language"] == "en"
    end

    test "update cluster options" do
      conn =
        request(:put, "/api2/json/cluster/options", %{
          "keyboard" => "de",
          "language" => "de"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/cluster/options")
      options = json(conn, 200)["data"]
      assert options["keyboard"] == "de"
      assert options["language"] == "de"
    end
  end

  # --- Router integration tests for Sprint 4.9.5 replication endpoints ---

  describe "replication via router" do
    test "list replication jobs (empty)" do
      conn = request(:get, "/api2/json/cluster/replication")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "create and list replication job" do
      conn =
        request(:post, "/api2/json/cluster/replication", %{
          "id" => "100-0",
          "target" => "pve-node2",
          "guest" => 100,
          "schedule" => "*/15"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/cluster/replication")
      data = json(conn, 200)["data"]
      assert length(data) == 1
      job = List.first(data)
      assert job["id"] == "100-0"
      assert job["target"] == "pve-node2"
    end

    test "create duplicate replication job returns 400" do
      request(:post, "/api2/json/cluster/replication", %{
        "id" => "101-0",
        "target" => "pve-node2"
      })

      conn =
        request(:post, "/api2/json/cluster/replication", %{
          "id" => "101-0",
          "target" => "pve-node2"
        })

      assert conn.status == 400
    end

    test "create replication job without ID returns 400" do
      conn = request(:post, "/api2/json/cluster/replication", %{"target" => "pve-node2"})
      assert conn.status == 400
    end
  end
end
