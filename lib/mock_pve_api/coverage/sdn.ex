# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Sdn do
  @moduledoc """
  PVE API coverage: Software Defined Networking (SDN) endpoints.

  Covers `/cluster/sdn/*` in the PVE API Viewer.
  SDN is available in PVE 7.0+ (tech preview) and production-ready in PVE 8.0+.
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
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
        since: "8.0",
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
      }
    }
  end

  defp planned_endpoints do
    %{
      "/api2/json/cluster/sdn/dns" =>
        planned(:get_post, :low, "8.0", "SDN DNS plugin management"),
      "/api2/json/cluster/sdn/dns/{dns}" =>
        planned(:get_put_delete, :low, "8.0", "Individual SDN DNS plugin operations"),
      "/api2/json/cluster/sdn/ipams" =>
        planned(:get_post, :low, "8.0", "SDN IPAM plugin management"),
      "/api2/json/cluster/sdn/ipams/{ipam}" =>
        planned(:get_put_delete, :low, "8.0", "Individual SDN IPAM plugin operations")
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
      capabilities_required: [:sdn_tech_preview],
      test_coverage: false,
      handler_module: nil,
      notes: nil
    }
  end

  defp methods_for(:get), do: [:get]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
