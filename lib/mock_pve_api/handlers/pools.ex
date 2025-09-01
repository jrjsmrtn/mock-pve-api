defmodule MockPveApi.Handlers.Pools do
  @moduledoc """
  Handler for PVE resource pool endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  GET /api2/json/pools
  Lists all resource pools.
  """
  def list_pools(conn) do
    pools = State.get_pools()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: pools}))
  end

  @doc """
  GET /api2/json/pools/:poolid
  Gets specific pool information.
  """
  def get_pool(conn) do
    poolid = conn.path_params["poolid"]
    pools = State.get_pools()

    case Enum.find(pools, fn pool -> pool.poolid == poolid end) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Pool '#{poolid}' not found"}
          })
        )

      pool ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: pool}))
    end
  end

  @doc """
  POST /api2/json/pools
  Creates a new resource pool.
  """
  def create_pool(conn) do
    params = conn.body_params
    poolid = Map.get(params, "poolid")

    if poolid do
      config = %{
        comment: Map.get(params, "comment", "")
      }

      case State.create_pool(poolid, config) do
        {:ok, _pool} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{
          errors: %{poolid: "property is missing and it is not optional"}
        })
      )
    end
  end

  @doc """
  PUT /api2/json/pools/:poolid
  Updates a resource pool configuration.
  """
  def update_pool(conn) do
    poolid = conn.path_params["poolid"]
    params = conn.body_params
    
    case State.update_pool(poolid, params) do
      {:ok, pool} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: pool}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/pools/:poolid
  Deletes a resource pool.
  """
  def delete_pool(conn) do
    poolid = conn.path_params["poolid"]
    pools = State.get_pools()

    case Enum.find(pools, fn pool -> pool.poolid == poolid end) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(
          404,
          Jason.encode!(%{
            errors: %{message: "Pool '#{poolid}' not found"}
          })
        )

      _pool ->
        State.delete_pool(poolid)

        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))
    end
  end
end
