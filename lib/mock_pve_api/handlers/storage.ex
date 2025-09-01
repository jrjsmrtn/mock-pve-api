defmodule MockPveApi.Handlers.Storage do
  @moduledoc """
  Handler for PVE storage-related endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  GET /api2/json/storage
  Lists all storage definitions.
  """
  def list_storage(conn) do
    storage = State.get_storage()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: storage}))
  end

  @doc """
  GET /api2/json/nodes/:node/storage/:storage/content
  Gets storage content for a specific storage on a node.
  """
  def get_storage_content(conn) do
    node_name = conn.path_params["node"]
    storage_id = conn.path_params["storage"]

    case State.get_node(node_name) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Node '#{node_name}' not found"}
          })
        )

      _node ->
        content = State.get_storage_content(node_name, storage_id)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: content}))
    end
  end
end
