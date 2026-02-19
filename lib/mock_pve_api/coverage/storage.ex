# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Storage do
  @moduledoc """
  PVE API coverage: Storage management endpoints.

  Covers `/storage/*` and `/nodes/{node}/storage/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :storage

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/storage" => %{
        path: "/api2/json/storage",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Storage definition management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage" => %{
        path: "/api2/json/nodes/{node}/storage",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "List storage configured for node",
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
            name: "content",
            type: :string,
            required: false,
            description: "Filter by content type",
            values: ["images", "backup", "vztmpl"],
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage/{storage}/status" => %{
        path: "/api2/json/nodes/{node}/storage/{storage}/status",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Storage status and capacity information",
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
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage/{storage}/content" => %{
        path: "/api2/json/nodes/{node}/storage/{storage}/content",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Storage content management (images, backups, templates)",
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
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: "Content listing implemented, content creation partial"
      },
      "/api2/json/nodes/{node}/storage/{storage}/backup" => %{
        path: "/api2/json/nodes/{node}/storage/{storage}/backup",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "List backup files in storage",
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
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:storage_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage/{storage}/import" => %{
        path: "/api2/json/nodes/{node}/storage/{storage}/import",
        methods: [:post],
        status: :implemented,
        priority: :low,
        since: "8.2",
        description: "Import content into storage (e.g., VMware import)",
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
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router; VMware import introduced in PVE 8.2"
      },
      "/api2/json/storage/{storage}" => %{
        path: "/api2/json/storage/{storage}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual storage definition CRUD",
        parameters: [
          %{
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage/{storage}/content/{volume}" => %{
        path: "/api2/json/nodes/{node}/storage/{storage}/content/{volume}",
        methods: [:get, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual storage volume operations",
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
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          },
          %{
            name: "volume",
            type: :string,
            required: true,
            description: "Volume identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: nil
      },
      "/api2/json/nodes/{node}/storage/{storage}/upload" => %{
        path: "/api2/json/nodes/{node}/storage/{storage}/upload",
        methods: [:post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Upload content to storage",
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
            name: "storage",
            type: :string,
            required: true,
            description: "Storage ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{
      "/api2/json/nodes/{node}/storage/{storage}/prunebackups" =>
        planned(:get_delete, :low, "6.0", "Prune old backups"),
      "/api2/json/nodes/{node}/storage/{storage}/rrd" =>
        planned(:get, :low, "6.0", "Storage RRD statistics"),
      "/api2/json/nodes/{node}/storage/{storage}/rrddata" =>
        planned(:get, :low, "6.0", "Storage RRD data"),
      "/api2/json/nodes/{node}/storage/{storage}/file-restore/list" =>
        planned(:get, :low, "7.0", "List files in a backup for single-file restore"),
      "/api2/json/nodes/{node}/storage/{storage}/file-restore/download" =>
        planned(:get, :low, "7.0", "Download files from a backup"),
      # Ceph (node-level)
      "/api2/json/nodes/{node}/ceph/status" => planned(:get, :low, "7.0", "Ceph status on node"),
      "/api2/json/nodes/{node}/ceph/osd" =>
        planned(:get_post, :low, "7.0", "Ceph OSD management"),
      "/api2/json/nodes/{node}/ceph/pools" =>
        planned(:get_post, :low, "7.0", "Ceph pool management"),
      "/api2/json/nodes/{node}/disks/zfs" =>
        planned(:get_post, :low, "6.0", "ZFS pool management on node"),
      "/api2/json/nodes/{node}/disks/lvm" =>
        planned(:get_post, :low, "6.0", "LVM management on node"),
      "/api2/json/nodes/{node}/disks/lvmthin" =>
        planned(:get_post, :low, "6.0", "LVM thin pool management on node")
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
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_delete), do: [:get, :delete]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
