# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Monitoring do
  @moduledoc """
  PVE API coverage: Metrics, monitoring, and statistics endpoints.

  Covers `/nodes/{node}/rrd*`, `/nodes/{node}/netstat`, `/nodes/{node}/report`,
  `/nodes/{node}/qemu/{vmid}/rrd*`, `/nodes/{node}/lxc/{vmid}/rrd*`,
  and `/cluster/metrics/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :monitoring

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/nodes/{node}/rrd" => %{
        path: "/api2/json/nodes/{node}/rrd",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read node RRD statistics (returns PNG graph)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          },
          %{
            name: "timeframe",
            type: :string,
            required: false,
            description: "Time frame",
            values: ["hour", "day", "week", "month", "year"],
            default: "hour"
          },
          %{
            name: "ds",
            type: :string,
            required: false,
            description: "Data source",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/rrddata" => %{
        path: "/api2/json/nodes/{node}/rrddata",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read node RRD statistics (returns JSON data)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          },
          %{
            name: "timeframe",
            type: :string,
            required: false,
            description: "Time frame",
            values: ["hour", "day", "week", "month", "year"],
            default: "hour"
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/rrd" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/rrd",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read VM RRD statistics (returns PNG graph)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          },
          %{
            name: "vmid",
            type: :integer,
            required: true,
            description: "VM ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:basic_virtualization],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/rrd" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/rrd",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read container RRD statistics (returns PNG graph)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          },
          %{
            name: "vmid",
            type: :integer,
            required: true,
            description: "Container ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:containers],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/netstat" => %{
        path: "/api2/json/nodes/{node}/netstat",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Read node network statistics",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/report" => %{
        path: "/api2/json/nodes/{node}/report",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Get node status report (text format)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/rrddata" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/rrddata",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read VM RRD statistics (JSON data)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          },
          %{
            name: "vmid",
            type: :integer,
            required: true,
            description: "VM ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/rrddata" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/rrddata",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read container RRD statistics (JSON data)",
        parameters: [
          %{
            name: "node",
            type: :string,
            required: true,
            description: "Node name",
            values: nil,
            default: nil
          },
          %{
            name: "vmid",
            type: :integer,
            required: true,
            description: "Container ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage/{storage}/rrd" =>
        implemented(:get, :low, "6.0", "Storage RRD statistics (graph)"),
      "/api2/json/nodes/{node}/storage/{storage}/rrddata" =>
        implemented(:get, :low, "6.0", "Storage RRD statistics (data)"),
      "/api2/json/cluster/metrics" => implemented(:get, :low, "7.0", "Cluster metrics index"),
      "/api2/json/cluster/metrics/server" =>
        implemented(:get, :low, "7.0", "List configured external metric servers"),
      "/api2/json/nodes/{node}/services" =>
        implemented(:get, :low, "6.0", "List system services on node"),
      "/api2/json/nodes/{node}/services/{service}" =>
        implemented(:get, :low, "6.0", "Get service status"),
      "/api2/json/nodes/{node}/services/{service}/state" =>
        implemented(:get, :low, "6.0", "Control service (start/stop/restart)"),
      "/api2/json/cluster/metrics/server/{id}" => %{
        path: "/api2/json/cluster/metrics/server/{id}",
        methods: [:get, :post, :put, :delete],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Get external metric server configuration",
        parameters: [
          %{
            name: "id",
            type: :string,
            required: true,
            description: "Metric server ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Metrics,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{}
  end

  defp implemented(methods_atom, priority, since, description) do
    %{
      path: "",
      methods: methods_for(methods_atom),
      status: :implemented,
      priority: priority,
      since: since,
      description: description,
      parameters: [],
      response_schema: %{data: :object},
      capabilities_required: [],
      test_coverage: true,
      handler_module: MockPveApi.Handlers.Metrics,
      notes: nil
    }
  end

  defp methods_for(:get), do: [:get]
  defp methods_for(:put), do: [:put]
  defp methods_for(:get_post_put_delete), do: [:get, :post, :put, :delete]
end
