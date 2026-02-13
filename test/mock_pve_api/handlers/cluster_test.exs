# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.ClusterTest do
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

  describe "list_ha_affinity_rules/1" do
    test "returns HA affinity rules" do
      conn = build_conn(:get, "/api2/json/cluster/ha/affinity")
      conn = Cluster.list_ha_affinity_rules(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  describe "create_ha_affinity_rule/1" do
    test "creates an affinity rule" do
      conn =
        build_conn(:post, "/api2/json/cluster/ha/affinity", %{
          "type" => "anti-affinity",
          "comment" => "Test rule"
        })

      conn = Cluster.create_ha_affinity_rule(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["type"] == "anti-affinity"
      assert body["data"]["comment"] == "Test rule"
    end
  end
end
