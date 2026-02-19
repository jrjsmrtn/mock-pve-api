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
      }
    }
  end

  defp planned_endpoints do
    %{
      # Cluster backup job management
      "/api2/json/cluster/backup" => planned(:get_post, :high, "6.0", "List/create backup jobs"),
      "/api2/json/cluster/backup/{id}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual backup job CRUD"),
      "/api2/json/cluster/backup/{id}/included_volumes" =>
        planned(:get, :low, "7.0", "List volumes included in backup job"),
      # Backup providers (PVE 8.2+)
      "/api2/json/cluster/backup-info/not-backed-up" =>
        planned(:get, :medium, "7.0", "List VMs/CTs not covered by any backup job"),
      # Restore endpoints
      "/api2/json/nodes/{node}/qmrestore" =>
        planned(:post, :medium, "6.0", "Restore VM from backup"),
      "/api2/json/nodes/{node}/vzrestore" =>
        planned(:post, :medium, "6.0", "Restore container from backup"),
      # Vzdump defaults and extractconfig
      "/api2/json/nodes/{node}/vzdump/defaults" =>
        planned(:get, :low, "6.0", "Get vzdump default options"),
      "/api2/json/nodes/{node}/vzdump/extractconfig" =>
        planned(:get, :low, "6.0", "Extract configuration from backup archive")
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
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
