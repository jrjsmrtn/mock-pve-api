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
  GET /api2/json/cluster/config/join
  Returns information needed to join an existing cluster.
  """
  def get_config_join(conn) do
    join_info = %{
      totem: %{
        version: 2,
        cluster_name: "pve-cluster",
        interface: [%{linknumber: 0}]
      },
      nodelist: [
        %{
          name: "pve-node1",
          nodeid: 1,
          quorum_votes: 1,
          ring0_addr: "192.168.1.10",
          pve_addr: "192.168.1.10",
          pve_fp: "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD"
        }
      ],
      preferred_node: "pve-node1",
      config_digest: "mock_digest_0"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: join_info}))
  end

  @doc """
  POST /api2/json/cluster/config/nodes/:node
  Adds a node to the cluster (mock: returns UPID).
  """
  def add_cluster_node(conn) do
    node_name = conn.path_params["node"]
    upid = "UPID:pve-node1:00001234:000000:00000000:addnode:#{node_name}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
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

  # Navigation index stubs

  @doc "GET /api2/json/cluster"
  def get_cluster_index(conn) do
    subdirs = ~w(replication tasks resources log options status ha sdn firewall
                 backup acme ceph config jobs notifications metrics mapping nextid)

    json_ok(conn, Enum.map(subdirs, &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/acme"
  def get_acme_index(conn) do
    json_ok(
      conn,
      Enum.map(~w(account plugins directories tos challenge-schema meta), &%{subdir: &1})
    )
  end

  @doc "GET /api2/json/cluster/ceph"
  def get_ceph_index(conn) do
    json_ok(conn, Enum.map(~w(flags metadata status), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/firewall"
  def get_firewall_index(conn) do
    json_ok(conn, Enum.map(~w(options rules groups aliases ipset refs), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/ha"
  def get_ha_index(conn) do
    json_ok(conn, Enum.map(~w(resources groups affinity status rules), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/ha/status"
  def get_ha_status_index(conn) do
    json_ok(conn, Enum.map(~w(current manager_status), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/jobs"
  def get_jobs_index(conn) do
    json_ok(conn, Enum.map(~w(realm-sync schedule-analyze), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/log"
  def get_log_index(conn) do
    json_ok(conn, [])
  end

  @doc "GET /api2/json/cluster/mapping"
  def get_mapping_index(conn) do
    json_ok(conn, Enum.map(~w(pci usb dir), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/backup-info"
  def get_backup_info_index(conn) do
    json_ok(conn, Enum.map(~w(not-backed-up providers), &%{subdir: &1}))
  end

  @doc "GET /api2/json/cluster/bulk-action"
  def get_bulk_action_index(conn) do
    json_ok(conn, [%{subdir: "guest"}])
  end

  # ACME individual resource CRUD

  @doc "GET /api2/json/cluster/acme/account/:name"
  def get_acme_account(conn) do
    name = conn.path_params["name"]

    case State.get_acme_account(name) do
      nil -> json_error(conn, 404, "ACME account '#{name}' not found")
      account -> json_ok(conn, account)
    end
  end

  @doc "PUT /api2/json/cluster/acme/account/:name"
  def update_acme_account(conn) do
    name = conn.path_params["name"]
    params = atomize_params(conn.body_params)

    case State.update_acme_account(name, params) do
      {:ok, _} -> json_ok(conn, nil)
      {:error, msg} -> json_error(conn, 404, msg)
    end
  end

  @doc "DELETE /api2/json/cluster/acme/account/:name"
  def delete_acme_account(conn) do
    name = conn.path_params["name"]

    case State.delete_acme_account(name) do
      :ok -> json_ok(conn, nil)
      {:error, msg} -> json_error(conn, 404, msg)
    end
  end

  @doc "GET /api2/json/cluster/acme/plugins/:id"
  def get_acme_plugin_by_id(conn) do
    id = conn.path_params["id"]

    case State.get_acme_plugin(id) do
      nil -> json_error(conn, 404, "ACME plugin '#{id}' not found")
      plugin -> json_ok(conn, plugin)
    end
  end

  @doc "PUT /api2/json/cluster/acme/plugins/:id"
  def update_acme_plugin_by_id(conn) do
    id = conn.path_params["id"]
    params = atomize_params(conn.body_params)

    case State.update_acme_plugin(id, params) do
      {:ok, _} -> json_ok(conn, nil)
      {:error, msg} -> json_error(conn, 404, msg)
    end
  end

  @doc "DELETE /api2/json/cluster/acme/plugins/:id"
  def delete_acme_plugin_by_id(conn) do
    id = conn.path_params["id"]

    case State.delete_acme_plugin(id) do
      :ok -> json_ok(conn, nil)
      {:error, msg} -> json_error(conn, 404, msg)
    end
  end

  # Static ACME read-only stubs

  @doc "GET /api2/json/cluster/acme/challenge-schema"
  def get_acme_challenge_schema(conn), do: json_ok(conn, [])

  @doc "GET /api2/json/cluster/acme/directories"
  def get_acme_directories(conn) do
    json_ok(conn, [
      %{name: "Let's Encrypt", url: "https://acme-v02.api.letsencrypt.org/directory"}
    ])
  end

  @doc "GET /api2/json/cluster/acme/tos"
  def get_acme_tos(conn), do: json_ok(conn, "")

  @doc "GET /api2/json/cluster/acme/meta"
  def get_acme_meta(conn), do: json_ok(conn, %{termsOfService: ""})

  # Jobs: schedule-analyze and realm-sync CRUD

  @doc "GET /api2/json/cluster/jobs/schedule-analyze"
  def get_schedule_analyze(conn), do: json_ok(conn, [])

  @doc "GET /api2/json/cluster/jobs/realm-sync"
  def list_realm_sync_jobs(conn), do: json_ok(conn, State.list_realm_sync_jobs())

  @doc "GET /api2/json/cluster/jobs/realm-sync/:id"
  def get_realm_sync_job(conn) do
    id = conn.path_params["id"]

    case State.get_realm_sync_job(id) do
      nil -> json_error(conn, 404, "Realm sync job '#{id}' not found")
      job -> json_ok(conn, job)
    end
  end

  @doc "POST /api2/json/cluster/jobs/realm-sync/:id"
  def create_realm_sync_job(conn) do
    id = conn.path_params["id"]

    case State.create_realm_sync_job(id, conn.body_params) do
      {:ok, job} -> json_ok(conn, job)
      {:error, msg} -> json_error(conn, 400, msg)
    end
  end

  @doc "PUT /api2/json/cluster/jobs/realm-sync/:id"
  def update_realm_sync_job(conn) do
    id = conn.path_params["id"]

    case State.update_realm_sync_job(id, conn.body_params) do
      {:ok, _} -> json_ok(conn, nil)
      {:error, msg} -> json_error(conn, 404, msg)
    end
  end

  @doc "DELETE /api2/json/cluster/jobs/realm-sync/:id"
  def delete_realm_sync_job(conn) do
    id = conn.path_params["id"]

    case State.delete_realm_sync_job(id) do
      :ok -> json_ok(conn, nil)
      {:error, msg} -> json_error(conn, 404, msg)
    end
  end

  # Private helpers

  defp json_ok(conn, data) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  defp json_error(conn, status, message) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(status, Jason.encode!(%{errors: %{message: message}}))
  end

  defp atomize_params(params) do
    Enum.reduce(params, %{}, fn {k, v}, acc ->
      Map.put(acc, String.to_atom(k), v)
    end)
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

  # Cluster tasks

  @doc "GET /api2/json/cluster/tasks"
  def get_cluster_tasks(conn), do: json_ok(conn, [])

  # HA manager status

  @doc "GET /api2/json/cluster/ha/status/manager_status"
  def get_ha_manager_status(conn) do
    json_ok(conn, %{
      manager_status: "active",
      quorum: %{quorate: 1, total_votes: 2, expected_votes: 2}
    })
  end

  # HA resources migrate/relocate

  @doc "POST /api2/json/cluster/ha/resources/:sid/migrate"
  def ha_resource_migrate(conn), do: json_ok(conn, nil)

  @doc "POST /api2/json/cluster/ha/resources/:sid/relocate"
  def ha_resource_relocate(conn), do: json_ok(conn, nil)

  # Cluster metrics export

  @doc "GET /api2/json/cluster/metrics/export"
  def get_metrics_export(conn), do: json_ok(conn, [])

  # SDN vnet IPs

  @doc "POST/PUT/DELETE /api2/json/cluster/sdn/vnets/:vnet/ips"
  def sdn_vnet_ips(conn), do: json_ok(conn, nil)

  # Bulk-action guest

  @doc "GET /api2/json/cluster/bulk-action/guest"
  def get_bulk_action_guest(conn) do
    json_ok(conn, Enum.map(~w(migrate shutdown start suspend), &%{subdir: &1}))
  end

  @doc "POST /api2/json/cluster/bulk-action/guest/:action"
  def bulk_action_guest(conn), do: json_ok(conn, nil)
end
