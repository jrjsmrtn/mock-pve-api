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
      |> Enum.map(fn {_tokenid, token} ->
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

  @doc """
  POST /api2/json/access/users
  Creates a new user.
  """
  def create_user(conn) do
    params = conn.body_params
    userid = Map.get(params, "userid")
    
    if userid do
      case State.create_user(userid, params) do
        {:ok, user} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: user}))
          
        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{userid: "property is missing and it is not optional"}}))
    end
  end

  @doc """
  PUT /api2/json/access/users/:userid
  Updates an existing user.
  """
  def update_user(conn) do
    userid = conn.path_params["userid"]
    params = conn.body_params
    
    case State.update_user(userid, params) do
      {:ok, user} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: user}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/access/users/:userid
  Deletes a user.
  """
  def delete_user(conn) do
    userid = conn.path_params["userid"]
    
    case State.delete_user(userid) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/access/groups
  Lists all groups.
  """
  def list_groups(conn) do
    groups = State.get_state().groups
    group_list = Enum.map(groups, fn {groupid, group} ->
      Map.put(group, :groupid, groupid)
    end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: group_list}))
  end

  @doc """
  POST /api2/json/access/groups
  Creates a new group.
  """
  def create_group(conn) do
    params = conn.body_params
    groupid = Map.get(params, "groupid")
    
    if groupid do
      case State.create_group(groupid, params) do
        {:ok, group} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: group}))
          
        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(400, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{groupid: "property is missing and it is not optional"}}))
    end
  end

  @doc """
  GET /api2/json/access/groups/:groupid
  Gets specific group information.
  """
  def get_group(conn) do
    groupid = conn.path_params["groupid"]
    groups = State.get_state().groups

    case Map.get(groups, groupid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Group '#{groupid}' not found"}}))

      group ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: Map.put(group, :groupid, groupid)}))
    end
  end

  @doc """
  PUT /api2/json/access/groups/:groupid
  Updates an existing group.
  """
  def update_group(conn) do
    groupid = conn.path_params["groupid"]
    params = conn.body_params
    
    case State.update_group(groupid, params) do
      {:ok, group} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: group}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/access/groups/:groupid
  Deletes a group.
  """
  def delete_group(conn) do
    groupid = conn.path_params["groupid"]
    
    case State.delete_group(groupid) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/access/domains
  Lists authentication realms/domains.
  """
  def list_domains(conn) do
    domains = State.get_state().domains
    domain_list = Enum.map(domains, fn {realm, domain} ->
      Map.put(domain, :realm, realm)
    end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: domain_list}))
  end

  @doc """
  DELETE /api2/json/access/users/:userid/token/:tokenid
  Deletes an API token for a user.
  """
  def delete_api_token(conn) do
    userid = conn.path_params["userid"]
    tokenid = conn.path_params["tokenid"]
    full_tokenid = "#{userid}!#{tokenid}"
    
    case State.delete_api_token(full_tokenid) do
      :ok ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: nil}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  GET /api2/json/access/users/:userid/token/:tokenid
  Gets specific API token information.
  """
  def get_api_token(conn) do
    userid = conn.path_params["userid"]
    tokenid = conn.path_params["tokenid"]
    full_tokenid = "#{userid}!#{tokenid}"
    
    tokens = State.get_state().api_tokens
    
    case Map.get(tokens, full_tokenid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Token '#{tokenid}' not found"}}))
        
      token ->
        # Don't include the actual token value in response
        safe_token = Map.take(token, [:tokenid, :privsep, :comment, :expire, :created_at])
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: safe_token}))
    end
  end

  @doc """
  PUT /api2/json/access/users/:userid/token/:tokenid
  Updates an existing API token.
  """
  def update_api_token(conn) do
    userid = conn.path_params["userid"]
    tokenid = conn.path_params["tokenid"]
    full_tokenid = "#{userid}!#{tokenid}"
    params = conn.body_params
    
    case State.update_api_token(full_tokenid, params) do
      {:ok, token} ->
        safe_token = Map.take(token, [:tokenid, :privsep, :comment, :expire, :created_at])
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: safe_token}))
        
      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end
end
