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
    implemented_endpoints()
    |> Map.merge(planned_endpoints())
  end

  defp implemented_endpoints do
    cluster_firewall_implemented()
    |> Map.merge(node_firewall_implemented())
  end

  defp planned_endpoints do
    cluster_firewall_planned()
    |> Map.merge(node_firewall_planned())
    |> Map.merge(vm_firewall())
    |> Map.merge(container_firewall())
  end

  # ── Implemented: Cluster Firewall ──

  defp cluster_firewall_implemented do
    %{
      "/api2/json/cluster/firewall/options" =>
        implemented(:get_put, :medium, "6.0", "Cluster firewall options"),
      "/api2/json/cluster/firewall/rules" =>
        implemented(:get_post, :medium, "6.0", "List/create cluster firewall rules"),
      "/api2/json/cluster/firewall/rules/{pos}" =>
        implemented(:get_put_delete, :medium, "6.0", "Individual cluster rule CRUD"),
      "/api2/json/cluster/firewall/groups" =>
        implemented(:get_post, :medium, "6.0", "List/create security groups"),
      "/api2/json/cluster/firewall/groups/{group}" =>
        implemented(:get_delete, :medium, "6.0", "Get rules / delete security group"),
      "/api2/json/cluster/firewall/groups/{group}/{pos}" =>
        implemented(:get_put_delete, :low, "6.0", "Security group rule CRUD"),
      "/api2/json/cluster/firewall/aliases" =>
        implemented(:get_post, :medium, "6.0", "List/create cluster IP aliases"),
      "/api2/json/cluster/firewall/aliases/{name}" =>
        implemented(:get_put_delete, :medium, "6.0", "Individual alias CRUD"),
      "/api2/json/cluster/firewall/ipset" =>
        implemented(:get_post, :medium, "6.0", "List/create IP sets"),
      "/api2/json/cluster/firewall/ipset/{name}" =>
        implemented(:get_post_delete, :medium, "6.0", "List/add entries, delete IP set"),
      "/api2/json/cluster/firewall/ipset/{name}/{cidr}" =>
        implemented(:get_put_delete, :low, "6.0", "IP set entry CRUD")
    }
  end

  # ── Implemented: Node Firewall ──

  defp node_firewall_implemented do
    %{
      "/api2/json/nodes/{node}/firewall/options" =>
        implemented(:get_put, :medium, "6.0", "Node firewall options"),
      "/api2/json/nodes/{node}/firewall/rules" =>
        implemented(:get_post, :medium, "6.0", "List/create node firewall rules"),
      "/api2/json/nodes/{node}/firewall/rules/{pos}" =>
        implemented(:get_put_delete, :medium, "6.0", "Individual node rule CRUD")
    }
  end

  # ── Planned: Remaining Cluster Firewall ──

  defp cluster_firewall_planned do
    %{
      "/api2/json/cluster/firewall/refs" =>
        planned(:get, :low, "6.0", "List available firewall references"),
      "/api2/json/cluster/firewall/macros" =>
        planned(:get, :low, "6.0", "List available firewall macros"),
      "/api2/json/cluster/firewall/log" => planned(:get, :low, "6.0", "Read cluster firewall log")
    }
  end

  # ── Planned: Remaining Node Firewall ──

  defp node_firewall_planned do
    %{
      "/api2/json/nodes/{node}/firewall" => planned(:get, :low, "6.0", "Node firewall index"),
      "/api2/json/nodes/{node}/firewall/log" =>
        planned(:get, :low, "6.0", "Read node firewall log")
    }
  end

  # ── Planned: VM Firewall ──

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

  # ── Planned: Container Firewall ──

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
      handler_module: MockPveApi.Handlers.Firewall,
      notes: nil
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
  defp methods_for(:get_post_delete), do: [:get, :post, :delete]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
