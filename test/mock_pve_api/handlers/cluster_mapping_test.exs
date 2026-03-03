# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.ClusterMappingTest do
  @moduledoc """
  Tests for cluster hardware mapping endpoints: PCI, USB, and Dir.
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

  describe "PCI mapping CRUD" do
    test "create, get, update, delete lifecycle" do
      request(:post, "/api2/json/cluster/mapping/pci", %{id: "gpu0", description: "GPU"})
      |> json(200)

      resp = request(:get, "/api2/json/cluster/mapping/pci/gpu0") |> json(200)
      assert resp["data"]["id"] == "gpu0"
      assert resp["data"]["description"] == "GPU"

      request(:put, "/api2/json/cluster/mapping/pci/gpu0", %{description: "Updated GPU"})
      |> json(200)

      resp2 = request(:get, "/api2/json/cluster/mapping/pci/gpu0") |> json(200)
      assert resp2["data"]["description"] == "Updated GPU"

      request(:delete, "/api2/json/cluster/mapping/pci/gpu0") |> json(200)

      resp3 = request(:get, "/api2/json/cluster/mapping/pci/gpu0")
      assert resp3.status == 404
    end

    test "GET unknown PCI mapping returns 404" do
      resp = request(:get, "/api2/json/cluster/mapping/pci/nonexistent")
      assert resp.status == 404
    end

    test "duplicate PCI create returns 400" do
      request(:post, "/api2/json/cluster/mapping/pci", %{id: "gpu-dup"})

      resp =
        request(:post, "/api2/json/cluster/mapping/pci", %{id: "gpu-dup"}) |> json(400)

      assert resp["errors"]["message"] =~ "already exists"
    end
  end

  describe "USB mapping CRUD" do
    test "create, get, delete lifecycle" do
      request(:post, "/api2/json/cluster/mapping/usb", %{id: "usb0", description: "USB dongle"})
      |> json(200)

      resp = request(:get, "/api2/json/cluster/mapping/usb/usb0") |> json(200)
      assert resp["data"]["id"] == "usb0"

      request(:delete, "/api2/json/cluster/mapping/usb/usb0") |> json(200)

      resp2 = request(:get, "/api2/json/cluster/mapping/usb/usb0")
      assert resp2.status == 404
    end

    test "GET unknown USB mapping returns 404" do
      resp = request(:get, "/api2/json/cluster/mapping/usb/nonexistent")
      assert resp.status == 404
    end
  end

  describe "Dir mapping CRUD" do
    test "create, get, update, delete lifecycle" do
      request(:post, "/api2/json/cluster/mapping/dir", %{
        id: "backup-dir",
        path: "/mnt/backup",
        nodes: ["pve-node1"]
      })
      |> json(200)

      resp = request(:get, "/api2/json/cluster/mapping/dir/backup-dir") |> json(200)
      assert resp["data"]["id"] == "backup-dir"
      assert resp["data"]["path"] == "/mnt/backup"

      request(:put, "/api2/json/cluster/mapping/dir/backup-dir", %{path: "/mnt/backup2"})
      |> json(200)

      resp2 = request(:get, "/api2/json/cluster/mapping/dir/backup-dir") |> json(200)
      assert resp2["data"]["path"] == "/mnt/backup2"

      request(:delete, "/api2/json/cluster/mapping/dir/backup-dir") |> json(200)

      resp3 = request(:get, "/api2/json/cluster/mapping/dir/backup-dir")
      assert resp3.status == 404
    end

    test "GET unknown Dir mapping returns 404" do
      resp = request(:get, "/api2/json/cluster/mapping/dir/nonexistent")
      assert resp.status == 404
      body = Jason.decode!(resp.resp_body)
      assert body["errors"]["message"] =~ "not found"
    end

    test "duplicate Dir create returns 400" do
      request(:post, "/api2/json/cluster/mapping/dir", %{id: "dir-dup"})

      resp =
        request(:post, "/api2/json/cluster/mapping/dir", %{id: "dir-dup"}) |> json(400)

      assert resp["errors"]["message"] =~ "already exists"
    end
  end
end
