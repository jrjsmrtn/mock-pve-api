defmodule MockPveApi.Handlers.Version do
  @moduledoc """
  Handler for PVE version-related endpoints.
  """

  import Plug.Conn
  require Logger

  alias MockPveApi.Capabilities

  @doc """
  GET /api2/json/version
  Returns PVE version information based on configured version.
  """
  def get_version(conn) do
    pve_version = Application.get_env(:mock_pve_server, :pve_version, "8.0")
    version_data = Capabilities.get_version_info(pve_version)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: version_data}))
  end
end
