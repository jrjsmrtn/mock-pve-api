# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.PoolsTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Pools
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params \\ %{}, path_params \\ %{}) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

  describe "list_pools/1" do
    test "returns empty list initially" do
      conn = build_conn(:get, "/api2/json/pools")
      conn = Pools.list_pools(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == []
    end

    test "returns pools after creation" do
      State.create_pool("test-pool", %{comment: "Test"})

      conn = build_conn(:get, "/api2/json/pools")
      conn = Pools.list_pools(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 1
    end
  end

  describe "get_pool/1" do
    test "returns pool by ID" do
      State.create_pool("test-pool", %{comment: "Test"})

      conn = build_conn(:get, "/api2/json/pools/test-pool", %{}, %{"poolid" => "test-pool"})
      conn = Pools.get_pool(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["poolid"] == "test-pool"
    end

    test "returns 404 for unknown pool" do
      conn = build_conn(:get, "/api2/json/pools/unknown", %{}, %{"poolid" => "unknown"})
      conn = Pools.get_pool(conn)
      assert conn.status == 404
    end
  end

  describe "create_pool/1" do
    test "creates a pool" do
      conn =
        build_conn(:post, "/api2/json/pools", %{
          "poolid" => "new-pool",
          "comment" => "New pool"
        })

      conn = Pools.create_pool(conn)
      assert conn.status == 200
    end

    test "returns 400 when poolid is missing" do
      conn = build_conn(:post, "/api2/json/pools", %{"comment" => "No ID"})
      conn = Pools.create_pool(conn)
      assert conn.status == 400
    end

    test "returns 400 for duplicate pool" do
      State.create_pool("dup", %{})

      conn = build_conn(:post, "/api2/json/pools", %{"poolid" => "dup"})
      conn = Pools.create_pool(conn)
      assert conn.status == 400
    end
  end

  describe "update_pool/1" do
    test "updates pool comment" do
      State.create_pool("test-pool", %{comment: "Old"})

      conn =
        build_conn(
          :put,
          "/api2/json/pools/test-pool",
          %{"comment" => "New"},
          %{"poolid" => "test-pool"}
        )

      conn = Pools.update_pool(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent pool" do
      conn =
        build_conn(:put, "/api2/json/pools/unknown", %{"comment" => "X"}, %{
          "poolid" => "unknown"
        })

      conn = Pools.update_pool(conn)
      assert conn.status == 404
    end
  end

  describe "delete_pool/1" do
    test "deletes existing pool" do
      State.create_pool("test-pool", %{})

      conn = build_conn(:delete, "/api2/json/pools/test-pool", %{}, %{"poolid" => "test-pool"})
      conn = Pools.delete_pool(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent pool" do
      conn = build_conn(:delete, "/api2/json/pools/unknown", %{}, %{"poolid" => "unknown"})
      conn = Pools.delete_pool(conn)
      assert conn.status == 404
    end
  end
end
