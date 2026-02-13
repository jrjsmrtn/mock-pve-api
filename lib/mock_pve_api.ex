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
    ssl_enabled = Application.get_env(:mock_pve_api, :ssl_enabled, false)

    # Configure server scheme and options
    {scheme, server_opts} =
      if ssl_enabled do
        # Convert relative paths to absolute paths
        keyfile = Application.get_env(:mock_pve_api, :ssl_keyfile) |> Path.expand()
        certfile = Application.get_env(:mock_pve_api, :ssl_certfile) |> Path.expand()

        ssl_opts = [
          port: port,
          ip: parse_ip(host),
          keyfile: keyfile,
          certfile: certfile
        ]

        # Add CA certificate file if specified
        ssl_opts =
          case Application.get_env(:mock_pve_api, :ssl_cacertfile) do
            nil -> ssl_opts
            cacertfile -> Keyword.put(ssl_opts, :cacertfile, Path.expand(cacertfile))
          end

        {:https, ssl_opts}
      else
        {:http, [port: port, ip: parse_ip(host)]}
      end

    children = [
      # HTTP client for test helper
      {Finch, name: MockPveApi.Finch},
      # State management for resources
      MockPveApi.State,
      # HTTP/HTTPS server
      {Plug.Cowboy, scheme: scheme, plug: MockPveApi.Router, options: server_opts}
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
    ssl_enabled = Keyword.get(opts, :ssl_enabled, false)

    Application.put_env(:mock_pve_api, :port, port)
    Application.put_env(:mock_pve_api, :pve_version, pve_version)
    Application.put_env(:mock_pve_api, :ssl_enabled, ssl_enabled)

    # Set SSL options if enabled
    if ssl_enabled do
      Application.put_env(
        :mock_pve_api,
        :ssl_keyfile,
        Keyword.get(opts, :ssl_keyfile, "certs/server.key")
      )

      Application.put_env(
        :mock_pve_api,
        :ssl_certfile,
        Keyword.get(opts, :ssl_certfile, "certs/server.crt")
      )

      if cacertfile = Keyword.get(opts, :ssl_cacertfile) do
        Application.put_env(:mock_pve_api, :ssl_cacertfile, cacertfile)
      end
    end

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
