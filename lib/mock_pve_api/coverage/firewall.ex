# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Firewall do
  @moduledoc """
  PVE API coverage: Firewall management endpoints.

  Covers `/cluster/firewall/*`, `/nodes/{node}/firewall/*`,
  `/nodes/{node}/qemu/{vmid}/firewall/*`, and
  `/nodes/{node}/lxc/{vmid}/firewall/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :firewall

  @impl true
  def endpoints do
    planned_endpoints()
  end

  defp planned_endpoints do
    cluster_firewall()
    |> Map.merge(node_firewall())
    |> Map.merge(vm_firewall())
    |> Map.merge(container_firewall())
  end

  defp cluster_firewall do
    %{
      # Cluster firewall options
      "/api2/json/cluster/firewall/options" =>
        planned(:get_put, :medium, "6.0", "Cluster firewall options"),
      # Cluster firewall rules
      "/api2/json/cluster/firewall/rules" =>
        planned(:get_post, :medium, "6.0", "List/create cluster firewall rules"),
      "/api2/json/cluster/firewall/rules/{pos}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual cluster rule CRUD"),
      # Security groups
      "/api2/json/cluster/firewall/groups" =>
        planned(:get_post, :medium, "6.0", "List/create security groups"),
      "/api2/json/cluster/firewall/groups/{group}" =>
        planned(:get_delete, :medium, "6.0", "Get rules / delete security group"),
      "/api2/json/cluster/firewall/groups/{group}/{pos}" =>
        planned(:get_put_delete, :low, "6.0", "Security group rule CRUD"),
      # Aliases
      "/api2/json/cluster/firewall/aliases" =>
        planned(:get_post, :medium, "6.0", "List/create cluster IP aliases"),
      "/api2/json/cluster/firewall/aliases/{name}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual alias CRUD"),
      # IP sets
      "/api2/json/cluster/firewall/ipset" =>
        planned(:get_post, :medium, "6.0", "List/create IP sets"),
      "/api2/json/cluster/firewall/ipset/{name}" =>
        planned(:get_delete, :medium, "6.0", "List entries / delete IP set"),
      "/api2/json/cluster/firewall/ipset/{name}/{cidr}" =>
        planned(:get_put_delete, :low, "6.0", "IP set entry CRUD"),
      # Cluster firewall refs and macros
      "/api2/json/cluster/firewall/refs" =>
        planned(:get, :low, "6.0", "List available firewall references"),
      "/api2/json/cluster/firewall/macros" =>
        planned(:get, :low, "6.0", "List available firewall macros"),
      # Cluster firewall log
      "/api2/json/cluster/firewall/log" => planned(:get, :low, "6.0", "Read cluster firewall log")
    }
  end

  defp node_firewall do
    %{
      "/api2/json/nodes/{node}/firewall" => planned(:get, :low, "6.0", "Node firewall index"),
      "/api2/json/nodes/{node}/firewall/options" =>
        planned(:get_put, :medium, "6.0", "Node firewall options"),
      "/api2/json/nodes/{node}/firewall/rules" =>
        planned(:get_post, :medium, "6.0", "List/create node firewall rules"),
      "/api2/json/nodes/{node}/firewall/rules/{pos}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual node rule CRUD"),
      "/api2/json/nodes/{node}/firewall/log" =>
        planned(:get, :low, "6.0", "Read node firewall log")
    }
  end

  defp vm_firewall do
    %{
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall" =>
        planned(:get, :low, "6.0", "VM firewall index"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/options" =>
        planned(:get_put, :medium, "6.0", "VM firewall options"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/rules" =>
        planned(:get_post, :medium, "6.0", "List/create VM firewall rules"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/rules/{pos}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual VM rule CRUD"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/aliases" =>
        planned(:get_post, :low, "6.0", "VM-level IP aliases"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/aliases/{name}" =>
        planned(:get_put_delete, :low, "6.0", "VM alias CRUD"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/ipset" =>
        planned(:get_post, :low, "6.0", "VM-level IP sets"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/ipset/{name}" =>
        planned(:get_delete, :low, "6.0", "VM IP set entries / delete"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/ipset/{name}/{cidr}" =>
        planned(:get_put_delete, :low, "6.0", "VM IP set entry CRUD"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/refs" =>
        planned(:get, :low, "6.0", "VM firewall references"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/log" =>
        planned(:get, :low, "6.0", "Read VM firewall log")
    }
  end

  defp container_firewall do
    %{
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall" =>
        planned(:get, :low, "6.0", "Container firewall index"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/options" =>
        planned(:get_put, :medium, "6.0", "Container firewall options"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/rules" =>
        planned(:get_post, :medium, "6.0", "List/create container firewall rules"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/rules/{pos}" =>
        planned(:get_put_delete, :medium, "6.0", "Individual container rule CRUD"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/aliases" =>
        planned(:get_post, :low, "6.0", "Container-level IP aliases"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/aliases/{name}" =>
        planned(:get_put_delete, :low, "6.0", "Container alias CRUD"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/ipset" =>
        planned(:get_post, :low, "6.0", "Container-level IP sets"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/ipset/{name}" =>
        planned(:get_delete, :low, "6.0", "Container IP set entries / delete"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/ipset/{name}/{cidr}" =>
        planned(:get_put_delete, :low, "6.0", "Container IP set entry CRUD"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/refs" =>
        planned(:get, :low, "6.0", "Container firewall references"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/log" =>
        planned(:get, :low, "6.0", "Read container firewall log")
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
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_delete), do: [:get, :delete]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
