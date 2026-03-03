# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Nodes do
  @moduledoc """
  Handler for PVE node-related endpoints including VMs and containers.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  # Node endpoints

  @doc """
  GET /api2/json/nodes
  Lists all cluster nodes.
  """
  def list_nodes(conn) do
    nodes = State.get_nodes()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nodes}))
  end

  @doc """
  GET /api2/json/nodes/:node
  Gets specific node information.
  """
  def get_node(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Node '#{node_name}' not found"}
          })
        )

      node ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: node}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/status
  Gets node status information.
  """
  def get_node_status(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      node ->
        status = %{
          cpu: node.cpu,
          maxcpu: node.maxcpu,
          memory: %{
            used: node.mem,
            total: node.maxmem,
            free: node.maxmem - node.mem
          },
          swap: %{
            used: 0,
            total: 0,
            free: 0
          },
          rootfs: %{
            used: node.disk,
            total: node.maxdisk,
            avail: node.maxdisk - node.disk
          },
          uptime: node.uptime,
          loadavg: [0.1, 0.05, 0.01]
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: status}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/version
  Gets node version information.
  """
  def get_node_version(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      node ->
        version = %{
          version: node.version,
          kernel: node.kernel,
          pve: node.version
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: version}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/tasks
  Gets node task history.
  """
  def get_node_tasks(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        tasks = State.get_tasks(node_name)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: tasks}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/syslog
  Gets node system log entries.
  """
  def get_node_syslog(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        # Generate some sample log entries
        logs = [
          %{
            n: 1,
            t: "Dec 01 12:00:01 #{node_name} systemd[1]: Started Session 123 of user root."
          },
          %{n: 2, t: "Dec 01 12:00:02 #{node_name} kernel: [12345.678901] CPU temperature: 45°C"},
          %{n: 3, t: "Dec 01 12:00:03 #{node_name} pvedaemon[1234]: worker 5678 finished"}
        ]

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: logs}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/network
  Gets node network interface configuration.
  """
  def get_node_network(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        # Generate sample network interfaces
        interfaces = [
          %{
            iface: "eth0",
            type: "eth",
            active: 1,
            address: "192.168.1.100",
            netmask: "255.255.255.0",
            gateway: "192.168.1.1"
          },
          %{
            iface: "vmbr0",
            type: "bridge",
            active: 1,
            bridge_ports: "eth0",
            address: "192.168.1.100",
            netmask: "255.255.255.0"
          }
        ]

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: interfaces}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/execute
  Executes command on node.
  """
  def execute_command(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params
    command = Map.get(params, "command")

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        # Mock command execution
        result = %{
          exitcode: 0,
          output: "Mock output for command: #{command}"
        }

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: result}))
    end
  end

  # VM endpoints

  @doc """
  GET /api2/json/nodes/:node/qemu
  Lists VMs on a node.
  """
  def list_vms(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        vms = State.get_vms(node_name)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: vms}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid
  Gets comprehensive VM information including config and status.
  """
  def get_vm(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      vm ->
        # Comprehensive VM info including config and status
        vm_info =
          Map.merge(vm, %{
            status: "running",
            uptime: 86400,
            pid: 1234,
            cpu: 0.15,
            cpus: vm.cores || 2,
            maxcpu: vm.cores || 2,
            mem: 2_147_483_648,
            maxmem: vm.memory || 4_294_967_296,
            disk: 0,
            maxdisk: 21_474_836_480,
            netin: 1_024_000,
            netout: 512_000,
            diskread: 10_485_760,
            diskwrite: 5_242_880,
            digest: "vm_digest_#{vmid}"
          })

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: vm_info}))
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/qemu/:vmid
  Updates VM configuration and settings.
  """
  def update_vm(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params

    case State.update_vm(node_name, vmid, params) do
      {:ok, updated_vm} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: updated_vm}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/config
  Gets VM configuration.
  """
  def get_vm_config(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      vm ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: vm}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/status/current
  Gets VM current status.
  """
  def get_vm_status(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      vm ->
        status = Map.take(vm, [:status, :vmid, :name, :memory, :cores])

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: status}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/qemu
  Creates a new VM.
  """
  def create_vm(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params

    vmid =
      case Map.get(params, "vmid") do
        nil -> State.get_next_vmid()
        id when is_integer(id) -> id
        id when is_binary(id) -> String.to_integer(id)
      end

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        config = %{
          name: Map.get(params, "name", "vm-#{vmid}"),
          memory: get_int_param(params, "memory", 2048),
          cores: get_int_param(params, "cores", 2),
          sockets: get_int_param(params, "sockets", 1),
          ostype: Map.get(params, "ostype", "l26")
        }

        case State.create_vm(node_name, vmid, config) do
          {:ok, _vm} ->
            # Create a task for VM creation
            {:ok, upid} = State.create_task(node_name, "qmcreate", %{vmid: vmid})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/qemu/:vmid/config
  Updates VM configuration.
  """
  def update_vm_config(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      _vm ->
        updates =
          %{}
          |> maybe_put(:name, Map.get(params, "name"))
          |> maybe_put(:memory, get_int_param(params, "memory"))
          |> maybe_put(:cores, get_int_param(params, "cores"))
          |> maybe_put(:sockets, get_int_param(params, "sockets"))

        State.update_vm(node_name, vmid, updates)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/status/:action
  Performs VM action (start, stop, restart, etc.).
  """
  def vm_action(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    action = conn.path_params["action"]

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      _vm ->
        new_status =
          case action do
            "start" -> "running"
            "stop" -> "stopped"
            "shutdown" -> "stopped"
            "restart" -> "running"
            "reboot" -> "running"
            _ -> "stopped"
          end

        State.update_vm(node_name, vmid, %{status: new_status})
        {:ok, upid} = State.create_task(node_name, "qm#{action}", %{vmid: vmid})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  @doc """
  DELETE /api2/json/nodes/:node/qemu/:vmid
  Deletes a VM.
  """
  def delete_vm(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      _vm ->
        State.delete_vm(node_name, vmid)
        {:ok, upid} = State.create_task(node_name, "qmdestroy", %{vmid: vmid})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  # Container endpoints

  @doc """
  GET /api2/json/nodes/:node/lxc
  Lists containers on a node.
  """
  def list_containers(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        containers = State.get_containers(node_name)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: containers}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/lxc/:vmid
  Gets comprehensive container information including config and status.
  """
  def get_container(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      container ->
        # Comprehensive container info including config and status
        container_info =
          Map.merge(container, %{
            status: "running",
            uptime: 86400,
            cpu: 0.08,
            cpus: container.cores || 2,
            maxcpu: container.cores || 2,
            mem: 1_073_741_824,
            maxmem: container.memory || 2_147_483_648,
            disk: 0,
            maxdisk: 10_737_418_240,
            netin: 512_000,
            netout: 256_000,
            diskread: 5_242_880,
            diskwrite: 2_621_440,
            digest: "container_digest_#{vmid}"
          })

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: container_info}))
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/lxc/:vmid
  Updates container configuration and settings.
  """
  def update_container(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params

    case State.update_container(node_name, vmid, params) do
      {:ok, updated_container} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: updated_container}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/lxc/:vmid/config
  Gets container configuration.
  """
  def get_container_config(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      container ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: container}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/lxc/:vmid/status/current
  Gets container current status.
  """
  def get_container_status(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      container ->
        status = Map.take(container, [:status, :vmid, :hostname, :memory])

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: status}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/lxc
  Creates a new container.
  """
  def create_container(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params

    vmid =
      case Map.get(params, "vmid") do
        nil -> State.get_next_vmid()
        id when is_integer(id) -> id
        id when is_binary(id) -> String.to_integer(id)
      end

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        config = %{
          hostname: Map.get(params, "hostname", "ct-#{vmid}"),
          memory: get_int_param(params, "memory", 1024),
          cores: get_int_param(params, "cores", 1),
          ostemplate: Map.get(params, "ostemplate"),
          rootfs: Map.get(params, "rootfs", "local-lvm:8")
        }

        case State.create_container(node_name, vmid, config) do
          {:ok, _container} ->
            {:ok, upid} = State.create_task(node_name, "pctcreate", %{vmid: vmid})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/lxc/:vmid/config
  Updates container configuration.
  """
  def update_container_config(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      _container ->
        updates =
          %{}
          |> maybe_put(:hostname, Map.get(params, "hostname"))
          |> maybe_put(:memory, get_int_param(params, "memory"))
          |> maybe_put(:cores, get_int_param(params, "cores"))

        State.update_container(node_name, vmid, updates)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/lxc/:vmid/status/:action
  Performs container action (start, stop, restart, etc.).
  """
  def container_action(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    action = conn.path_params["action"]

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      _container ->
        new_status =
          case action do
            "start" -> "running"
            "stop" -> "stopped"
            "shutdown" -> "stopped"
            "restart" -> "running"
            "reboot" -> "running"
            _ -> "stopped"
          end

        State.update_container(node_name, vmid, %{status: new_status})
        {:ok, upid} = State.create_task(node_name, "pct#{action}", %{vmid: vmid})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  @doc """
  DELETE /api2/json/nodes/:node/lxc/:vmid
  Deletes a container.
  """
  def delete_container(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      _container ->
        State.delete_container(node_name, vmid)
        {:ok, upid} = State.create_task(node_name, "pctdestroy", %{vmid: vmid})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  # Backup and migration endpoints

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/migrate
  Migrates a VM to another node.
  """
  def migrate_vm(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params
    target_node = Map.get(params, "target")

    if target_node do
      case State.migrate_vm(node_name, vmid, target_node, params) do
        {:ok, upid} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: upid}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{message: "Missing target node"}}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/lxc/:vmid/migrate
  Migrates a container to another node.
  """
  def migrate_container(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params
    target_node = Map.get(params, "target")

    if target_node do
      case State.migrate_container(node_name, vmid, target_node, params) do
        {:ok, upid} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: upid}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{message: "Missing target node"}}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/snapshot
  Creates a VM snapshot.
  """
  def create_vm_snapshot(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params
    snapname = Map.get(params, "snapname", "snapshot-#{:os.system_time(:second)}")

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      _vm ->
        {:ok, upid} =
          State.create_task(node_name, "qmsnapshot", %{vmid: vmid, snapname: snapname})

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/vzdump
  Creates backup of VMs/containers.
  """
  def create_backup(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params
    vmid_param = Map.get(params, "vmid")

    cond do
      vmid_param ->
        vmid = String.to_integer(vmid_param)

        case State.create_backup(node_name, vmid, params) do
          {:ok, upid} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end

      true ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{errors: %{message: "Missing vmid parameter"}}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/backup
  Lists backup files in storage.
  """
  def list_backup_files(conn) do
    node_name = conn.path_params["node"]
    storage = conn.path_params["storage"]

    backups = State.list_backups(node_name, storage)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: backups}))
  end

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/clone
  Clones a VM.
  """
  def clone_vm(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params
    newid = get_int_param(params, "newid") || State.get_next_vmid()

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      vm ->
        # Create cloned VM config
        clone_config = %{
          name: Map.get(params, "name", "#{vm.name}-clone"),
          memory: vm.memory,
          cores: vm.cores,
          sockets: vm.sockets,
          ostype: vm.ostype
        }

        case State.create_vm(node_name, newid, clone_config) do
          {:ok, _new_vm} ->
            {:ok, upid} = State.create_task(node_name, "qmclone", %{vmid: vmid, newid: newid})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  POST /api2/json/nodes/:node/lxc/:vmid/clone
  Clones an LXC container.
  """
  def clone_container(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    params = conn.body_params
    newid = get_int_param(params, "newid") || State.get_next_vmid()

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      container ->
        # Create cloned container config
        clone_config = %{
          hostname: Map.get(params, "hostname", "#{container.hostname}-clone"),
          memory: container.memory,
          swap: container.swap,
          cores: container.cores,
          ostemplate: container.ostemplate,
          rootfs: Map.get(params, "rootfs", container.rootfs)
        }

        case State.create_container(node_name, newid, clone_config) do
          {:ok, _new_container} ->
            {:ok, upid} = State.create_task(node_name, "pctclone", %{vmid: vmid, newid: newid})

            conn
            |> put_resp_content_type("application/json")
            |> send_resp(200, Jason.encode!(%{data: upid}))

          {:error, message} ->
            conn
            |> put_resp_content_type("application/json")
            |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
        end
    end
  end

  @doc """
  GET /api2/json/nodes/:node/tasks/:upid/status
  Gets task status with progress information.
  """
  def get_task_status(conn) do
    _node_name = conn.path_params["node"]
    upid = conn.path_params["upid"]

    case State.get_task(upid) do
      nil ->
        send_not_found(conn, "Task", upid)

      task ->
        # Add realistic progress simulation
        now = :os.system_time(:second)
        elapsed = now - task.starttime

        # Simulate task progress
        # Complete in ~60 seconds
        progress = min(100, div(elapsed * 100, 60))

        status =
          if progress >= 100 do
            Map.merge(task, %{
              status: "OK",
              exitstatus: "OK",
              endtime: now,
              progress: 100
            })
          else
            Map.merge(task, %{
              status: "running",
              progress: progress
            })
          end

        # Update task in state if it's completed
        if progress >= 100 and task.status != "OK" do
          State.update_task(upid, %{status: "OK", exitstatus: "OK", endtime: now})
        end

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: status}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/tasks/:upid/log
  Gets task log output.
  """
  def get_task_log(conn) do
    _node_name = conn.path_params["node"]
    upid = conn.path_params["upid"]

    case State.get_task(upid) do
      nil ->
        send_not_found(conn, "Task", upid)

      task ->
        # Generate sample log entries based on task type
        logs = generate_task_logs(task)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: logs}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/time
  Gets node time configuration.
  """
  def get_node_time(conn) do
    _node_name = conn.path_params["node"]

    # Simulate current node time configuration
    time_config = %{
      timezone: "Europe/Vienna",
      time: :os.system_time(:second),
      localtime: :os.system_time(:second)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: time_config}))
  end

  @doc """
  PUT /api2/json/nodes/:node/time
  Sets node time configuration.
  """
  def set_node_time(conn) do
    _node_name = conn.path_params["node"]
    params = conn.body_params

    # In a real implementation, this would actually set the system time
    # For mocking, we just return success
    timezone = Map.get(params, "timezone", "Europe/Vienna")

    updated_config = %{
      timezone: timezone,
      time: :os.system_time(:second),
      localtime: :os.system_time(:second)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: updated_config}))
  end

  # Helper functions

  defp generate_task_logs(task) do
    base_logs = [
      %{n: 1, t: "#{task.starttime}: starting task UPID:#{task.upid}"},
      %{n: 2, t: "#{task.starttime + 1}: task type: #{task.type}"}
    ]

    case task.type do
      "qmstart" ->
        base_logs ++
          [
            %{n: 3, t: "#{task.starttime + 2}: starting VM #{task.vmid}"},
            %{n: 4, t: "#{task.starttime + 5}: VM #{task.vmid} started successfully"}
          ]

      "qmstop" ->
        base_logs ++
          [
            %{n: 3, t: "#{task.starttime + 2}: stopping VM #{task.vmid}"},
            %{n: 4, t: "#{task.starttime + 5}: VM #{task.vmid} stopped successfully"}
          ]

      "qmigrate" ->
        target = Map.get(task, :target, "unknown")

        base_logs ++
          [
            %{
              n: 3,
              t: "#{task.starttime + 2}: starting migration of VM #{task.vmid} to #{target}"
            },
            %{n: 4, t: "#{task.starttime + 10}: copying VM state..."},
            %{n: 5, t: "#{task.starttime + 20}: migration completed successfully"}
          ]

      "qmclone" ->
        newid = Map.get(task, :newid, "unknown")

        base_logs ++
          [
            %{n: 3, t: "#{task.starttime + 2}: starting clone of VM #{task.vmid} to #{newid}"},
            %{n: 4, t: "#{task.starttime + 5}: creating VM configuration..."},
            %{n: 5, t: "#{task.starttime + 10}: copying disk images..."},
            %{n: 6, t: "#{task.starttime + 25}: clone completed successfully"}
          ]

      "pctclone" ->
        newid = Map.get(task, :newid, "unknown")

        base_logs ++
          [
            %{
              n: 3,
              t: "#{task.starttime + 2}: starting clone of Container #{task.vmid} to #{newid}"
            },
            %{n: 4, t: "#{task.starttime + 5}: creating container configuration..."},
            %{n: 5, t: "#{task.starttime + 10}: copying container data..."},
            %{n: 6, t: "#{task.starttime + 20}: clone completed successfully"}
          ]

      "vzdump" ->
        base_logs ++
          [
            %{n: 3, t: "#{task.starttime + 2}: starting backup of VM #{task.vmid}"},
            %{n: 4, t: "#{task.starttime + 10}: creating snapshot..."},
            %{n: 5, t: "#{task.starttime + 20}: backing up VM config..."},
            %{n: 6, t: "#{task.starttime + 30}: backup completed successfully"}
          ]

      _ ->
        base_logs ++
          [
            %{n: 3, t: "#{task.starttime + 5}: task completed successfully"}
          ]
    end
  end

  defp send_not_found(conn, resource_type, identifier) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(
      404,
      Jason.encode!(%{
        errors: %{message: "#{resource_type} '#{identifier}' not found"}
      })
    )
  end

  defp get_int_param(params, key, default \\ nil) do
    case Map.get(params, key) do
      nil ->
        default

      val when is_integer(val) ->
        val

      val when is_binary(val) ->
        case Integer.parse(val) do
          {int, _} -> int
          :error -> default
        end

      _ ->
        default
    end
  end

  defp maybe_put(map, _key, nil), do: map
  defp maybe_put(map, key, value), do: Map.put(map, key, value)

  # Node DNS endpoints

  @doc """
  GET /api2/json/nodes/:node/dns
  Gets node DNS configuration.
  """
  def get_node_dns(conn) do
    node_name = conn.path_params["node"]
    dns = State.get_node_dns(node_name)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: dns}))
  end

  @doc """
  PUT /api2/json/nodes/:node/dns
  Updates node DNS configuration.
  """
  def update_node_dns(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params
    :ok = State.update_node_dns(node_name, params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # APT endpoints

  @doc """
  GET /api2/json/nodes/:node/apt/update
  Lists available package updates.
  """
  def get_apt_updates(conn) do
    updates = [
      %{
        "Package" => "pve-manager",
        "Title" => "Proxmox VE Manager",
        "OldVersion" => "8.0.3",
        "Version" => "8.0.4",
        "Section" => "admin",
        "Priority" => "optional",
        "Origin" => "Proxmox"
      },
      %{
        "Package" => "libpve-common-perl",
        "Title" => "Proxmox VE common library",
        "OldVersion" => "8.0.5",
        "Version" => "8.0.6",
        "Section" => "perl",
        "Priority" => "optional",
        "Origin" => "Proxmox"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: updates}))
  end

  @doc """
  POST /api2/json/nodes/:node/apt/update
  Triggers package database refresh.
  """
  def post_apt_update(conn) do
    node_name = conn.path_params["node"]
    upid = "UPID:#{node_name}:00000001:00000000:00000000:aptupdate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc """
  GET /api2/json/nodes/:node/apt/versions
  Gets installed package versions.
  """
  def get_apt_versions(conn) do
    versions = [
      %{
        "Package" => "pve-manager",
        "Title" => "Proxmox VE Manager",
        "CurrentState" => "Installed",
        "RunningKernel" => "6.2.16-15-pve",
        "OldVersion" => "8.0.3",
        "Version" => "8.0.3",
        "ManagerVersion" => "8.0.3"
      },
      %{
        "Package" => "proxmox-ve",
        "Title" => "Proxmox Virtual Environment",
        "CurrentState" => "Installed",
        "OldVersion" => "8.0.2",
        "Version" => "8.0.2"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: versions}))
  end

  # Network interface individual endpoints

  @doc """
  GET /api2/json/nodes/:node/network/:iface
  Gets a specific network interface configuration.
  """
  def get_node_network_iface(conn) do
    node_name = conn.path_params["node"]
    iface = conn.path_params["iface"]

    case State.get_node_network_iface(node_name, iface) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Interface '#{iface}' not found on '#{node_name}'"}})
        )

      iface_info ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: iface_info}))
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/network/:iface
  Updates a network interface configuration.
  """
  def update_node_network_iface(conn) do
    node_name = conn.path_params["node"]
    iface = conn.path_params["iface"]
    params = conn.body_params

    case State.update_node_network_iface(node_name, iface, params) do
      {:ok, _updated} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/nodes/:node/network/:iface
  Deletes a network interface configuration.
  """
  def delete_node_network_iface(conn) do
    node_name = conn.path_params["node"]
    iface = conn.path_params["iface"]

    case State.delete_node_network_iface(node_name, iface) do
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

  # Disk listing

  @doc """
  GET /api2/json/nodes/:node/disks/list
  Lists local disks on a node.
  """
  def list_disks(conn) do
    disks = [
      %{
        devpath: "/dev/sda",
        size: 500_107_862_016,
        serial: "WD-WCC4M1234567",
        model: "WDC WD5003ABYX-01WERA0",
        type: "hdd",
        rpm: 7200,
        vendor: "WDC",
        wwn: "0x50014ee2",
        health: "PASSED",
        gpt: 1,
        used: "LVM"
      },
      %{
        devpath: "/dev/sdb",
        size: 256_060_514_304,
        serial: "S1234567890",
        model: "Samsung SSD 860",
        type: "ssd",
        rpm: 0,
        vendor: "Samsung",
        wwn: "0x50025385",
        health: "PASSED",
        gpt: 1,
        used: "LVM"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: disks}))
  end

  # Disk management endpoints

  @doc "GET /api2/json/nodes/:node/disks/lvm"
  def list_disks_lvm(conn) do
    data = [
      %{name: "pve", size: 500_107_862_016, free: 100_000_000_000, pvs: "/dev/sda3"}
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  @doc "POST /api2/json/nodes/:node/disks/lvm"
  def create_disk_lvm(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:lvmcreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc "GET /api2/json/nodes/:node/disks/lvmthin"
  def list_disks_lvmthin(conn) do
    data = [
      %{lv: "data", vg: "pve", lv_size: 400_000_000_000, metadata_size: 1_073_741_824, used: 0.25}
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  @doc "POST /api2/json/nodes/:node/disks/lvmthin"
  def create_disk_lvmthin(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:lvmthincreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc "GET /api2/json/nodes/:node/disks/zfs"
  def list_disks_zfs(conn) do
    data = [
      %{
        name: "rpool",
        size: 500_107_862_016,
        alloc: 50_000_000_000,
        free: 450_000_000_000,
        health: "ONLINE"
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  @doc "POST /api2/json/nodes/:node/disks/zfs"
  def create_disk_zfs(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:zfscreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc "POST /api2/json/nodes/:node/disks/initgpt"
  def init_disk_gpt(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:initgpt::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Node Ceph endpoints

  @doc "GET /api2/json/nodes/:node/ceph/status"
  def get_node_ceph_status(conn) do
    status = %{
      health: %{status: "HEALTH_OK"},
      pgmap: %{pgs_by_state: [], num_pgs: 0},
      osdmap: %{num_osds: 0, num_up_osds: 0, num_in_osds: 0}
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: status}))
  end

  @doc "GET /api2/json/nodes/:node/ceph/osd"
  def list_node_ceph_osd(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{root: %{children: []}}}))
  end

  @doc "POST /api2/json/nodes/:node/ceph/osd"
  def create_node_ceph_osd(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:osdcreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc "GET /api2/json/nodes/:node/ceph/pools"
  def list_node_ceph_pools(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  @doc "POST /api2/json/nodes/:node/ceph/pools"
  def create_node_ceph_pool(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephcreatepool::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # ACME certificate endpoints

  @doc "POST /api2/json/nodes/:node/certificates/acme/certificate"
  def acme_certificate_new(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:acmenewcert::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc "PUT /api2/json/nodes/:node/certificates/acme/certificate"
  def acme_certificate_renew(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:acmerenew::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  @doc "DELETE /api2/json/nodes/:node/certificates/acme/certificate"
  def acme_certificate_delete(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # Task delete

  @doc """
  DELETE /api2/json/nodes/:node/tasks/:upid
  Stops/deletes a task.
  """
  def delete_task(conn) do
    upid = conn.path_params["upid"]

    case State.delete_task(upid) do
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

  # Node config

  @doc """
  GET /api2/json/nodes/:node/config
  Gets node configuration.
  """
  def get_node_config(conn) do
    node_name = conn.path_params["node"]
    config = State.get_node_config(node_name)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: config}))
  end

  @doc """
  PUT /api2/json/nodes/:node/config
  Updates node configuration.
  """
  def update_node_config(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params
    :ok = State.update_node_config(node_name, params)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # Vzdump defaults

  @doc """
  GET /api2/json/nodes/:node/vzdump/defaults
  Gets default vzdump options.
  """
  def get_vzdump_defaults(conn) do
    defaults = %{
      mode: "snapshot",
      compress: "zstd",
      storage: "local",
      mailnotification: "always",
      mailto: "",
      maxfiles: 1,
      pigz: 0,
      bwlimit: 0,
      ionice: 7,
      lockwait: 180,
      stopwait: 10,
      tmpdir: "/var/tmp"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: defaults}))
  end

  @doc """
  GET /api2/json/nodes/:node/vzdump/extractconfig
  Extract configuration from vzdump backup archive.
  """
  def get_vzdump_extractconfig(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{node: "Node '#{node_name}' not found"}}))

      _node ->
        # Return mock extracted config (vzdump archive config section)
        config = """
        #qemu server config
        boot: order=scsi0;net0
        cores: 2
        memory: 2048
        name: restored-vm
        net0: virtio=AA:BB:CC:DD:EE:FF,bridge=vmbr0
        scsi0: local-lvm:vm-100-disk-0,size=32G
        scsihw: virtio-scsi-single
        smbios1: uuid=12345678-1234-1234-1234-123456789abc
        vmgenid: 12345678-1234-1234-1234-123456789abc
        """

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: String.trim(config)}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/qmrestore
  Restore VM from vzdump backup archive.
  """
  def qmrestore(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{node: "Node '#{node_name}' not found"}}))

      _node ->
        upid =
          "UPID:#{node_name}:#{:rand.uniform(9_999_999) |> Integer.to_string() |> String.pad_leading(8, "0")}:00000000:00000000:qmrestore::root@pam:"

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  @doc """
  POST /api2/json/nodes/:node/vzrestore
  Restore container from vzdump backup archive.
  """
  def vzrestore(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{node: "Node '#{node_name}' not found"}}))

      _node ->
        upid =
          "UPID:#{node_name}:#{:rand.uniform(9_999_999) |> Integer.to_string() |> String.pad_leading(8, "0")}:00000000:00000000:vzrestore::root@pam:"

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: upid}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/pending
  Get pending VM configuration changes.
  """
  def get_vm_pending(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_vm(node_name, vmid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{vmid: "VM '#{vmid}' not found"}}))

      vm ->
        # Return current config as pending entries (no pending changes in mock)
        pending =
          vm
          |> Map.drop([:vmid, :node, :status, :uptime, :pid, :disk_read, :disk_write])
          |> Enum.map(fn {key, value} ->
            %{key: to_string(key), value: value}
          end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: pending}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/lxc/:vmid/pending
  Get pending container configuration changes.
  """
  def get_container_pending(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])

    case State.get_container(node_name, vmid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{vmid: "Container '#{vmid}' not found"}}))

      ct ->
        pending =
          ct
          |> Map.drop([:vmid, :node, :status, :uptime, :pid])
          |> Enum.map(fn {key, value} ->
            %{key: to_string(key), value: value}
          end)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: pending}))
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/qemu/:vmid/resize
  Resize a VM disk.
  """
  def resize_vm_disk(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    disk = Map.get(conn.body_params, "disk", "scsi0")
    size = Map.get(conn.body_params, "size", "+1G")

    case State.resize_vm_disk(node_name, vmid, disk, size) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{vmid: "VM '#{vmid}' not found"}}))
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/lxc/:vmid/resize
  Resize a container disk.
  """
  def resize_container_disk(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    disk = Map.get(conn.body_params, "disk", "rootfs")
    size = Map.get(conn.body_params, "size", "+1G")

    case State.resize_container_disk(node_name, vmid, disk, size) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, :not_found} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{vmid: "Container '#{vmid}' not found"}}))
    end
  end

  # --- Hosts ---

  def get_hosts(conn) do
    data = %{
      digest: :crypto.strong_rand_bytes(16) |> Base.encode16(case: :lower),
      data: "127.0.0.1 localhost\n::1 localhost ip6-localhost ip6-loopback\n"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  def set_hosts(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- Subscription ---

  def get_subscription(conn) do
    now = System.system_time(:second)

    data = %{
      status: "notfound",
      message: "There is no subscription key",
      serverid: "MOCK000000000000",
      checktime: now,
      key: ""
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  def set_subscription(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- Bulk Operations ---

  def startall(conn) do
    node = conn.path_params["node"]
    now = System.system_time(:second)
    upid = "UPID:#{node}:0000AAAA:00000001:#{now}:startall:#{node}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def stopall(conn) do
    node = conn.path_params["node"]
    now = System.system_time(:second)
    upid = "UPID:#{node}:0000BBBB:00000001:#{now}:stopall:#{node}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def migrateall(conn) do
    node = conn.path_params["node"]
    now = System.system_time(:second)
    upid = "UPID:#{node}:0000CCCC:00000001:#{now}:migrateall:#{node}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # --- Journal ---

  def get_journal(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # --- Certificates ---

  def get_certificates_info(conn) do
    now = System.system_time(:second)

    data = [
      %{
        filename: "/etc/pve/local/pve-ssl.pem",
        fingerprint: "AA:BB:CC:DD:EE:FF:00:11:22:33:44:55:66:77:88:99:AA:BB:CC:DD",
        issuer: "CN=Proxmox Virtual Environment, O=PVE",
        notafter: now + 365 * 24 * 3600,
        notbefore: now - 365 * 24 * 3600,
        subject: "CN=mock-pve-node, O=PVE",
        "public-key-type": "rsaEncryption",
        "public-key-bits": 2048
      }
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- Disks SMART ---

  def get_disks_smart(conn) do
    data = %{
      health: "PASSED",
      type: "text",
      text:
        "=== START OF INFORMATION SECTION ===\nModel Family:     Mock SSD\nSerial Number:    MOCK1234567890\n"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- VM Feature Check ---

  def get_vm_feature(conn) do
    data = %{hasFeature: true}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- VM Template ---

  def convert_vm_to_template(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- VM Agent ---

  def vm_agent(conn) do
    data = %{result: ""}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  def vm_agent_subcommand(conn) do
    data =
      case conn.method do
        "POST" -> nil
        _ -> %{result: ""}
      end

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- VM Sendkey ---

  @doc "PUT /api2/json/nodes/:node/qemu/:vmid/sendkey"
  def vm_sendkey(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- VM Cloud-Init ---

  def get_vm_cloudinit_dump(conn) do
    data = "# cloud-init config\nnetwork:\n  version: 2\n"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- VM Unlink ---

  def vm_unlink(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- VM Move Disk ---

  def vm_move_disk(conn) do
    node = conn.path_params["node"]
    vmid = conn.path_params["vmid"]
    now = System.system_time(:second)
    upid = "UPID:#{node}:0000DDDD:00000001:#{now}:move_disk:#{vmid}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # --- Container Feature Check ---

  def get_ct_feature(conn) do
    data = %{hasFeature: true}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- Container Template ---

  def convert_ct_to_template(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- Container Move Volume ---

  def ct_move_volume(conn) do
    node = conn.path_params["node"]
    vmid = conn.path_params["vmid"]
    now = System.system_time(:second)
    upid = "UPID:#{node}:0000EEEE:00000001:#{now}:move_volume:#{vmid}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # --- VM Migrate Preconditions ---

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/migrate
  Returns VM migration preconditions (running status, local disks, local resources).
  """
  def get_vm_migrate_preconditions(conn) do
    data = %{
      running: false,
      local_disks: [],
      local_resources: [],
      allowed_nodes: []
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- VM Async Config Update ---

  @doc """
  POST /api2/json/nodes/:node/qemu/:vmid/config
  Asynchronous VM configuration update — returns a UPID task string.
  """
  def async_update_vm_config(conn) do
    node = conn.path_params["node"]
    vmid = conn.path_params["vmid"]
    now = System.system_time(:second)
    upid = "UPID:#{node}:00001234:000000:#{now}:qmconfig:#{vmid}:root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # --- VM Agent Info ---

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/agent
  Returns QEMU guest agent availability info.
  """
  def get_vm_agent(conn) do
    data = %{supported: false}

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- Container Migrate Preconditions ---

  @doc """
  GET /api2/json/nodes/:node/lxc/:vmid/migrate
  Returns container migration preconditions.
  """
  def get_ct_migrate_preconditions(conn) do
    data = %{
      running: false,
      local_volumes: [],
      allowed_nodes: []
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- Node Network Create/Reload/Delete Pending ---

  @doc """
  POST /api2/json/nodes/:node/network
  Creates a new network interface configuration.
  """
  def create_node_network_iface(conn) do
    node_name = conn.path_params["node"]
    params = conn.body_params
    iface = Map.get(params, "iface")

    if iface do
      iface_config = Map.put(params, "iface", iface)
      State.update_node_network_iface(node_name, iface, iface_config)

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{data: nil}))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{iface: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  PUT /api2/json/nodes/:node/network
  Reloads network configuration (apply pending changes).
  """
  def reload_node_network(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  @doc """
  DELETE /api2/json/nodes/:node/network
  Reverts pending network configuration changes.
  """
  def delete_pending_node_network(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- Subscription Update/Delete ---

  @doc """
  PUT /api2/json/nodes/:node/subscription
  Updates the subscription key.
  """
  def update_subscription(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  @doc """
  DELETE /api2/json/nodes/:node/subscription
  Deletes the subscription.
  """
  def delete_subscription(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- Task Summary ---

  @doc """
  GET /api2/json/nodes/:node/tasks/:upid
  Returns task summary (distinct from /status and /log).
  """
  def get_task(conn) do
    upid = conn.path_params["upid"]

    summary = %{
      upid: upid,
      type: "unknown",
      id: "",
      user: "root@pam",
      status: "stopped",
      exitstatus: "OK",
      starttime: System.system_time(:second),
      endtime: System.system_time(:second)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: summary}))
  end

  # --- VM status index ---

  def get_vm_status_index(conn) do
    data = Enum.map(~w(current start stop reset shutdown suspend resume reboot), &%{subdir: &1})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- LXC status index ---

  def get_container_status_index(conn) do
    data = Enum.map(~w(current start stop shutdown suspend resume reboot), &%{subdir: &1})

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: data}))
  end

  # --- VM/LXC console stubs ---

  def vm_vncproxy(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{port: 5900, ticket: "stub-ticket", cert: ""}}))
  end

  def vm_termproxy(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{port: 5900, ticket: "stub-ticket", user: "root"}}))
  end

  def vm_spiceproxy(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{type: "spice", host: "localhost", port: 61000}}))
  end

  def vm_vncwebsocket(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{port: 5900}}))
  end

  def vm_mtunnel(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def vm_mtunnelwebsocket(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def vm_remote_migrate(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def vm_monitor(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ""}))
  end

  # --- VM cloudinit ---

  def get_vm_cloudinit(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def update_vm_cloudinit(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- LXC console stubs ---

  def container_vncproxy(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{port: 5900, ticket: "stub-ticket", cert: ""}}))
  end

  def container_termproxy(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{port: 5900, ticket: "stub-ticket", user: "root"}}))
  end

  def container_spiceproxy(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{type: "spice", host: "localhost", port: 61001}}))
  end

  def container_vncwebsocket(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{port: 5900}}))
  end

  def container_mtunnel(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def container_mtunnelwebsocket(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def container_remote_migrate(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def container_interfaces(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # --- Node scan stubs ---

  def get_scan_index(conn) do
    subdirs = ~w(cifs glusterfs iscsi lvm lvmthin nfs pbs zfs)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: Enum.map(subdirs, &%{method: &1})}))
  end

  def scan_stub(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # --- Node services actions ---

  def node_service_action(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # --- Node replication stubs ---

  def list_node_replication(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_replication_job(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_replication_log(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def node_replication_schedule_now(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def get_node_replication_status(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  # --- Sprint 4.9.12: Node apt, capabilities, certs, disks, console, misc ---

  def get_apt_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_apt_changelog(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ""}))
  end

  def get_apt_repositories(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{repositories: [], errors: [], infos: []}}))
  end

  def update_apt_repositories(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def post_apt_repositories(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def get_capabilities_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_qemu_capabilities(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_qemu_cpu_capabilities(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_qemu_machine_capabilities(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_qemu_cpu_flags(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_qemu_migration_capabilities(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_certificates_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_acme_cert_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def manage_custom_certificate(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def get_disks_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_disks_directory(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def create_disks_directory(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def delete_disks_directory(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def delete_disks_lvm(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def delete_disks_lvmthin(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def delete_disks_zfs(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def wipe_disk(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def node_console_stub(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_vncwebsocket(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def node_wakeonlan(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  def node_suspendall(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  # Node aplinfo

  def get_node_aplinfo(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def post_node_aplinfo(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:apldownload::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Node vncshell

  def node_vncshell(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  # Node query stubs

  def get_query_url_metadata(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_query_oci_repo_tags(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # Node qemu dbus-vmstate stub

  def node_qemu_dbus_vmstate(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:dbusstate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Node disks index and remaining stubs

  def get_node_disks_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def delete_node_disks_lvm(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:lvmremove::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def delete_node_disks_lvmthin(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:lvmthinremove::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def wipe_node_disk(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:wipedisk::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def delete_node_disks_zfs(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:zfsdestroy::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_disks_zfs_detail(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  # Node storage sub-item stubs

  def get_node_storage(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def node_storage_download_url(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:download::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_storage_import_metadata(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def node_storage_oci_pull(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:ocipull::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Node SDN local stubs

  def get_node_sdn_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_fabric(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_sdn_fabric_interfaces(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_fabric_neighbors(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_fabric_routes(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_vnet(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_sdn_vnet_mac_vrf(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_zones(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_zone(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_sdn_zone_bridges(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_zone_content(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_sdn_zone_ip_vrf(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  # Node ceph sub-endpoint stubs

  def get_node_ceph_index(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_ceph_cfg(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_ceph_cfg_db(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_ceph_cfg_raw(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ""}))
  end

  def get_node_ceph_cfg_value(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_ceph_cmd_safety(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_ceph_config(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ""}))
  end

  def get_node_ceph_configdb(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_ceph_crush(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ""}))
  end

  def get_node_ceph_fs(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def create_node_ceph_fs(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephcreatefscreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def init_node_ceph(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephinit::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_log(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def get_node_ceph_mds(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def delete_node_ceph_mds(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephmdsdelete::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def create_node_ceph_mds(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephmdscreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_mgr(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def delete_node_ceph_mgr(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephmgrremove::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def create_node_ceph_mgr(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephmgrcreate::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_mon(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def delete_node_ceph_mon(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephmonremove::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def create_node_ceph_mon(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephmonstart::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def delete_node_ceph_osd(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephosdremove::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_osd_detail(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def node_ceph_osd_in(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephosdin::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_osd_lv_info(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def get_node_ceph_osd_metadata(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def node_ceph_osd_out(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephosdout::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def node_ceph_osd_scrub(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephosdscrub::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Node ceph pool (singular) stubs - alias for pools (newer PVE API path)

  def get_node_ceph_pool_list(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def create_node_ceph_pool_v2(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephcreatepool::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def delete_node_ceph_pool_by_name(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephdeletepool::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_pool_by_name(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def update_node_ceph_pool(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephupdatepool::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def get_node_ceph_pool_status(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  # Node ceph pools/{name} sub-item stubs (legacy path, exists alongside pool/)

  def get_node_ceph_pools_by_name(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: %{}}))
  end

  def update_node_ceph_pools(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephupdatepool::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def delete_node_ceph_pools_by_name(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephdeletepool::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  # Node ceph lifecycle stubs

  def get_node_ceph_rules(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: []}))
  end

  def restart_node_ceph(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephrestart::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def start_node_ceph(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephstart::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end

  def stop_node_ceph(conn) do
    node = conn.path_params["node"]
    upid = "UPID:#{node}:00000001:00000000:00000000:cephstop::root@pam:"

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: upid}))
  end
end
