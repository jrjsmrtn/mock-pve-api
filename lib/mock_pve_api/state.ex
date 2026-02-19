# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.State do
  @moduledoc """
  State management for mock PVE resources.

  Maintains in-memory state for VMs, containers, nodes, storage, and other
  PVE resources to support realistic lifecycle testing scenarios.

  Now includes version-aware capabilities to support different PVE versions.
  """

  use GenServer
  require Logger

  alias MockPveApi.Capabilities

  @name __MODULE__

  # Default state structure
  defp initial_state do
    pve_version = Application.get_env(:mock_pve_api, :pve_version, "8.0")

    %{
      pve_version: pve_version,
      capabilities: Capabilities.get_capabilities(pve_version),
      nodes: %{
        "pve-node1" => %{
          node: "pve-node1",
          status: "online",
          cpu: 0.15,
          maxcpu: 8,
          # 8GB
          mem: 8_589_934_592,
          # 16GB
          maxmem: 17_179_869_184,
          # 50GB
          disk: 50_000_000_000,
          # 100GB
          maxdisk: 100_000_000_000,
          uptime: 86400,
          version: pve_version,
          kernel: "6.2.16-15-pve"
        },
        "pve-node2" => %{
          node: "pve-node2",
          status: "online",
          cpu: 0.08,
          maxcpu: 4,
          # 4GB
          mem: 4_294_967_296,
          # 8GB
          maxmem: 8_589_934_592,
          # 25GB
          disk: 25_000_000_000,
          # 50GB
          maxdisk: 50_000_000_000,
          uptime: 172_800,
          version: pve_version,
          kernel: "6.2.16-15-pve"
        }
      },
      vms: %{},
      containers: %{},
      storage: %{
        "local" => %{
          storage: "local",
          type: "dir",
          content: "vztmpl,backup,iso",
          path: "/var/lib/vz",
          nodes: "pve-node1,pve-node2",
          maxfiles: 0,
          enabled: 1
        },
        "local-lvm" => %{
          storage: "local-lvm",
          type: "lvmthin",
          content: "images,rootdir",
          vgname: "pve",
          thinpool: "data",
          nodes: "pve-node1,pve-node2",
          enabled: 1
        }
      },
      snapshots: %{},
      pools: %{},
      users: %{
        "root@pam" => %{
          userid: "root@pam",
          comment: "Root user",
          enable: 1,
          expire: 0,
          groups: []
        }
      },
      groups: %{
        "admin" => %{
          groupid: "admin",
          comment: "System administrators"
        }
      },
      domains: %{
        "pam" => %{
          realm: "pam",
          type: "pam",
          comment: "PAM standard authentication",
          default: 1
        },
        "pve" => %{
          realm: "pve",
          type: "pve",
          comment: "Proxmox VE authentication server"
        }
      },
      cluster_config: %{
        cluster_name: "pve-cluster",
        nodes: %{
          "pve-node1" => %{
            name: "pve-node1",
            nodeid: 1,
            votes: 1,
            ring0_addr: "192.168.1.10",
            quorum_votes: 1,
            online: true
          },
          "pve-node2" => %{
            name: "pve-node2",
            nodeid: 2,
            votes: 1,
            ring0_addr: "192.168.1.11",
            quorum_votes: 1,
            online: true
          }
        },
        expected_votes: 2,
        quorum: %{
          expected_votes: 2,
          total_votes: 2,
          quorate: 1
        },
        cluster_log: []
      },
      next_vmid: 100,
      tasks: %{},
      next_upid: 1,
      backups: %{},
      tickets: %{},
      api_tokens: %{},
      permissions: %{
        "/" => %{
          "root@pam" => ["Administrator"]
        }
      },
      roles: %{
        "Administrator" => [
          "VM.Allocate",
          "VM.Audit",
          "VM.Backup",
          "VM.Clone",
          "VM.Config.CDROM",
          "VM.Config.CPU",
          "VM.Config.Cloudinit",
          "VM.Config.Disk",
          "VM.Config.HWType",
          "VM.Config.Memory",
          "VM.Config.Network",
          "VM.Config.Options",
          "VM.Migrate",
          "VM.Monitor",
          "VM.PowerMgmt",
          "VM.Snapshot",
          "VM.Snapshot.Rollback"
        ]
      }
    }
  end

  ## Client API

  def start_link(_) do
    GenServer.start_link(__MODULE__, initial_state(), name: @name)
  end

  def get_state do
    GenServer.call(@name, :get_state)
  end

  def reset do
    GenServer.call(@name, :reset)
  end

  # Node operations
  def get_nodes do
    GenServer.call(@name, :get_nodes)
  end

  def get_node(name) do
    GenServer.call(@name, {:get_node, name})
  end

  def update_node(name, updates) do
    GenServer.cast(@name, {:update_node, name, updates})
  end

  # VM operations
  def get_vms(node \\ nil) do
    GenServer.call(@name, {:get_vms, node})
  end

  def get_vm(node, vmid) do
    GenServer.call(@name, {:get_vm, node, vmid})
  end

  def create_vm(node, vmid, config) do
    GenServer.call(@name, {:create_vm, node, vmid, config})
  end

  def update_vm(node, vmid, config) do
    GenServer.call(@name, {:update_vm, node, vmid, config})
  end

  def delete_vm(node, vmid) do
    GenServer.cast(@name, {:delete_vm, node, vmid})
  end

  # Container operations
  def get_containers(node \\ nil) do
    GenServer.call(@name, {:get_containers, node})
  end

  def get_container(node, vmid) do
    GenServer.call(@name, {:get_container, node, vmid})
  end

  def create_container(node, vmid, config) do
    GenServer.call(@name, {:create_container, node, vmid, config})
  end

  def update_container(node, vmid, config) do
    GenServer.call(@name, {:update_container, node, vmid, config})
  end

  def delete_container(node, vmid) do
    GenServer.cast(@name, {:delete_container, node, vmid})
  end

  # Snapshot operations
  def list_snapshots(vmid) do
    GenServer.call(@name, {:list_snapshots, vmid})
  end

  def get_snapshot(vmid, snapname) do
    GenServer.call(@name, {:get_snapshot, vmid, snapname})
  end

  def create_snapshot(vmid, snapname, params \\ %{}) do
    GenServer.call(@name, {:create_snapshot, vmid, snapname, params})
  end

  def get_snapshot_config(vmid, snapname) do
    GenServer.call(@name, {:get_snapshot_config, vmid, snapname})
  end

  def update_snapshot_config(vmid, snapname, params) do
    GenServer.call(@name, {:update_snapshot_config, vmid, snapname, params})
  end

  def delete_snapshot(vmid, snapname) do
    GenServer.call(@name, {:delete_snapshot, vmid, snapname})
  end

  def rollback_snapshot(vmid, snapname) do
    GenServer.call(@name, {:rollback_snapshot, vmid, snapname})
  end

  # Storage operations
  def get_storage do
    GenServer.call(@name, :get_storage)
  end

  def get_storage_content(node, storage) do
    GenServer.call(@name, {:get_storage_content, node, storage})
  end

  def add_storage_content(node, storage, content) do
    GenServer.call(@name, {:add_storage_content, node, storage, content})
  end

  # Pool operations
  def get_pools do
    GenServer.call(@name, :get_pools)
  end

  def create_pool(poolid, config) do
    GenServer.call(@name, {:create_pool, poolid, config})
  end

  def update_pool(poolid, params) do
    GenServer.call(@name, {:update_pool, poolid, params})
  end

  def delete_pool(poolid) do
    GenServer.cast(@name, {:delete_pool, poolid})
  end

  # Task operations
  def create_task(node, type, params \\ %{}) do
    GenServer.call(@name, {:create_task, node, type, params})
  end

  def get_tasks(node) do
    GenServer.call(@name, {:get_tasks, node})
  end

  def get_task(upid) do
    GenServer.call(@name, {:get_task, upid})
  end

  def update_task(upid, updates) do
    GenServer.cast(@name, {:update_task, upid, updates})
  end

  # Backup operations
  def create_backup(node, vmid, params \\ %{}) do
    GenServer.call(@name, {:create_backup, node, vmid, params})
  end

  def list_backups(node, storage) do
    GenServer.call(@name, {:list_backups, node, storage})
  end

  def restore_backup(node, vmid, backup_file, params \\ %{}) do
    GenServer.call(@name, {:restore_backup, node, vmid, backup_file, params})
  end

  # Migrate operations
  def migrate_vm(node, vmid, target_node, params \\ %{}) do
    GenServer.call(@name, {:migrate_vm, node, vmid, target_node, params})
  end

  def migrate_container(node, vmid, target_node, params \\ %{}) do
    GenServer.call(@name, {:migrate_container, node, vmid, target_node, params})
  end

  # Authentication operations
  def create_ticket(username, password, params \\ %{}) do
    GenServer.call(@name, {:create_ticket, username, password, params})
  end

  def validate_ticket(ticket) do
    GenServer.call(@name, {:validate_ticket, ticket})
  end

  def create_api_token(username, tokenid, params \\ %{}) do
    GenServer.call(@name, {:create_api_token, username, tokenid, params})
  end

  # Permission operations
  def get_permissions(userid) do
    GenServer.call(@name, {:get_permissions, userid})
  end

  def set_permissions(path, userid, roleid) do
    GenServer.call(@name, {:set_permissions, path, userid, roleid})
  end

  # User management operations
  def create_user(userid, params) do
    GenServer.call(@name, {:create_user, userid, params})
  end

  def update_user(userid, params) do
    GenServer.call(@name, {:update_user, userid, params})
  end

  def delete_user(userid) do
    GenServer.call(@name, {:delete_user, userid})
  end

  # Group management operations
  def create_group(groupid, params) do
    GenServer.call(@name, {:create_group, groupid, params})
  end

  def update_group(groupid, params) do
    GenServer.call(@name, {:update_group, groupid, params})
  end

  def delete_group(groupid) do
    GenServer.call(@name, {:delete_group, groupid})
  end

  # API Token management operations
  def delete_api_token(tokenid) do
    GenServer.call(@name, {:delete_api_token, tokenid})
  end

  def update_api_token(tokenid, params) do
    GenServer.call(@name, {:update_api_token, tokenid, params})
  end

  # Cluster management operations
  def get_cluster_status do
    GenServer.call(@name, :get_cluster_status)
  end

  def join_cluster(hostname, nodeid, votes) do
    GenServer.call(@name, {:join_cluster, hostname, nodeid, votes})
  end

  def get_cluster_config do
    GenServer.call(@name, :get_cluster_config)
  end

  def update_cluster_config(params) do
    GenServer.call(@name, {:update_cluster_config, params})
  end

  def get_cluster_nodes_config do
    GenServer.call(@name, :get_cluster_nodes_config)
  end

  def remove_cluster_node(node_name) do
    GenServer.call(@name, {:remove_cluster_node, node_name})
  end

  def get_next_vmid do
    GenServer.call(@name, :get_next_vmid)
  end

  # Version and capability operations
  def get_pve_version do
    GenServer.call(@name, :get_pve_version)
  end

  def get_capabilities do
    GenServer.call(@name, :get_capabilities)
  end

  def has_capability?(capability) do
    GenServer.call(@name, {:has_capability, capability})
  end

  def endpoint_supported?(endpoint_path) do
    GenServer.call(@name, {:endpoint_supported, endpoint_path})
  end

  ## Server Callbacks

  @impl true
  def init(state) do
    Logger.info("Mock PVE Server state initialized")
    {:ok, state}
  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_nodes, _from, state) do
    nodes = Map.values(state.nodes)
    {:reply, nodes, state}
  end

  def handle_call({:get_node, name}, _from, state) do
    node = Map.get(state.nodes, name)
    {:reply, node, state}
  end

  def handle_call({:get_vms, node}, _from, state) do
    vms =
      case node do
        nil ->
          Map.values(state.vms)

        node ->
          state.vms
          |> Enum.filter(fn {_vmid, vm} -> vm.node == node end)
          |> Enum.map(&elem(&1, 1))
      end

    {:reply, vms, state}
  end

  def handle_call({:get_vm, node, vmid}, _from, state) do
    vm = Map.get(state.vms, vmid)
    result = if vm && vm.node == node, do: vm, else: nil
    {:reply, result, state}
  end

  def handle_call({:create_vm, node, vmid, config}, _from, state) do
    if Map.has_key?(state.vms, vmid) do
      {:reply, {:error, "VM #{vmid} already exists"}, state}
    else
      vm =
        Map.merge(
          %{
            vmid: vmid,
            node: node,
            status: "stopped",
            name: Map.get(config, :name, "vm-#{vmid}"),
            memory: Map.get(config, :memory, 2048),
            cores: Map.get(config, :cores, 2),
            sockets: Map.get(config, :sockets, 1),
            ostype: Map.get(config, :ostype, "l26"),
            bootdisk: Map.get(config, :bootdisk, "scsi0")
          },
          config
        )

      new_vms = Map.put(state.vms, vmid, vm)
      new_state = %{state | vms: new_vms}

      {:reply, {:ok, vm}, new_state}
    end
  end

  def handle_call({:update_vm, node, vmid, config}, _from, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:reply, {:error, "VM #{vmid} not found"}, state}

      vm when vm.node == node ->
        updated_vm = Map.merge(vm, config)
        new_vms = Map.put(state.vms, vmid, updated_vm)
        new_state = %{state | vms: new_vms}
        {:reply, {:ok, updated_vm}, new_state}

      _ ->
        {:reply, {:error, "VM #{vmid} not found on node #{node}"}, state}
    end
  end

  def handle_call({:get_containers, node}, _from, state) do
    containers =
      case node do
        nil ->
          Map.values(state.containers)

        node ->
          state.containers
          |> Enum.filter(fn {_vmid, ct} -> ct.node == node end)
          |> Enum.map(&elem(&1, 1))
      end

    {:reply, containers, state}
  end

  def handle_call({:get_container, node, vmid}, _from, state) do
    container = Map.get(state.containers, vmid)
    result = if container && container.node == node, do: container, else: nil
    {:reply, result, state}
  end

  def handle_call({:create_container, node, vmid, config}, _from, state) do
    if Map.has_key?(state.containers, vmid) do
      {:reply, {:error, "Container #{vmid} already exists"}, state}
    else
      container =
        Map.merge(
          %{
            vmid: vmid,
            node: node,
            type: "lxc",
            status: "stopped",
            hostname: Map.get(config, :hostname, "ct-#{vmid}"),
            memory: Map.get(config, :memory, 1024),
            swap: Map.get(config, :swap, 512),
            cores: Map.get(config, :cores, 1),
            ostemplate:
              Map.get(
                config,
                :ostemplate,
                "local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
              ),
            rootfs: Map.get(config, :rootfs, "local-lvm:8")
          },
          config
        )

      new_containers = Map.put(state.containers, vmid, container)
      new_state = %{state | containers: new_containers}

      {:reply, {:ok, container}, new_state}
    end
  end

  def handle_call({:update_container, node, vmid, config}, _from, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:reply, {:error, "Container #{vmid} not found"}, state}

      container when container.node == node ->
        updated_container = Map.merge(container, config)
        new_containers = Map.put(state.containers, vmid, updated_container)
        new_state = %{state | containers: new_containers}
        {:reply, {:ok, updated_container}, new_state}

      _ ->
        {:reply, {:error, "Container #{vmid} not found on node #{node}"}, state}
    end
  end

  # Snapshot callbacks
  def handle_call({:list_snapshots, vmid}, _from, state) do
    snapshots =
      state.snapshots
      |> Enum.filter(fn {{vid, _snapname}, _snap} -> vid == vmid end)
      |> Enum.map(fn {_key, snap} -> snap end)

    # PVE always includes a "current" pseudo-snapshot
    current = %{name: "current", description: "You are here!", snaptime: 0, parent: nil}
    {:reply, [current | snapshots], state}
  end

  def handle_call({:get_snapshot, vmid, snapname}, _from, state) do
    snapshot = Map.get(state.snapshots, {vmid, snapname})
    {:reply, snapshot, state}
  end

  def handle_call({:create_snapshot, vmid, snapname, params}, _from, state) do
    key = {vmid, snapname}

    if Map.has_key?(state.snapshots, key) do
      {:reply, {:error, "Snapshot '#{snapname}' already exists"}, state}
    else
      # Find parent (most recent snapshot or nil)
      parent =
        state.snapshots
        |> Enum.filter(fn {{vid, _}, _} -> vid == vmid end)
        |> Enum.sort_by(fn {_, snap} -> snap.snap_order end, :desc)
        |> case do
          [{_, latest} | _] -> latest.name
          [] -> nil
        end

      snapshot = %{
        name: snapname,
        description: Map.get(params, :description, Map.get(params, "description", "")),
        snaptime: System.system_time(:second),
        # Monotonic counter for reliable ordering in tests
        snap_order: System.monotonic_time(),
        vmstate: Map.get(params, :vmstate, Map.get(params, "vmstate", 0)),
        parent: parent
      }

      new_snapshots = Map.put(state.snapshots, key, snapshot)
      {:reply, {:ok, snapshot}, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call({:get_snapshot_config, vmid, snapname}, _from, state) do
    case Map.get(state.snapshots, {vmid, snapname}) do
      nil -> {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}
      snapshot -> {:reply, {:ok, snapshot}, state}
    end
  end

  def handle_call({:update_snapshot_config, vmid, snapname, params}, _from, state) do
    key = {vmid, snapname}

    case Map.get(state.snapshots, key) do
      nil ->
        {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}

      snapshot ->
        description =
          Map.get(params, :description, Map.get(params, "description", snapshot.description))

        updated = %{snapshot | description: description}
        new_snapshots = Map.put(state.snapshots, key, updated)
        {:reply, {:ok, updated}, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call({:delete_snapshot, vmid, snapname}, _from, state) do
    key = {vmid, snapname}

    case Map.get(state.snapshots, key) do
      nil ->
        {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}

      deleted_snap ->
        # Update children's parent pointers
        new_snapshots =
          state.snapshots
          |> Map.delete(key)
          |> Enum.map(fn {k, snap} ->
            {vid, _sn} = k

            if vid == vmid && snap.parent == snapname do
              {k, %{snap | parent: deleted_snap.parent}}
            else
              {k, snap}
            end
          end)
          |> Map.new()

        {:reply, :ok, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call({:rollback_snapshot, vmid, snapname}, _from, state) do
    key = {vmid, snapname}

    case Map.get(state.snapshots, key) do
      nil ->
        {:reply, {:error, "Snapshot '#{snapname}' not found"}, state}

      target_snap ->
        # Remove all snapshots newer than the target (using monotonic order)
        new_snapshots =
          state.snapshots
          |> Enum.reject(fn {{vid, _sn}, snap} ->
            vid == vmid && snap.snap_order > target_snap.snap_order
          end)
          |> Map.new()

        {:reply, :ok, %{state | snapshots: new_snapshots}}
    end
  end

  def handle_call(:get_storage, _from, state) do
    storage = Map.values(state.storage)
    {:reply, storage, state}
  end

  def handle_call({:get_storage_content, _node, storage_id}, _from, state) do
    storage = Map.get(state.storage, storage_id)

    if storage do
      # Generate some sample content based on storage type
      content =
        case storage.type do
          "dir" ->
            [
              %{
                volid: "#{storage_id}:iso/ubuntu-22.04.3-live-server-amd64.iso",
                content: "iso",
                format: "iso",
                size: 1_474_560_000
              },
              %{
                volid: "#{storage_id}:backup/vzdump-qemu-100-2023_12_01-12_00_00.vma.zst",
                content: "backup",
                format: "vma.zst",
                size: 2_147_483_648
              }
            ]

          "lvmthin" ->
            [
              %{
                volid: "#{storage_id}:vm-100-disk-0",
                content: "images",
                format: "raw",
                size: 21_474_836_480,
                vmid: 100
              }
            ]

          _ ->
            []
        end

      {:reply, content, state}
    else
      {:reply, [], state}
    end
  end

  def handle_call({:add_storage_content, _node, storage_id, content}, _from, state) do
    storage = Map.get(state.storage, storage_id)

    if storage do
      # In a real implementation, we'd maintain a storage content registry
      # For now, we'll just return success with the created content
      {:reply, {:ok, content}, state}
    else
      {:reply, {:error, "Storage '#{storage_id}' not found"}, state}
    end
  end

  def handle_call(:get_pools, _from, state) do
    pools = Map.values(state.pools)
    {:reply, pools, state}
  end

  def handle_call({:create_pool, poolid, config}, _from, state) do
    if Map.has_key?(state.pools, poolid) do
      {:reply, {:error, "Pool #{poolid} already exists"}, state}
    else
      pool =
        Map.merge(
          %{
            poolid: poolid,
            comment: Map.get(config, :comment, ""),
            members: []
          },
          config
        )

      new_pools = Map.put(state.pools, poolid, pool)
      new_state = %{state | pools: new_pools}

      {:reply, {:ok, pool}, new_state}
    end
  end

  def handle_call({:update_pool, poolid, params}, _from, state) do
    case Map.get(state.pools, poolid) do
      nil ->
        {:reply, {:error, "Pool '#{poolid}' not found"}, state}

      existing_pool ->
        updated_pool =
          Map.merge(existing_pool, %{
            comment: Map.get(params, "comment", existing_pool.comment)
          })

        new_pools = Map.put(state.pools, poolid, updated_pool)
        new_state = %{state | pools: new_pools}

        {:reply, {:ok, updated_pool}, new_state}
    end
  end

  def handle_call({:create_task, node, type, params}, _from, state) do
    upid = "UPID:#{node}:#{state.next_upid}:#{:os.system_time(:second)}:#{type}:root@pam:"

    task =
      Map.merge(
        %{
          upid: upid,
          node: node,
          type: type,
          id: "root@pam",
          user: "root@pam",
          status: "OK",
          exitstatus: "OK",
          starttime: :os.system_time(:second),
          endtime: :os.system_time(:second) + 1,
          pstart: state.next_upid
        },
        params
      )

    new_tasks = Map.put(state.tasks, upid, task)
    new_state = %{state | tasks: new_tasks, next_upid: state.next_upid + 1}

    {:reply, {:ok, upid}, new_state}
  end

  def handle_call({:get_tasks, node}, _from, state) do
    tasks =
      state.tasks
      |> Enum.filter(fn {_upid, task} -> task.node == node end)
      |> Enum.map(&elem(&1, 1))

    {:reply, tasks, state}
  end

  def handle_call(:get_next_vmid, _from, state) do
    vmid = state.next_vmid
    new_state = %{state | next_vmid: vmid + 1}
    {:reply, vmid, new_state}
  end

  def handle_call(:get_pve_version, _from, state) do
    {:reply, state.pve_version, state}
  end

  def handle_call(:get_capabilities, _from, state) do
    {:reply, state.capabilities, state}
  end

  def handle_call({:has_capability, capability}, _from, state) do
    has_capability = capability in state.capabilities
    {:reply, has_capability, state}
  end

  def handle_call({:endpoint_supported, endpoint_path}, _from, state) do
    supported = Capabilities.endpoint_supported?(state.pve_version, endpoint_path)
    {:reply, supported, state}
  end

  def handle_call({:get_task, upid}, _from, state) do
    task = Map.get(state.tasks, upid)
    {:reply, task, state}
  end

  def handle_call({:create_backup, node, vmid, params}, _from, state) do
    backup_file =
      "vzdump-#{if vmid < 1000, do: "qemu", else: "lxc"}-#{vmid}-#{Date.utc_today()}-12_00_00.vma.zst"

    storage = Map.get(params, :storage, "local")

    backup = %{
      node: node,
      vmid: vmid,
      filename: backup_file,
      storage: storage,
      size: :rand.uniform(5_000_000_000) + 1_000_000_000,
      ctime: :os.system_time(:second),
      format: "vma.zst"
    }

    # Create backup entry
    backup_key = "#{storage}:backup/#{backup_file}"
    new_backups = Map.put(state.backups, backup_key, backup)

    # Create task for backup operation
    {:reply, {:ok, upid}, new_state} =
      handle_call({:create_task, node, "vzdump", %{vmid: vmid}}, nil, %{
        state
        | backups: new_backups
      })

    {:reply, {:ok, upid}, new_state}
  end

  def handle_call({:list_backups, node, storage}, _from, state) do
    backups =
      state.backups
      |> Enum.filter(fn {_key, backup} -> backup.node == node and backup.storage == storage end)
      |> Enum.map(&elem(&1, 1))

    {:reply, backups, state}
  end

  def handle_call({:restore_backup, node, vmid, backup_file, _params}, _from, state) do
    # Check if backup exists
    case Enum.find(state.backups, fn {_key, backup} ->
           backup.filename == backup_file and backup.node == node
         end) do
      nil ->
        {:reply, {:error, "Backup file not found"}, state}

      {_key, _backup} ->
        # Create task for restore operation
        {:reply, {:ok, upid}, new_state} =
          handle_call(
            {:create_task, node, "qmrestore", %{vmid: vmid, archive: backup_file}},
            nil,
            state
          )

        {:reply, {:ok, upid}, new_state}
    end
  end

  def handle_call({:migrate_vm, node, vmid, target_node, _params}, _from, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:reply, {:error, "VM #{vmid} not found"}, state}

      vm when vm.node != node ->
        {:reply, {:error, "VM #{vmid} not on node #{node}"}, state}

      vm ->
        # Update VM to new node
        updated_vm = %{vm | node: target_node}
        new_vms = Map.put(state.vms, vmid, updated_vm)

        # Create migration task
        {:reply, {:ok, upid}, new_state} =
          handle_call(
            {:create_task, node, "qmigrate", %{vmid: vmid, target: target_node}},
            nil,
            %{state | vms: new_vms}
          )

        {:reply, {:ok, upid}, new_state}
    end
  end

  def handle_call({:migrate_container, node, vmid, target_node, _params}, _from, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:reply, {:error, "Container #{vmid} not found"}, state}

      container when container.node != node ->
        {:reply, {:error, "Container #{vmid} not on node #{node}"}, state}

      container ->
        # Update container to new node
        updated_container = %{container | node: target_node}
        new_containers = Map.put(state.containers, vmid, updated_container)

        # Create migration task
        {:reply, {:ok, upid}, new_state} =
          handle_call(
            {:create_task, node, "pctmigrate", %{vmid: vmid, target: target_node}},
            nil,
            %{state | containers: new_containers}
          )

        {:reply, {:ok, upid}, new_state}
    end
  end

  def handle_call({:create_ticket, username, _password, _params}, _from, state) do
    # Mock authentication - in real PVE this would validate against PAM/LDAP/etc
    case Map.get(state.users, username) do
      nil ->
        {:reply, {:error, "Authentication failed"}, state}

      _user ->
        ticket = :crypto.strong_rand_bytes(32) |> Base.encode64()
        csrf_token = :crypto.strong_rand_bytes(16) |> Base.encode64()

        ticket_data = %{
          username: username,
          ticket: ticket,
          csrf_token: csrf_token,
          created_at: :os.system_time(:second),
          # 2 hours
          expires_at: :os.system_time(:second) + 7200
        }

        new_tickets = Map.put(state.tickets, ticket, ticket_data)

        response = %{
          username: username,
          ticket: ticket,
          CSRFPreventionToken: csrf_token
        }

        {:reply, {:ok, response}, %{state | tickets: new_tickets}}
    end
  end

  def handle_call({:validate_ticket, ticket}, _from, state) do
    case Map.get(state.tickets, ticket) do
      nil ->
        {:reply, {:error, "Invalid ticket"}, state}

      ticket_data ->
        if ticket_data.expires_at > :os.system_time(:second) do
          {:reply, {:ok, ticket_data}, state}
        else
          # Ticket expired, remove it
          new_tickets = Map.delete(state.tickets, ticket)
          {:reply, {:error, "Ticket expired"}, %{state | tickets: new_tickets}}
        end
    end
  end

  def handle_call({:create_api_token, username, tokenid, params}, _from, state) do
    case Map.get(state.users, username) do
      nil ->
        {:reply, {:error, "User not found"}, state}

      _user ->
        token_value = :crypto.strong_rand_bytes(32) |> Base.encode64()
        full_tokenid = "#{username}!#{tokenid}"

        token_data = %{
          tokenid: full_tokenid,
          token: token_value,
          privsep: Map.get(params, :privsep, 1),
          comment: Map.get(params, :comment, ""),
          expire: Map.get(params, :expire, 0),
          created_at: :os.system_time(:second)
        }

        new_tokens = Map.put(state.api_tokens, full_tokenid, token_data)

        response = %{
          tokenid: full_tokenid,
          value: "#{full_tokenid}=#{token_value}"
        }

        {:reply, {:ok, response}, %{state | api_tokens: new_tokens}}
    end
  end

  def handle_call({:get_permissions, userid}, _from, state) do
    permissions =
      state.permissions
      |> Enum.filter(fn {_path, users} -> Map.has_key?(users, userid) end)
      |> Enum.map(fn {path, users} ->
        roles = Map.get(users, userid, [])
        privileges = Enum.flat_map(roles, fn role -> Map.get(state.roles, role, []) end)
        %{path: path, roles: roles, privileges: privileges}
      end)

    {:reply, permissions, state}
  end

  def handle_call({:set_permissions, path, userid, roleid}, _from, state) do
    current_path_perms = Map.get(state.permissions, path, %{})
    current_user_roles = Map.get(current_path_perms, userid, [])
    updated_roles = [roleid | current_user_roles] |> Enum.uniq()

    new_path_perms = Map.put(current_path_perms, userid, updated_roles)
    new_permissions = Map.put(state.permissions, path, new_path_perms)

    {:reply, :ok, %{state | permissions: new_permissions}}
  end

  # User management callbacks
  def handle_call({:create_user, userid, params}, _from, state) do
    if Map.has_key?(state.users, userid) do
      {:reply, {:error, "User #{userid} already exists"}, state}
    else
      user =
        Map.merge(
          %{
            userid: userid,
            comment: "",
            enable: 1,
            expire: 0,
            groups: []
          },
          params
        )

      new_users = Map.put(state.users, userid, user)
      new_state = %{state | users: new_users}

      {:reply, {:ok, user}, new_state}
    end
  end

  def handle_call({:update_user, userid, params}, _from, state) do
    case Map.get(state.users, userid) do
      nil ->
        {:reply, {:error, "User #{userid} not found"}, state}

      user ->
        updated_user = Map.merge(user, params)
        new_users = Map.put(state.users, userid, updated_user)
        new_state = %{state | users: new_users}
        {:reply, {:ok, updated_user}, new_state}
    end
  end

  def handle_call({:delete_user, userid}, _from, state) do
    case Map.get(state.users, userid) do
      nil ->
        {:reply, {:error, "User #{userid} not found"}, state}

      _user ->
        # Also clean up any API tokens for this user
        tokens_to_remove =
          state.api_tokens
          |> Enum.filter(fn {tokenid, _token} -> String.starts_with?(tokenid, "#{userid}!") end)
          |> Enum.map(&elem(&1, 0))

        new_tokens = Enum.reduce(tokens_to_remove, state.api_tokens, &Map.delete(&2, &1))
        new_users = Map.delete(state.users, userid)

        new_state = %{state | users: new_users, api_tokens: new_tokens}
        {:reply, :ok, new_state}
    end
  end

  # Group management callbacks
  def handle_call({:create_group, groupid, params}, _from, state) do
    if Map.has_key?(state.groups, groupid) do
      {:reply, {:error, "Group #{groupid} already exists"}, state}
    else
      group =
        Map.merge(
          %{
            groupid: groupid,
            comment: ""
          },
          params
        )

      new_groups = Map.put(state.groups, groupid, group)
      new_state = %{state | groups: new_groups}

      {:reply, {:ok, group}, new_state}
    end
  end

  def handle_call({:update_group, groupid, params}, _from, state) do
    case Map.get(state.groups, groupid) do
      nil ->
        {:reply, {:error, "Group #{groupid} not found"}, state}

      group ->
        updated_group = Map.merge(group, params)
        new_groups = Map.put(state.groups, groupid, updated_group)
        new_state = %{state | groups: new_groups}
        {:reply, {:ok, updated_group}, new_state}
    end
  end

  def handle_call({:delete_group, groupid}, _from, state) do
    case Map.get(state.groups, groupid) do
      nil ->
        {:reply, {:error, "Group #{groupid} not found"}, state}

      _group ->
        new_groups = Map.delete(state.groups, groupid)
        new_state = %{state | groups: new_groups}
        {:reply, :ok, new_state}
    end
  end

  # API Token management callbacks
  def handle_call({:delete_api_token, tokenid}, _from, state) do
    case Map.get(state.api_tokens, tokenid) do
      nil ->
        {:reply, {:error, "Token #{tokenid} not found"}, state}

      _token ->
        new_tokens = Map.delete(state.api_tokens, tokenid)
        new_state = %{state | api_tokens: new_tokens}
        {:reply, :ok, new_state}
    end
  end

  def handle_call({:update_api_token, tokenid, params}, _from, state) do
    case Map.get(state.api_tokens, tokenid) do
      nil ->
        {:reply, {:error, "Token #{tokenid} not found"}, state}

      token ->
        # Only allow updating certain fields, not the actual token value
        allowed_updates = Map.take(params, [:comment, :expire, :privsep])
        updated_token = Map.merge(token, allowed_updates)
        new_tokens = Map.put(state.api_tokens, tokenid, updated_token)
        new_state = %{state | api_tokens: new_tokens}
        {:reply, {:ok, updated_token}, new_state}
    end
  end

  # Cluster management callbacks
  def handle_call(:get_cluster_status, _from, state) do
    cluster_nodes =
      state.nodes
      |> Enum.map(fn {node_name, node_data} ->
        cluster_node = get_in(state, [:cluster_config, :nodes, node_name]) || %{}

        Map.merge(node_data, %{
          type: "node",
          level: "",
          nodeid: Map.get(cluster_node, :nodeid, 1),
          local: node_name == "pve-node1"
        })
      end)

    {:reply, cluster_nodes, state}
  end

  def handle_call({:join_cluster, hostname, nodeid, votes}, _from, state) do
    # Generate a new node name based on the hostname
    new_node_name = hostname
    new_nodeid = nodeid || map_size(state.cluster_config.nodes) + 1

    # Create new node configuration
    new_node = %{
      name: new_node_name,
      nodeid: new_nodeid,
      votes: votes,
      ring0_addr: "192.168.1.#{20 + new_nodeid}",
      quorum_votes: votes,
      online: true
    }

    # Update cluster configuration
    updated_cluster_config =
      state.cluster_config
      |> put_in([:nodes, new_node_name], new_node)
      |> update_in([:expected_votes], &(&1 + votes))
      |> put_in([:quorum, :expected_votes], state.cluster_config.expected_votes + votes)
      |> put_in([:quorum, :total_votes], state.cluster_config.quorum.total_votes + votes)

    # Add node to main nodes state
    default_node = %{
      node: new_node_name,
      status: "online",
      cpu: 0.05,
      maxcpu: 4,
      # 2GB
      mem: 2_147_483_648,
      # 8GB
      maxmem: 8_589_934_592,
      # 30GB
      disk: 30_000_000_000,
      # 100GB
      maxdisk: 100_000_000_000,
      uptime: 3600,
      version: state.pve_version,
      kernel: "6.2.16-15-pve"
    }

    updated_nodes = Map.put(state.nodes, new_node_name, default_node)

    # Create join task
    task_result =
      handle_call({:create_task, new_node_name, "clusterjoin", %{hostname: hostname}}, nil, %{
        state
        | cluster_config: updated_cluster_config,
          nodes: updated_nodes
      })

    {:reply, {:ok, upid}, final_state} = task_result

    {:reply, {:ok, upid}, final_state}
  end

  def handle_call(:get_cluster_config, _from, state) do
    {:reply, state.cluster_config, state}
  end

  def handle_call({:update_cluster_config, params}, _from, state) do
    updated_config =
      Enum.reduce(params, state.cluster_config, fn {key, value}, acc ->
        case key do
          "cluster_name" -> Map.put(acc, :cluster_name, value)
          _ -> acc
        end
      end)

    new_state = %{state | cluster_config: updated_config}
    {:reply, {:ok, updated_config}, new_state}
  end

  def handle_call(:get_cluster_nodes_config, _from, state) do
    nodes_list =
      state.cluster_config.nodes
      |> Enum.map(fn {_name, node_config} -> node_config end)

    {:reply, nodes_list, state}
  end

  def handle_call({:remove_cluster_node, node_name}, _from, state) do
    case get_in(state, [:cluster_config, :nodes, node_name]) do
      nil ->
        {:reply, {:error, "Node #{node_name} not found in cluster"}, state}

      node_config ->
        votes = Map.get(node_config, :votes, 1)

        # Update cluster configuration
        updated_cluster_config =
          state.cluster_config
          |> put_in([:nodes], Map.delete(state.cluster_config.nodes, node_name))
          |> update_in([:expected_votes], &(&1 - votes))
          |> put_in([:quorum, :expected_votes], state.cluster_config.expected_votes - votes)
          |> put_in([:quorum, :total_votes], state.cluster_config.quorum.total_votes - votes)

        # Remove from main nodes state
        updated_nodes = Map.delete(state.nodes, node_name)

        # Create removal task
        task_result =
          handle_call({:create_task, node_name, "clusterremove", %{node: node_name}}, nil, %{
            state
            | cluster_config: updated_cluster_config,
              nodes: updated_nodes
          })

        {:reply, {:ok, upid}, final_state} = task_result
        {:reply, {:ok, upid}, final_state}
    end
  end

  @impl true
  def handle_call(:reset, _from, _state) do
    Logger.info("Mock PVE Server state reset")
    {:reply, :ok, initial_state()}
  end

  @impl true
  def handle_cast({:update_node, name, updates}, state) do
    case Map.get(state.nodes, name) do
      nil ->
        {:noreply, state}

      node ->
        updated_node = Map.merge(node, updates)
        new_nodes = Map.put(state.nodes, name, updated_node)
        new_state = %{state | nodes: new_nodes}
        {:noreply, new_state}
    end
  end

  def handle_cast({:delete_vm, node, vmid}, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:noreply, state}

      vm when vm.node == node ->
        new_vms = Map.delete(state.vms, vmid)
        new_state = %{state | vms: new_vms}
        {:noreply, new_state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:delete_container, node, vmid}, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:noreply, state}

      container when container.node == node ->
        new_containers = Map.delete(state.containers, vmid)
        new_state = %{state | containers: new_containers}
        {:noreply, new_state}

      _ ->
        {:noreply, state}
    end
  end

  def handle_cast({:delete_pool, poolid}, state) do
    new_pools = Map.delete(state.pools, poolid)
    new_state = %{state | pools: new_pools}
    {:noreply, new_state}
  end

  def handle_cast({:update_task, upid, updates}, state) do
    case Map.get(state.tasks, upid) do
      nil ->
        {:noreply, state}

      task ->
        updated_task = Map.merge(task, updates)
        new_tasks = Map.put(state.tasks, upid, updated_task)
        {:noreply, %{state | tasks: new_tasks}}
    end
  end
end
