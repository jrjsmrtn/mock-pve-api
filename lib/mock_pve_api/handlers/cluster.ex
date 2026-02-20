# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

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

  # HA Resource endpoints

  @doc "GET /api2/json/cluster/ha/resources"
  def list_ha_resources(conn) do
    resources = State.list_ha_resources()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: resources}))
  end

  @doc "POST /api2/json/cluster/ha/resources"
  def create_ha_resource(conn) do
    params = conn.body_params
    sid = Map.get(params, "sid")

    if sid do
      case State.create_ha_resource(sid, params) do
        {:ok, _resource} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

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
        Jason.encode!(%{errors: %{sid: "property is missing and it is not optional"}})
      )
    end
  end

  @doc "GET /api2/json/cluster/ha/resources/:sid"
  def get_ha_resource(conn) do
    sid = conn.path_params["sid"]

    case State.get_ha_resource(sid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "HA resource '#{sid}' not found"}}))

      resource ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: resource}))
    end
  end

  @doc "PUT /api2/json/cluster/ha/resources/:sid"
  def update_ha_resource(conn) do
    sid = conn.path_params["sid"]
    params = conn.body_params

    case State.update_ha_resource(sid, params) do
      {:ok, _resource} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/ha/resources/:sid"
  def delete_ha_resource(conn) do
    sid = conn.path_params["sid"]

    case State.delete_ha_resource(sid) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # HA Status endpoint

  @doc "GET /api2/json/cluster/ha/status/current"
  def get_ha_status(conn) do
    status = State.get_ha_status()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: status}))
  end

  # HA Group endpoints

  @doc "GET /api2/json/cluster/ha/groups"
  def list_ha_groups(conn) do
    groups = State.list_ha_groups()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: groups}))
  end

  @doc "POST /api2/json/cluster/ha/groups"
  def create_ha_group(conn) do
    params = conn.body_params
    group = Map.get(params, "group")

    if group do
      case State.create_ha_group(group, params) do
        {:ok, _group} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

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
        Jason.encode!(%{errors: %{group: "property is missing and it is not optional"}})
      )
    end
  end

  @doc "GET /api2/json/cluster/ha/groups/:group"
  def get_ha_group(conn) do
    group = conn.path_params["group"]

    case State.get_ha_group(group) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "HA group '#{group}' not found"}})
        )

      ha_group ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: ha_group}))
    end
  end

  @doc "PUT /api2/json/cluster/ha/groups/:group"
  def update_ha_group(conn) do
    group = conn.path_params["group"]
    params = conn.body_params

    case State.update_ha_group(group, params) do
      {:ok, _group} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/ha/groups/:group"
  def delete_ha_group(conn) do
    group = conn.path_params["group"]

    case State.delete_ha_group(group) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # HA Affinity Rule endpoints (PVE 9.0+)

  @doc "GET /api2/json/cluster/ha/affinity"
  def list_ha_affinity_rules(conn) do
    rules = State.list_ha_affinity_rules()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: rules}))
  end

  @doc "POST /api2/json/cluster/ha/affinity"
  def create_ha_affinity_rule(conn) do
    params = conn.body_params
    rule = Map.get(params, "id", "rule-#{:rand.uniform(9999)}")

    case State.create_ha_affinity_rule(rule, params) do
      {:ok, _rule} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "GET /api2/json/cluster/ha/affinity/:rule"
  def get_ha_affinity_rule(conn) do
    rule = conn.path_params["rule"]

    case State.get_ha_affinity_rule(rule) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "HA affinity rule '#{rule}' not found"}})
        )

      affinity_rule ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: affinity_rule}))
    end
  end

  @doc "PUT /api2/json/cluster/ha/affinity/:rule"
  def update_ha_affinity_rule(conn) do
    rule = conn.path_params["rule"]
    params = conn.body_params

    case State.update_ha_affinity_rule(rule, params) do
      {:ok, _rule} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/ha/affinity/:rule"
  def delete_ha_affinity_rule(conn) do
    rule = conn.path_params["rule"]

    case State.delete_ha_affinity_rule(rule) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # Backup Job endpoints

  @doc "GET /api2/json/cluster/backup"
  def list_backup_jobs(conn) do
    jobs = State.list_backup_jobs()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: jobs}))
  end

  @doc "POST /api2/json/cluster/backup"
  def create_backup_job(conn) do
    params = conn.body_params

    case State.create_backup_job(params) do
      {:ok, job} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: job.id}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "GET /api2/json/cluster/backup/:id"
  def get_backup_job(conn) do
    id = conn.path_params["id"]

    case State.get_backup_job(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Backup job '#{id}' not found"}})
        )

      job ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: job}))
    end
  end

  @doc "PUT /api2/json/cluster/backup/:id"
  def update_backup_job(conn) do
    id = conn.path_params["id"]
    params = conn.body_params

    case State.update_backup_job(id, params) do
      {:ok, _job} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/backup/:id"
  def delete_backup_job(conn) do
    id = conn.path_params["id"]

    case State.delete_backup_job(id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "GET /api2/json/cluster/backup/:id/included_volumes"
  def get_backup_job_volumes(conn) do
    id = conn.path_params["id"]

    case State.get_backup_job_volumes(id) do
      {:ok, volumes} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: %{children: volumes}}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "GET /api2/json/cluster/backup-info/not-backed-up"
  def get_not_backed_up(conn) do
    not_backed_up = State.get_not_backed_up()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: not_backed_up}))
  end

  # Cluster Options endpoints

  @doc "GET /api2/json/cluster/options"
  def get_cluster_options(conn) do
    options = State.get_cluster_options()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: options}))
  end

  @doc "PUT /api2/json/cluster/options"
  def update_cluster_options(conn) do
    params = conn.body_params

    {:ok, _options} = State.update_cluster_options(params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # Replication endpoints

  @doc "GET /api2/json/cluster/replication"
  def list_replication_jobs(conn) do
    jobs = State.list_replication_jobs()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: jobs}))
  end

  @doc "GET /api2/json/cluster/replication/:id"
  def get_replication_job(conn) do
    id = conn.path_params["id"]

    case State.get_replication_job(id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Replication job '#{id}' not found"}})
        )

      job ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: job}))
    end
  end

  @doc "PUT /api2/json/cluster/replication/:id"
  def update_replication_job(conn) do
    id = conn.path_params["id"]
    params = conn.body_params

    atom_params =
      params
      |> Enum.reduce(%{}, fn
        {"id", _}, acc -> acc
        {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
      end)

    case State.update_replication_job(id, atom_params) do
      {:ok, _job} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc "DELETE /api2/json/cluster/replication/:id"
  def delete_replication_job(conn) do
    id = conn.path_params["id"]

    case State.delete_replication_job(id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # Ceph endpoints

  @doc "GET /api2/json/cluster/ceph/flags"
  def get_ceph_flags(conn) do
    flags = %{
      nobackfill: false,
      nodeep_scrub: false,
      nodown: false,
      noin: false,
      noout: false,
      norebalance: false,
      norecover: false,
      noscrub: false,
      notieragent: false,
      noup: false,
      pause: false
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: flags}))
  end

  @doc "PUT /api2/json/cluster/ceph/flags"
  def set_ceph_flags(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  @doc "GET /api2/json/cluster/ceph/metadata"
  def get_ceph_metadata(conn) do
    metadata = %{
      mgr: %{},
      mon: %{},
      mds: %{},
      osd: %{},
      node: %{}
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: metadata}))
  end

  @doc "GET /api2/json/cluster/ceph/status"
  def get_ceph_status(conn) do
    status = %{
      health: %{status: "HEALTH_OK", checks: %{}},
      pgmap: %{pgs_by_state: [], num_pgs: 0},
      osdmap: %{num_osds: 0, num_up_osds: 0, num_in_osds: 0}
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: status}))
  end

  # ACME endpoints

  @doc "GET /api2/json/cluster/acme/account"
  def list_acme_accounts(conn) do
    accounts = State.list_acme_accounts()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: accounts}))
  end

  @doc "POST /api2/json/cluster/acme/account"
  def create_acme_account(conn) do
    params = conn.body_params
    name = Map.get(params, "name", "default")

    atom_params =
      params
      |> Enum.reduce(%{}, fn
        {"name", _}, acc -> acc
        {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
      end)

    case State.create_acme_account(name, atom_params) do
      {:ok, _account} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: name}))

      {:error, :already_exists} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          400,
          Jason.encode!(%{errors: %{name: "ACME account '#{name}' already exists"}})
        )
    end
  end

  @doc "GET /api2/json/cluster/acme/plugins"
  def list_acme_plugins(conn) do
    plugins = State.list_acme_plugins()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: plugins}))
  end

  @doc "POST /api2/json/cluster/acme/plugins"
  def create_acme_plugin(conn) do
    params = conn.body_params
    id = Map.get(params, "id")

    if is_nil(id) or id == "" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{id: "ACME plugin ID is required"}}))
    else
      atom_params =
        params
        |> Enum.reduce(%{}, fn
          {"id", _}, acc -> acc
          {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
        end)

      case State.create_acme_plugin(id, atom_params) do
        {:ok, _plugin} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, :already_exists} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{id: "ACME plugin '#{id}' already exists"}}))
      end
    end
  end

  @doc "POST /api2/json/cluster/replication"
  def create_replication_job(conn) do
    params = conn.body_params
    id = Map.get(params, "id")

    if is_nil(id) or id == "" do
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{id: "Replication job ID is required"}}))
    else
      atom_params =
        params
        |> Enum.reduce(%{}, fn
          {"id", _}, acc -> acc
          {k, v}, acc -> Map.put(acc, String.to_atom(k), v)
        end)

      case State.create_replication_job(id, atom_params) do
        {:ok, _job} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, :already_exists} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(
            400,
            Jason.encode!(%{errors: %{id: "Replication job '#{id}' already exists"}})
          )
      end
    end
  end
end
