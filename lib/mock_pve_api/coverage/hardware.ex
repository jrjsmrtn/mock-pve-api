# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Hardware do
  @moduledoc """
  PVE API coverage: Hardware detection and passthrough endpoints.

  Covers `/nodes/{node}/hardware/*` and `/cluster/mapping/*`
  in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @min_since Application.compile_env(:mock_pve_api, :min_pve_version, "7.0")

  @impl true
  def category, do: :hardware

  @impl true
  def endpoints do
    implemented_endpoints()
    |> Map.merge(planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/nodes/{node}/hardware/pci" =>
        implemented(:get, :medium, @min_since, "List PCI devices on node"),
      "/api2/json/nodes/{node}/hardware/pci/{pciid}" =>
        implemented(:get, :low, @min_since, "Get PCI device details"),
      "/api2/json/nodes/{node}/hardware/usb" =>
        implemented(:get, :medium, @min_since, "List USB devices on node"),
      "/api2/json/cluster/mapping/pci" =>
        implemented(:get_post, :low, "8.0", "PCI resource mapping management"),
      "/api2/json/cluster/mapping/pci/{id}" =>
        implemented(:get_put_delete, :low, "8.0", "Individual PCI mapping CRUD"),
      "/api2/json/cluster/mapping/usb" =>
        implemented(:get_post, :low, "8.0", "USB resource mapping management"),
      "/api2/json/cluster/mapping/usb/{id}" =>
        implemented(:get_put_delete, :low, "8.0", "Individual USB mapping CRUD")
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
      capabilities_required: [],
      test_coverage: true,
      handler_module: MockPveApi.Handlers.Hardware,
      notes: nil
    }
  end

  defp methods_for(:get), do: [:get]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
