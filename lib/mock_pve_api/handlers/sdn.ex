# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Sdn do
  @moduledoc """
  Handler for PVE Software Defined Networking (SDN) endpoints.
  Available in PVE 8.0+ only.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  PUT /api2/json/cluster/sdn
  Apply pending SDN configuration changes (mock: no-op, returns nil).
  """
  def apply_sdn(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  @doc """
  GET /api2/json/cluster/sdn
  Returns SDN index (available sub-resources).
  """
  def get_sdn_index(conn) do
    index = [
      %{subdir: "zones"},
      %{subdir: "vnets"},
      %{subdir: "controllers"},
      %{subdir: "dns"},
      %{subdir: "ipams"}
    ]

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: index}))
  end

  # --- SDN Zones ---

  @doc """
  GET /api2/json/cluster/sdn/zones
  Lists SDN zones.
  """
  def list_zones(conn) do
    zones = State.list_sdn_zones()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: zones}))
  end

  @doc """
  POST /api2/json/cluster/sdn/zones
  Creates an SDN zone.
  """
  def create_zone(conn) do
    params = conn.body_params
    zone_id = Map.get(params, "zone")

    if zone_id do
      case State.create_sdn_zone(zone_id, params) do
        {:ok, zone} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: zone}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{zone: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/cluster/sdn/zones/:zone
  Gets specific SDN zone information.
  """
  def get_zone(conn) do
    zone_id = conn.path_params["zone"]

    case State.get_sdn_zone(zone_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Zone '#{zone_id}' not found"}}))

      zone ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: zone}))
    end
  end

  @doc """
  PUT /api2/json/cluster/sdn/zones/:zone
  Updates SDN zone configuration.
  """
  def update_zone(conn) do
    zone_id = conn.path_params["zone"]
    params = conn.body_params

    case State.update_sdn_zone(zone_id, params) do
      {:ok, zone} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: zone}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/cluster/sdn/zones/:zone
  Deletes an SDN zone.
  """
  def delete_zone(conn) do
    zone_id = conn.path_params["zone"]

    case State.delete_sdn_zone(zone_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # --- SDN VNets ---

  @doc """
  GET /api2/json/cluster/sdn/vnets
  Lists virtual networks.
  """
  def list_vnets(conn) do
    vnets = State.list_sdn_vnets()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: vnets}))
  end

  @doc """
  POST /api2/json/cluster/sdn/vnets
  Creates a new virtual network.
  """
  def create_vnet(conn) do
    params = conn.body_params
    vnet_id = Map.get(params, "vnet")

    if vnet_id do
      case State.create_sdn_vnet(vnet_id, params) do
        {:ok, vnet} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: vnet}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{vnet: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/cluster/sdn/vnets/:vnet
  Gets specific virtual network information.
  """
  def get_vnet(conn) do
    vnet_id = conn.path_params["vnet"]

    case State.get_sdn_vnet(vnet_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "VNet '#{vnet_id}' not found"}}))

      vnet ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: vnet}))
    end
  end

  @doc """
  PUT /api2/json/cluster/sdn/vnets/:vnet
  Updates virtual network configuration.
  """
  def update_vnet(conn) do
    vnet_id = conn.path_params["vnet"]
    params = conn.body_params

    case State.update_sdn_vnet(vnet_id, params) do
      {:ok, vnet} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: vnet}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/cluster/sdn/vnets/:vnet
  Deletes a virtual network.
  """
  def delete_vnet(conn) do
    vnet_id = conn.path_params["vnet"]

    case State.delete_sdn_vnet(vnet_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # --- SDN Subnets ---

  @doc """
  GET /api2/json/cluster/sdn/vnets/:vnet/subnets
  Lists subnets for a virtual network.
  """
  def list_subnets(conn) do
    vnet_id = conn.path_params["vnet"]
    subnets = State.list_sdn_subnets(vnet_id)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: subnets}))
  end

  @doc """
  POST /api2/json/cluster/sdn/vnets/:vnet/subnets
  Creates a subnet in a virtual network.
  """
  def create_subnet(conn) do
    vnet_id = conn.path_params["vnet"]
    params = conn.body_params
    subnet_id = Map.get(params, "subnet")

    if subnet_id do
      case State.create_sdn_subnet(vnet_id, subnet_id, params) do
        {:ok, subnet} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: subnet}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{subnet: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/cluster/sdn/vnets/:vnet/subnets/:subnet
  Gets specific subnet information.
  """
  def get_subnet(conn) do
    vnet_id = conn.path_params["vnet"]
    subnet_id = conn.path_params["subnet"]

    case State.get_sdn_subnet(vnet_id, subnet_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Subnet '#{subnet_id}' not found"}})
        )

      subnet ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: subnet}))
    end
  end

  @doc """
  PUT /api2/json/cluster/sdn/vnets/:vnet/subnets/:subnet
  Updates subnet configuration.
  """
  def update_subnet(conn) do
    vnet_id = conn.path_params["vnet"]
    subnet_id = conn.path_params["subnet"]
    params = conn.body_params

    case State.update_sdn_subnet(vnet_id, subnet_id, params) do
      {:ok, subnet} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: subnet}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/cluster/sdn/vnets/:vnet/subnets/:subnet
  Deletes a subnet.
  """
  def delete_subnet(conn) do
    vnet_id = conn.path_params["vnet"]
    subnet_id = conn.path_params["subnet"]

    case State.delete_sdn_subnet(vnet_id, subnet_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # --- SDN Controllers ---

  @doc """
  GET /api2/json/cluster/sdn/controllers
  Lists SDN controllers.
  """
  def list_controllers(conn) do
    controllers = State.list_sdn_controllers()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: controllers}))
  end

  @doc """
  POST /api2/json/cluster/sdn/controllers
  Creates an SDN controller.
  """
  def create_controller(conn) do
    params = conn.body_params
    controller_id = Map.get(params, "controller")

    if controller_id do
      case State.create_sdn_controller(controller_id, params) do
        {:ok, controller} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: controller}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{controller: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/cluster/sdn/controllers/:controller
  Gets specific SDN controller information.
  """
  def get_controller(conn) do
    controller_id = conn.path_params["controller"]

    case State.get_sdn_controller(controller_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "Controller '#{controller_id}' not found"}})
        )

      controller ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: controller}))
    end
  end

  @doc """
  PUT /api2/json/cluster/sdn/controllers/:controller
  Updates SDN controller configuration.
  """
  def update_controller(conn) do
    controller_id = conn.path_params["controller"]
    params = conn.body_params

    case State.update_sdn_controller(controller_id, params) do
      {:ok, controller} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: controller}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/cluster/sdn/controllers/:controller
  Deletes an SDN controller.
  """
  def delete_controller(conn) do
    controller_id = conn.path_params["controller"]

    case State.delete_sdn_controller(controller_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # --- SDN DNS ---

  def list_dns(conn) do
    dns_list = State.list_sdn_dns()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: dns_list}))
  end

  def create_dns(conn) do
    params = conn.body_params
    dns_id = Map.get(params, "dns")

    if dns_id do
      case State.create_sdn_dns(dns_id, params) do
        {:ok, dns} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: dns}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{dns: "property is missing and it is not optional"}})
      )
    end
  end

  def get_dns(conn) do
    dns_id = conn.path_params["dns"]

    case State.get_sdn_dns(dns_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "DNS plugin '#{dns_id}' not found"}})
        )

      dns ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: dns}))
    end
  end

  def update_dns(conn) do
    dns_id = conn.path_params["dns"]
    params = conn.body_params

    case State.update_sdn_dns(dns_id, params) do
      {:ok, dns} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: dns}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  def delete_dns(conn) do
    dns_id = conn.path_params["dns"]

    case State.delete_sdn_dns(dns_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  # --- SDN IPAM ---

  def list_ipams(conn) do
    ipams = State.list_sdn_ipams()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ipams}))
  end

  def create_ipam(conn) do
    params = conn.body_params
    ipam_id = Map.get(params, "ipam")

    if ipam_id do
      case State.create_sdn_ipam(ipam_id, params) do
        {:ok, ipam} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: ipam}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{ipam: "property is missing and it is not optional"}})
      )
    end
  end

  def get_ipam(conn) do
    ipam_id = conn.path_params["ipam"]

    case State.get_sdn_ipam(ipam_id) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{errors: %{message: "IPAM '#{ipam_id}' not found"}})
        )

      ipam ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: ipam}))
    end
  end

  def update_ipam(conn) do
    ipam_id = conn.path_params["ipam"]
    params = conn.body_params

    case State.update_sdn_ipam(ipam_id, params) do
      {:ok, ipam} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: ipam}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  def delete_ipam(conn) do
    ipam_id = conn.path_params["ipam"]

    case State.delete_sdn_ipam(ipam_id) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end
end
