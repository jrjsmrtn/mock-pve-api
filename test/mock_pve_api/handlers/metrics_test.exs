# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.MetricsTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Metrics
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params, path_params) do
    conn = Plug.Test.conn(method, path)
    conn = %{conn | body_params: body_params, path_params: path_params}
    %{conn | query_params: %{}}
  end

  defp build_conn_with_query(method, path, path_params, query_params) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: %{}, path_params: path_params, query_params: query_params}
  end

  describe "get_node_rrd/1" do
    test "returns RRD data for existing node" do
      conn = build_conn(:get, "/api2/json/nodes/pve-node1/rrd", %{}, %{"node" => "pve-node1"})
      conn = Metrics.get_node_rrd(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_map(body["data"])
      assert Map.has_key?(body["data"], "filename")
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/rrd", %{}, %{"node" => "unknown"})
      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 404
    end

    test "respects timeframe parameter" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrd",
          %{"node" => "pve-node1"},
          %{"timeframe" => "day"}
        )

      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["resolution"] == 300
    end
  end

  describe "get_node_rrd_data/1" do
    test "returns RRD data points for existing node" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/rrddata", %{}, %{"node" => "pve-node1"})

      conn = Metrics.get_node_rrd_data(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      assert length(body["data"]) > 0

      point = hd(body["data"])
      assert Map.has_key?(point, "time")
      assert Map.has_key?(point, "cpu")
      assert Map.has_key?(point, "memory")
    end

    test "returns 404 for unknown node" do
      conn =
        build_conn(:get, "/api2/json/nodes/unknown/rrddata", %{}, %{"node" => "unknown"})

      conn = Metrics.get_node_rrd_data(conn)
      assert conn.status == 404
    end
  end

  describe "get_vm_rrd/1" do
    test "returns RRD data for existing VM" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/qemu/100/rrd",
          %{"node" => "pve-node1", "vmid" => "100"},
          %{}
        )

      conn = Metrics.get_vm_rrd(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_map(body["data"])
    end

    test "returns 404 for nonexistent VM" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/qemu/999/rrd",
          %{"node" => "pve-node1", "vmid" => "999"},
          %{}
        )

      conn = Metrics.get_vm_rrd(conn)
      assert conn.status == 404
    end
  end

  describe "get_container_rrd/1" do
    test "returns RRD data for existing container" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/lxc/200/rrd",
          %{"node" => "pve-node1", "vmid" => "200"},
          %{}
        )

      conn = Metrics.get_container_rrd(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_map(body["data"])
    end

    test "returns 404 for nonexistent container" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/lxc/999/rrd",
          %{"node" => "pve-node1", "vmid" => "999"},
          %{}
        )

      conn = Metrics.get_container_rrd(conn)
      assert conn.status == 404
    end
  end

  describe "get_cluster_metrics/1" do
    test "returns cluster-wide metrics" do
      conn =
        build_conn(:get, "/api2/json/cluster/metrics/server/node1", %{}, %{"id" => "node1"})

      conn = Metrics.get_cluster_metrics(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      data = body["data"]
      assert is_map(data["cpu"])
      assert is_map(data["memory"])
      assert is_map(data["storage"])
      assert data["nodes_online"] == 2
    end
  end

  describe "get_node_netstat/1" do
    test "returns network statistics for existing node" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/netstat", %{}, %{"node" => "pve-node1"})

      conn = Metrics.get_node_netstat(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
      assert length(body["data"]) == 2
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/netstat", %{}, %{"node" => "unknown"})
      conn = Metrics.get_node_netstat(conn)
      assert conn.status == 404
    end
  end

  describe "get_node_report/1" do
    test "returns text report for existing node" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/report", %{}, %{"node" => "pve-node1"})

      conn = Metrics.get_node_report(conn)

      assert conn.status == 200
      assert conn.resp_body =~ "Node Report"
      assert conn.resp_body =~ "pve-node1"
    end

    test "returns 404 for unknown node" do
      conn = build_conn(:get, "/api2/json/nodes/unknown/report", %{}, %{"node" => "unknown"})
      conn = Metrics.get_node_report(conn)
      assert conn.status == 404
    end

    test "includes VM summary when VMs exist" do
      State.create_vm("pve-node1", 100, %{name: "test-vm"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/report", %{}, %{"node" => "pve-node1"})

      conn = Metrics.get_node_report(conn)
      assert conn.status == 200
      assert conn.resp_body =~ "VM 100"
    end

    test "includes container summary when containers exist" do
      State.create_container("pve-node1", 200, %{hostname: "test-ct"})

      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/report", %{}, %{"node" => "pve-node1"})

      conn = Metrics.get_node_report(conn)
      assert conn.status == 200
      assert conn.resp_body =~ "CT 200"
    end

    test "shows no VMs/containers message when empty" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/report", %{}, %{"node" => "pve-node1"})

      conn = Metrics.get_node_report(conn)
      assert conn.status == 200
      assert conn.resp_body =~ "No VMs configured"
      assert conn.resp_body =~ "No containers configured"
    end
  end

  # --- Different timeframe tests ---

  describe "timeframe variations" do
    test "week timeframe for node RRD" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrd",
          %{"node" => "pve-node1"},
          %{"timeframe" => "week"}
        )

      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["resolution"] == 1800
    end

    test "month timeframe for node RRD" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrd",
          %{"node" => "pve-node1"},
          %{"timeframe" => "month"}
        )

      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["resolution"] == 7200
    end

    test "year timeframe for node RRD" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrd",
          %{"node" => "pve-node1"},
          %{"timeframe" => "year"}
        )

      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["resolution"] == 86400
    end

    test "unknown timeframe defaults to hour resolution" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrd",
          %{"node" => "pve-node1"},
          %{"timeframe" => "invalid"}
        )

      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["resolution"] == 60
    end

    test "week timeframe for node RRD data points" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrddata",
          %{"node" => "pve-node1"},
          %{"timeframe" => "week"}
        )

      conn = Metrics.get_node_rrd_data(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 336
    end

    test "month timeframe for node RRD data points" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrddata",
          %{"node" => "pve-node1"},
          %{"timeframe" => "month"}
        )

      conn = Metrics.get_node_rrd_data(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 360
    end

    test "year timeframe for node RRD data points" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrddata",
          %{"node" => "pve-node1"},
          %{"timeframe" => "year"}
        )

      conn = Metrics.get_node_rrd_data(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 365
    end

    test "week timeframe for VM RRD" do
      State.create_vm("pve-node1", 100, %{})

      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/qemu/100/rrd",
          %{"node" => "pve-node1", "vmid" => "100"},
          %{"timeframe" => "week"}
        )

      conn = Metrics.get_vm_rrd(conn)
      assert conn.status == 200
    end

    test "month timeframe for container RRD" do
      State.create_container("pve-node1", 200, %{})

      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/lxc/200/rrd",
          %{"node" => "pve-node1", "vmid" => "200"},
          %{"timeframe" => "month"}
        )

      conn = Metrics.get_container_rrd(conn)
      assert conn.status == 200
    end

    test "MAX consolidation function for node RRD" do
      conn =
        build_conn_with_query(
          :get,
          "/api2/json/nodes/pve-node1/rrd",
          %{"node" => "pve-node1"},
          %{"cf" => "MAX"}
        )

      conn = Metrics.get_node_rrd(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["cf"] == "MAX"
    end
  end

  # ── Cluster Metrics (via router) ──

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

  describe "cluster metrics index" do
    test "GET returns sub-resource list" do
      resp = request(:get, "/api2/json/cluster/metrics") |> json(200)
      subdirs = Enum.map(resp["data"], & &1["subdir"])
      assert "server" in subdirs
    end
  end

  describe "cluster metrics server list" do
    test "GET returns empty server list" do
      resp = request(:get, "/api2/json/cluster/metrics/server") |> json(200)
      assert resp["data"] == []
    end
  end

  describe "node services" do
    test "GET returns list of services" do
      resp = request(:get, "/api2/json/nodes/pve-node1/services") |> json(200)
      assert is_list(resp["data"])
      names = Enum.map(resp["data"], & &1["service"])
      assert "pvedaemon" in names
      assert "sshd" in names
    end

    test "GET individual service returns status" do
      resp = request(:get, "/api2/json/nodes/pve-node1/services/pvedaemon") |> json(200)
      assert resp["data"]["service"] == "pvedaemon"
      assert resp["data"]["state"] == "running"
    end

    test "GET service state returns service info" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/services/pvedaemon/state")
        |> json(200)

      assert resp["data"]["service"] == "pvedaemon"
    end
  end
end
