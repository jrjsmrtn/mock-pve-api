# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Cluster do
  @moduledoc """
  PVE API coverage: Cluster management endpoints.

  Covers `/cluster/*` in the PVE API Viewer, excluding:
  - SDN (`/cluster/sdn/*`) — see `MockPveApi.Coverage.Sdn`
  - Firewall (`/cluster/firewall/*`) — see `MockPveApi.Coverage.Firewall`
  - Backup jobs (`/cluster/backup/*`) — see `MockPveApi.Coverage.Backup`
  - Metrics (`/cluster/metrics/*`) — see `MockPveApi.Coverage.Monitoring`
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :cluster

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/cluster/status" => %{
        path: "/api2/json/cluster/status",
        methods: [:get],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Get cluster status and node information",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/resources" => %{
        path: "/api2/json/cluster/resources",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Get cluster resource overview (VMs, containers, storage)",
        parameters: [
          %{
            name: "type",
            type: :string,
            required: false,
            description: "Filter by resource type",
            values: ["vm", "storage", "node", "sdn"],
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/nextid" => %{
        path: "/api2/json/cluster/nextid",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Get next free VMID",
        parameters: [],
        response_schema: %{data: :integer},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/config" => %{
        path: "/api2/json/cluster/config",
        methods: [:get, :put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Cluster configuration management",
        parameters: [],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Cluster configuration implemented"
      },
      "/api2/json/cluster/config/join" => %{
        path: "/api2/json/cluster/config/join",
        methods: [:post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Join node to existing cluster",
        parameters: [
          %{
            name: "hostname",
            type: :string,
            required: true,
            description: "Cluster hostname",
            values: nil,
            default: nil
          },
          %{
            name: "nodeid",
            type: :integer,
            required: false,
            description: "Node ID",
            values: nil,
            default: nil
          },
          %{
            name: "votes",
            type: :integer,
            required: false,
            description: "Number of votes",
            values: nil,
            default: 1
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Cluster management operations implemented"
      },
      "/api2/json/cluster/config/nodes" => %{
        path: "/api2/json/cluster/config/nodes",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "List cluster nodes configuration",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Cluster nodes listing implemented"
      },
      "/api2/json/cluster/config/nodes/{node}" => %{
        path: "/api2/json/cluster/config/nodes/{node}",
        methods: [:delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Remove node from cluster",
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
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Node removal from cluster implemented"
      },
      "/api2/json/cluster/backup-info/providers" => %{
        path: "/api2/json/cluster/backup-info/providers",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "8.2",
        description: "List available backup providers",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:backup_providers],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Backup provider plugins introduced in PVE 8.2"
      },
      "/api2/json/cluster/backup-providers" => %{
        path: "/api2/json/cluster/backup-providers",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "8.2",
        description: "List backup providers (alternate path)",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:backup_providers],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router; alternate path for backup provider listing"
      },
      "/api2/json/cluster/ha/affinity" => %{
        path: "/api2/json/cluster/ha/affinity",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "9.0",
        description: "HA resource affinity rules management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:ha_resource_affinity],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "HA affinity rules new in PVE 9.0"
      },
      "/api2/json/cluster/notifications/endpoints" => %{
        path: "/api2/json/cluster/notifications/endpoints",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.1",
        description: "List notification endpoints",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router; notification system introduced in PVE 8.1"
      },
      "/api2/json/cluster/notifications/filters" => %{
        path: "/api2/json/cluster/notifications/filters",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.1",
        description: "List notification filters",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router; notification system introduced in PVE 8.1"
      },
      "/api2/json/cluster/ha/resources" => %{
        path: "/api2/json/cluster/ha/resources",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "HA resource management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/ha/resources/{sid}" => %{
        path: "/api2/json/cluster/ha/resources/{sid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Individual HA resource operations",
        parameters: [
          %{
            name: "sid",
            type: :string,
            required: true,
            description: "HA resource SID (e.g. vm:100)",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/ha/status/current" => %{
        path: "/api2/json/cluster/ha/status/current",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Current HA manager and resource status",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/ha/groups" => %{
        path: "/api2/json/cluster/ha/groups",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "HA group management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/ha/groups/{group}" => %{
        path: "/api2/json/cluster/ha/groups/{group}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual HA group operations",
        parameters: [
          %{
            name: "group",
            type: :string,
            required: true,
            description: "HA group name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/ha/affinity/{rule}" => %{
        path: "/api2/json/cluster/ha/affinity/{rule}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "9.0",
        description: "Individual HA affinity rule operations",
        parameters: [
          %{
            name: "rule",
            type: :string,
            required: true,
            description: "Affinity rule ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:ha_resource_affinity],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "HA affinity rules new in PVE 9.0"
      },
      "/api2/json/cluster/options" => %{
        path: "/api2/json/cluster/options",
        methods: [:get, :put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Cluster-wide datacenter options",
        parameters: [],
        response_schema: %{data: :object},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/replication" => %{
        path: "/api2/json/cluster/replication",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Replication job management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{
      # Replication (individual job)
      "/api2/json/cluster/replication/{id}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual replication job operations"),
      # ACME
      "/api2/json/cluster/acme/account" =>
        planned(:get_post, :low, "6.0", "ACME account management"),
      "/api2/json/cluster/acme/plugins" =>
        planned(:get_post, :low, "6.0", "ACME plugin management"),
      # Ceph
      "/api2/json/cluster/ceph/metadata" => planned(:get, :low, "7.0", "Ceph cluster metadata"),
      "/api2/json/cluster/ceph/status" => planned(:get, :low, "7.0", "Ceph cluster status"),
      "/api2/json/cluster/ceph/flags" => planned(:get_put, :low, "7.0", "Ceph global flags"),
      # Notifications (extended)
      "/api2/json/cluster/notifications/matchers" =>
        planned(:get_post, :low, "8.1", "Notification matchers management"),
      "/api2/json/cluster/notifications/matchers/{name}" =>
        planned(:get_put_delete, :low, "8.1", "Individual notification matcher operations"),
      "/api2/json/cluster/notifications/endpoints/sendmail" =>
        planned(:get_post, :low, "8.1", "Sendmail notification endpoints"),
      "/api2/json/cluster/notifications/endpoints/sendmail/{name}" =>
        planned(:get_put_delete, :low, "8.1", "Individual sendmail endpoint operations"),
      "/api2/json/cluster/notifications/endpoints/gotify" =>
        planned(:get_post, :low, "8.1", "Gotify notification endpoints"),
      "/api2/json/cluster/notifications/endpoints/gotify/{name}" =>
        planned(:get_put_delete, :low, "8.1", "Individual gotify endpoint operations"),
      # Mapping (resource mappings for PCI/USB passthrough)
      "/api2/json/cluster/mapping/pci" =>
        planned(:get_post, :low, "8.0", "PCI device resource mappings"),
      "/api2/json/cluster/mapping/pci/{id}" =>
        planned(:get_put_delete, :low, "8.0", "Individual PCI mapping operations"),
      "/api2/json/cluster/mapping/usb" =>
        planned(:get_post, :low, "8.0", "USB device resource mappings"),
      "/api2/json/cluster/mapping/usb/{id}" =>
        planned(:get_put_delete, :low, "8.0", "Individual USB mapping operations")
    }
  end

  # Helpers for concise planned endpoint definitions

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
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
  defp methods_for(:get_post_put_delete), do: [:get, :post, :put, :delete]
end
