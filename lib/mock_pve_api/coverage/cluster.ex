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
        methods: [:get, :post],
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
        methods: [:get, :post],
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
        methods: [:post, :delete],
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
      },
      "/api2/json/cluster/replication/{id}" =>
        implemented(:get_put_delete, :medium, "6.0", "Individual replication job operations"),
      "/api2/json/cluster/acme/account" =>
        implemented(:get_post, :low, "6.0", "ACME account management"),
      "/api2/json/cluster/acme/plugins" =>
        implemented(:get_post, :low, "6.0", "ACME plugin management"),
      "/api2/json/cluster/ceph/metadata" =>
        implemented(:get, :low, "7.0", "Ceph cluster metadata"),
      "/api2/json/cluster/ceph/status" => implemented(:get, :low, "7.0", "Ceph cluster status"),
      "/api2/json/cluster/ceph/flags" => implemented(:get_put, :low, "7.0", "Ceph global flags"),
      "/api2/json/cluster" => implemented(:get, :low, "7.0", "Top-level cluster index"),
      "/api2/json/cluster/acme" => implemented(:get, :low, "7.0", "ACME module index"),
      "/api2/json/cluster/ceph" => implemented(:get, :low, "7.0", "Ceph module index"),
      "/api2/json/cluster/firewall" => implemented(:get, :low, "7.0", "Cluster firewall index"),
      "/api2/json/cluster/ha" => implemented(:get, :low, "7.0", "HA module index"),
      "/api2/json/cluster/ha/status" => implemented(:get, :low, "7.0", "HA status index"),
      "/api2/json/cluster/jobs" => implemented(:get, :low, "7.1", "Scheduled jobs index"),
      "/api2/json/cluster/log" => implemented(:get, :low, "7.0", "Recent cluster log entries"),
      "/api2/json/cluster/mapping" => implemented(:get, :low, "7.0", "Hardware mapping index"),
      "/api2/json/cluster/backup-info" => implemented(:get, :low, "7.0", "Backup info index"),
      "/api2/json/cluster/bulk-action" => implemented(:get, :low, "9.0", "Bulk action index"),
      "/api2/json/cluster/acme/account/{name}" => %{
        path: "/api2/json/cluster/acme/account/{name}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Get, update, or delete a specific ACME account",
        parameters: [
          %{
            name: "name",
            type: :string,
            required: true,
            description: "Account name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/acme/plugins/{id}" => %{
        path: "/api2/json/cluster/acme/plugins/{id}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Get, update, or delete a specific ACME plugin",
        parameters: [
          %{
            name: "id",
            type: :string,
            required: true,
            description: "Plugin ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        example_response: nil,
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/acme/challenge-schema" =>
        implemented(:get, :low, "7.0", "ACME challenge schema types"),
      "/api2/json/cluster/acme/directories" =>
        implemented(:get, :low, "7.0", "Known ACME directory endpoints"),
      "/api2/json/cluster/acme/tos" =>
        implemented(:get, :low, "7.0", "ACME terms of service URL"),
      "/api2/json/cluster/acme/meta" => implemented(:get, :low, "8.1", "ACME directory metadata"),
      "/api2/json/cluster/jobs/schedule-analyze" =>
        implemented(:get, :low, "7.1", "Analyze scheduled job timing"),
      "/api2/json/cluster/jobs/realm-sync" =>
        implemented(:get, :low, "7.1", "List realm sync jobs"),
      "/api2/json/cluster/jobs/realm-sync/{id}" =>
        implemented(:get_post_put_delete, :low, "7.1", "Realm sync job CRUD"),
      "/api2/json/cluster/tasks" => implemented(:get, :medium, "4.0", "List cluster-wide tasks"),
      "/api2/json/cluster/ha/manager_status" =>
        implemented(:get, :medium, "4.0", "HA manager status"),
      "/api2/json/cluster/ha/resources/{sid}/migrate" =>
        implemented(:post, :medium, "4.0", "Migrate HA resource to different node"),
      "/api2/json/cluster/ha/resources/{sid}/relocate" =>
        implemented(:post, :medium, "4.0", "Relocate HA resource to different node"),
      "/api2/json/cluster/metrics/export" =>
        implemented(:get, :low, "7.0", "Export cluster metrics"),
      "/api2/json/cluster/sdn/vnets/{vnet}/ips" =>
        implemented(:post_put_delete, :low, "8.0", "Create, update and delete vnet IPs"),
      "/api2/json/cluster/bulk-action/guest" =>
        implemented(:get, :low, "9.0", "Bulk action guest overview"),
      "/api2/json/cluster/bulk-action/guest/start" =>
        implemented(:post, :low, "9.0", "Bulk start guests"),
      "/api2/json/cluster/bulk-action/guest/shutdown" =>
        implemented(:post, :low, "9.0", "Bulk shutdown guests"),
      "/api2/json/cluster/bulk-action/guest/suspend" =>
        implemented(:post, :low, "9.0", "Bulk suspend guests"),
      "/api2/json/cluster/bulk-action/guest/migrate" =>
        implemented(:post, :low, "9.0", "Bulk migrate guests")
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
      handler_module: MockPveApi.Handlers.Cluster,
      notes: nil
    }
  end

  # Helpers for concise planned endpoint definitions

  defp methods_for(:get), do: [:get]
  defp methods_for(:post), do: [:post]
  defp methods_for(:delete), do: [:delete]
  defp methods_for(:post_put_delete), do: [:post, :put, :delete]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
  defp methods_for(:get_post_put_delete), do: [:get, :post, :put, :delete]
end
