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

  # Sprint 4.9.3 - Domain CRUD (via router)

  defp request(method, path, body \\ nil) do
    conn =
      Plug.Test.conn(method, path, body && Jason.encode!(body))
      |> Plug.Conn.put_req_header("content-type", "application/json")
      |> Plug.Conn.put_req_header("authorization", "PVEAPIToken=root@pam!test=secret")

    MockPveApi.Router.call(conn, MockPveApi.Router.init([]))
  end

  defp json(conn, status) do
    assert conn.status == status
    Jason.decode!(conn.resp_body)
  end

  describe "domain CRUD" do
    test "create and get domain" do
      conn = request(:post, "/api2/json/access/domains", %{"realm" => "ldap1", "type" => "ldap"})
      assert conn.status == 200

      conn = request(:get, "/api2/json/access/domains/ldap1")
      domain = json(conn, 200)["data"]
      assert domain["realm"] == "ldap1"
      assert domain["type"] == "ldap"
    end

    test "update domain" do
      conn =
        request(:put, "/api2/json/access/domains/pam", %{"comment" => "Updated PAM"})

      assert conn.status == 200

      updated = State.get_domain("pam")
      assert updated.comment == "Updated PAM"
    end

    test "delete domain" do
      State.create_domain("test-realm", %{"type" => "pam"})

      conn = request(:delete, "/api2/json/access/domains/test-realm")
      assert conn.status == 200
      assert State.get_domain("test-realm") == nil
    end

    test "create duplicate domain returns 400" do
      conn = request(:post, "/api2/json/access/domains", %{"realm" => "pam"})
      assert conn.status == 400
    end

    test "get nonexistent domain returns 404" do
      conn = request(:get, "/api2/json/access/domains/nonexistent")
      assert conn.status == 404
    end

    test "create domain requires realm" do
      conn = request(:post, "/api2/json/access/domains", %{"type" => "ldap"})
      assert conn.status == 400
    end

    test "domains listed includes new domain" do
      State.create_domain("ad1", %{"type" => "ad"})

      conn = request(:get, "/api2/json/access/domains")
      domains = json(conn, 200)["data"]
      realms = Enum.map(domains, & &1["realm"])
      assert "ad1" in realms
    end
  end

  # Sprint 4.9.3 - Role CRUD

  describe "role CRUD" do
    test "create and get role" do
      conn =
        request(:post, "/api2/json/access/roles", %{
          "roleid" => "TestRole",
          "privs" => "VM.Audit,VM.PowerMgmt"
        })

      assert conn.status == 200

      conn = request(:get, "/api2/json/access/roles/TestRole")
      role = json(conn, 200)["data"]
      assert role["roleid"] == "TestRole"
      assert role["privs"] =~ "VM.Audit"
    end

    test "get existing Administrator role" do
      conn = request(:get, "/api2/json/access/roles/Administrator")
      role = json(conn, 200)["data"]
      assert role["roleid"] == "Administrator"
      assert role["privs"] =~ "VM.Allocate"
    end

    test "update role" do
      State.create_role("EditRole", ["VM.Audit"])

      conn =
        request(:put, "/api2/json/access/roles/EditRole", %{"privs" => "VM.Audit,VM.PowerMgmt"})

      assert conn.status == 200
      updated = State.get_role("EditRole")
      assert "VM.PowerMgmt" in updated
    end

    test "delete role" do
      State.create_role("DelRole", ["VM.Audit"])

      conn = request(:delete, "/api2/json/access/roles/DelRole")
      assert conn.status == 200
      assert State.get_role("DelRole") == nil
    end

    test "create duplicate role returns 400" do
      conn = request(:post, "/api2/json/access/roles", %{"roleid" => "Administrator"})
      assert conn.status == 400
    end

    test "get nonexistent role returns 404" do
      conn = request(:get, "/api2/json/access/roles/nonexistent")
      assert conn.status == 404
    end

    test "create role requires roleid" do
      conn = request(:post, "/api2/json/access/roles", %{"privs" => "VM.Audit"})
      assert conn.status == 400
    end

    test "roles listed includes new role" do
      State.create_role("ListedRole", ["VM.Audit"])

      conn = request(:get, "/api2/json/access/roles")
      roles = json(conn, 200)["data"]
      roleids = Enum.map(roles, & &1["roleid"])
      assert "ListedRole" in roleids
    end
  end

  # Sprint 4.9.3 - Password Change

  describe "password change" do
    test "change password for existing user" do
      conn =
        request(:put, "/api2/json/access/password", %{
          "userid" => "root@pam",
          "password" => "newpassword"
        })

      assert conn.status == 200
    end

    test "change password for nonexistent user returns 404" do
      conn =
        request(:put, "/api2/json/access/password", %{
          "userid" => "unknown@pam",
          "password" => "newpassword"
        })

      assert conn.status == 404
    end

    test "change password requires userid and password" do
      conn = request(:put, "/api2/json/access/password", %{"userid" => "root@pam"})
      assert conn.status == 400
    end
  end

  # Sprint 4.9.3 - ACL GET

  describe "ACL GET" do
    test "get ACL list" do
      conn = request(:get, "/api2/json/access/acl")
      acl = json(conn, 200)["data"]
      assert is_list(acl)
      # Default state has root@pam with Administrator role on /
      assert length(acl) >= 1
      entry = hd(acl)
      assert entry["path"] == "/"
      assert entry["ugid"] == "root@pam"
    end
  end
end
