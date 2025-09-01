defmodule MockPveApi.Handlers.Sdn do
  @moduledoc """
  Handler for PVE Software Defined Networking (SDN) endpoints.
  Available in PVE 8.0+ only.
  """

  import Plug.Conn
  require Logger
  # alias MockPveApi.State  # Currently unused

  @doc """
  GET /api2/json/cluster/sdn/zones/{zone}
  Gets specific SDN zone information.
  """
  def get_sdn_zone(conn) do
    zone_id = conn.path_params["zone"]

    # Mock SDN zone data
    zone_data = %{
      type: "vxlan",
      zone: zone_id,
      nodes: "pve-node1,pve-node2",
      peers: "192.168.1.10,192.168.1.11",
      tag: 100,
      mtu: 1450,
      digest: "a1b2c3d4e5f6"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: zone_data}))
  end

  @doc """
  PUT /api2/json/cluster/sdn/zones/{zone}
  Updates SDN zone configuration.
  """
  def update_sdn_zone(conn) do
    zone_id = conn.path_params["zone"]
    params = conn.body_params

    # Mock update - in real implementation this would modify SDN configuration
    updated_zone = %{
      type: Map.get(params, "type", "vxlan"),
      zone: zone_id,
      nodes: Map.get(params, "nodes", "pve-node1,pve-node2"),
      peers: Map.get(params, "peers", "192.168.1.10,192.168.1.11"),
      tag: get_int_param(params, "tag") || 100,
      mtu: get_int_param(params, "mtu") || 1450,
      digest: "updated_digest"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: updated_zone}))
  end

  @doc """
  DELETE /api2/json/cluster/sdn/zones/{zone}
  Deletes an SDN zone.
  """
  def delete_sdn_zone(conn) do
    _zone_id = conn.path_params["zone"]

    # Mock deletion - return success
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  @doc """
  GET /api2/json/cluster/sdn/vnets
  Lists virtual networks.
  """
  def list_vnets(conn) do
    # Mock virtual networks data
    vnets = [
      %{
        vnet: "vnet100",
        zone: "localnetwork",
        tag: 100,
        alias: "Production Network",
        digest: "vnet1digest"
      },
      %{
        vnet: "vnet200", 
        zone: "localnetwork",
        tag: 200,
        alias: "Development Network",
        digest: "vnet2digest"
      }
    ]

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
      # Mock creation - return success
      new_vnet = %{
        vnet: vnet_id,
        zone: Map.get(params, "zone", "localnetwork"),
        tag: get_int_param(params, "tag"),
        alias: Map.get(params, "alias", ""),
        digest: "new_vnet_digest"
      }

      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{data: new_vnet}))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{
          errors: %{vnet: "property is missing and it is not optional"}
        })
      )
    end
  end

  # Helper functions
  defp get_int_param(params, key) do
    case Map.get(params, key) do
      nil -> nil
      val when is_integer(val) -> val
      val when is_binary(val) -> 
        case Integer.parse(val) do
          {int, ""} -> int
          _ -> nil
        end
      _ -> nil
    end
  end
end