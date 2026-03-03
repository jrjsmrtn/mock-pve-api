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
        methods: [:get, :delete],
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
        methods: [:get, :put, :post],
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
        methods: [:get, :post],
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
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/feature" =>
        implemented(:get, :low, "6.0", "Check VM feature availability"),
      "/api2/json/nodes/{node}/qemu/{vmid}/template" =>
        implemented(:post, :low, "6.0", "Convert VM to template"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent" =>
        implemented(:get_post, :medium, "6.0", "QEMU guest agent info and commands"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/exec-status" =>
        implemented(:get, :low, "7.0", "Get agent exec command exit code and output"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/file-read" =>
        implemented(:get, :low, "7.0", "Read file from guest via agent"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-fsinfo" =>
        implemented(:get, :low, "7.0", "Get guest filesystem info"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-host-name" =>
        implemented(:get, :low, "7.0", "Get guest hostname"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-memory-block-info" =>
        implemented(:get, :low, "7.0", "Get guest memory block info"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-memory-blocks" =>
        implemented(:get, :low, "7.0", "Get guest memory blocks"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-osinfo" =>
        implemented(:get, :low, "7.0", "Get guest OS information"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-time" =>
        implemented(:get, :low, "7.0", "Get guest time"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-timezone" =>
        implemented(:get, :low, "7.0", "Get guest timezone"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-users" =>
        implemented(:get, :low, "7.0", "List logged-in guest users"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/get-vcpus" =>
        implemented(:get, :low, "7.0", "Get guest vCPU info"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/info" =>
        implemented(:get, :low, "7.0", "Get QEMU guest agent info"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/network-get-interfaces" =>
        implemented(:get, :low, "7.0", "Get guest network interfaces"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/exec" =>
        implemented(:post, :low, "7.0", "Execute command in guest"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/file-write" =>
        implemented(:post, :low, "7.0", "Write file to guest via agent"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/fsfreeze-freeze" =>
        implemented(:post, :low, "7.0", "Freeze guest filesystems"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/fsfreeze-status" =>
        implemented(:post, :low, "7.0", "Get filesystem freeze status"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/fsfreeze-thaw" =>
        implemented(:post, :low, "7.0", "Thaw guest filesystems"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/fstrim" =>
        implemented(:post, :low, "7.0", "Trim guest filesystems"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/ping" =>
        implemented(:post, :low, "7.0", "Ping QEMU guest agent"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/set-user-password" =>
        implemented(:post, :low, "7.0", "Set guest user password"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/shutdown" =>
        implemented(:post, :low, "7.0", "Shutdown guest via agent"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/suspend-disk" =>
        implemented(:post, :low, "7.0", "Suspend guest to disk"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/suspend-hybrid" =>
        implemented(:post, :low, "7.0", "Hybrid guest suspend"),
      "/api2/json/nodes/{node}/qemu/{vmid}/agent/suspend-ram" =>
        implemented(:post, :low, "7.0", "Suspend guest to RAM"),
      "/api2/json/nodes/{node}/qemu/{vmid}/cloudinit/dump" =>
        implemented(:get, :low, "6.0", "Get cloud-init configuration dump"),
      "/api2/json/nodes/{node}/qemu/{vmid}/unlink" =>
        implemented(:put, :low, "6.0", "Unlink/delete disk images"),
      "/api2/json/nodes/{node}/qemu/{vmid}/move_disk" =>
        implemented(:post, :medium, "6.0", "Move VM disk to different storage"),
      "/api2/json/nodes/{node}/qemu/{vmid}/sendkey" =>
        implemented(:put, :low, "6.0", "Send key event to VM")
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
      capabilities_required: [:basic_virtualization],
      test_coverage: true,
      handler_module: MockPveApi.Handlers.Nodes,
      notes: nil
    }
  end

  defp methods_for(:get), do: [:get]
  defp methods_for(:post), do: [:post]
  defp methods_for(:put), do: [:put]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_delete), do: [:get, :delete]
end
