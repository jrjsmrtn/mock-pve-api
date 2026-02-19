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
        handler_module: "Elixir.MockPveApi.Handlers.Sdn",
        notes: "Complete CRUD operations for SDN zones"
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
        handler_module: "Elixir.MockPveApi.Handlers.Sdn",
        notes: "Virtual network management with creation support"
      },
      "/api2/json/cluster/sdn/subnets" => %{
        path: "/api2/json/cluster/sdn/subnets",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "8.0",
        description: "List all SDN subnets",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:sdn_tech_preview],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router"
      }
    }
  end

  defp planned_endpoints do
    %{
      "/api2/json/cluster/sdn" => planned(:get, :medium, "8.0", "SDN index"),
      "/api2/json/cluster/sdn/vnets/{vnet}" =>
        planned(:get_put_delete, :medium, "8.0", "Individual virtual network operations"),
      "/api2/json/cluster/sdn/vnets/{vnet}/subnets" =>
        planned(:get_post, :medium, "8.0", "Subnet management for a virtual network"),
      "/api2/json/cluster/sdn/vnets/{vnet}/subnets/{subnet}" =>
        planned(:get_put_delete, :medium, "8.0", "Individual subnet operations"),
      "/api2/json/cluster/sdn/controllers" =>
        planned(:get_post, :medium, "8.0", "SDN controller management"),
      "/api2/json/cluster/sdn/controllers/{controller}" =>
        planned(:get_put_delete, :medium, "8.0", "Individual SDN controller operations"),
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
