defmodule MockPveApi.Handlers.Cluster do
  @moduledoc """
  Handler for PVE cluster-related endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.{State, Fixtures}

  @doc """
  GET /api2/json/cluster/resources
  Gets all cluster resources (nodes, VMs, containers).
  """
  def get_resources(conn) do
    # Use version-aware fixture data
    resources = Fixtures.cluster_resources()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: resources}))
  end

  @doc """
  GET /api2/json/cluster/nextid
  Gets next available VMID.
  """
  def get_next_vmid(conn) do
    next_vmid = State.get_next_vmid()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: next_vmid}))
  end

  @doc """
  GET /api2/json/cluster/status
  Gets cluster status information.
  """
  def get_cluster_status(conn) do
    # Get cluster status from state
    cluster_status = State.get_cluster_status()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: cluster_status}))
  end

  @doc """
  POST /api2/json/cluster/config/join
  Joins a node to an existing cluster.
  """
  def join_cluster(conn) do
    params = conn.body_params
    hostname = Map.get(params, "hostname")
    nodeid = Map.get(params, "nodeid")
    votes = Map.get(params, "votes", 1)

    if hostname do
      case State.join_cluster(hostname, nodeid, votes) do
        {:ok, task_id} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: task_id}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{hostname: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/cluster/config
  Gets cluster configuration.
  """
  def get_cluster_config(conn) do
    config = State.get_cluster_config()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: config}))
  end

  @doc """
  PUT /api2/json/cluster/config
  Updates cluster configuration.
  """
  def update_cluster_config(conn) do
    params = conn.body_params

    case State.update_cluster_config(params) do
      {:ok, config} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: config}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/cluster/config/nodes
  Lists cluster nodes configuration.
  """
  def get_cluster_nodes_config(conn) do
    nodes_config = State.get_cluster_nodes_config()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nodes_config}))
  end

  @doc """
  DELETE /api2/json/cluster/config/nodes/:node
  Removes a node from the cluster.
  """
  def remove_cluster_node(conn) do
    node_name = conn.path_params["node"]

    case State.remove_cluster_node(node_name) do
      {:ok, task_id} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: task_id}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/cluster/backup-info/providers
  Lists available backup providers (PVE 8.2+).
  """
  def list_backup_providers(conn) do
    providers = [
      %{
        id: "backup-store-1",
        type: "pbs",
        server: "pbs.example.com",
        username: "backup@pbs",
        datastore: "datastore1",
        enabled: true
      },
      %{
        id: "nfs-backup",
        type: "nfs",
        server: "nfs.example.com",
        path: "/backup",
        enabled: true
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: providers}))
  end

  @doc """
  GET /api2/json/cluster/ha/affinity
  Lists HA resource affinity rules (PVE 9.0+).
  """
  def list_ha_affinity_rules(conn) do
    rules = [
      %{
        sid: "rule-1",
        comment: "Database servers on separate hosts",
        state: "enabled",
        type: "anti-affinity",
        group: "db-group"
      },
      %{
        sid: "rule-2",
        comment: "Web servers prefer node1",
        state: "enabled",
        type: "affinity",
        node: "pve-node1"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: rules}))
  end

  @doc """
  POST /api2/json/cluster/ha/affinity
  Creates a new HA resource affinity rule (PVE 9.0+).
  """
  def create_ha_affinity_rule(conn) do
    params = conn.body_params
    sid = Map.get(params, "sid", "auto-#{:rand.uniform(9999)}")
    rule_type = Map.get(params, "type", "affinity")
    comment = Map.get(params, "comment", "")

    new_rule = %{
      sid: sid,
      comment: comment,
      state: "enabled",
      type: rule_type,
      node: Map.get(params, "node"),
      group: Map.get(params, "group")
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: new_rule}))
  end
end
