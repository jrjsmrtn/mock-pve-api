defmodule MockPveApi.Handlers.Metrics do
  @moduledoc """
  Handler for PVE metrics and statistics endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  GET /api2/json/nodes/:node/rrd
  Gets node RRD data for graphs.
  """
  def get_node_rrd(conn) do
    node_name = conn.path_params["node"]
    query_params = conn.query_params

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        # Generate sample RRD data
        timeframe = Map.get(query_params, "timeframe", "hour")
        cf = Map.get(query_params, "cf", "AVERAGE")

        data = generate_rrd_data(timeframe, cf)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: data}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/rrddata
  Gets node RRD data in structured format.
  """
  def get_node_rrd_data(conn) do
    node_name = conn.path_params["node"]
    query_params = conn.query_params

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      node ->
        # Generate sample RRD data points
        timeframe = Map.get(query_params, "timeframe", "hour")
        points = generate_rrd_data_points(timeframe, node)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: points}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/qemu/:vmid/rrd
  Gets VM RRD data for graphs.
  """
  def get_vm_rrd(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    query_params = conn.query_params

    case State.get_vm(node_name, vmid) do
      nil ->
        send_not_found(conn, "VM", vmid)

      vm ->
        timeframe = Map.get(query_params, "timeframe", "hour")
        cf = Map.get(query_params, "cf", "AVERAGE")

        data = generate_vm_rrd_data(vm, timeframe, cf)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: data}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/lxc/:vmid/rrd
  Gets container RRD data for graphs.
  """
  def get_container_rrd(conn) do
    node_name = conn.path_params["node"]
    vmid = String.to_integer(conn.path_params["vmid"])
    query_params = conn.query_params

    case State.get_container(node_name, vmid) do
      nil ->
        send_not_found(conn, "Container", vmid)

      container ->
        timeframe = Map.get(query_params, "timeframe", "hour")
        cf = Map.get(query_params, "cf", "AVERAGE")

        data = generate_container_rrd_data(container, timeframe, cf)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: data}))
    end
  end

  @doc """
  GET /api2/json/cluster/metrics/server/:id
  Gets cluster-wide metrics for a specific server.
  """
  def get_cluster_metrics(conn) do
    _server_id = conn.path_params["id"]

    # Generate cluster-wide metrics
    metrics = %{
      cpu: %{
        avg: 0.15,
        max: 0.45,
        nodes: 2
      },
      memory: %{
        # 12GB
        used: 12_884_901_888,
        # 24GB
        total: 25_769_803_776,
        free: 12_884_901_888,
        usage_percent: 50.0
      },
      storage: %{
        # 75GB
        used: 75_000_000_000,
        # 150GB
        total: 150_000_000_000,
        free: 75_000_000_000,
        usage_percent: 50.0
      },
      network: %{
        # 1MB/s
        in: 1_048_576,
        # 512KB/s
        out: 524_288
      },
      nodes_online: 2,
      nodes_total: 2,
      vms_running: 0,
      vms_total: 0,
      containers_running: 0,
      containers_total: 0
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: metrics}))
  end

  @doc """
  GET /api2/json/nodes/:node/netstat
  Gets node network statistics.
  """
  def get_node_netstat(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      _node ->
        # Generate network interface statistics
        interfaces = [
          %{
            name: "eth0",
            bytes_in: :rand.uniform(1_000_000_000),
            bytes_out: :rand.uniform(1_000_000_000),
            packets_in: :rand.uniform(1_000_000),
            packets_out: :rand.uniform(1_000_000),
            errors_in: 0,
            errors_out: 0,
            # Mbps
            speed: 1000
          },
          %{
            name: "vmbr0",
            bytes_in: :rand.uniform(2_000_000_000),
            bytes_out: :rand.uniform(2_000_000_000),
            packets_in: :rand.uniform(2_000_000),
            packets_out: :rand.uniform(2_000_000),
            errors_in: 0,
            errors_out: 0,
            speed: 1000
          }
        ]

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: interfaces}))
    end
  end

  @doc """
  GET /api2/json/nodes/:node/report
  Gets node system report.
  """
  def get_node_report(conn) do
    node_name = conn.path_params["node"]

    case State.get_node(node_name) do
      nil ->
        send_not_found(conn, "Node", node_name)

      node ->
        report = """
        Node Report for #{node_name}
        =============================

        System Information:
        - Kernel: #{node.kernel}
        - PVE Version: #{node.version}
        - Uptime: #{div(node.uptime, 86400)} days
        - CPU: #{node.maxcpu} cores, #{Float.round(node.cpu * 100, 2)}% usage
        - Memory: #{div(node.mem, 1024 * 1024 * 1024)}GB / #{div(node.maxmem, 1024 * 1024 * 1024)}GB
        - Storage: #{div(node.disk, 1024 * 1024 * 1024)}GB / #{div(node.maxdisk, 1024 * 1024 * 1024)}GB

        Virtual Machines:
        #{get_vm_summary(node_name)}

        Containers:
        #{get_container_summary(node_name)}

        Generated at: #{DateTime.utc_now()}
        """

        conn
        |> put_resp_content_type("text/plain")
        |> send_resp(200, report)
    end
  end

  # Helper functions

  defp generate_rrd_data(timeframe, cf) do
    # Generate mock RRD data structure
    %{
      filename: "/var/lib/rrdcached/db/pve2-node/#{timeframe}.rrd",
      cf: cf,
      resolution: get_resolution(timeframe),
      data: generate_time_series_data(timeframe)
    }
  end

  defp generate_rrd_data_points(timeframe, node) do
    # Generate time series data points
    now = :os.system_time(:second)
    interval = get_interval(timeframe)
    points = get_point_count(timeframe)

    for i <- 0..(points - 1) do
      timestamp = now - i * interval

      %{
        time: timestamp,
        cpu: Float.round(:rand.normal(node.cpu, 0.1), 3),
        memory: round(:rand.normal(node.mem, node.mem * 0.1)),
        disk_read: :rand.uniform(10_000_000),
        disk_write: :rand.uniform(5_000_000),
        network_in: :rand.uniform(1_000_000),
        network_out: :rand.uniform(800_000)
      }
    end
    |> Enum.reverse()
  end

  defp generate_vm_rrd_data(vm, timeframe, cf) do
    %{
      filename: "/var/lib/rrdcached/db/pve2-vm/#{vm.vmid}.rrd",
      cf: cf,
      resolution: get_resolution(timeframe),
      data: generate_vm_time_series(vm, timeframe)
    }
  end

  defp generate_container_rrd_data(container, timeframe, cf) do
    %{
      filename: "/var/lib/rrdcached/db/pve2-vm/#{container.vmid}.rrd",
      cf: cf,
      resolution: get_resolution(timeframe),
      data: generate_container_time_series(container, timeframe)
    }
  end

  defp generate_time_series_data(timeframe) do
    point_count = get_point_count(timeframe)

    for _i <- 1..point_count do
      %{
        cpu: Float.round(:rand.uniform() * 0.8, 3),
        memory: :rand.uniform(8_000_000_000),
        disk_read: :rand.uniform(50_000_000),
        disk_write: :rand.uniform(25_000_000),
        network_in: :rand.uniform(5_000_000),
        network_out: :rand.uniform(3_000_000)
      }
    end
  end

  defp generate_vm_time_series(vm, timeframe) do
    point_count = get_point_count(timeframe)

    for _i <- 1..point_count do
      %{
        cpu: Float.round(:rand.uniform() * 0.6, 3),
        memory: round(:rand.uniform() * vm.memory * 1024 * 1024),
        disk_read: :rand.uniform(10_000_000),
        disk_write: :rand.uniform(5_000_000),
        network_in: :rand.uniform(1_000_000),
        network_out: :rand.uniform(800_000)
      }
    end
  end

  defp generate_container_time_series(container, timeframe) do
    point_count = get_point_count(timeframe)

    for _i <- 1..point_count do
      %{
        cpu: Float.round(:rand.uniform() * 0.4, 3),
        memory: round(:rand.uniform() * container.memory * 1024 * 1024),
        disk_read: :rand.uniform(5_000_000),
        disk_write: :rand.uniform(2_000_000),
        network_in: :rand.uniform(500_000),
        network_out: :rand.uniform(400_000)
      }
    end
  end

  # 1 minute
  defp get_resolution("hour"), do: 60
  # 5 minutes  
  defp get_resolution("day"), do: 300
  # 30 minutes
  defp get_resolution("week"), do: 1800
  # 2 hours
  defp get_resolution("month"), do: 7200
  # 1 day
  defp get_resolution("year"), do: 86400
  defp get_resolution(_), do: 60

  # 1 minute
  defp get_interval("hour"), do: 60
  # 5 minutes
  defp get_interval("day"), do: 300
  # 30 minutes
  defp get_interval("week"), do: 1800
  # 2 hours
  defp get_interval("month"), do: 7200
  # 1 day
  defp get_interval("year"), do: 86400
  defp get_interval(_), do: 60

  # 60 points
  defp get_point_count("hour"), do: 60
  # 288 points (24h / 5min)
  defp get_point_count("day"), do: 288
  # 336 points (7d / 30min)
  defp get_point_count("week"), do: 336
  # 360 points (30d / 2h)
  defp get_point_count("month"), do: 360
  # 365 points (365d / 1d)
  defp get_point_count("year"), do: 365
  defp get_point_count(_), do: 60

  defp get_vm_summary(node_name) do
    vms = State.get_vms(node_name)

    case vms do
      [] ->
        "- No VMs configured"

      vms ->
        vms
        |> Enum.map(fn vm ->
          "- VM #{vm.vmid} (#{vm.name}): #{vm.status}, #{vm.memory}MB RAM, #{vm.cores} cores"
        end)
        |> Enum.join("\n")
    end
  end

  defp get_container_summary(node_name) do
    containers = State.get_containers(node_name)

    case containers do
      [] ->
        "- No containers configured"

      containers ->
        containers
        |> Enum.map(fn ct ->
          "- CT #{ct.vmid} (#{ct.hostname}): #{ct.status}, #{ct.memory}MB RAM, #{ct.cores} cores"
        end)
        |> Enum.join("\n")
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
end
