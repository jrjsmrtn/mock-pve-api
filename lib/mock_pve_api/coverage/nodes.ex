# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Nodes do
  @moduledoc """
  PVE API coverage: Node management endpoints.

  Covers `/nodes` and `/nodes/{node}/*` (node-level only) in the PVE API Viewer.
  Excludes per-node qemu, lxc, storage, and firewall sub-resources which have
  their own sub-modules.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :nodes

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/nodes" => %{
        path: "/api2/json/nodes",
        methods: [:get],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "List all cluster nodes with status",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}" => %{
        path: "/api2/json/nodes/{node}",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Node index — lists available sub-resources",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/status" => %{
        path: "/api2/json/nodes/{node}/status",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Node status and control operations",
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
            name: "command",
            type: :string,
            required: false,
            description: "Control command",
            values: ["reboot", "shutdown"],
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/version" => %{
        path: "/api2/json/nodes/{node}/version",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Node-specific version information",
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
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/time" => %{
        path: "/api2/json/nodes/{node}/time",
        methods: [:get, :put],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Node time configuration",
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
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: "Elixir.MockPveApi.Handlers.Nodes",
        notes: "Node time configuration and timezone management"
      },
      "/api2/json/nodes/{node}/tasks" => %{
        path: "/api2/json/nodes/{node}/tasks",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "List tasks on node",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/tasks/{upid}/status" => %{
        path: "/api2/json/nodes/{node}/tasks/{upid}/status",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Get task status by UPID",
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
            name: "upid",
            type: :string,
            required: true,
            description: "Task UPID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/tasks/{upid}/log" => %{
        path: "/api2/json/nodes/{node}/tasks/{upid}/log",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Get task log by UPID",
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
            name: "upid",
            type: :string,
            required: true,
            description: "Task UPID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/syslog" => %{
        path: "/api2/json/nodes/{node}/syslog",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Read system log (syslog)",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/network" => %{
        path: "/api2/json/nodes/{node}/network",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "List available network interfaces",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/execute" => %{
        path: "/api2/json/nodes/{node}/execute",
        methods: [:post],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Execute a command on a node (API call, not shell)",
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
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{
      "/api2/json/nodes/{node}/apt/update" =>
        planned(:get_post, :medium, "6.0", "APT package update management"),
      "/api2/json/nodes/{node}/apt/versions" =>
        planned(:get, :low, "6.0", "Get package version information"),
      "/api2/json/nodes/{node}/certificates/info" =>
        planned(:get, :low, "6.0", "Get node TLS certificate info"),
      "/api2/json/nodes/{node}/certificates/acme/certificate" =>
        planned(:post_put_delete, :low, "6.0", "ACME certificate management"),
      "/api2/json/nodes/{node}/disks/list" => planned(:get, :medium, "6.0", "List local disks"),
      "/api2/json/nodes/{node}/disks/smart" =>
        planned(:get, :low, "6.0", "Get SMART health data for disks"),
      "/api2/json/nodes/{node}/disks/initgpt" =>
        planned(:post, :low, "6.0", "Initialize disk with GPT"),
      "/api2/json/nodes/{node}/dns" =>
        planned(:get_put, :medium, "6.0", "Node DNS configuration"),
      "/api2/json/nodes/{node}/hosts" =>
        planned(:get_post, :low, "6.0", "Node /etc/hosts management"),
      "/api2/json/nodes/{node}/subscription" =>
        planned(:get_post, :low, "6.0", "Node subscription information"),
      "/api2/json/nodes/{node}/network/{iface}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual network interface management"),
      "/api2/json/nodes/{node}/tasks/{upid}" =>
        planned(:delete, :medium, "6.0", "Stop a running task"),
      "/api2/json/nodes/{node}/config" =>
        planned(:get_put, :low, "6.0", "Node configuration options"),
      "/api2/json/nodes/{node}/startall" =>
        planned(:post, :low, "6.0", "Start all VMs and containers on node"),
      "/api2/json/nodes/{node}/stopall" =>
        planned(:post, :low, "6.0", "Stop all VMs and containers on node"),
      "/api2/json/nodes/{node}/migrateall" =>
        planned(:post, :low, "6.0", "Migrate all VMs and containers to another node"),
      "/api2/json/nodes/{node}/journal" => planned(:get, :low, "7.0", "Read systemd journal")
    }
  end

  defp planned(methods_atom, priority, since, description) do
    %{
      path: "",
      methods: methods_for(methods_atom),
      status: :planned,
      priority: priority,
      since: since,
      description: description,
      parameters: [],
      response_schema: %{data: :object},
      capabilities_required: [],
      test_coverage: false,
      handler_module: nil,
      notes: nil
    }
  end

  defp methods_for(:get), do: [:get]
  defp methods_for(:post), do: [:post]
  defp methods_for(:delete), do: [:delete]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
  defp methods_for(:post_put_delete), do: [:post, :put, :delete]
end
