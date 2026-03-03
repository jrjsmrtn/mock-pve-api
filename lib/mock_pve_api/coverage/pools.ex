# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Pools do
  @moduledoc """
  PVE API coverage: Resource pool endpoints.

  Covers `/pools/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @min_since Application.compile_env(:mock_pve_api, :min_pve_version, "7.0")

  @impl true
  def category, do: :pools

  @impl true
  def endpoints do
    %{
      "/api2/json/pools" => %{
        path: "/api2/json/pools",
        methods: [:get, :post, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: @min_since,
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
        since: @min_since,
        description: "Individual pool operations",
        parameters: [
          %{
            name: "poolid",
            type: :string,
            required: true,
            description: "Pool ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:cluster_basic],
        test_coverage: true,
        handler_module: "Elixir.MockPveApi.Handlers.Pools",
        notes: "Complete CRUD operations for resource pools"
      }
    }
  end
end
