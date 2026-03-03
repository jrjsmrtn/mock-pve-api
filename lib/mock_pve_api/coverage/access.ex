# SPDX-FileCopyrightText: 2025 Georges Martin
# SPDX-License-Identifier: MIT

defmodule MockPveApi.Coverage.Access do
  @moduledoc """
  PVE API coverage: Access control and authentication endpoints.

  Covers `/access/*` in the PVE API Viewer.
  """

  @behaviour MockPveApi.Coverage.Category

  @impl true
  def category, do: :access

  @impl true
  def endpoints do
    Map.merge(implemented_endpoints(), planned_endpoints())
  end

  defp implemented_endpoints do
    %{
      "/api2/json/access/users" => %{
        path: "/api2/json/access/users",
        methods: [:get, :post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "User account management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/users/{userid}" => %{
        path: "/api2/json/access/users/{userid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual user account operations",
        parameters: [
          %{
            name: "userid",
            type: :string,
            required: true,
            description: "User ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Individual user CRUD operations implemented"
      },
      "/api2/json/access/users/{userid}/token" => %{
        path: "/api2/json/access/users/{userid}/token",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "List API tokens for user",
        parameters: [
          %{
            name: "userid",
            type: :string,
            required: true,
            description: "User ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/users/{userid}/token/{tokenid}" => %{
        path: "/api2/json/access/users/{userid}/token/{tokenid}",
        methods: [:get, :post, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual API token operations",
        parameters: [
          %{
            name: "userid",
            type: :string,
            required: true,
            description: "User ID",
            values: nil,
            default: nil
          },
          %{
            name: "tokenid",
            type: :string,
            required: true,
            description: "Token ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "API token CRUD operations implemented"
      },
      "/api2/json/access/ticket" => %{
        path: "/api2/json/access/ticket",
        methods: [:post],
        status: :implemented,
        priority: :high,
        since: "6.0",
        description: "Authentication ticket creation",
        parameters: [
          %{
            name: "username",
            type: :string,
            required: true,
            description: "Username",
            values: nil,
            default: nil
          },
          %{
            name: "password",
            type: :string,
            required: true,
            description: "Password",
            values: nil,
            default: nil
          },
          %{
            name: "realm",
            type: :string,
            required: false,
            description: "Authentication realm",
            values: nil,
            default: "pam"
          }
        ],
        response_schema: %{data: %{ticket: :string, CSRFPreventionToken: :string}},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Authentication system implemented"
      },
      "/api2/json/access/groups" => %{
        path: "/api2/json/access/groups",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "User group management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Group management implemented"
      },
      "/api2/json/access/groups/{groupid}" => %{
        path: "/api2/json/access/groups/{groupid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual group operations",
        parameters: [
          %{
            name: "groupid",
            type: :string,
            required: true,
            description: "Group ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: "Individual group CRUD operations implemented"
      },
      "/api2/json/access/domains" => %{
        path: "/api2/json/access/domains",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Authentication realms/domains management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/permissions" => %{
        path: "/api2/json/access/permissions",
        methods: [:get],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Get current user permissions",
        parameters: [],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: false,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/acl" => %{
        path: "/api2/json/access/acl",
        methods: [:get, :put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Access control list management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/roles" => %{
        path: "/api2/json/access/roles",
        methods: [:get, :post],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Role management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/domains/{realm}/sync" => %{
        path: "/api2/json/access/domains/{realm}/sync",
        methods: [:post],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Sync realm/domain from external source",
        parameters: [
          %{
            name: "realm",
            type: :string,
            required: true,
            description: "Realm name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :string},
        capabilities_required: [],
        test_coverage: false,
        handler_module: nil,
        notes: "Inline handler in router; realm sync available in PVE 8.0+"
      },
      "/api2/json/access/roles/{roleid}" => %{
        path: "/api2/json/access/roles/{roleid}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual role CRUD",
        parameters: [
          %{
            name: "roleid",
            type: :string,
            required: true,
            description: "Role ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/domains/{realm}" => %{
        path: "/api2/json/access/domains/{realm}",
        methods: [:get, :put, :delete],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Individual realm/domain CRUD",
        parameters: [
          %{
            name: "realm",
            type: :string,
            required: true,
            description: "Realm name",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/password" => %{
        path: "/api2/json/access/password",
        methods: [:put],
        status: :implemented,
        priority: :medium,
        since: "6.0",
        description: "Change user password",
        parameters: [
          %{
            name: "userid",
            type: :string,
            required: true,
            description: "User ID",
            values: nil,
            default: nil
          },
          %{
            name: "password",
            type: :string,
            required: true,
            description: "New password",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/tfa" => %{
        path: "/api2/json/access/tfa",
        methods: [:get, :post],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "Two-factor authentication management",
        parameters: [],
        response_schema: %{data: :array},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      },
      "/api2/json/access/tfa/{userid}" => %{
        path: "/api2/json/access/tfa/{userid}",
        methods: [:get],
        status: :implemented,
        priority: :low,
        since: "7.0",
        description: "User TFA configuration",
        parameters: [
          %{
            name: "userid",
            type: :string,
            required: true,
            description: "User ID",
            values: nil,
            default: nil
          }
        ],
        response_schema: %{data: :object},
        capabilities_required: [:user_management_basic],
        test_coverage: true,
        handler_module: MockPveApi.Handlers.Access,
        notes: nil
      }
    }
  end

  defp planned_endpoints do
    %{}
  end
end
