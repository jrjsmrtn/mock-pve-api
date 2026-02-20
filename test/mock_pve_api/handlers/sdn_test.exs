# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.SdnTest do
  @moduledoc """
  Tests for SDN handler endpoints including zones, vnets, subnets, and controllers.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp request(method, path, body \\ nil) do
    conn =
      Plug.Test.conn(method, path, body && Jason.encode!(body))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", "PVEAPIToken=root@pam!test=secret")

    MockPveApi.Router.call(conn, MockPveApi.Router.init([]))
  end

  defp json(conn, status) do
    assert conn.status == status
    Jason.decode!(conn.resp_body)
  end

  # SDN Index

  describe "SDN index" do
    test "returns sub-resource list" do
      conn = request(:get, "/api2/json/cluster/sdn")
      data = json(conn, 200)["data"]
      assert is_list(data)
      subdirs = Enum.map(data, & &1["subdir"])
      assert "zones" in subdirs
      assert "vnets" in subdirs
      assert "controllers" in subdirs
      assert "dns" in subdirs
      assert "ipams" in subdirs
    end
  end

  # SDN Zones

  describe "SDN zones" do
    test "list empty zones" do
      conn = request(:get, "/api2/json/cluster/sdn/zones")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for zone" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/sdn/zones", %{
          "zone" => "myzone",
          "type" => "vxlan",
          "peers" => "10.0.0.1,10.0.0.2"
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/sdn/zones/myzone")
      zone = json(conn, 200)["data"]
      assert zone["zone"] == "myzone"
      assert zone["type"] == "vxlan"

      # Update
      conn = request(:put, "/api2/json/cluster/sdn/zones/myzone", %{"mtu" => 9000})
      assert conn.status == 200
      updated = State.get_sdn_zone("myzone")
      assert updated.mtu == 9000

      # Delete
      conn = request(:delete, "/api2/json/cluster/sdn/zones/myzone")
      assert conn.status == 200
      assert State.get_sdn_zone("myzone") == nil
    end

    test "create duplicate zone returns 400" do
      State.create_sdn_zone("dup-zone", %{})
      conn = request(:post, "/api2/json/cluster/sdn/zones", %{"zone" => "dup-zone"})
      assert conn.status == 400
    end

    test "get nonexistent zone returns 404" do
      conn = request(:get, "/api2/json/cluster/sdn/zones/nonexistent")
      assert conn.status == 404
    end

    test "create zone requires zone name" do
      conn = request(:post, "/api2/json/cluster/sdn/zones", %{"type" => "vxlan"})
      assert conn.status == 400
    end
  end

  # SDN VNets

  describe "SDN vnets" do
    test "list empty vnets" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for vnet" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/sdn/vnets", %{
          "vnet" => "vnet100",
          "zone" => "myzone",
          "tag" => 100
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/sdn/vnets/vnet100")
      vnet = json(conn, 200)["data"]
      assert vnet["vnet"] == "vnet100"
      assert vnet["zone"] == "myzone"

      # Update
      conn =
        request(:put, "/api2/json/cluster/sdn/vnets/vnet100", %{
          "alias" => "Production Net"
        })

      assert conn.status == 200
      updated = State.get_sdn_vnet("vnet100")
      assert updated.alias == "Production Net"

      # Delete
      conn = request(:delete, "/api2/json/cluster/sdn/vnets/vnet100")
      assert conn.status == 200
      assert State.get_sdn_vnet("vnet100") == nil
    end

    test "create duplicate vnet returns 400" do
      State.create_sdn_vnet("dup-vnet", %{})
      conn = request(:post, "/api2/json/cluster/sdn/vnets", %{"vnet" => "dup-vnet"})
      assert conn.status == 400
    end

    test "get nonexistent vnet returns 404" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/nonexistent")
      assert conn.status == 404
    end

    test "create vnet requires vnet name" do
      conn = request(:post, "/api2/json/cluster/sdn/vnets", %{"zone" => "myzone"})
      assert conn.status == 400
    end

    test "deleting vnet also removes its subnets" do
      State.create_sdn_vnet("v1", %{})
      State.create_sdn_subnet("v1", "10.0.0.0-24", %{})

      conn = request(:delete, "/api2/json/cluster/sdn/vnets/v1")
      assert conn.status == 200
      assert State.get_sdn_subnet("v1", "10.0.0.0-24") == nil
    end
  end

  # SDN Subnets

  describe "SDN subnets" do
    setup do
      State.create_sdn_vnet("vnet1", %{"zone" => "myzone"})
      :ok
    end

    test "list empty subnets" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/vnet1/subnets")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for subnet" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/sdn/vnets/vnet1/subnets", %{
          "subnet" => "10.0.0.0-24",
          "gateway" => "10.0.0.1"
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/sdn/vnets/vnet1/subnets/10.0.0.0-24")
      subnet = json(conn, 200)["data"]
      assert subnet["subnet"] == "10.0.0.0-24"
      assert subnet["gateway"] == "10.0.0.1"

      # Update
      conn =
        request(:put, "/api2/json/cluster/sdn/vnets/vnet1/subnets/10.0.0.0-24", %{
          "gateway" => "10.0.0.254"
        })

      assert conn.status == 200
      updated = State.get_sdn_subnet("vnet1", "10.0.0.0-24")
      assert updated.gateway == "10.0.0.254"

      # Delete
      conn = request(:delete, "/api2/json/cluster/sdn/vnets/vnet1/subnets/10.0.0.0-24")
      assert conn.status == 200
      assert State.get_sdn_subnet("vnet1", "10.0.0.0-24") == nil
    end

    test "create duplicate subnet returns 400" do
      State.create_sdn_subnet("vnet1", "10.0.0.0-24", %{})

      conn =
        request(:post, "/api2/json/cluster/sdn/vnets/vnet1/subnets", %{
          "subnet" => "10.0.0.0-24"
        })

      assert conn.status == 400
    end

    test "get nonexistent subnet returns 404" do
      conn = request(:get, "/api2/json/cluster/sdn/vnets/vnet1/subnets/nonexistent")
      assert conn.status == 404
    end

    test "create subnet requires subnet name" do
      conn =
        request(:post, "/api2/json/cluster/sdn/vnets/vnet1/subnets", %{
          "gateway" => "10.0.0.1"
        })

      assert conn.status == 400
    end
  end

  # SDN Controllers

  describe "SDN controllers" do
    test "list empty controllers" do
      conn = request(:get, "/api2/json/cluster/sdn/controllers")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for controller" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/sdn/controllers", %{
          "controller" => "ctrl1",
          "type" => "evpn",
          "asn" => 65000
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/sdn/controllers/ctrl1")
      controller = json(conn, 200)["data"]
      assert controller["controller"] == "ctrl1"
      assert controller["type"] == "evpn"

      # Update
      conn =
        request(:put, "/api2/json/cluster/sdn/controllers/ctrl1", %{"peers" => "10.0.0.1"})

      assert conn.status == 200
      updated = State.get_sdn_controller("ctrl1")
      assert updated.peers == "10.0.0.1"

      # Delete
      conn = request(:delete, "/api2/json/cluster/sdn/controllers/ctrl1")
      assert conn.status == 200
      assert State.get_sdn_controller("ctrl1") == nil
    end

    test "create duplicate controller returns 400" do
      State.create_sdn_controller("dup-ctrl", %{})

      conn =
        request(:post, "/api2/json/cluster/sdn/controllers", %{"controller" => "dup-ctrl"})

      assert conn.status == 400
    end

    test "get nonexistent controller returns 404" do
      conn = request(:get, "/api2/json/cluster/sdn/controllers/nonexistent")
      assert conn.status == 404
    end

    test "create controller requires controller name" do
      conn = request(:post, "/api2/json/cluster/sdn/controllers", %{"type" => "evpn"})
      assert conn.status == 400
    end
  end

  # SDN DNS

  describe "SDN DNS" do
    test "list empty DNS plugins" do
      conn = request(:get, "/api2/json/cluster/sdn/dns")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for DNS plugin" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/sdn/dns", %{
          "dns" => "powerdns1",
          "type" => "powerdns",
          "url" => "http://dns.local:8081"
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/sdn/dns/powerdns1")
      dns = json(conn, 200)["data"]
      assert dns["dns"] == "powerdns1"
      assert dns["type"] == "powerdns"
      assert dns["url"] == "http://dns.local:8081"

      # Update
      conn =
        request(:put, "/api2/json/cluster/sdn/dns/powerdns1", %{
          "url" => "http://dns2.local:8081"
        })

      assert conn.status == 200
      updated = State.get_sdn_dns("powerdns1")
      assert updated.url == "http://dns2.local:8081"

      # Delete
      conn = request(:delete, "/api2/json/cluster/sdn/dns/powerdns1")
      assert conn.status == 200
      assert State.get_sdn_dns("powerdns1") == nil
    end

    test "create duplicate DNS plugin returns 400" do
      State.create_sdn_dns("dup-dns", %{})
      conn = request(:post, "/api2/json/cluster/sdn/dns", %{"dns" => "dup-dns"})
      assert conn.status == 400
    end

    test "get nonexistent DNS plugin returns 404" do
      conn = request(:get, "/api2/json/cluster/sdn/dns/nonexistent")
      assert conn.status == 404
    end

    test "create DNS plugin requires dns name" do
      conn = request(:post, "/api2/json/cluster/sdn/dns", %{"type" => "powerdns"})
      assert conn.status == 400
    end
  end

  # SDN IPAM

  describe "SDN IPAM" do
    test "list empty IPAMs" do
      conn = request(:get, "/api2/json/cluster/sdn/ipams")
      assert json(conn, 200)["data"] == []
    end

    test "CRUD lifecycle for IPAM" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/sdn/ipams", %{
          "ipam" => "pve-ipam",
          "type" => "pve"
        })

      assert conn.status == 200

      # Get
      conn = request(:get, "/api2/json/cluster/sdn/ipams/pve-ipam")
      ipam = json(conn, 200)["data"]
      assert ipam["ipam"] == "pve-ipam"
      assert ipam["type"] == "pve"

      # Update
      conn =
        request(:put, "/api2/json/cluster/sdn/ipams/pve-ipam", %{
          "type" => "netbox"
        })

      assert conn.status == 200
      updated = State.get_sdn_ipam("pve-ipam")
      assert updated.type == "netbox"

      # Delete
      conn = request(:delete, "/api2/json/cluster/sdn/ipams/pve-ipam")
      assert conn.status == 200
      assert State.get_sdn_ipam("pve-ipam") == nil
    end

    test "create duplicate IPAM returns 400" do
      State.create_sdn_ipam("dup-ipam", %{})
      conn = request(:post, "/api2/json/cluster/sdn/ipams", %{"ipam" => "dup-ipam"})
      assert conn.status == 400
    end

    test "get nonexistent IPAM returns 404" do
      conn = request(:get, "/api2/json/cluster/sdn/ipams/nonexistent")
      assert conn.status == 404
    end

    test "create IPAM requires ipam name" do
      conn = request(:post, "/api2/json/cluster/sdn/ipams", %{"type" => "pve"})
      assert conn.status == 400
    end
  end
end
