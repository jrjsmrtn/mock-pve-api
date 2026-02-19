# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Backup do
  @moduledoc """
  PVE API coverage: Backup and restore endpoints.

  Covers `/cluster/backup*`, `/nodes/{node}/vzdump`,
  and `/nodes/{node}/qmrestore` / `/nodes/{node}/vzrestore`
  in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :backup

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/nodes/{node}/vzdump" => %{
        path: "/api2/json/nodes/{node}/vzdump",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Create backup (vzdump)",
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
            type: :string,
            required: false,
            description: "VM IDs to backup",
            values: nil,
            default: nil
          },
          %{
            name: "storage",
            type: :string,
            required: false,
            description: "Target storage",
            values: nil,
            default: nil
          },
          %{
            name: "mode",
            type: :string,
            required: false,
            description: "Backup mode",
            values: ["snapshot", "suspend", "stop"],
            default: "snapshot"
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router"
      },
      "/api2/json/cluster/backup" => %{
        path: "/api2/json/cluster/backup",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "List/create backup jobs",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/cluster/backup/{id}" => %{
        path: "/api2/json/cluster/backup/{id}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual backup job CRUD",
        parameters: [
          %{
            name: "id",
            type: :string,
            required: true,
            description: "Backup job ID",
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
      "/api2/json/cluster/backup/{id}/included_volumes" => %{
        path: "/api2/json/cluster/backup/{id}/included_volumes",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "List volumes included in backup job",
        parameters: [
          %{
            name: "id",
            type: :string,
            required: true,
            description: "Backup job ID",
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
      "/api2/json/cluster/backup-info/not-backed-up" => %{
        path: "/api2/json/cluster/backup-info/not-backed-up",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "List VMs/CTs not covered by any backup job",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: nil
      },
      "/api2/json/nodes/{node}/vzdump/defaults" => %{
        path: "/api2/json/nodes/{node}/vzdump/defaults",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Get vzdump default options",
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
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/vzdump/extractconfig" => %{
        path: "/api2/json/nodes/{node}/vzdump/extractconfig",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "6.0",
        description: "Extract configuration from backup archive",
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
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/qmrestore" => %{
        path: "/api2/json/nodes/{node}/qmrestore",
        methods: [:post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Restore VM from backup",
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
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/vzrestore" => %{
        path: "/api2/json/nodes/{node}/vzrestore",
        methods: [:post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Restore container from backup",
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
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{}
  end
end
