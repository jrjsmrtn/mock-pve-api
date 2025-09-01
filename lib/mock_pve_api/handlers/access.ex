defmodule MockPveApi.Handlers.Access do
  @moduledoc """
  Handler for PVE access/authentication endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  POST /api2/json/access/ticket
  Creates authentication ticket for username/password authentication.
  """
  def create_ticket(conn) do
    params = conn.body_params

    username = Map.get(params, "username")
    password = Map.get(params, "password")

    if username && password do
      case State.create_ticket(username, password) do
        {:ok, ticket_data} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: ticket_data}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(401, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(
        400,
        Jason.encode!(%{
          errors: %{
            username: "property is missing and it is not optional",
            password: "property is missing and it is not optional"
          }
        })
      )
    end
  end

  @doc """
  GET /api2/json/access/users
  Lists all users in the system.
  """
  def list_users(conn) do
    users = State.get_state().users
    user_list = Enum.map(users, fn {userid, user} ->
      Map.put(user, :userid, userid)
    end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: user_list}))
  end

  @doc """
  GET /api2/json/access/users/:userid
  Gets specific user information.
  """
  def get_user(conn) do
    userid = conn.path_params["userid"]
    users = State.get_state().users

    case Map.get(users, userid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "User '#{userid}' not found"}}))

      user ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: Map.put(user, :userid, userid)}))
    end
  end

  @doc """
  POST /api2/json/access/users/:userid/token/:tokenid
  Creates an API token for a user.
  """
  def create_api_token(conn) do
    userid = conn.path_params["userid"]
    tokenid = conn.path_params["tokenid"]
    params = conn.body_params

    case State.create_api_token(userid, tokenid, params) do
      {:ok, token_data} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: token_data}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/access/users/:userid/token
  Lists API tokens for a user.
  """
  def list_user_tokens(conn) do
    userid = conn.path_params["userid"]
    tokens = State.get_state().api_tokens

    user_tokens = 
      tokens
      |> Enum.filter(fn {tokenid, _token} -> String.starts_with?(tokenid, "#{userid}!") end)
      |> Enum.map(fn {tokenid, token} ->
        Map.take(token, [:tokenid, :privsep, :comment, :expire, :created_at])
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: user_tokens}))
  end

  @doc """
  GET /api2/json/access/permissions
  Gets permissions for current user.
  """
  def get_permissions(conn) do
    # In a real implementation, this would get the user from the auth token
    userid = "root@pam"  # Mock current user
    
    permissions = State.get_permissions(userid)
    
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: permissions}))
  end

  @doc """
  PUT /api2/json/access/acl
  Sets access control permissions.
  """
  def set_acl(conn) do
    params = conn.body_params
    path = Map.get(params, "path", "/")
    userid = Map.get(params, "users")
    roleid = Map.get(params, "roles")

    if userid && roleid do
      :ok = State.set_permissions(path, userid, roleid)
      
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(200, Jason.encode!(%{data: nil}))
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{message: "Missing required parameters"}}))
    end
  end

  @doc """
  GET /api2/json/access/roles
  Lists all available roles.
  """
  def list_roles(conn) do
    roles = State.get_state().roles
    role_list = Enum.map(roles, fn {roleid, privileges} ->
      %{roleid: roleid, privs: privileges}
    end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: role_list}))
  end
end
