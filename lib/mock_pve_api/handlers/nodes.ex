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
        vm_info = Map.merge(vm, %{
          status: "running",
          uptime: 86400,
          pid: 1234,
          cpu: 0.15,
          cpus: vm.cores || 2,
          maxcpu: vm.cores || 2,
          mem: 2147483648,
          maxmem: vm.memory || 4294967296,
          disk: 0,
          maxdisk: 21474836480,
          netin: 1024000,
          netout: 512000,
          diskread: 10485760,
          diskwrite: 5242880,
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
          {:ok, vm} ->
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
        container_info = Map.merge(container, %{
          status: "running",
          uptime: 86400,
          cpu: 0.08,
          cpus: container.cores || 2,
          maxcpu: container.cores || 2,
          mem: 1073741824,
          maxmem: container.memory || 2147483648,
          disk: 0,
          maxdisk: 10737418240,
          netin: 512000,
          netout: 256000,
          diskread: 5242880,
          diskwrite: 2621440,
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
        {:ok, upid} = State.create_task(node_name, "qmsnapshot", %{vmid: vmid, snapname: snapname})

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
    node_name = conn.path_params["node"]
    upid = conn.path_params["upid"]

    case State.get_task(upid) do
      nil ->
        send_not_found(conn, "Task", upid)

      task ->
        # Add realistic progress simulation
        now = :os.system_time(:second)
        elapsed = now - task.starttime
        
        # Simulate task progress
        progress = min(100, div(elapsed * 100, 60))  # Complete in ~60 seconds
        
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
    node_name = conn.path_params["node"]
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
    node_name = conn.path_params["node"]

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
    node_name = conn.path_params["node"]
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
        base_logs ++ [
          %{n: 3, t: "#{task.starttime + 2}: starting VM #{task.vmid}"},
          %{n: 4, t: "#{task.starttime + 5}: VM #{task.vmid} started successfully"}
        ]

      "qmstop" ->
        base_logs ++ [
          %{n: 3, t: "#{task.starttime + 2}: stopping VM #{task.vmid}"},
          %{n: 4, t: "#{task.starttime + 5}: VM #{task.vmid} stopped successfully"}
        ]

      "qmigrate" ->
        target = Map.get(task, :target, "unknown")
        base_logs ++ [
          %{n: 3, t: "#{task.starttime + 2}: starting migration of VM #{task.vmid} to #{target}"},
          %{n: 4, t: "#{task.starttime + 10}: copying VM state..."},
          %{n: 5, t: "#{task.starttime + 20}: migration completed successfully"}
        ]

      "qmclone" ->
        newid = Map.get(task, :newid, "unknown")
        base_logs ++ [
          %{n: 3, t: "#{task.starttime + 2}: starting clone of VM #{task.vmid} to #{newid}"},
          %{n: 4, t: "#{task.starttime + 5}: creating VM configuration..."},
          %{n: 5, t: "#{task.starttime + 10}: copying disk images..."},
          %{n: 6, t: "#{task.starttime + 25}: clone completed successfully"}
        ]

      "pctclone" ->
        newid = Map.get(task, :newid, "unknown")
        base_logs ++ [
          %{n: 3, t: "#{task.starttime + 2}: starting clone of Container #{task.vmid} to #{newid}"},
          %{n: 4, t: "#{task.starttime + 5}: creating container configuration..."},
          %{n: 5, t: "#{task.starttime + 10}: copying container data..."},
          %{n: 6, t: "#{task.starttime + 20}: clone completed successfully"}
        ]

      "vzdump" ->
        base_logs ++ [
          %{n: 3, t: "#{task.starttime + 2}: starting backup of VM #{task.vmid}"},
          %{n: 4, t: "#{task.starttime + 10}: creating snapshot..."},
          %{n: 5, t: "#{task.starttime + 20}: backing up VM config..."},
          %{n: 6, t: "#{task.starttime + 30}: backup completed successfully"}
        ]

      _ ->
        base_logs ++ [
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
end
