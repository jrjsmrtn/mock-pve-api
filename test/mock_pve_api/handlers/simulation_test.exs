# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.SimulationTest do
  use ExUnit.Case, async: false

  import Plug.Test
  import Plug.Conn

  alias MockPveApi.Router
  alias MockPveApi.State

  @opts Router.init([])

  setup do
    prev_delay = Application.get_env(:mock_pve_api, :response_delay_ms, 0)
    prev_error_rate = Application.get_env(:mock_pve_api, :error_rate, 0)
    prev_sdn = Application.get_env(:mock_pve_api, :enable_sdn, true)
    prev_firewall = Application.get_env(:mock_pve_api, :enable_firewall, true)
    prev_backup = Application.get_env(:mock_pve_api, :enable_backup_providers, true)
    prev_version = Application.get_env(:mock_pve_api, :pve_version, "8.3")

    on_exit(fn ->
      Application.put_env(:mock_pve_api, :response_delay_ms, prev_delay)
      Application.put_env(:mock_pve_api, :error_rate, prev_error_rate)
      Application.put_env(:mock_pve_api, :enable_sdn, prev_sdn)
      Application.put_env(:mock_pve_api, :enable_firewall, prev_firewall)
      Application.put_env(:mock_pve_api, :enable_backup_providers, prev_backup)
      Application.put_env(:mock_pve_api, :pve_version, prev_version)
      State.reset()
    end)

    Application.put_env(:mock_pve_api, :pve_version, "9.0")
    State.reset()
    :ok
  end

  defp request(method, path) do
    conn =
      conn(method, path)
      |> put_req_header("authorization", "Bearer test-token")
      |> put_req_header("content-type", "application/json")

    Router.call(conn, @opts)
  end

  # ─── Response Delay ───────────────────────────────────────────

  test "response_delay_ms=0 does not add measurable delay" do
    Application.put_env(:mock_pve_api, :response_delay_ms, 0)
    {elapsed_us, _conn} = :timer.tc(fn -> request(:get, "/api2/json/nodes") end)
    # Should be well under 1 second (no artificial delay)
    assert elapsed_us < 1_000_000
  end

  test "response_delay_ms=100 delays response by at least 100ms" do
    Application.put_env(:mock_pve_api, :response_delay_ms, 100)
    {elapsed_us, conn} = :timer.tc(fn -> request(:get, "/api2/json/nodes") end)
    assert conn.status == 200
    assert elapsed_us >= 100_000
  end

  test "delay does not apply to coverage endpoints" do
    Application.put_env(:mock_pve_api, :response_delay_ms, 500)
    {elapsed_us, _conn} = :timer.tc(fn -> request(:get, "/api2/json/_coverage/stats") end)
    # Coverage endpoint should not be delayed
    assert elapsed_us < 500_000
  end

  # ─── Error Injection ──────────────────────────────────────────

  test "error_rate=0 never returns 500" do
    Application.put_env(:mock_pve_api, :error_rate, 0)

    results =
      for _ <- 1..20 do
        conn = request(:get, "/api2/json/nodes")
        conn.status
      end

    assert Enum.all?(results, &(&1 == 200))
  end

  test "error_rate=100 always returns 500" do
    Application.put_env(:mock_pve_api, :error_rate, 100)

    results =
      for _ <- 1..10 do
        conn = request(:get, "/api2/json/nodes")
        conn.status
      end

    assert Enum.all?(results, &(&1 == 500))
  end

  test "error_rate=100 response body contains error message" do
    Application.put_env(:mock_pve_api, :error_rate, 100)
    conn = request(:get, "/api2/json/nodes")
    assert conn.status == 500
    body = Jason.decode!(conn.resp_body)
    assert %{"errors" => %{"message" => msg}} = body
    assert String.contains?(msg, "Simulated error")
  end

  test "error_rate=100 does not affect version endpoint" do
    Application.put_env(:mock_pve_api, :error_rate, 100)
    conn = request(:get, "/api2/json/version")
    assert conn.status == 200
  end

  test "error_rate=100 does not affect coverage endpoints" do
    Application.put_env(:mock_pve_api, :error_rate, 100)
    conn = request(:get, "/api2/json/_coverage/stats")
    # Coverage endpoint is unaffected by error injection
    assert conn.status != 500
  end

  # ─── SDN Feature Toggle ──────────────────────────────────────

  test "enable_sdn=true (default) allows SDN requests" do
    Application.put_env(:mock_pve_api, :enable_sdn, true)
    conn = request(:get, "/api2/json/cluster/sdn")
    assert conn.status == 200
  end

  test "enable_sdn=false returns 501 for cluster SDN paths" do
    Application.put_env(:mock_pve_api, :enable_sdn, false)
    conn = request(:get, "/api2/json/cluster/sdn")
    assert conn.status == 501
    body = Jason.decode!(conn.resp_body)
    assert %{"errors" => %{"message" => msg}} = body
    assert String.contains?(msg, "SDN")
  end

  test "enable_sdn=false returns 501 for SDN sub-paths" do
    Application.put_env(:mock_pve_api, :enable_sdn, false)
    conn = request(:get, "/api2/json/cluster/sdn/zones")
    assert conn.status == 501
  end

  test "enable_sdn=false does not affect non-SDN cluster endpoints" do
    Application.put_env(:mock_pve_api, :enable_sdn, false)
    conn = request(:get, "/api2/json/cluster/status")
    assert conn.status == 200
  end

  # ─── Firewall Feature Toggle ─────────────────────────────────

  test "enable_firewall=true (default) allows firewall requests" do
    Application.put_env(:mock_pve_api, :enable_firewall, true)
    conn = request(:get, "/api2/json/cluster/firewall/options")
    assert conn.status == 200
  end

  test "enable_firewall=false returns 501 for cluster firewall paths" do
    Application.put_env(:mock_pve_api, :enable_firewall, false)
    conn = request(:get, "/api2/json/cluster/firewall/options")
    assert conn.status == 501
    body = Jason.decode!(conn.resp_body)
    assert %{"errors" => %{"message" => msg}} = body
    assert String.contains?(msg, "Firewall")
  end

  test "enable_firewall=false returns 501 for node firewall paths" do
    Application.put_env(:mock_pve_api, :enable_firewall, false)
    conn = request(:get, "/api2/json/nodes/pve1/firewall/options")
    assert conn.status == 501
  end

  test "enable_firewall=false returns 501 for VM firewall paths" do
    Application.put_env(:mock_pve_api, :enable_firewall, false)
    conn = request(:get, "/api2/json/nodes/pve1/qemu/100/firewall/options")
    assert conn.status == 501
  end

  test "enable_firewall=false does not affect non-firewall node endpoints" do
    Application.put_env(:mock_pve_api, :enable_firewall, false)
    conn = request(:get, "/api2/json/nodes")
    assert conn.status == 200
  end

  # ─── Backup Providers Feature Toggle ─────────────────────────

  test "enable_backup_providers=true (default) allows backup-providers" do
    Application.put_env(:mock_pve_api, :enable_backup_providers, true)
    conn = request(:get, "/api2/json/cluster/backup-providers")
    assert conn.status == 200
  end

  test "enable_backup_providers=false returns 501 for backup-providers" do
    Application.put_env(:mock_pve_api, :enable_backup_providers, false)
    conn = request(:get, "/api2/json/cluster/backup-providers")
    assert conn.status == 501
    body = Jason.decode!(conn.resp_body)
    assert %{"errors" => %{"message" => msg}} = body
    assert String.contains?(msg, "Backup Providers")
  end

  test "enable_backup_providers=false returns 501 for backup-info/providers" do
    Application.put_env(:mock_pve_api, :enable_backup_providers, false)
    conn = request(:get, "/api2/json/cluster/backup-info/providers")
    assert conn.status == 501
  end

  test "enable_backup_providers=false does not affect other cluster endpoints" do
    Application.put_env(:mock_pve_api, :enable_backup_providers, false)
    conn = request(:get, "/api2/json/cluster/status")
    assert conn.status == 200
  end
end
