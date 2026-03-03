# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.HardwareTest do
  @moduledoc """
  Tests for hardware detection and cluster resource mapping endpoints.
  """

  use ExUnit.Case, async: false

  alias MockPveApi.State

  setup do
    original_version = Application.get_env(:mock_pve_api, :pve_version, "8.0")
    Application.put_env(:mock_pve_api, :pve_version, "8.3")
    State.reset()

    on_exit(fn ->
      Application.put_env(:mock_pve_api, :pve_version, original_version)
      State.reset()
    end)

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

  # ── Node PCI Devices ──

  describe "node PCI devices" do
    test "GET returns list of PCI devices" do
      resp = request(:get, "/api2/json/nodes/pve-node1/hardware/pci") |> json(200)
      assert is_list(resp["data"])
      assert length(resp["data"]) > 0
      device = hd(resp["data"])
      assert Map.has_key?(device, "id")
      assert Map.has_key?(device, "vendor_name")
    end

    test "GET individual PCI device returns detail" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/hardware/pci/0000:00:00.0")
        |> json(200)

      assert resp["data"]["id"] == "0000:00:00.0"
      assert Map.has_key?(resp["data"], "iommugroup")
    end
  end

  # ── Node USB Devices ──

  describe "node USB devices" do
    test "GET returns list of USB devices" do
      resp = request(:get, "/api2/json/nodes/pve-node1/hardware/usb") |> json(200)
      assert is_list(resp["data"])
      assert length(resp["data"]) > 0
      device = hd(resp["data"])
      assert Map.has_key?(device, "busnum")
      assert Map.has_key?(device, "product")
    end
  end

  # ── Cluster PCI Mappings ──

  describe "cluster PCI mappings" do
    test "list empty PCI mappings" do
      resp = request(:get, "/api2/json/cluster/mapping/pci") |> json(200)
      assert resp["data"] == []
    end

    test "CRUD lifecycle for PCI mapping" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/mapping/pci", %{
          "id" => "gpu0",
          "description" => "GPU passthrough"
        })

      assert conn.status == 200

      # Get
      resp = request(:get, "/api2/json/cluster/mapping/pci/gpu0") |> json(200)
      assert resp["data"]["id"] == "gpu0"
      assert resp["data"]["description"] == "GPU passthrough"

      # Update
      request(:put, "/api2/json/cluster/mapping/pci/gpu0", %{
        "description" => "Updated GPU"
      })
      |> json(200)

      resp = request(:get, "/api2/json/cluster/mapping/pci/gpu0") |> json(200)
      assert resp["data"]["description"] == "Updated GPU"

      # Delete
      request(:delete, "/api2/json/cluster/mapping/pci/gpu0") |> json(200)
      resp = request(:get, "/api2/json/cluster/mapping/pci") |> json(200)
      assert resp["data"] == []
    end

    test "create duplicate PCI mapping returns 400" do
      State.create_pci_mapping("dup", %{})
      conn = request(:post, "/api2/json/cluster/mapping/pci", %{"id" => "dup"})
      assert conn.status == 400
    end

    test "get nonexistent PCI mapping returns 404" do
      conn = request(:get, "/api2/json/cluster/mapping/pci/nope")
      assert conn.status == 404
    end

    test "create PCI mapping requires id" do
      conn = request(:post, "/api2/json/cluster/mapping/pci", %{"description" => "test"})
      assert conn.status == 400
    end
  end

  # ── Cluster USB Mappings ──

  describe "cluster USB mappings" do
    test "list empty USB mappings" do
      resp = request(:get, "/api2/json/cluster/mapping/usb") |> json(200)
      assert resp["data"] == []
    end

    test "CRUD lifecycle for USB mapping" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/mapping/usb", %{
          "id" => "usbkey0",
          "description" => "USB security key"
        })

      assert conn.status == 200

      # Get
      resp = request(:get, "/api2/json/cluster/mapping/usb/usbkey0") |> json(200)
      assert resp["data"]["id"] == "usbkey0"

      # Update
      request(:put, "/api2/json/cluster/mapping/usb/usbkey0", %{
        "description" => "Updated key"
      })
      |> json(200)

      resp = request(:get, "/api2/json/cluster/mapping/usb/usbkey0") |> json(200)
      assert resp["data"]["description"] == "Updated key"

      # Delete
      request(:delete, "/api2/json/cluster/mapping/usb/usbkey0") |> json(200)
      resp = request(:get, "/api2/json/cluster/mapping/usb") |> json(200)
      assert resp["data"] == []
    end

    test "create duplicate USB mapping returns 400" do
      State.create_usb_mapping("dup", %{})
      conn = request(:post, "/api2/json/cluster/mapping/usb", %{"id" => "dup"})
      assert conn.status == 400
    end

    test "get nonexistent USB mapping returns 404" do
      conn = request(:get, "/api2/json/cluster/mapping/usb/nope")
      assert conn.status == 404
    end
  end
end
