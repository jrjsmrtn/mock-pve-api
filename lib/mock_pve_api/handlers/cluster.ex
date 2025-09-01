defmodule MockPveApi.Handlers.Cluster do
  @moduledoc """
  Handler for PVE cluster-related endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.{State, Fixtures}

  @doc """
  GET /api2/json/cluster/resources
  Gets all cluster resources (nodes, VMs, containers).
  """
  def get_resources(conn) do
    # Use version-aware fixture data
    resources = Fixtures.cluster_resources()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: resources}))
  end

  @doc """
  GET /api2/json/cluster/nextid
  Gets next available VMID.
  """
  def get_next_vmid(conn) do
    next_vmid = State.get_next_vmid()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: next_vmid}))
  end
end
