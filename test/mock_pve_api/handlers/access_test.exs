# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Handlers.AccessTest do
  use ExUnit.Case, async: false

  alias MockPveApi.Handlers.Access
  alias MockPveApi.State

  setup do
    State.reset()
    :ok
  end

  defp build_conn(method, path, body_params \\ %{}, path_params \\ %{}) do
    conn = Plug.Test.conn(method, path)
    %{conn | body_params: body_params, path_params: path_params}
  end

  # --- Ticket ---

  describe "create_ticket/1" do
    test "creates ticket for valid user" do
      conn =
        build_conn(:post, "/api2/json/access/ticket", %{
          "username" => "root@pam",
          "password" => "secret"
        })

      conn = Access.create_ticket(conn)
      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["username"] == "root@pam"
      assert is_binary(body["data"]["ticket"])
    end

    test "returns 401 for unknown user" do
      conn =
        build_conn(:post, "/api2/json/access/ticket", %{
          "username" => "unknown@pam",
          "password" => "secret"
        })

      conn = Access.create_ticket(conn)
      assert conn.status == 401
    end

    test "returns 400 when username or password missing" do
      conn = build_conn(:post, "/api2/json/access/ticket", %{"username" => "root@pam"})
      conn = Access.create_ticket(conn)
      assert conn.status == 400
    end
  end

  # --- Users ---

  describe "list_users/1" do
    test "returns users" do
      conn = build_conn(:get, "/api2/json/access/users")
      conn = Access.list_users(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) >= 1
    end
  end

  describe "get_user/1" do
    test "returns user by ID" do
      conn = build_conn(:get, "/api2/json/access/users/root@pam", %{}, %{"userid" => "root@pam"})
      conn = Access.get_user(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["userid"] == "root@pam"
    end

    test "returns 404 for unknown user" do
      conn =
        build_conn(:get, "/api2/json/access/users/unknown@pam", %{}, %{
          "userid" => "unknown@pam"
        })

      conn = Access.get_user(conn)
      assert conn.status == 404
    end
  end

  describe "create_user/1" do
    test "creates a user" do
      conn =
        build_conn(:post, "/api2/json/access/users", %{
          "userid" => "test@pam",
          "comment" => "Test user"
        })

      conn = Access.create_user(conn)
      assert conn.status == 200
    end

    test "returns 400 when userid missing" do
      conn = build_conn(:post, "/api2/json/access/users", %{"comment" => "no id"})
      conn = Access.create_user(conn)
      assert conn.status == 400
    end

    test "returns 400 for duplicate user" do
      conn =
        build_conn(:post, "/api2/json/access/users", %{"userid" => "root@pam"})

      conn = Access.create_user(conn)
      assert conn.status == 400
    end
  end

  describe "update_user/1" do
    test "updates user" do
      conn =
        build_conn(
          :put,
          "/api2/json/access/users/root@pam",
          %{"comment" => "Updated"},
          %{"userid" => "root@pam"}
        )

      conn = Access.update_user(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent user" do
      conn =
        build_conn(
          :put,
          "/api2/json/access/users/unknown@pam",
          %{"comment" => "X"},
          %{"userid" => "unknown@pam"}
        )

      conn = Access.update_user(conn)
      assert conn.status == 404
    end
  end

  describe "delete_user/1" do
    test "deletes existing user" do
      State.create_user("test@pam", %{})

      conn =
        build_conn(:delete, "/api2/json/access/users/test@pam", %{}, %{"userid" => "test@pam"})

      conn = Access.delete_user(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent user" do
      conn =
        build_conn(:delete, "/api2/json/access/users/unknown@pam", %{}, %{
          "userid" => "unknown@pam"
        })

      conn = Access.delete_user(conn)
      assert conn.status == 404
    end
  end

  # --- Groups ---

  describe "list_groups/1" do
    test "returns groups" do
      conn = build_conn(:get, "/api2/json/access/groups")
      conn = Access.list_groups(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) >= 1
    end
  end

  describe "get_group/1" do
    test "returns group by ID" do
      conn = build_conn(:get, "/api2/json/access/groups/admin", %{}, %{"groupid" => "admin"})
      conn = Access.get_group(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["groupid"] == "admin"
    end

    test "returns 404 for unknown group" do
      conn =
        build_conn(:get, "/api2/json/access/groups/nonexistent", %{}, %{
          "groupid" => "nonexistent"
        })

      conn = Access.get_group(conn)
      assert conn.status == 404
    end
  end

  describe "create_group/1" do
    test "creates a group" do
      conn =
        build_conn(:post, "/api2/json/access/groups", %{
          "groupid" => "devs",
          "comment" => "Developers"
        })

      conn = Access.create_group(conn)
      assert conn.status == 200
    end

    test "returns 400 when groupid missing" do
      conn = build_conn(:post, "/api2/json/access/groups", %{"comment" => "no id"})
      conn = Access.create_group(conn)
      assert conn.status == 400
    end

    test "returns 400 for duplicate group" do
      conn = build_conn(:post, "/api2/json/access/groups", %{"groupid" => "admin"})
      conn = Access.create_group(conn)
      assert conn.status == 400
    end
  end

  describe "update_group/1" do
    test "updates group" do
      conn =
        build_conn(
          :put,
          "/api2/json/access/groups/admin",
          %{"comment" => "Updated"},
          %{"groupid" => "admin"}
        )

      conn = Access.update_group(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent group" do
      conn =
        build_conn(
          :put,
          "/api2/json/access/groups/nonexistent",
          %{},
          %{"groupid" => "nonexistent"}
        )

      conn = Access.update_group(conn)
      assert conn.status == 404
    end
  end

  describe "delete_group/1" do
    test "deletes existing group" do
      State.create_group("devs", %{})

      conn =
        build_conn(:delete, "/api2/json/access/groups/devs", %{}, %{"groupid" => "devs"})

      conn = Access.delete_group(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent group" do
      conn =
        build_conn(:delete, "/api2/json/access/groups/nonexistent", %{}, %{
          "groupid" => "nonexistent"
        })

      conn = Access.delete_group(conn)
      assert conn.status == 404
    end
  end

  # --- Tokens ---

  describe "create_api_token/1" do
    test "creates token for existing user" do
      conn =
        build_conn(
          :post,
          "/api2/json/access/users/root@pam/token/mytoken",
          %{},
          %{"userid" => "root@pam", "tokenid" => "mytoken"}
        )

      conn = Access.create_api_token(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["tokenid"] == "root@pam!mytoken"
    end

    test "returns 400 for nonexistent user" do
      conn =
        build_conn(
          :post,
          "/api2/json/access/users/unknown@pam/token/tok",
          %{},
          %{"userid" => "unknown@pam", "tokenid" => "tok"}
        )

      conn = Access.create_api_token(conn)
      assert conn.status == 400
    end
  end

  describe "list_user_tokens/1" do
    test "returns empty list initially" do
      conn =
        build_conn(:get, "/api2/json/access/users/root@pam/token", %{}, %{
          "userid" => "root@pam"
        })

      conn = Access.list_user_tokens(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"] == []
    end

    test "returns tokens after creation" do
      State.create_api_token("root@pam", "tok1")

      conn =
        build_conn(:get, "/api2/json/access/users/root@pam/token", %{}, %{
          "userid" => "root@pam"
        })

      conn = Access.list_user_tokens(conn)

      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) == 1
    end
  end

  describe "get_api_token/1" do
    test "returns token info" do
      State.create_api_token("root@pam", "tok1")

      conn =
        build_conn(
          :get,
          "/api2/json/access/users/root@pam/token/tok1",
          %{},
          %{"userid" => "root@pam", "tokenid" => "tok1"}
        )

      conn = Access.get_api_token(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert body["data"]["tokenid"] == "root@pam!tok1"
      # Token value should not be in the response
      refute Map.has_key?(body["data"], "token")
    end

    test "returns 404 for nonexistent token" do
      conn =
        build_conn(
          :get,
          "/api2/json/access/users/root@pam/token/nonexistent",
          %{},
          %{"userid" => "root@pam", "tokenid" => "nonexistent"}
        )

      conn = Access.get_api_token(conn)
      assert conn.status == 404
    end
  end

  describe "update_api_token/1" do
    test "updates token metadata" do
      State.create_api_token("root@pam", "tok1")

      conn =
        build_conn(
          :put,
          "/api2/json/access/users/root@pam/token/tok1",
          %{"comment" => "Updated"},
          %{"userid" => "root@pam", "tokenid" => "tok1"}
        )

      conn = Access.update_api_token(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent token" do
      conn =
        build_conn(
          :put,
          "/api2/json/access/users/root@pam/token/nonexistent",
          %{},
          %{"userid" => "root@pam", "tokenid" => "nonexistent"}
        )

      conn = Access.update_api_token(conn)
      assert conn.status == 404
    end
  end

  describe "delete_api_token/1" do
    test "deletes existing token" do
      State.create_api_token("root@pam", "tok1")

      conn =
        build_conn(
          :delete,
          "/api2/json/access/users/root@pam/token/tok1",
          %{},
          %{"userid" => "root@pam", "tokenid" => "tok1"}
        )

      conn = Access.delete_api_token(conn)
      assert conn.status == 200
    end

    test "returns 404 for nonexistent token" do
      conn =
        build_conn(
          :delete,
          "/api2/json/access/users/root@pam/token/nonexistent",
          %{},
          %{"userid" => "root@pam", "tokenid" => "nonexistent"}
        )

      conn = Access.delete_api_token(conn)
      assert conn.status == 404
    end
  end

  # --- Permissions and ACL ---

  describe "get_permissions/1" do
    test "returns permissions for current user" do
      conn = build_conn(:get, "/api2/json/access/permissions")
      conn = Access.get_permissions(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert is_list(body["data"])
    end
  end

  describe "set_acl/1" do
    test "sets permissions" do
      conn =
        build_conn(:put, "/api2/json/access/acl", %{
          "path" => "/vms",
          "users" => "root@pam",
          "roles" => "PVEAdmin"
        })

      conn = Access.set_acl(conn)
      assert conn.status == 200
    end

    test "returns 400 when required params missing" do
      conn = build_conn(:put, "/api2/json/access/acl", %{"path" => "/"})
      conn = Access.set_acl(conn)
      assert conn.status == 400
    end
  end

  # --- Roles ---

  describe "list_roles/1" do
    test "returns roles" do
      conn = build_conn(:get, "/api2/json/access/roles")
      conn = Access.list_roles(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) >= 1

      admin_role = Enum.find(body["data"], &(&1["roleid"] == "Administrator"))
      assert admin_role != nil
    end
  end

  # --- Domains ---

  describe "list_domains/1" do
    test "returns authentication domains" do
      conn = build_conn(:get, "/api2/json/access/domains")
      conn = Access.list_domains(conn)

      assert conn.status == 200
      body = Jason.decode!(conn.resp_body)
      assert length(body["data"]) >= 2

      realms = Enum.map(body["data"], & &1["realm"])
      assert "pam" in realms
      assert "pve" in realms
    end
  end
end
