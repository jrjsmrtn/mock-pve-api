# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.ClusterJobsTest do
  @moduledoc """
  Tests for cluster jobs endpoints: schedule-analyze and realm-sync CRUD.
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

  describe "schedule-analyze" do
    test "GET /cluster/jobs/schedule-analyze returns empty list" do
      resp = request(:get, "/api2/json/cluster/jobs/schedule-analyze") |> json(200)
      assert resp["data"] == []
    end
  end

  describe "realm-sync CRUD" do
    test "GET /cluster/jobs/realm-sync returns empty list initially" do
      resp = request(:get, "/api2/json/cluster/jobs/realm-sync") |> json(200)
      assert resp["data"] == []
    end

    test "POST /cluster/jobs/realm-sync/:id creates a job" do
      resp =
        request(:post, "/api2/json/cluster/jobs/realm-sync/sync-pam", %{
          realm: "pam",
          schedule: "0 0 * * *"
        })
        |> json(200)

      assert resp["data"]["id"] == "sync-pam"
      assert resp["data"]["realm"] == "pam"
      assert resp["data"]["schedule"] == "0 0 * * *"
    end

    test "GET /cluster/jobs/realm-sync/:id returns created job" do
      request(:post, "/api2/json/cluster/jobs/realm-sync/sync-pve", %{
        realm: "pve",
        schedule: "daily"
      })

      resp = request(:get, "/api2/json/cluster/jobs/realm-sync/sync-pve") |> json(200)
      assert resp["data"]["id"] == "sync-pve"
      assert resp["data"]["realm"] == "pve"
    end

    test "PUT /cluster/jobs/realm-sync/:id updates a job" do
      request(:post, "/api2/json/cluster/jobs/realm-sync/sync-test", %{
        realm: "pam",
        schedule: "daily"
      })

      request(:put, "/api2/json/cluster/jobs/realm-sync/sync-test", %{schedule: "weekly"})
      |> json(200)

      resp = request(:get, "/api2/json/cluster/jobs/realm-sync/sync-test") |> json(200)
      assert resp["data"]["schedule"] == "weekly"
    end

    test "DELETE /cluster/jobs/realm-sync/:id removes a job" do
      request(:post, "/api2/json/cluster/jobs/realm-sync/sync-del", %{realm: "pam"})

      request(:delete, "/api2/json/cluster/jobs/realm-sync/sync-del") |> json(200)

      resp = request(:get, "/api2/json/cluster/jobs/realm-sync/sync-del")
      assert resp.status == 404
    end

    test "GET /cluster/jobs/realm-sync/:id for unknown id returns 404" do
      resp = request(:get, "/api2/json/cluster/jobs/realm-sync/nonexistent")
      assert resp.status == 404
      body = Jason.decode!(resp.resp_body)
      assert body["errors"]["message"] =~ "not found"
    end

    test "POST duplicate job id returns 400" do
      request(:post, "/api2/json/cluster/jobs/realm-sync/sync-dup", %{realm: "pam"})

      resp =
        request(:post, "/api2/json/cluster/jobs/realm-sync/sync-dup", %{realm: "pam"})
        |> json(400)

      assert resp["errors"]["message"] =~ "already exists"
    end
  end
end
