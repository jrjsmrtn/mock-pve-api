# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Hardware do
  @moduledoc """
  PVE API coverage: Hardware detection and passthrough endpoints.

  Covers `/nodes/{node}/hardware/*` and `/cluster/mapping/*`
  in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :hardware

  @impl true
  def endpoints do
    planned_endpoints()
  end

  defp planned_endpoints do
    %{
      # Node hardware detection
      "/api2/json/nodes/{node}/hardware/pci" =>
        planned(:get, :medium, "6.0", "List PCI devices on node"),
      "/api2/json/nodes/{node}/hardware/pci/{pciid}" =>
        planned(:get, :low, "6.0", "Get PCI device details"),
      "/api2/json/nodes/{node}/hardware/usb" =>
        planned(:get, :medium, "6.0", "List USB devices on node"),
      # Resource mappings (PVE 8.0+)
      "/api2/json/cluster/mapping/pci" =>
        planned(:get_post, :low, "8.0", "PCI resource mapping management"),
      "/api2/json/cluster/mapping/pci/{id}" =>
        planned(:get_put_delete, :low, "8.0", "Individual PCI mapping CRUD"),
      "/api2/json/cluster/mapping/usb" =>
        planned(:get_post, :low, "8.0", "USB resource mapping management"),
      "/api2/json/cluster/mapping/usb/{id}" =>
        planned(:get_put_delete, :low, "8.0", "Individual USB mapping CRUD")
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
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
