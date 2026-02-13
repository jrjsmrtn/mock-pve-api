# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.SdnTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Sdn
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params \\ %{}, path_params \\ %{}) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

  describe "get_sdn_zone/1" do
    test "returns zone data" do
      conn =
        build_conn(:get, "/api2/json/cluster/sdn/zones/test-zone", %{}, %{
          "zone" => "test-zone"
        })

      conn = Sdn.get_sdn_zone(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["zone"] == "test-zone"
      assert body["data"]["type"] == "vxlan"
    end
  end

  describe "update_sdn_zone/1" do
    test "updates zone and returns data" do
      conn =
        build_conn(
          :put,
          "/api2/json/cluster/sdn/zones/test-zone",
          %{"type" => "vlan", "tag" => "200"},
          %{"zone" => "test-zone"}
        )

      conn = Sdn.update_sdn_zone(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["type"] == "vlan"
      assert body["data"]["tag"] == 200
    end

    test "handles integer tag param" do
      conn =
        build_conn(
          :put,
          "/api2/json/cluster/sdn/zones/z1",
          %{"tag" => 300},
          %{"zone" => "z1"}
        )

      conn = Sdn.update_sdn_zone(conn)
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["tag"] == 300
    end
  end

  describe "delete_sdn_zone/1" do
    test "returns success" do
      conn =
        build_conn(:delete, "/api2/json/cluster/sdn/zones/test-zone", %{}, %{
          "zone" => "test-zone"
        })

      conn = Sdn.delete_sdn_zone(conn)
      assert conn.status == 200
    end
  end

  describe "list_vnets/1" do
    test "returns virtual networks" do
      conn = build_conn(:get, "/api2/json/cluster/sdn/vnets")
      conn = Sdn.list_vnets(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  describe "create_vnet/1" do
    test "creates a virtual network" do
      conn =
        build_conn(:post, "/api2/json/cluster/sdn/vnets", %{
          "vnet" => "vnet300",
          "zone" => "test-zone",
          "tag" => "300"
        })

      conn = Sdn.create_vnet(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["vnet"] == "vnet300"
    end

    test "returns 400 when vnet ID is missing" do
      conn = build_conn(:post, "/api2/json/cluster/sdn/vnets", %{"zone" => "test-zone"})
      conn = Sdn.create_vnet(conn)
      assert conn.status == 400
    end
  end
end
