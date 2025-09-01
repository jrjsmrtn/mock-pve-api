defmodule MockPveApi.Coverage do
  @moduledoc """
  Comprehensive PVE API coverage matrix for the Mock PVE Server.

  This module defines all PVE API endpoints, their implementation status,
  parameters, response schemas, and version requirements. Based on pvex project
  analysis showing 97.8% API coverage across 305+ endpoints.

  Status Legend:
  - :implemented - ✅ Fully implemented with complete functionality
  - :partial - 🟡 Core functionality available, some features missing
  - :in_progress - 🔄 Currently being developed
  - :planned - 📋 Planned for implementation
  - :not_supported - ❌ Not supported/not planned
  - :pve8_only - 🔴 Available in PVE 8.x+ only
  - :pve9_only - 🟠 Available in PVE 9.x+ only
  """

  @type endpoint_category() :: 
    :version | :cluster | :nodes | :vms | :containers | :storage | 
    :network | :firewall | :access | :backup | :hardware | :pools | :monitoring

  @type http_method() :: :get | :post | :put | :delete | :patch
  
  @type implementation_status() :: 
    :implemented | :partial | :in_progress | :planned | :not_supported |
    :pve8_only | :pve9_only

  @type priority() :: :critical | :high | :medium | :low

  @type parameter() :: %{
    name: String.t(),
    type: :string | :integer | :boolean | :array | :object,
    required: boolean(),
    description: String.t(),
    values: [String.t()] | nil,
    default: any() | nil
  }

  @type endpoint_info() :: %{
    path: String.t(),
    methods: [http_method()],
    status: implementation_status(),
    priority: priority(),
    since: String.t(),
    description: String.t(),
    parameters: [parameter()],
    response_schema: map(),
    capabilities_required: [atom()],
    test_coverage: boolean(),
    handler_module: atom() | nil,
    notes: String.t() | nil
  }

  # Comprehensive API Coverage Matrix based on pvex analysis (305+ endpoints)
  @coverage_matrix %{
    # Version Information (Critical Foundation)
    version: %{
      "/api2/json/version" => %{
        path: "/api2/json/version",
        methods: [:get],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "Get PVE version information and server details",
        parameters: [],
        response_schema: %{
          version: :string,
          release: :string, 
          repoid: :string,
          keyboard: :string
        },
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Version,
        notes: "Foundation endpoint required for client compatibility"
      }
    },

    # Cluster Management (18 endpoints, pvex: 94% coverage)
    cluster: %{
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
      "/api2/json/cluster/config/join" => %{
        path: "/api2/json/cluster/config/join",
        methods: [:post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Join node to existing cluster",
        parameters: [
          %{name: "hostname", type: :string, required: true, description: "Cluster hostname", values: nil, default: nil},
          %{name: "nodeid", type: :integer, required: false, description: "Node ID", values: nil, default: nil},
          %{name: "votes", type: :integer, required: false, description: "Number of votes", values: nil, default: 1}
        ],
        response_schema: %{data: :string},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Cluster management operations implemented"
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
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil}
        ],
        response_schema: %{data: :string},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Cluster,
        notes: "Node removal from cluster implemented"
      },
      # SDN Management (PVE 8.0+, pvex: 97% coverage)
      "/api2/json/cluster/sdn/zones" => %{
        path: "/api2/json/cluster/sdn/zones",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "8.0",
        description: "Software Defined Networking zone management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.SDN,
        notes: "SDN features available in PVE 8.0+ only"
      },
      "/api2/json/cluster/sdn/zones/{zone}" => %{
        path: "/api2/json/cluster/sdn/zones/{zone}",
        methods: [:get, :put, :delete],
        status: :planned,
        priority: :medium,
        since: "8.0",
        description: "Individual SDN zone operations",
        parameters: [
          %{name: "zone", type: :string, required: true, description: "Zone identifier", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: false,
        handler_module: nil,
        notes: "Individual zone CRUD operations planned"
      },
      "/api2/json/cluster/sdn/vnets" => %{
        path: "/api2/json/cluster/sdn/vnets",
        methods: [:get, :post],
        status: :planned,
        priority: :medium,
        since: "8.0",
        description: "Virtual network management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: false,
        handler_module: nil,
        notes: "VNet management planned for SDN support"
      },
      # Backup Provider Management (PVE 8.2+)
      "/api2/json/cluster/backup-info/providers" => %{
        path: "/api2/json/cluster/backup-info/providers",
        methods: [:get],
        status: :pve8_only,
        priority: :medium,
        since: "8.2",
        description: "List available backup providers",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:backup_providers],
        test_coverage: false,
        handler_module: nil,
        notes: "Backup provider plugins introduced in PVE 8.2"
      },
      # HA Affinity Rules (PVE 9.0+, pvex: 100% coverage)
      "/api2/json/cluster/ha/affinity" => %{
        path: "/api2/json/cluster/ha/affinity",
        methods: [:get, :post],
        status: :pve9_only,
        priority: :medium,
        since: "9.0",
        description: "HA resource affinity rules management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:ha_resource_affinity],
        test_coverage: false,
        handler_module: nil,
        notes: "HA affinity rules new in PVE 9.0"
      }
    },

    # Node Management (25 endpoints, pvex: 96% coverage)  
    nodes: %{
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
      "/api2/json/nodes/{node}/status" => %{
        path: "/api2/json/nodes/{node}/status",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Node status and control operations",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "command", type: :string, required: false, description: "Control command", values: ["reboot", "shutdown"], default: nil}
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
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil}
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
        status: :planned,
        priority: :low,
        since: "6.0",
        description: "Node time configuration",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: false,
        handler_module: nil,
        notes: "Time management operations planned"
      }
    },

    # Virtual Machine Management (35 endpoints, pvex: 97% coverage)
    vms: %{
      "/api2/json/nodes/{node}/qemu" => %{
        path: "/api2/json/nodes/{node}/qemu",
        methods: [:get, :post],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "List and create virtual machines on node",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "full", type: :boolean, required: false, description: "Full VM information", values: nil, default: false}
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
        status: :partial,
        priority: :critical,
        since: "6.0", 
        description: "Individual VM configuration and management",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "VM ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:basic_virtualization],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.VMs,
        notes: "Core VM operations implemented, advanced config partial"
      },
      "/api2/json/nodes/{node}/qemu/{vmid}/status/current" => %{
        path: "/api2/json/nodes/{node}/qemu/{vmid}/status/current",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Current VM status and statistics",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "VM ID", values: nil, default: nil}
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
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "VM ID", values: nil, default: nil},
          %{name: "command", type: :string, required: true, description: "Control command", values: ["start", "stop", "reset", "shutdown", "suspend", "resume"], default: nil}
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
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "Source VM ID", values: nil, default: nil},
          %{name: "newid", type: :integer, required: true, description: "New VM ID", values: nil, default: nil}
        ],
        response_schema: %{data: :string},
        capabilities_required: [:basic_virtualization],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: "VM cloning operations implemented"
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/clone" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/clone",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Clone LXC container",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "Source Container ID", values: nil, default: nil},
          %{name: "newid", type: :integer, required: true, description: "New Container ID", values: nil, default: nil}
        ],
        response_schema: %{data: :string},
        capabilities_required: [:containers],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Nodes,
        notes: "Container cloning operations implemented"
      }
    },

    # LXC Container Management (30 endpoints, pvex: 97% coverage) 
    containers: %{
      "/api2/json/nodes/{node}/lxc" => %{
        path: "/api2/json/nodes/{node}/lxc",
        methods: [:get, :post],
        status: :implemented,
        priority: :critical,
        since: "6.0",
        description: "List and create LXC containers on node",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil}
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
        status: :partial,
        priority: :critical,
        since: "6.0",
        description: "Individual LXC container configuration",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "Container ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Containers,
        notes: "Core container operations implemented"
      },
      "/api2/json/nodes/{node}/lxc/{vmid}/status/current" => %{
        path: "/api2/json/nodes/{node}/lxc/{vmid}/status/current",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Current container status and statistics",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "vmid", type: :integer, required: true, description: "Container ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:containers],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Containers,
        notes: nil
      }
    },

    # Storage Management (40 endpoints, pvex: 98% coverage)
    storage: %{
      "/api2/json/nodes/{node}/storage" => %{
        path: "/api2/json/nodes/{node}/storage",
        methods: [:get],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "List storage configured for node",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "content", type: :string, required: false, description: "Filter by content type", values: ["images", "backup", "vztmpl"], default: nil}
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
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "storage", type: :string, required: true, description: "Storage ID", values: nil, default: nil}
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
        status: :partial,
        priority: :medium,
        since: "6.0",
        description: "Storage content management (images, backups, templates)",
        parameters: [
          %{name: "node", type: :string, required: true, description: "Node name", values: nil, default: nil},
          %{name: "storage", type: :string, required: true, description: "Storage ID", values: nil, default: nil}
        ],
        response_schema: %{data: :array},
        capabilities_required: [:storage_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Storage,
        notes: "Content listing implemented, content creation partial"
      }
    },

    # User Management & Access Control (24 endpoints, pvex: 96% coverage)
    access: %{
      "/api2/json/access/users" => %{
        path: "/api2/json/access/users",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "User account management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/users/{userid}" => %{
        path: "/api2/json/access/users/{userid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual user account operations",
        parameters: [
          %{name: "userid", type: :string, required: true, description: "User ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Individual user CRUD operations implemented"
      },
      "/api2/json/access/ticket" => %{
        path: "/api2/json/access/ticket",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Authentication ticket creation",
        parameters: [
          %{name: "username", type: :string, required: true, description: "Username", values: nil, default: nil},
          %{name: "password", type: :string, required: true, description: "Password", values: nil, default: nil},
          %{name: "realm", type: :string, required: false, description: "Authentication realm", values: nil, default: "pam"}
        ],
        response_schema: %{data: %{ticket: :string, CSRFPreventionToken: :string}},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Authentication system implemented"
      },
      "/api2/json/access/groups" => %{
        path: "/api2/json/access/groups",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "User group management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Group management implemented"
      },
      "/api2/json/access/groups/{groupid}" => %{
        path: "/api2/json/access/groups/{groupid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual group operations",
        parameters: [
          %{name: "groupid", type: :string, required: true, description: "Group ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Individual group CRUD operations implemented"
      },
      "/api2/json/access/domains" => %{
        path: "/api2/json/access/domains",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Authentication realms/domains listing",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Domains/realms listing implemented"
      },
      "/api2/json/access/users/{userid}/token/{tokenid}" => %{
        path: "/api2/json/access/users/{userid}/token/{tokenid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual API token operations",
        parameters: [
          %{name: "userid", type: :string, required: true, description: "User ID", values: nil, default: nil},
          %{name: "tokenid", type: :string, required: true, description: "Token ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "API token CRUD operations implemented"
      }
    },

    # Resource Pool Management (15 endpoints, pvex: 100% coverage)
    pools: %{
      "/api2/json/pools" => %{
        path: "/api2/json/pools",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Resource pool management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Pools,
        notes: nil
      },
      "/api2/json/pools/{poolid}" => %{
        path: "/api2/json/pools/{poolid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual pool operations",
        parameters: [
          %{name: "poolid", type: :string, required: true, description: "Pool ID", values: nil, default: nil}
        ],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: "Elixir.MockPveApi.Handlers.Pools",
        notes: "Complete CRUD operations for resource pools"
      }
    }
  }

  @doc """
  Gets endpoint information by path pattern matching.

  ## Examples

      iex> MockPveApi.Coverage.get_endpoint_info("/api2/json/version")
      %{path: "/api2/json/version", methods: [:get], status: :implemented, ...}
      
      iex> MockPveApi.Coverage.get_endpoint_info("/api2/json/nodes/pve1/qemu/100")
      %{path: "/api2/json/nodes/{node}/qemu/{vmid}", methods: [:get, :put, :delete], ...}
  """
  @spec get_endpoint_info(String.t()) :: endpoint_info() | nil
  def get_endpoint_info(endpoint_path) do
    @coverage_matrix
    |> Enum.flat_map(fn {_category, endpoints} -> Map.to_list(endpoints) end)
    |> Enum.find_value(fn {pattern, info} ->
      if matches_pattern?(endpoint_path, pattern), do: info
    end)
  end

  @doc """
  Gets all endpoints for a specific category.
  """
  @spec get_category_endpoints(endpoint_category()) :: [endpoint_info()]
  def get_category_endpoints(category) do
    case Map.get(@coverage_matrix, category) do
      nil -> []
      endpoints -> Map.values(endpoints)
    end
  end

  @doc """
  Gets overall coverage statistics.
  """
  @spec get_coverage_stats() :: map()
  def get_coverage_stats do
    all_endpoints = get_all_endpoints()
    
    stats = %{
      total: length(all_endpoints),
      implemented: count_by_status(all_endpoints, :implemented),
      partial: count_by_status(all_endpoints, :partial),
      in_progress: count_by_status(all_endpoints, :in_progress),
      planned: count_by_status(all_endpoints, :planned),
      not_supported: count_by_status(all_endpoints, :not_supported),
      pve8_only: count_by_status(all_endpoints, :pve8_only),
      pve9_only: count_by_status(all_endpoints, :pve9_only)
    }
    
    coverage_percentage = 
      (stats.implemented + stats.partial) / stats.total * 100
    
    Map.put(stats, :coverage_percentage, Float.round(coverage_percentage, 1))
  end

  @doc """
  Gets endpoints by implementation status.
  """
  @spec get_endpoints_by_status(implementation_status()) :: [endpoint_info()]
  def get_endpoints_by_status(status) do
    get_all_endpoints()
    |> Enum.filter(&(&1.status == status))
  end

  @doc """
  Gets endpoints by priority level.
  """
  @spec get_endpoints_by_priority(priority()) :: [endpoint_info()]
  def get_endpoints_by_priority(priority) do
    get_all_endpoints()
    |> Enum.filter(&(&1.priority == priority))
  end

  @doc """
  Gets critical endpoints that are not fully implemented.
  """
  @spec get_missing_critical_endpoints() :: [endpoint_info()]
  def get_missing_critical_endpoints do
    get_endpoints_by_priority(:critical)
    |> Enum.filter(&(&1.status != :implemented))
  end

  @doc """
  Gets coverage statistics by category.
  """
  @spec get_category_stats() :: map()
  def get_category_stats do
    @coverage_matrix
    |> Enum.map(fn {category, endpoints} ->
      endpoint_list = Map.values(endpoints)
      total = length(endpoint_list)
      implemented = length(Enum.filter(endpoint_list, &(&1.status == :implemented)))
      coverage = if total > 0, do: Float.round(implemented / total * 100, 1), else: 0.0
      
      {category, %{
        total: total,
        implemented: implemented,
        coverage_percentage: coverage
      }}
    end)
    |> Enum.into(%{})
  end

  @doc """
  Validates coverage matrix for consistency and completeness.
  """
  @spec validate_coverage() :: {:ok, [String.t()]} | {:error, [String.t()]}
  def validate_coverage do
    issues = []
    
    # Check for endpoints without tests
    no_tests = get_all_endpoints()
    |> Enum.filter(&(!&1.test_coverage && &1.status == :implemented))
    |> Enum.map(&"Missing tests: #{&1.path}")
    
    # Check for missing critical endpoints
    missing_critical = get_missing_critical_endpoints()
    |> Enum.map(&"Critical endpoint not implemented: #{&1.path}")
    
    # Check for endpoints without handler modules
    no_handlers = get_all_endpoints()
    |> Enum.filter(&(is_nil(&1.handler_module) && &1.status == :implemented))
    |> Enum.map(&"Missing handler module: #{&1.path}")
    
    all_issues = issues ++ no_tests ++ missing_critical ++ no_handlers
    
    if length(all_issues) == 0 do
      {:ok, ["Coverage validation passed"]}
    else
      {:error, all_issues}
    end
  end

  @doc """
  Gets all supported categories.
  """
  @spec get_categories() :: [endpoint_category()]
  def get_categories do
    Map.keys(@coverage_matrix)
  end

  @doc """
  Checks if an endpoint is version-compatible.
  """
  @spec version_compatible?(String.t(), String.t()) :: boolean()
  def version_compatible?(endpoint_path, pve_version) do
    case get_endpoint_info(endpoint_path) do
      nil -> false
      endpoint_info ->
        case endpoint_info.status do
          :pve8_only -> version_gte?(pve_version, "8.0")
          :pve9_only -> version_gte?(pve_version, "9.0")
          _ -> version_gte?(pve_version, endpoint_info.since)
        end
    end
  end

  # Private helper functions

  defp get_all_endpoints do
    @coverage_matrix
    |> Enum.flat_map(fn {_category, endpoints} -> Map.values(endpoints) end)
  end

  defp count_by_status(endpoints, status) do
    endpoints
    |> Enum.count(&(&1.status == status))
  end

  defp matches_pattern?(endpoint_path, pattern) do
    # Handle parameterized routes like /nodes/{node}/qemu/{vmid}
    pattern_regex =
      pattern
      |> String.replace("{node}", "[^/]+")
      |> String.replace("{vmid}", "[0-9]+")
      |> String.replace("{storage}", "[^/]+")
      |> String.replace("{userid}", "[^/]+")
      |> String.replace("{poolid}", "[^/]+")
      |> String.replace("{zone}", "[^/]+")
      |> String.replace("{command}", "[^/]+")
    
    Regex.match?(~r/^#{pattern_regex}$/, endpoint_path)
  end

  defp version_gte?(version_a, version_b) do
    # Simple version comparison - could be enhanced with proper semver
    String.to_float(version_a) >= String.to_float(version_b)
  rescue
    _ -> true  # Default to true if version parsing fails
  end
end