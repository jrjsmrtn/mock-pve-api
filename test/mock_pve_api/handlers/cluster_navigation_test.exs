# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.ClusterNavigationTest do
  @moduledoc """
  Tests for cluster navigation index stubs and ACME individual resource endpoints.
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

  defp subdirs(resp), do: Enum.map(resp["data"], & &1["subdir"])

  # ── Navigation Index Stubs ──

  describe "cluster index" do
    test "GET /cluster returns subdir list with expected sections" do
      resp = request(:get, "/api2/json/cluster") |> json(200)
      dirs = subdirs(resp)
      assert "ha" in dirs
      assert "acme" in dirs
      assert "sdn" in dirs
      assert "firewall" in dirs
      assert "metrics" in dirs
    end

    test "GET /cluster returns subdir structure" do
      resp = request(:get, "/api2/json/cluster") |> json(200)
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "subdir"))
    end
  end

  describe "navigation index endpoints" do
    test "GET /cluster/acme returns subdir list" do
      resp = request(:get, "/api2/json/cluster/acme") |> json(200)
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "subdir"))
    end

    test "GET /cluster/ceph returns subdir list" do
      resp = request(:get, "/api2/json/cluster/ceph") |> json(200)
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "subdir"))
    end

    test "GET /cluster/firewall returns subdir list" do
      resp = request(:get, "/api2/json/cluster/firewall") |> json(200)
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "subdir"))
    end

    test "GET /cluster/ha returns subdir list" do
      resp = request(:get, "/api2/json/cluster/ha") |> json(200)
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "subdir"))
    end

    test "GET /cluster/ha/status returns subdir list" do
      resp = request(:get, "/api2/json/cluster/ha/status") |> json(200)
      assert is_list(resp["data"])
      dirs = subdirs(resp)
      assert "current" in dirs
    end

    test "GET /cluster/jobs returns subdir list" do
      resp = request(:get, "/api2/json/cluster/jobs") |> json(200)
      assert is_list(resp["data"])
      assert Enum.all?(resp["data"], &Map.has_key?(&1, "subdir"))
    end

    test "GET /cluster/log returns empty list" do
      resp = request(:get, "/api2/json/cluster/log") |> json(200)
      assert resp["data"] == []
    end

    test "GET /cluster/mapping returns subdir list" do
      resp = request(:get, "/api2/json/cluster/mapping") |> json(200)
      assert is_list(resp["data"])
      dirs = subdirs(resp)
      assert "pci" in dirs
      assert "usb" in dirs
    end

    test "GET /cluster/backup-info returns subdir list" do
      resp = request(:get, "/api2/json/cluster/backup-info") |> json(200)
      assert is_list(resp["data"])
      dirs = subdirs(resp)
      assert "not-backed-up" in dirs
      assert "providers" in dirs
    end

    test "GET /cluster/bulk-action returns subdir list on PVE 9.0+" do
      Application.put_env(:mock_pve_api, :pve_version, "9.0")
      State.reset()
      resp = request(:get, "/api2/json/cluster/bulk-action") |> json(200)
      assert is_list(resp["data"])
      dirs = subdirs(resp)
      assert "guest" in dirs
    end
  end

  # ── Static ACME Endpoints ──

  describe "static ACME endpoints" do
    test "GET /cluster/acme/challenge-schema returns 200" do
      resp = request(:get, "/api2/json/cluster/acme/challenge-schema") |> json(200)
      assert is_list(resp["data"])
    end

    test "GET /cluster/acme/directories returns 200 with entries" do
      resp = request(:get, "/api2/json/cluster/acme/directories") |> json(200)
      assert is_list(resp["data"])
    end

    test "GET /cluster/acme/tos returns 200" do
      conn = request(:get, "/api2/json/cluster/acme/tos")
      assert conn.status == 200
    end

    test "GET /cluster/acme/meta returns 200" do
      conn = request(:get, "/api2/json/cluster/acme/meta")
      assert conn.status == 200
    end
  end

  # ── ACME Account CRUD ──

  describe "ACME account individual resource" do
    test "CRUD lifecycle: create then get, update, delete by name" do
      # Create via list endpoint
      conn = request(:post, "/api2/json/cluster/acme/account", %{"name" => "myaccount"})
      assert conn.status == 200

      # GET by name
      resp = request(:get, "/api2/json/cluster/acme/account/myaccount") |> json(200)
      assert resp["data"]["name"] == "myaccount"

      # PUT update
      request(:put, "/api2/json/cluster/acme/account/myaccount", %{
        "contact" => "admin@example.com"
      })
      |> json(200)

      # DELETE
      request(:delete, "/api2/json/cluster/acme/account/myaccount") |> json(200)

      # Confirm gone
      conn = request(:get, "/api2/json/cluster/acme/account/myaccount")
      assert conn.status == 404
    end

    test "GET unknown account returns 404" do
      conn = request(:get, "/api2/json/cluster/acme/account/nonexistent")
      assert conn.status == 404
    end
  end

  # ── ACME Plugin CRUD ──

  describe "ACME plugin individual resource" do
    test "CRUD lifecycle: create then get, update, delete by id" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/acme/plugins", %{
          "id" => "myplugin",
          "type" => "dns"
        })

      assert conn.status == 200

      # GET by id (state stores plugin under "plugin" key, not "id")
      resp = request(:get, "/api2/json/cluster/acme/plugins/myplugin") |> json(200)
      assert resp["data"]["plugin"] == "myplugin"

      # PUT update
      request(:put, "/api2/json/cluster/acme/plugins/myplugin", %{"api" => "cf"})
      |> json(200)

      # DELETE
      request(:delete, "/api2/json/cluster/acme/plugins/myplugin") |> json(200)

      # Confirm gone
      conn = request(:get, "/api2/json/cluster/acme/plugins/myplugin")
      assert conn.status == 404
    end

    test "GET unknown plugin returns 404" do
      conn = request(:get, "/api2/json/cluster/acme/plugins/nonexistent")
      assert conn.status == 404
    end
  end

  # ── Version Gating ──

  describe "version gating" do
    test "bulk-action index returns 501 on PVE 7.4" do
      Application.put_env(:mock_pve_api, :pve_version, "7.4")
      State.reset()

      conn = request(:get, "/api2/json/cluster/bulk-action")
      assert conn.status == 501
    end

    test "jobs index returns 200 on PVE 7.1+ and 501 on PVE 7.0" do
      Application.put_env(:mock_pve_api, :pve_version, "7.1")
      State.reset()
      assert request(:get, "/api2/json/cluster/jobs").status == 200

      Application.put_env(:mock_pve_api, :pve_version, "7.0")
      State.reset()
      assert request(:get, "/api2/json/cluster/jobs").status == 501
    end
  end
end
