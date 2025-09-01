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
    pve_version = Application.get_env(:mock_pve_server, :pve_version, "8.0")

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
      next_vmid: 100,
      tasks: %{},
      next_upid: 1
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
    GenServer.cast(@name, :reset)
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
    GenServer.cast(@name, {:update_vm, node, vmid, config})
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
    GenServer.cast(@name, {:update_container, node, vmid, config})
  end

  def delete_container(node, vmid) do
    GenServer.cast(@name, {:delete_container, node, vmid})
  end

  # Storage operations  
  def get_storage do
    GenServer.call(@name, :get_storage)
  end

  def get_storage_content(node, storage) do
    GenServer.call(@name, {:get_storage_content, node, storage})
  end

  # Pool operations
  def get_pools do
    GenServer.call(@name, :get_pools)
  end

  def create_pool(poolid, config) do
    GenServer.call(@name, {:create_pool, poolid, config})
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

  def handle_call(:get_storage, _from, state) do
    storage = Map.values(state.storage)
    {:reply, storage, state}
  end

  def handle_call({:get_storage_content, node, storage_id}, _from, state) do
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

  @impl true
  def handle_cast(:reset, _state) do
    Logger.info("Mock PVE Server state reset")
    {:noreply, initial_state()}
  end

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

  def handle_cast({:update_vm, node, vmid, config}, state) do
    case Map.get(state.vms, vmid) do
      nil ->
        {:noreply, state}

      vm when vm.node == node ->
        updated_vm = Map.merge(vm, config)
        new_vms = Map.put(state.vms, vmid, updated_vm)
        new_state = %{state | vms: new_vms}
        {:noreply, new_state}

      _ ->
        {:noreply, state}
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

  def handle_cast({:update_container, node, vmid, config}, state) do
    case Map.get(state.containers, vmid) do
      nil ->
        {:noreply, state}

      container when container.node == node ->
        updated_container = Map.merge(container, config)
        new_containers = Map.put(state.containers, vmid, updated_container)
        new_state = %{state | containers: new_containers}
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
end
