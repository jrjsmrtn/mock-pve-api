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

  @min_since Application.compile_env(:mock_pve_api, :min_pve_version, "7.0")

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
    |> Map.merge(vm_firewall_implemented())
    |> Map.merge(container_firewall_implemented())
  end

  defp planned_endpoints do
    %{}
  end

  # ── Implemented: Cluster Firewall ──

  defp cluster_firewall_implemented do
    %{
      "/api2/json/cluster/firewall/options" =>
        implemented(:get_put, :medium, @min_since, "Cluster firewall options"),
      "/api2/json/cluster/firewall/rules" =>
        implemented(:get_post, :medium, @min_since, "List/create cluster firewall rules"),
      "/api2/json/cluster/firewall/rules/{pos}" =>
        implemented(:get_put_delete, :medium, @min_since, "Individual cluster rule CRUD"),
      "/api2/json/cluster/firewall/groups" =>
        implemented(:get_post, :medium, @min_since, "List/create security groups"),
      "/api2/json/cluster/firewall/groups/{group}" =>
        implemented(
          :get_post_delete,
          :medium,
          @min_since,
          "Get rules / create rule / delete security group"
        ),
      "/api2/json/cluster/firewall/groups/{group}/{pos}" =>
        implemented(:get_put_delete, :low, @min_since, "Security group rule CRUD"),
      "/api2/json/cluster/firewall/aliases" =>
        implemented(:get_post, :medium, @min_since, "List/create cluster IP aliases"),
      "/api2/json/cluster/firewall/aliases/{name}" =>
        implemented(:get_put_delete, :medium, @min_since, "Individual alias CRUD"),
      "/api2/json/cluster/firewall/ipset" =>
        implemented(:get_post, :medium, @min_since, "List/create IP sets"),
      "/api2/json/cluster/firewall/ipset/{name}" =>
        implemented(:get_post_delete, :medium, @min_since, "List/add entries, delete IP set"),
      "/api2/json/cluster/firewall/ipset/{name}/{cidr}" =>
        implemented(:get_put_delete, :low, @min_since, "IP set entry CRUD"),
      "/api2/json/cluster/firewall/refs" =>
        implemented(:get, :low, @min_since, "List available firewall references"),
      "/api2/json/cluster/firewall/macros" =>
        implemented(:get, :low, @min_since, "List available firewall macros"),
      "/api2/json/cluster/firewall/log" =>
        implemented(:get, :low, @min_since, "Read cluster firewall log")
    }
  end

  # ── Implemented: Node Firewall ──

  defp node_firewall_implemented do
    %{
      "/api2/json/nodes/{node}/firewall/options" =>
        implemented(:get_put, :medium, @min_since, "Node firewall options"),
      "/api2/json/nodes/{node}/firewall/rules" =>
        implemented(:get_post, :medium, @min_since, "List/create node firewall rules"),
      "/api2/json/nodes/{node}/firewall/rules/{pos}" =>
        implemented(:get_put_delete, :medium, @min_since, "Individual node rule CRUD"),
      "/api2/json/nodes/{node}/firewall" =>
        implemented(:get, :low, @min_since, "Node firewall index"),
      "/api2/json/nodes/{node}/firewall/log" =>
        implemented(:get, :low, @min_since, "Read node firewall log")
    }
  end

  # ── Implemented: VM Firewall ──

  defp vm_firewall_implemented do
    %{
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall" =>
        implemented(:get, :low, @min_since, "VM firewall index"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/options" =>
        implemented(:get_put, :medium, @min_since, "VM firewall options"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/rules" =>
        implemented(:get_post, :medium, @min_since, "List/create VM firewall rules"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/rules/{pos}" =>
        implemented(:get_put_delete, :medium, @min_since, "Individual VM rule CRUD"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/aliases" =>
        implemented(:get_post, :low, @min_since, "VM-level IP aliases"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/aliases/{name}" =>
        implemented(:get_put_delete, :low, @min_since, "VM alias CRUD"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/ipset" =>
        implemented(:get_post, :low, @min_since, "VM-level IP sets"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/ipset/{name}" =>
        implemented(:get_post_delete, :low, @min_since, "VM IP set entries / add / delete"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/ipset/{name}/{cidr}" =>
        implemented(:get_put_delete, :low, @min_since, "VM IP set entry CRUD"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/refs" =>
        implemented(:get, :low, @min_since, "VM firewall references"),
      "/api2/json/nodes/{node}/qemu/{vmid}/firewall/log" =>
        implemented(:get, :low, @min_since, "Read VM firewall log")
    }
  end

  # ── Implemented: Container Firewall ──

  defp container_firewall_implemented do
    %{
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall" =>
        implemented(:get, :low, @min_since, "Container firewall index"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/options" =>
        implemented(:get_put, :medium, @min_since, "Container firewall options"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/rules" =>
        implemented(:get_post, :medium, @min_since, "List/create container firewall rules"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/rules/{pos}" =>
        implemented(:get_put_delete, :medium, @min_since, "Individual container rule CRUD"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/aliases" =>
        implemented(:get_post, :low, @min_since, "Container-level IP aliases"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/aliases/{name}" =>
        implemented(:get_put_delete, :low, @min_since, "Container alias CRUD"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/ipset" =>
        implemented(:get_post, :low, @min_since, "Container-level IP sets"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/ipset/{name}" =>
        implemented(:get_post_delete, :low, @min_since, "Container IP set entries / add / delete"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/ipset/{name}/{cidr}" =>
        implemented(:get_put_delete, :low, @min_since, "Container IP set entry CRUD"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/refs" =>
        implemented(:get, :low, @min_since, "Container firewall references"),
      "/api2/json/nodes/{node}/lxc/{vmid}/firewall/log" =>
        implemented(:get, :low, @min_since, "Read container firewall log")
    }
  end

  # (No more planned endpoints — firewall category is 100% implemented)

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

  defp methods_for(:get), do: [:get]
  defp methods_for(:get_put), do: [:get, :put]
  defp methods_for(:get_post), do: [:get, :post]
  defp methods_for(:get_delete), do: [:get, :delete]
  defp methods_for(:get_post_delete), do: [:get, :post, :delete]
  defp methods_for(:get_put_delete), do: [:get, :put, :delete]
end
