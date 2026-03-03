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
        methods: [:get, :post, :put, :delete],
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
      },
      "/api2/json/nodes/{node}/dns" => %{
        path: "/api2/json/nodes/{node}/dns",
        methods: [:get, :put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Node DNS configuration",
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
      "/api2/json/nodes/{node}/apt/update" => %{
        path: "/api2/json/nodes/{node}/apt/update",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "APT package update management",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/apt/versions" => %{
        path: "/api2/json/nodes/{node}/apt/versions",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Get package version information",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/network/{iface}" => %{
        path: "/api2/json/nodes/{node}/network/{iface}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual network interface management",
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
            name: "iface",
            type: :string,
            required: true,
            description: "Interface name",
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
      "/api2/json/nodes/{node}/disks/list" => %{
        path: "/api2/json/nodes/{node}/disks/list",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "List local disks",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/tasks/{upid}" => %{
        path: "/api2/json/nodes/{node}/tasks/{upid}",
        methods: [:get, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Stop a running task",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/config" => %{
        path: "/api2/json/nodes/{node}/config",
        methods: [:get, :put],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Node configuration options",
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
      "/api2/json/nodes/{node}/hosts" =>
        implemented(:get_post, :low, "6.0", "Node /etc/hosts management"),
      "/api2/json/nodes/{node}/subscription" =>
        implemented(:get_post_put_delete, :low, "6.0", "Node subscription information"),
      "/api2/json/nodes/{node}/startall" =>
        implemented(:post, :low, "6.0", "Start all VMs and containers on node"),
      "/api2/json/nodes/{node}/stopall" =>
        implemented(:post, :low, "6.0", "Stop all VMs and containers on node"),
      "/api2/json/nodes/{node}/migrateall" =>
        implemented(:post, :low, "6.0", "Migrate all VMs and containers to another node"),
      "/api2/json/nodes/{node}/journal" => implemented(:get, :low, "7.0", "Read systemd journal"),
      "/api2/json/nodes/{node}/certificates/info" =>
        implemented(:get, :low, "6.0", "Get node TLS certificate info"),
      "/api2/json/nodes/{node}/disks/smart" =>
        implemented(:get, :low, "6.0", "Get SMART health data for disks"),
      "/api2/json/nodes/{node}/certificates/acme/certificate" =>
        implemented(:post_put_delete, :low, "6.0", "ACME certificate management"),
      "/api2/json/nodes/{node}/disks/initgpt" =>
        implemented(:post, :low, "6.0", "Initialize disk with GPT"),
      "/api2/json/nodes/{node}/disks/lvm" =>
        implemented(:get_post, :low, "6.0", "LVM management on node"),
      "/api2/json/nodes/{node}/disks/lvmthin" =>
        implemented(:get_post, :low, "6.0", "LVM thin pool management on node"),
      "/api2/json/nodes/{node}/disks/zfs" =>
        implemented(:get_post, :low, "6.0", "ZFS pool management on node"),
      "/api2/json/nodes/{node}/ceph/status" =>
        implemented(:get, :low, "7.0", "Ceph status on node"),
      "/api2/json/nodes/{node}/ceph/osd" =>
        implemented(:get_post, :low, "7.0", "Ceph OSD management"),
      "/api2/json/nodes/{node}/ceph/pools" =>
        implemented(:get_post, :low, "7.0", "Ceph pool management"),
      "/api2/json/nodes/{node}/scan" =>
        implemented(:get, :low, "6.0", "List available scan types"),
      "/api2/json/nodes/{node}/scan/{type}" =>
        implemented(:get, :low, "6.0", "Scan for resources of a specific type"),
      "/api2/json/nodes/{node}/replication" =>
        implemented(:get, :low, "5.0", "List replication jobs for node"),
      "/api2/json/nodes/{node}/replication/{id}" =>
        implemented(:get, :low, "5.0", "Get replication job status on node"),
      "/api2/json/nodes/{node}/replication/{id}/log" =>
        implemented(:get, :low, "5.0", "Get replication job log on node"),
      "/api2/json/nodes/{node}/replication/{id}/schedule_now" =>
        implemented(:post, :low, "5.0", "Schedule replication job immediately"),
      "/api2/json/nodes/{node}/replication/{id}/status" =>
        implemented(:get, :low, "5.0", "Get replication job detailed status on node"),
      "/api2/json/nodes/{node}/services/{service}/reload" =>
        implemented(:post, :low, "6.0", "Reload a system service"),
      "/api2/json/nodes/{node}/services/{service}/restart" =>
        implemented(:post, :low, "6.0", "Restart a system service"),
      "/api2/json/nodes/{node}/services/{service}/start" =>
        implemented(:post, :low, "6.0", "Start a system service"),
      "/api2/json/nodes/{node}/services/{service}/stop" =>
        implemented(:post, :low, "6.0", "Stop a system service")
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
      capabilities_required: [:cluster_basic],
      test_coverage: true,
      handler_module: MockPveApi.Handlers.Nodes,
      notes: nil
    }
  end

  defp methods_for(:get), do: [:get]
  defp methods_for(:post), do: [:post]
  defp methods_for(:delete), do: [:delete]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
  defp methods_for(:get_post_put_delete), do: [:get, :post, :put, :delete]
  defp methods_for(:post_put_delete), do: [:post, :put, :delete]
end
