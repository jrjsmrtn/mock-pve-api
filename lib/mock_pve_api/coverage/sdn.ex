# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Sdn do
  @moduledoc """
  PVE API coverage: Software Defined Networking (SDN) endpoints.

  Covers `/cluster/sdn/*` in the PVE API Viewer.
  SDN endpoints exist in the PVE API since 7.0 (tech preview), production-ready in 8.0+.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :sdn

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/cluster/sdn" => %{
        path: "/api2/json/cluster/sdn",
        methods: [:get, :put],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "SDN index",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/zones" => %{
        path: "/api2/json/cluster/sdn/zones",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Software Defined Networking zone management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/zones/{zone}" => %{
        path: "/api2/json/cluster/sdn/zones/{zone}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Individual SDN zone operations",
        parameters: [
          %{
            name: "zone",
            type: :string,
            required: true,
            description: "Zone identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets" => %{
        path: "/api2/json/cluster/sdn/vnets",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Virtual network management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Individual virtual network operations",
        parameters: [
          %{
            name: "vnet",
            type: :string,
            required: true,
            description: "VNet identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}/subnets" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}/subnets",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Subnet management for a virtual network",
        parameters: [
          %{
            name: "vnet",
            type: :string,
            required: true,
            description: "VNet identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}/subnets/{subnet}" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}/subnets/{subnet}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Individual subnet operations",
        parameters: [
          %{
            name: "vnet",
            type: :string,
            required: true,
            description: "VNet identifier",
            values: nil,
            default: nil
          },
          %{
            name: "subnet",
            type: :string,
            required: true,
            description: "Subnet identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/controllers" => %{
        path: "/api2/json/cluster/sdn/controllers",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "SDN controller management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/controllers/{controller}" => %{
        path: "/api2/json/cluster/sdn/controllers/{controller}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "7.0",
        description: "Individual SDN controller operations",
        parameters: [
          %{
            name: "controller",
            type: :string,
            required: true,
            description: "Controller identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/dns" => %{
        path: "/api2/json/cluster/sdn/dns",
        methods: [:get, :post],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "SDN DNS plugin management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/dns/{dns}" => %{
        path: "/api2/json/cluster/sdn/dns/{dns}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Individual SDN DNS plugin operations",
        parameters: [
          %{
            name: "dns",
            type: :string,
            required: true,
            description: "DNS plugin identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/ipams" => %{
        path: "/api2/json/cluster/sdn/ipams",
        methods: [:get, :post],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "SDN IPAM plugin management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/ipams/{ipam}" => %{
        path: "/api2/json/cluster/sdn/ipams/{ipam}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Individual SDN IPAM plugin operations",
        parameters: [
          %{
            name: "ipam",
            type: :string,
            required: true,
            description: "IPAM identifier",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Sdn,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}/firewall" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}/firewall",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.3",
        description: "SDN vnet firewall index",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Firewall,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}/firewall/options" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}/firewall/options",
        methods: [:get, :put],
        status: :implemented,
        priority: :low,
        since: "8.3",
        description: "SDN vnet firewall options",
        parameters: [],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Firewall,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}/firewall/rules" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}/firewall/rules",
        methods: [:get, :post],
        status: :implemented,
        priority: :low,
        since: "8.3",
        description: "SDN vnet firewall rules list and create",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Firewall,
        notes: nil
      },
      "/api2/json/cluster/sdn/vnets/{vnet}/firewall/rules/{pos}" => %{
        path: "/api2/json/cluster/sdn/vnets/{vnet}/firewall/rules/{pos}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :low,
        since: "8.3",
        description: "SDN vnet firewall rule CRUD",
        parameters: [],
        response_schema: %{data: :object},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Firewall,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{}
  end
end
