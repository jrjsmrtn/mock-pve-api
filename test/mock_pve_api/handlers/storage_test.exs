# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.StorageTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Storage
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params \\ %{}, path_params \\ %{}) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

  describe "list_storage/1" do
    test "returns all storage definitions" do
      conn = build_conn(:get, "/api2/json/storage")
      conn = Storage.list_storage(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end
  end

  describe "get_storage_content/1" do
    test "returns content for existing node and storage" do
      conn =
        build_conn(:get, "/api2/json/nodes/pve-node1/storage/local/content", %{}, %{
          "node" => "pve-node1",
          "storage" => "local"
        })

      conn = Storage.get_storage_content(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 2
    end

    test "returns 404 for unknown node" do
      conn =
        build_conn(:get, "/api2/json/nodes/unknown/storage/local/content", %{}, %{
          "node" => "unknown",
          "storage" => "local"
        })

      conn = Storage.get_storage_content(conn)
      assert conn.status == 404
    end
  end

  describe "create_storage_content/1" do
    test "creates content on existing storage" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{"content" => "iso", "filename" => "test.iso"},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["content"] == "iso"
    end

    test "returns 404 for unknown node" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/unknown/storage/local/content",
          %{"filename" => "test.iso"},
          %{"node" => "unknown", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 404
    end

    test "returns 400 for unknown storage" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/nonexistent/content",
          %{"filename" => "test.iso"},
          %{"node" => "pve-node1", "storage" => "nonexistent"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 400
    end

    test "detects qcow2 format from filename" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{"content" => "images", "filename" => "disk.qcow2"},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["format"] == "qcow2"
    end

    test "detects vmdk format from filename" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{"content" => "images", "filename" => "disk.vmdk"},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["format"] == "vmdk"
    end

    test "detects vma format from filename" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{"content" => "backup", "filename" => "backup.vma"},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["format"] == "vma"
    end

    test "detects img format as raw" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{"content" => "images", "filename" => "disk.img"},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["format"] == "raw"
    end

    test "defaults to raw format for unknown extension" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{"content" => "images", "filename" => "disk.unknown"},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["format"] == "raw"
    end

    test "uses default content type and filename when not provided" do
      conn =
        build_conn(
          :post,
          "/api2/json/nodes/pve-node1/storage/local/content",
          %{},
          %{"node" => "pve-node1", "storage" => "local"}
        )

      conn = Storage.create_storage_content(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["content"] == "backup"
    end
  end
end
