# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.NotificationsCompletionTest do
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

  # SMTP endpoints

  describe "smtp endpoints" do
    test "list smtp endpoints (empty)" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "CRUD smtp endpoint" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/smtp", %{
          "name" => "my-smtp",
          "server" => "smtp.example.com",
          "from-address" => "pve@example.com"
        })

      json(conn, 200)

      # List
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp")
      data = json(conn, 200)["data"]
      assert length(data) == 1

      # Get
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp/my-smtp")
      endpoint = json(conn, 200)["data"]
      assert endpoint["name"] == "my-smtp"

      # Update
      conn =
        request(:put, "/api2/json/cluster/notifications/endpoints/smtp/my-smtp", %{
          "server" => "smtp2.example.com"
        })

      json(conn, 200)

      # Verify update
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp/my-smtp")
      endpoint = json(conn, 200)["data"]
      assert endpoint["server"] == "smtp2.example.com"

      # Delete
      conn = request(:delete, "/api2/json/cluster/notifications/endpoints/smtp/my-smtp")
      json(conn, 200)

      # Verify deleted
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp/my-smtp")
      assert conn.status == 404
    end

    test "get unknown smtp returns 404" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp/no-such-smtp")
      assert conn.status == 404
    end

    test "create duplicate smtp returns 400" do
      request(:post, "/api2/json/cluster/notifications/endpoints/smtp", %{"name" => "dup-smtp"})

      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/smtp", %{"name" => "dup-smtp"})

      assert conn.status == 400
    end

    test "smtp returns 501 on PVE 7.4" do
      Application.put_env(:mock_pve_api, :pve_version, "7.4")
      State.reset()
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/smtp")
      assert conn.status == 501
    end
  end

  # Webhook endpoints

  describe "webhook endpoints" do
    test "list webhook endpoints (empty)" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "CRUD webhook endpoint" do
      # Create
      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/webhook", %{
          "name" => "my-webhook",
          "url" => "https://hooks.example.com/alert"
        })

      json(conn, 200)

      # List
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook")
      data = json(conn, 200)["data"]
      assert length(data) == 1

      # Get
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook/my-webhook")
      endpoint = json(conn, 200)["data"]
      assert endpoint["name"] == "my-webhook"

      # Update
      conn =
        request(:put, "/api2/json/cluster/notifications/endpoints/webhook/my-webhook", %{
          "url" => "https://hooks2.example.com/alert"
        })

      json(conn, 200)

      # Verify update
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook/my-webhook")
      endpoint = json(conn, 200)["data"]
      assert endpoint["url"] == "https://hooks2.example.com/alert"

      # Delete
      conn = request(:delete, "/api2/json/cluster/notifications/endpoints/webhook/my-webhook")
      json(conn, 200)

      # Verify deleted
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook/my-webhook")
      assert conn.status == 404
    end

    test "get unknown webhook returns 404" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook/no-such-webhook")
      assert conn.status == 404
    end

    test "create duplicate webhook returns 400" do
      request(:post, "/api2/json/cluster/notifications/endpoints/webhook", %{
        "name" => "dup-webhook"
      })

      conn =
        request(:post, "/api2/json/cluster/notifications/endpoints/webhook", %{
          "name" => "dup-webhook"
        })

      assert conn.status == 400
    end

    test "webhook returns 501 on PVE 8.1" do
      Application.put_env(:mock_pve_api, :pve_version, "8.1")
      State.reset()
      conn = request(:get, "/api2/json/cluster/notifications/endpoints/webhook")
      assert conn.status == 501
    end
  end

  # Targets

  describe "targets" do
    test "list targets returns empty when no endpoints exist" do
      conn = request(:get, "/api2/json/cluster/notifications/targets")
      data = json(conn, 200)["data"]
      assert data == []
    end

    test "list targets aggregates all endpoint types with type field" do
      request(:post, "/api2/json/cluster/notifications/endpoints/gotify", %{
        "name" => "g1",
        "server" => "https://gotify.example.com",
        "token" => "t"
      })

      request(:post, "/api2/json/cluster/notifications/endpoints/smtp", %{
        "name" => "s1",
        "server" => "smtp.example.com"
      })

      conn = request(:get, "/api2/json/cluster/notifications/targets")
      data = json(conn, 200)["data"]
      assert length(data) == 2

      types = Enum.map(data, & &1["type"])
      assert "gotify" in types
      assert "smtp" in types
    end

    test "POST target test returns 200" do
      conn = request(:post, "/api2/json/cluster/notifications/targets/any-target/test")
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == nil
    end
  end

  # Matcher fields

  describe "matcher fields" do
    test "list matcher fields returns known fields" do
      conn = request(:get, "/api2/json/cluster/notifications/matcher-fields")
      data = json(conn, 200)["data"]
      names = Enum.map(data, & &1["name"])
      assert "severity" in names
      assert "type" in names
    end

    test "get matcher field values returns map" do
      conn = request(:get, "/api2/json/cluster/notifications/matcher-field-values")
      data = json(conn, 200)["data"]
      assert is_map(data)
      assert Map.has_key?(data, "severity")
    end
  end

  # Notifications index

  describe "notifications index" do
    test "GET /cluster/notifications returns child resource list" do
      conn = request(:get, "/api2/json/cluster/notifications")
      data = json(conn, 200)["data"]
      assert is_list(data)
      names = Enum.map(data, & &1["name"])
      assert "endpoints" in names
      assert "matchers" in names
      assert "targets" in names
    end
  end

  # Endpoint types list

  describe "endpoint types" do
    test "GET /cluster/notifications/endpoints lists types" do
      conn = request(:get, "/api2/json/cluster/notifications/endpoints")
      data = json(conn, 200)["data"]
      assert is_list(data)
      names = Enum.map(data, & &1["name"])
      assert "gotify" in names
      assert "sendmail" in names
      assert "smtp" in names
      assert "webhook" in names
    end
  end
end
