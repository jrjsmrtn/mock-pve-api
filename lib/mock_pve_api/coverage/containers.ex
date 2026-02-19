# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Containers do
  @moduledoc """
  PVE API coverage: LXC container endpoints.

  Covers `/nodes/{node}/lxc/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :containers

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/nodes/{node}/lxc" => %{
        path: "/api2/json/nodes/{node}/lxc",
        methods: [:get, :post],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "List and create LXC containers on node",
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
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Containers,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Individual LXC container configuration",
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
        test_coverage: true,
        handler_module: "Elixir.MockPveApi.Handlers.Nodes",
        notes: "Complete container configuration and management with comprehensive status info"
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/config" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/config",
        methods: [:get, :put],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Container configuration (get current or update)",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/status/current" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/status/current",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Current container status and statistics",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Containers,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/status/{action}" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/status/{action}",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Container control operations (start, stop, shutdown, etc.)",
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
          },
          %{
            name: "action",
            type: :string,
            required: true,
            description: "Control action",
            values: ["start", "stop", "shutdown", "reboot", "suspend", "resume"],
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:containers],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: "Container lifecycle operations"
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/clone" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/clone",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Clone LXC container",
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
            description: "Source Container ID",
            values: nil,
            default: nil
          },
          %{
            name: "newid",
            type: :integer,
            required: true,
            description: "New Container ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:containers],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: "Container cloning operations implemented"
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/migrate" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/migrate",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Migrate container to another node",
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
        response_schema: %{data: :string},
        capabilities_required: [:containers],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/snapshot" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/snapshot",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "List snapshots / create snapshot",
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
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: "Full snapshot CRUD with state management"
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}",
        methods: [:get, :delete],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Get snapshot info / delete snapshot",
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
          },
          %{
            name: "snapname",
            type: :string,
            required: true,
            description: "Snapshot name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/config" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/config",
        methods: [:get, :put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Get or update snapshot configuration",
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
          },
          %{
            name: "snapname",
            type: :string,
            required: true,
            description: "Snapshot name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/rollback" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/snapshot/{snapname}/rollback",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Rollback container to snapshot",
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
          },
          %{
            name: "snapname",
            type: :string,
            required: true,
            description: "Snapshot name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/pending" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/pending",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Get pending container configuration changes",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/resize" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/resize",
        methods: [:put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Resize container disk",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{
      "/api2/json/nodes/{node}/lxc/{vmid}/feature" =>
        planned(:get, :low, "6.0", "Check container feature availability"),
      "/api2/json/nodes/{node}/lxc/{vmid}/template" =>
        planned(:post, :low, "6.0", "Convert container to template"),
      "/api2/json/nodes/{node}/lxc/{vmid}/move_volume" =>
        planned(:post, :medium, "6.0", "Move container volume to different storage"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall" =>
        planned(:get, :low, "6.0", "Container firewall index")
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
  defp methods_for(:put), do: [:put]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_delete), do: [:get, :delete]
end
