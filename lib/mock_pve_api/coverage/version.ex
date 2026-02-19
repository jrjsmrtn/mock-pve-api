# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Version do
  @moduledoc """
  PVE API coverage: Version endpoints.

  Covers `/version` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :version

  @impl true
  def endpoints do
    %{
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
        example_response: %{
          data: %{
            version: "8.3",
            release: "8.3-1",
            repoid: "abcd1234",
            keyboard: "en-us"
          }
        },
        capabilities_required: [],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Version,
        notes: "Foundation endpoint required for client compatibility"
      }
    }
  end
end
