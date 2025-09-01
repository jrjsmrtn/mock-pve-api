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
        id -> String.to_integer(id)
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
        id -> String.to_integer(id)
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

  # Helper functions

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
