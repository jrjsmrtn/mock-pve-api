defmodule MockPveApi do
  @moduledoc """
  Mock Proxmox VE API Server for testing purposes.

  This module provides a lightweight HTTP server that simulates PVE API responses
  for both version 7.x and 8.x, enabling comprehensive testing without requiring
  a real Proxmox VE environment.
  """

  use Application

  @default_port 8006
  @default_host "0.0.0.0"

  def start(_type, _args) do
    port = Application.get_env(:mock_pve_api, :port, @default_port)
    host = Application.get_env(:mock_pve_api, :host, @default_host)

    children = [
      # State management for resources
      MockPveApi.State,
      # HTTP server
      {Plug.Cowboy,
       scheme: :http, plug: MockPveApi.Router, options: [port: port, ip: parse_ip(host)]}
    ]

    opts = [strategy: :one_for_one, name: MockPveApi.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @doc """
  Starts the mock server for testing with optional configuration.
  """
  def start_test_server(opts \\ []) do
    port = Keyword.get(opts, :port, @default_port)
    pve_version = Keyword.get(opts, :pve_version, "8.0")

    Application.put_env(:mock_pve_api, :port, port)
    Application.put_env(:mock_pve_api, :pve_version, pve_version)

    start(:normal, [])
  end

  @doc """
  Stops the mock server.
  """
  def stop_test_server do
    Supervisor.stop(MockPveApi.Supervisor)
  end

  @doc """
  Resets all mock server state to initial values.
  """
  def reset_state do
    MockPveApi.State.reset()
  end

  defp parse_ip(host) when is_binary(host) do
    case :inet.parse_address(String.to_charlist(host)) do
      {:ok, ip} -> ip
      # fallback to localhost
      {:error, _} -> {127, 0, 0, 1}
    end
  end

  defp parse_ip({_, _, _, _} = ip), do: ip
  defp parse_ip(_), do: {127, 0, 0, 1}
end
