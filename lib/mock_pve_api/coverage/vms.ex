# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.VMs do
  @moduledoc """
  PVE API coverage: Virtual machine (QEMU) endpoints.

  Covers `/nodes/{node}/qemu/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :vms

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/nodes/{node}/qemu" => %{
        path: "/api2/json/nodes/{node}/qemu",
        methods: [:get, :post],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "List and create virtual machines on node",
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
            name: "full",
            type: :boolean,
            required: false,
            description: "Full VM information",
            values: nil,
            default: false
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.VMs,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Individual VM configuration and management",
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
        test_coverage: true,
        handler_module: "Elixir.MockPveApi.Handlers.Nodes",
        notes: "Complete VM configuration and management with comprehensive status info"
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/config" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/config",
        methods: [:get, :put],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "VM configuration (get current or update)",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/status/current" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/status/current",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Current VM status and statistics",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.VMs,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/status/{command}" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/status/{command}",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "VM control operations (start, stop, reset, etc.)",
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
          },
          %{
            name: "command",
            type: :string,
            required: true,
            description: "Control command",
            values: ["start", "stop", "reset", "shutdown", "suspend", "resume"],
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.VMs,
        notes: "VM lifecycle operations fully supported"
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/clone" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/clone",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Clone virtual machine",
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
            description: "Source VM ID",
            values: nil,
            default: nil
          },
          %{
            name: "newid",
            type: :integer,
            required: true,
            description: "New VM ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [:basic_virtualization],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: "VM cloning operations implemented"
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/migrate" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/migrate",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Migrate VM to another node",
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
        response_schema: %{data: :string},
        capabilities_required: [:basic_virtualization],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/snapshot" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/snapshot",
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
            description: "VM ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: "Full snapshot CRUD with state management"
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}",
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
            description: "VM ID",
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
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/config" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/config",
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
            description: "VM ID",
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
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/snapshot/{snapname}/rollback",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Rollback VM to snapshot",
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
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Snapshots,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/pending" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/pending",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Get pending VM configuration changes",
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
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/resize" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/resize",
        methods: [:put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Resize VM disk",
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
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{
      "/api2/json/nodes/{node}/qemu/{vmid}/feature" =>
        planned(:get, :low, "6.0", "Check VM feature availability"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent" =>
        planned(:post, :low, "6.0", "Execute QEMU guest agent commands"),
      "/api2/json/nodes/{node}/qemu/{vmid}/cloudinit/dump" =>
        planned(:get, :low, "7.0", "Get cloud-init generated config"),
      "/api2/json/nodes/{node}/qemu/{vmid}/template" =>
        planned(:post, :low, "6.0", "Convert VM to template"),
      "/api2/json/nodes/{node}/qemu/{vmid}/unlink" =>
        planned(:put, :low, "6.0", "Unlink/delete disk images"),
      "/api2/json/nodes/{node}/qemu/{vmid}/move_disk" =>
        planned(:post, :medium, "6.0", "Move VM disk to different storage"),
      "/api2/json/nodes/{node}/qemu/{vmid}/sendkey" =>
        planned(:put, :low, "6.0", "Send key event to VM"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall" =>
        planned(:get, :low, "6.0", "VM firewall index")
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
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_delete), do: [:get, :delete]
end
