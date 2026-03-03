# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.NotificationsTest do
  use ExUnit.Case, async: false

  alias MockPveApi.State

  setup do
    original_version = Application.get_env(:mock_pve_api, :pve_version, "8.0")
    # Ensure PVE version supports notifications (8.1+)
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

  # Gotify endpoints

  describe "gotify endpoints" do
    test "list gotify endpoints (empty)" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/gotify")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "CRUD gotify endpoint" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/gotify", %{
          "name" => "my-gotify",
          "server" => "https://gotify.example.com",
          "token" => "abc123"
        })

      json(conn, 200)

      # List
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/gotify")
      data = json(conn, 200)["data"]
      assert length(data) == 1

      # Get
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/gotify/my-gotify")
      endpoint = json(conn, 200)["data"]
      assert endpoint["name"] == "my-gotify"

      # Update
      conn =
        request(:put, "/api2/json/cluster/notifications/endpoints/gotify/my-gotify", %{
          "server" => "https://gotify2.example.com"
        })

      json(conn, 200)

      # Verify update
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/gotify/my-gotify")
      endpoint = json(conn, 200)["data"]
      assert endpoint["server"] == "https://gotify2.example.com"

      # Delete
      conn = request(:delete, "/api2/json/cluster/notifications/endpoints/gotify/my-gotify")
      json(conn, 200)

      # Verify deleted
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/gotify/my-gotify")
      assert conn.status == 404
    end

    test "create gotify without name returns 400" do
      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/gotify", %{
          "server" => "https://gotify.example.com"
        })

      assert conn.status == 400
    end

    test "create duplicate gotify returns 400" do
      request(:post, "/api2/json/cluster/notifications/endpoints/gotify", %{
        "name" => "dup-gotify"
      })

      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/gotify", %{
          "name" => "dup-gotify"
        })

      assert conn.status == 400
    end
  end

  # Sendmail endpoints

  describe "sendmail endpoints" do
    test "list sendmail endpoints (empty)" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/sendmail")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "CRUD sendmail endpoint" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/sendmail", %{
          "name" => "my-sendmail",
          "mailto" => "admin@example.com"
        })

      json(conn, 200)

      # Get
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/sendmail/my-sendmail")
      endpoint = json(conn, 200)["data"]
      assert endpoint["name"] == "my-sendmail"

      # Update
      conn =
        request(:put, "/api2/json/cluster/notifications/endpoints/sendmail/my-sendmail", %{
          "mailto" => "ops@example.com"
        })

      json(conn, 200)

      # Delete
      conn = request(:delete, "/api2/json/cluster/notifications/endpoints/sendmail/my-sendmail")
      json(conn, 200)

      # Verify deleted
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/sendmail/my-sendmail")
      assert conn.status == 404
    end

    test "create sendmail without name returns 400" do
      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/sendmail", %{
          "mailto" => "admin@example.com"
        })

      assert conn.status == 400
    end
  end

  # Matcher endpoints

  describe "matcher endpoints" do
    test "list matchers (empty)" do
      conn = request(:get, "/api2/json/cluster/notifications/matchers")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "CRUD matcher" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/notifications/matchers", %{
          "name" => "my-matcher",
          "match-severity" => "error",
          "target" => "my-gotify"
        })

      json(conn, 200)

      # List
      conn = request(:get, "/api2/json/cluster/notifications/matchers")
      data = json(conn, 200)["data"]
      assert length(data) == 1

      # Get
      conn = request(:get, "/api2/json/cluster/notifications/matchers/my-matcher")
      matcher = json(conn, 200)["data"]
      assert matcher["name"] == "my-matcher"

      # Update
      conn =
        request(:put, "/api2/json/cluster/notifications/matchers/my-matcher", %{
          "match-severity" => "warning"
        })

      json(conn, 200)

      # Delete
      conn = request(:delete, "/api2/json/cluster/notifications/matchers/my-matcher")
      json(conn, 200)

      # Verify deleted
      conn = request(:get, "/api2/json/cluster/notifications/matchers/my-matcher")
      assert conn.status == 404
    end

    test "create matcher without name returns 400" do
      conn =
        request(:post, "/api2/json/cluster/notifications/matchers", %{
          "match-severity" => "error"
        })

      assert conn.status == 400
    end

    test "create duplicate matcher returns 400" do
      request(:post, "/api2/json/cluster/notifications/matchers", %{"name" => "dup-matcher"})

      conn =
        request(:post, "/api2/json/cluster/notifications/matchers", %{"name" => "dup-matcher"})

      assert conn.status == 400
    end
  end
end
