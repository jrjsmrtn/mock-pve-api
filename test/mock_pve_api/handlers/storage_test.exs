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

  # Router integration tests for new storage endpoints

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

  describe "storage CRUD via router" do
    test "create and get storage" do
      conn =
        request(:post, "/api2/json/storage", %{
          "storage" => "nfs-share",
          "type" => "nfs",
          "content" => "backup,iso"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/storage/nfs-share")
      storage = json(conn, 200)["data"]
      assert storage["storage"] == "nfs-share"
      assert storage["type"] == "nfs"
    end

    test "update storage" do
      conn =
        request(:put, "/api2/json/storage/local", %{
          "content" => "images,backup,iso,vztmpl"
        })

      assert conn.status == 200
      updated = State.get_storage_by_id("local")
      assert updated.content == "images,backup,iso,vztmpl"
    end

    test "delete storage" do
      conn = request(:delete, "/api2/json/storage/local-lvm")
      assert conn.status == 200
      assert State.get_storage_by_id("local-lvm") == nil
    end

    test "create duplicate storage returns 400" do
      conn = request(:post, "/api2/json/storage", %{"storage" => "local", "type" => "dir"})
      assert conn.status == 400
    end

    test "get nonexistent storage returns 404" do
      conn = request(:get, "/api2/json/storage/nonexistent")
      assert conn.status == 404
    end

    test "create storage requires storage name" do
      conn = request(:post, "/api2/json/storage", %{"type" => "dir"})
      assert conn.status == 400
    end
  end

  describe "file-restore endpoints via router" do
    test "list file-restore returns directory listing" do
      conn = request(:get, "/api2/json/nodes/pve-node1/storage/local/file-restore/list")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert Enum.any?(data, &(&1["filepath"] == "/"))
      assert Enum.any?(data, &(&1["type"] == "d"))
    end

    test "download file-restore returns binary content" do
      conn = request(:get, "/api2/json/nodes/pve-node1/storage/local/file-restore/download")
      assert conn.status == 200
      assert conn.resp_body == "mock-file-content"
    end
  end

  describe "prunebackups endpoints via router" do
    test "list prunebackups returns prune info" do
      conn = request(:get, "/api2/json/nodes/pve-node1/storage/local/prunebackups")
      data = json(conn, 200)["data"]
      assert is_list(data)
      assert hd(data)["mark"] == "keep"
    end

    test "delete prunebackups returns UPID" do
      conn = request(:delete, "/api2/json/nodes/pve-node1/storage/local/prunebackups")
      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
      assert String.contains?(data, "prunebackups")
    end
  end

  describe "storage upload via router" do
    test "upload returns UPID" do
      conn =
        request(:post, "/api2/json/nodes/pve-node1/storage/local/upload", %{
          "content" => "iso",
          "filename" => "test.iso"
        })

      data = json(conn, 200)["data"]
      assert String.starts_with?(data, "UPID:")
    end
  end

  describe "node storage sub-items" do
    test "GET /nodes/:node/storage/:storage returns 200" do
      conn = request(:get, "/api2/json/nodes/pve-node1/storage/local")
      json(conn, 200)
    end

    test "POST /nodes/:node/storage/:storage/download-url returns 200" do
      conn =
        request(:post, "/api2/json/nodes/pve-node1/storage/local/download-url", %{
          "url" => "http://example.com/img.iso",
          "filename" => "img.iso"
        })

      json(conn, 200)
    end

    test "GET /nodes/:node/storage/:storage/import-metadata returns 200" do
      conn = request(:get, "/api2/json/nodes/pve-node1/storage/local/import-metadata")
      json(conn, 200)
    end
  end
end
