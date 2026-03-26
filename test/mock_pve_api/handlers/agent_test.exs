# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.AgentTest do
  @moduledoc """
  Tests for QEMU guest agent endpoints, including sub-command routing.
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

  describe "base agent endpoint" do
    test "GET /nodes/:node/qemu/:vmid/agent returns 200" do
      resp = request(:get, "/api2/json/nodes/pve-node1/qemu/100/agent") |> json(200)
      assert is_map(resp["data"])
    end

    test "POST /nodes/:node/qemu/:vmid/agent returns 200" do
      resp = request(:post, "/api2/json/nodes/pve-node1/qemu/100/agent") |> json(200)
      assert Map.has_key?(resp, "data")
    end
  end

  describe "GET agent sub-commands" do
    test "get-osinfo returns 200 with result field" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/agent/get-osinfo") |> json(200)

      assert is_map(resp["data"])
      assert Map.has_key?(resp["data"], "result")
    end

    test "network-get-interfaces returns 200 with result field" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/agent/network-get-interfaces")
        |> json(200)

      assert Map.has_key?(resp["data"], "result")
    end

    test "info returns 200 with result field" do
      resp = request(:get, "/api2/json/nodes/pve-node1/qemu/100/agent/info") |> json(200)
      assert Map.has_key?(resp["data"], "result")
    end

    test "get-host-name returns 200" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/agent/get-host-name") |> json(200)

      assert is_map(resp["data"])
    end

    test "unknown GET sub-command returns 200 (catch-all)" do
      resp =
        request(:get, "/api2/json/nodes/pve-node1/qemu/100/agent/some-unknown-cmd") |> json(200)

      assert is_map(resp["data"])
    end
  end

  describe "POST agent sub-commands" do
    test "ping returns 200 with nil data" do
      resp = request(:post, "/api2/json/nodes/pve-node1/qemu/100/agent/ping") |> json(200)
      assert is_nil(resp["data"])
    end

    test "exec returns 200 with nil data" do
      resp =
        request(:post, "/api2/json/nodes/pve-node1/qemu/100/agent/exec", %{command: "ls"})
        |> json(200)

      assert is_nil(resp["data"])
    end

    test "shutdown returns 200 with nil data" do
      resp =
        request(:post, "/api2/json/nodes/pve-node1/qemu/100/agent/shutdown") |> json(200)

      assert is_nil(resp["data"])
    end

    test "unknown POST sub-command returns 200 (catch-all)" do
      resp =
        request(:post, "/api2/json/nodes/pve-node1/qemu/100/agent/some-unknown-cmd")
        |> json(200)

      assert is_nil(resp["data"])
    end
  end
end
