# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.Access do
  @moduledoc """
  Handler for PVE access/authentication endpoints.
  """

  import Plug.Conn
  require Logger
  alias MockPveApi.State

  @doc """
  GET /api2/json/access/ticket
  Returns current authentication ticket info (mock: returns a static ticket).
  """
  def get_ticket(conn) do
    ticket_info = %{
      ticket: "PVE:root@pam:MOCK_TICKET",
      CSRFPreventionToken: "MOCK_CSRF_TOKEN",
      username: "root@pam"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: ticket_info}))
  end

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

    user_list =
      Enum.map(users, fn {userid, user} ->
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
    # Mock current user
    userid = "root@pam"

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

    role_list =
      Enum.map(roles, fn {roleid, privileges} ->
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
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{userid: "property is missing and it is not optional"}})
      )
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

    group_list =
      Enum.map(groups, fn {groupid, group} ->
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
      |> send_resp(
        400,
        Jason.encode!(%{errors: %{groupid: "property is missing and it is not optional"}})
      )
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

    domain_list =
      Enum.map(domains, fn {realm, domain} ->
        Map.put(domain, :realm, realm)
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: domain_list}))
  end

  @doc """
  POST /api2/json/access/domains
  Creates a new authentication realm/domain.
  """
  def create_domain(conn) do
    params = conn.body_params
    realm = Map.get(params, "realm")

    if realm do
      case State.create_domain(realm, params) do
        {:ok, domain} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: domain}))

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
        Jason.encode!(%{errors: %{realm: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  GET /api2/json/access/domains/:realm
  Gets specific domain/realm information.
  """
  def get_domain(conn) do
    realm = conn.path_params["realm"]

    case State.get_domain(realm) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Domain '#{realm}' not found"}}))

      domain ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: Map.put(domain, :realm, realm)}))
    end
  end

  @doc """
  PUT /api2/json/access/domains/:realm
  Updates an existing domain/realm.
  """
  def update_domain(conn) do
    realm = conn.path_params["realm"]
    params = conn.body_params

    case State.update_domain(realm, params) do
      {:ok, domain} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: domain}))

      {:error, message} ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
    end
  end

  @doc """
  DELETE /api2/json/access/domains/:realm
  Deletes an authentication realm/domain.
  """
  def delete_domain(conn) do
    realm = conn.path_params["realm"]

    case State.delete_domain(realm) do
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
  GET /api2/json/access/roles/:roleid
  Gets specific role information.
  """
  def get_role(conn) do
    roleid = conn.path_params["roleid"]

    case State.get_role(roleid) do
      nil ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(404, Jason.encode!(%{errors: %{message: "Role '#{roleid}' not found"}}))

      privs ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, Jason.encode!(%{data: %{roleid: roleid, privs: Enum.join(privs, ",")}}))
    end
  end

  @doc """
  POST /api2/json/access/roles
  Creates a new role.
  """
  def create_role(conn) do
    params = conn.body_params
    roleid = Map.get(params, "roleid")

    if roleid do
      privs_str = Map.get(params, "privs", "")

      privs =
        privs_str
        |> String.split(",")
        |> Enum.map(&String.trim/1)
        |> Enum.reject(&(&1 == ""))

      case State.create_role(roleid, privs) do
        {:ok, _} ->
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
        Jason.encode!(%{errors: %{roleid: "property is missing and it is not optional"}})
      )
    end
  end

  @doc """
  PUT /api2/json/access/roles/:roleid
  Updates an existing role.
  """
  def update_role(conn) do
    roleid = conn.path_params["roleid"]
    params = conn.body_params
    privs_str = Map.get(params, "privs", "")

    privs =
      privs_str
      |> String.split(",")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&(&1 == ""))

    case State.update_role(roleid, privs) do
      {:ok, _} ->
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
  DELETE /api2/json/access/roles/:roleid
  Deletes a role.
  """
  def delete_role(conn) do
    roleid = conn.path_params["roleid"]

    case State.delete_role(roleid) do
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
  PUT /api2/json/access/password
  Changes user password.
  """
  def change_password(conn) do
    params = conn.body_params
    userid = Map.get(params, "userid")
    password = Map.get(params, "password")

    if userid && password do
      case State.change_password(userid, password) do
        :ok ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, Jason.encode!(%{data: nil}))

        {:error, message} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(404, Jason.encode!(%{errors: %{message: message}}))
      end
    else
      conn
      |> put_resp_content_type("application/json")
      |> send_resp(400, Jason.encode!(%{errors: %{message: "Missing required parameters"}}))
    end
  end

  @doc """
  GET /api2/json/access/acl
  Gets access control list.
  """
  def get_acl(conn) do
    acl = State.get_acl()

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: acl}))
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

  # --- TFA ---

  @doc """
  PUT /api2/json/access/tfa
  Update TFA settings (mock: no-op, returns nil).
  """
  def update_tfa(conn) do
    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: nil}))
  end

  @doc """
  GET /api2/json/access/tfa
  Lists TFA configurations for all users.
  """
  def list_tfa(conn) do
    users = State.get_state().users

    tfa_entries =
      Enum.map(users, fn {userid, _user} ->
        %{userid: userid, entries: []}
      end)

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: tfa_entries}))
  end

  @doc """
  POST /api2/json/access/tfa
  Add TFA entry for the current user (mock: returns success with a recovery key).
  """
  def add_tfa(conn) do
    result = %{
      recovery:
        Enum.map(1..8, fn _ ->
          :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
        end)
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: result}))
  end

  @doc """
  POST /api2/json/access/tfa/:userid
  Add a TFA entry for a user (mock: returns a static recovery key set).
  """
  def create_tfa_entry(conn) do
    userid = conn.path_params["userid"]

    result = %{
      id: "totp/#{userid}",
      type: "totp",
      description: "Mock TFA entry"
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: result}))
  end

  @doc """
  GET /api2/json/access/tfa/:userid
  Get TFA configuration for a specific user.
  """
  def get_user_tfa(conn) do
    userid = conn.path_params["userid"]

    tfa_data = %{
      userid: userid,
      entries: []
    }

    conn
    |> put_resp_content_type("application/json")
    |> send_resp(200, Jason.encode!(%{data: tfa_data}))
  end
end
